#ifndef SIH_TOWNSCAPER_OUTLINE_PASS_INCLUDED
#define SIH_TOWNSCAPER_OUTLINE_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "SIH_TownscaperFunction.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    
#ifdef _USESMOOTHNORMALOUTLINE_ON
    float4 color : COLOR;
#endif
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 uvPalette : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    half fogFactor : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings vert (Attributes input)
{
    Varyings output;                
    
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap) * lerp(1.0, 4.0, _DebugUV4x4);
    output.uvPalette = TRANSFORM_TEX(input.texcoord, _PaletteMap) * (1 / float2(16.0, 2.0)) + _PaletteColorOffset;
    
#ifdef _USESMOOTHNORMALOUTLINE_ON
    input.normalOS = input.color.xyz;// * 2 - 1;
#endif
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    float3 normalCS = TransformWorldToHClipDir(output.normalWS);

    float4 scaledScreenParams = GetScaledScreenParams();
    float scaleX = abs(scaledScreenParams.x / scaledScreenParams.y);    //求得X因屏幕比例缩放的倍数

    // 计算物体到摄像机的距离
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float distance = length(positionWS - _WorldSpaceCameraPos);
    float adjustedOutlineWidth = _OutlineWidth * 0.01 * distance;
    adjustedOutlineWidth = clamp(adjustedOutlineWidth, _OutlineMinWidth, _OutlineMaxWidth);
    
    float2 extendis = normalize(normalCS.xy) * adjustedOutlineWidth;  // 根据法线和线宽计算偏移量
    // float2 extendis = normalize(normalCS.xy) * (_OutlineWidth * 0.01);  //根据法线和线宽计算偏移量
    extendis.x /= scaleX;   //修正屏幕比例x
    #if _USEOUTLINE_ON
    output.positionHCS.xy += extendis;
    #endif
    
    output.fogFactor = ComputeFogFactor(output.positionHCS.z);

    return output;
}

float4 frag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    // Light
    Light mainLight = GetMainLight();
    half3 lightColor = mainLight.color;
    float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    float3 lightShadowColor = lerp(half(0.1).rrr, half3(1.0, 1.0, 1.0), lightShadow);
    float3 bakeGI = SampleSH(input.normalWS);


    // BaseMap
    float2 baseMapUV = (frac(input.uv) * _PixelNumber + 0.6) / 2.0;
    baseMapUV = floor(baseMapUV) * 2.0 + floor(min(frac(baseMapUV) - _PixelOffset, 0.0)) + 0.5;
    baseMapUV = baseMapUV / _PixelNumber;
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseMapUV) * _BaseColor;
    half maskMap = Saturation(SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, baseMapUV).rgb, 0.0).g;

    // Palette
    float2 paletteUV = input.uvPalette;
    half4 paletteMap = SAMPLE_TEXTURE2D(_PaletteMap, sampler_PaletteMap, paletteUV);
    half4 roofPaletteMap = SAMPLE_TEXTURE2D(_RoofPaletteMap, sampler_RoofPaletteMap, paletteUV);
    half3 roofFinal = lerp(roofPaletteMap.rgb, _RoofColor.rgb, _RoofColor.a);
    half3 paletteColor = (maskMap >= 0.7 && maskMap <= 0.75) ? roofFinal : paletteMap.rgb;
    
    // Color
    half alpha = baseMap.a;
    half3 color = lerp(baseMap.rgb, paletteColor, 1.0 - baseMap.a);
    color = DayNightColorBlend(color, lightColor, 1,  _DayColor, _NightColor, _DayIntensity, _NightIntensity);
    color = pow(color,1.5) * lightShadowColor + Saturation(baseMap,saturate(pow(ToGray(lightColor), 1))) * bakeGI;
    color *= _OutlineColor.rgb;

    // Final
    color = MixFog(color.rgb, input.fogFactor);
#ifdef _ALPHACUT_ON
    clip(alpha - _Cutoff);
#endif
    
    return float4(color, alpha);
}

#endif
