#ifndef SIH_STARRAIL_DRAWOUTLINE_PASS_INCLUDED
#define SIH_STARRAIL_DRAWOUTLINE_PASS_INCLUDED

// -------------------------------------
// 方法
// 根据相机距离调整描边宽度
float GetCameraFOV()
{
    //https://answers.unity.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
    float t = unity_CameraProjection._m11;
    float Rad2Deg = 180 / 3.1415;
    float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
    return fov;
}
float ApplyOutlineDistanceFadeOut(float inputMulFix)
{
    //make outline "fadeout" if character is too small in camera's view
    return saturate(inputMulFix);
}
float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
{
    float cameraMulFix;
    if(unity_OrthoParams.w == 0)
    {
        ////////////////////////////////
        // Perspective camera case
        ////////////////////////////////

        // keep outline similar width on screen accoss all camera distance       
        cameraMulFix = abs(positionVS_Z);

        // can replace to a tonemap function if a smooth stop is needed
        cameraMulFix = ApplyOutlineDistanceFadeOut(cameraMulFix);

        // keep outline similar width on screen accoss all camera fov
        cameraMulFix *= GetCameraFOV();       
    }
    else
    {
        ////////////////////////////////
        // Orthographic camera case
        ////////////////////////////////
        float orthoSize = abs(unity_OrthoParams.y);
        orthoSize = ApplyOutlineDistanceFadeOut(orthoSize);
        cameraMulFix = orthoSize * 50; // 50 is a magic number to match perspective camera's outline width
    }

    return cameraMulFix * 0.00005; // mul a const to make return result = default normal expand amount WS
}

// -------------------------------------
// 基本结构体输入
struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float4 color        : COLOR;
    float2 texcoord     : TEXCOORD0;
};

// -------------------------------------
// 基本结构体输出
struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float fogFactor                 : TEXCOORD1;
    float4 color                    : TEXCOORD2;
    float4 positionCS               : SV_POSITION;
};

// -------------------------------------
// 基本顶点着色器
Varyings StarRailPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float width = _OutlineWidth;
    width *= GetOutlineCameraFovAndDistanceFixMultiplier(positionInputs.positionVS.z);  // 根据相机距离调整描边宽度
    
    float3 positionWS = positionInputs.positionWS;
    #if _OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL
        float3x3 tbn = float3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS);
        positionWS += mul(input.color.rgb * 2 - 1, tbn) * width;
    #else
        positionWS += normalInputs.normalWS * width;
    #endif
    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
    output.positionCS = TransformWorldToHClip(positionWS);
    return output;
}

// -------------------------------------
// 基本片元着色器
float4 StarRailPassFragment(Varyings input) : SV_Target
{
    float3 coolRamp = 0;
    float3 warmRamp = 0;
    #if _AREA_HAIR
        float2 outlineUV = float2(0, 0.5);
        coolRamp = SAMPLE_TEXTURE2D(_HairCoolRamp, sampler_HairCoolRamp, outlineUV).rgb;
        warmRamp = SAMPLE_TEXTURE2D(_HairWarmRamp, sampler_HairWarmRamp, outlineUV).rgb;
    #elif _AREA_UPPERBODY || _AREA_LOWERBODY
        float4 lightMap = 0;
        #if _AREA_UPPERBODY
            lightMap = SAMPLE_TEXTURE2D(_UpperBodyLightMap, sampler_UpperBodyLightMap, input.uv);
        #elif _AREA_LOWERBODY
            lightMap = SAMPLE_TEXTURE2D(_LowerBodyLightMap, sampler_LowerBodyLightMap, input.uv);
        #endif
        float materialEnum = lightMap.a;
        float materialEnumOffset = materialEnum + 0.0425;
        float outlineUVy = lerp(materialEnumOffset, materialEnumOffset + 0.5 > 1 ? materialEnumOffset + 0.5 - 1 : materialEnumOffset + 0.5, fmod((round(materialEnumOffset/0.0625) - 1)/2, 2));
        float2 outlineUV = float2(0, outlineUVy);
        coolRamp = SAMPLE_TEXTURE2D(_BodyCoolRamp, sampler_BodyCoolRamp, outlineUV).rgb;
        warmRamp = SAMPLE_TEXTURE2D(_BodyWarmRamp, sampler_BodyWarmRamp, outlineUV).rgb;
    #elif _AREA_FACE
        float2 outlineUV = float2(0, 0.0625);
        coolRamp = SAMPLE_TEXTURE2D(_BodyCoolRamp, sampler_BodyCoolRamp, outlineUV).rgb;
        warmRamp = SAMPLE_TEXTURE2D(_BodyWarmRamp, sampler_BodyWarmRamp, outlineUV).rgb;
    #endif

    float3 ramp = lerp(coolRamp, warmRamp, 0.5);
    float3 albedo = pow(saturate(ramp), _OutlineGamma);;
    
    float4 color = float4(albedo, 1);
    color.rgb = MixFog(color.rgb, input.fogFactor);
    
    return color;
}
#endif