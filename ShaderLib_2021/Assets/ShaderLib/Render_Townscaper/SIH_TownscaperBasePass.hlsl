#ifndef SIH_TOWNSCAPER_BASE_PASS_INCLUDED
#define SIH_TOWNSCAPER_BASE_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "SIH_TownscaperFunction.hlsl"


struct Attributes
{
    float4 positionOS : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 staticLightmapUV   : TEXCOORD1;
    float2 dynamicLightmapUV  : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionHCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 uvPalette : TEXCOORD1;
    float3 positionWS : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    half fogFactor : TEXCOORD4;
    
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD5;
#endif
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 6);
#ifdef DYNAMICLIGHTMAP_ON
    float2  dynamicLightmapUV : TEXCOORD7; // Dynamic lightmap UVs
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings vert(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionHCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangent);
    output.normalWS = normalInput.normalWS;

    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap) * lerp(1.0, 4.0, _DebugUV4x4);
    output.uvPalette = TRANSFORM_TEX(input.texcoord, _PaletteMap) * (1 / float2(16.0, 2.0)) ;


    // Light
    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    output.fogFactor = ComputeFogFactor(output.positionHCS.z);
    
    // Shadow
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif
    
    return output;
}

half4 frag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    // Light
    input.normalWS = NormalizeNormalPerPixel(input.normalWS);
    float3 bakeGI = SampleSH(input.normalWS);
    /*float4 upColor = float4(1,1,1,1) * 1.0;
    float4 sideColor = float4(1,1,1,1) * 0.5;
    float4 downColor = float4(1,1,1,1) * 0.1;
    float3 bakeGI = ThreeColorAmbient(input.normalWS, upColor, sideColor, downColor);*/

    #if defined(DYNAMICLIGHTMAP_ON)
        bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, input.normalWS);
    #else
        bakeGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, input.normalWS);
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        float4 shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    #else
        float4 shadowCoord = float4(0, 0, 0, 0);
    #endif
    
    Light mainLight = GetMainLight(shadowCoord);
    float3 lightDir = normalize(mainLight.direction);
    half3 lightColor = mainLight.color;
    float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, input.positionWS);//获得额外光源结构体（内部包含阴影衰减）
        lightShadow *= light.shadowAttenuation;
        lightColor += light.color;
    }
#endif
    
    // lightShadow = ShadowFix(input.positionWS);   // 阴影修复
    float3 lightShadowColor = lerp(half(0.1).rrr, half3(1.0, 1.0, 1.0), lightShadow);
    half lambert = saturate(dot(normalize(input.normalWS), lightDir)) ;

    // BaseMap
    float2 baseMapUV = (frac(input.uv) * _PixelNumber + 0.6) / 2.0;
    baseMapUV = floor(baseMapUV) * 2.0 + floor(min(frac(baseMapUV) - _PixelOffset, 0.0)) + 0.5;
    baseMapUV = baseMapUV / _PixelNumber;
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseMapUV);
    half maskMap = Saturation(SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, baseMapUV).rgb, 0.0).g;

    // Palette
    float2 paletteUV = input.uvPalette;
    half4 paletteMap = SAMPLE_TEXTURE2D(_PaletteMap, sampler_PaletteMap, paletteUV + _PaletteColorOffset / 16.0);
    half4 roofPaletteMap = SAMPLE_TEXTURE2D(_RoofPaletteMap, sampler_RoofPaletteMap, paletteUV + _RoofColorOffset / 16.0);
    half3 roofFinal = lerp(roofPaletteMap.rgb, _RoofColor.rgb, _RoofColor.a);
    half3 paletteColor = saturate(maskMap >= 0.7 && maskMap <= 0.75) ? roofFinal : paletteMap.rgb;
    half3 emissionFinal = lerp(float3(0.0, 0.0, 0.0), _EmissionColor.rgb, _EmissionColor.a);
    half3 emissionColor = saturate(maskMap >= 0.001 && maskMap <= 0.01) ? emissionFinal : float3(0.0, 0.0, 0.0);
    
    // Color
    half alpha = baseMap.a;
    baseMap.rgb = lerp(baseMap.rgb, paletteColor, 1.0 - baseMap.a) * _BaseColor.rgb;
    float3 color = DayNightColorBlend(baseMap.rgb, lightColor, lambert, _DayColor, _NightColor, _DayIntensity, _NightIntensity);
    color = pow(color,1.5) * lightShadowColor + Saturation(baseMap,saturate(pow(ToGray(lightColor), 1))) * bakeGI;
    // color += lerp(float3(0.0, 0.0, 0.0), emissionColor, 1);
    color += lerp(float3(0.0, 0.0, 0.0), emissionColor, _EmissionSwitch);
    
    // Final
    color = MixFog(color.rgb, input.fogFactor);
#ifdef _ALPHACUT_ON
    clip(alpha - _Cutoff);
#endif
    
    // Debug
#ifdef _DEBUGMASKMAPVALUE_ON
    color =  float((maskMap >= _DebugMaskMapValueMin && maskMap <= _DebugMaskMapValueMax) ? 1 : 0).rrr;
    alpha = 1.0;
#endif
    // 输出纯色
#ifdef _DEBUGBASEMAP_ON
    color = baseMap.rgb;
#endif

	// return float4(lambert.rrr * saturate(lightShadow *4) * lightColor + lambert.rrr * bakeGI, alpha);
	return float4(color, alpha);
}

#endif
