#ifndef CAR_PAINT_INPUT_INCLUDE
#define CAR_PAINT_INPUT_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

// Declare property variables
CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _Metallic;
half _Smoothness;
half _BumpScale;
half _OcclusionStrength;

half _LightSwitch;
half4 _LightColor;
half _FlowSpeed;
CBUFFER_END

TEXTURE2D(_MetallicMap);     SAMPLER(sampler_MetallicMap);
TEXTURE2D(_RoughnessMap);    SAMPLER(sampler_RoughnessMap);
TEXTURE2D(_OcclusionMap);    SAMPLER(sampler_OcclusionMap);

//Define flowing light dynamic funcation
half FlowingLight (float2 uv)
{
    half range01 = frac(_Time.y * _FlowSpeed);
    return step(uv.x, range01);
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData.albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv).rgb * _BaseColor.rgb;

    //half4 metallicGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
    //outSurfaceData.metallic = metallicGloss.r * _Metallic;
    //outSurfaceData.smoothness = metallicGloss.a * _Smoothness;

    half metallicMap = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, uv).r;
    outSurfaceData.metallic = metallicMap * _Metallic;

    half roughnessMap = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, uv).r;
    outSurfaceData.smoothness = (1 - roughnessMap) * _Smoothness;

    half4 normal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv);
    outSurfaceData.normalTS = UnpackNormalScale(normal, _BumpScale);

    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).r;
    outSurfaceData.occlusion = lerp(1.0, occ, _OcclusionStrength);

    half3 light = FlowingLight(uv) * _LightColor.rgb;
    outSurfaceData.emission = _LightSwitch ? light : half3(0.0, 0.0, 0.0);

    //Set up default values
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
    outSurfaceData.clearCoatMask       = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
    outSurfaceData.alpha = 1.0;
}

#endif