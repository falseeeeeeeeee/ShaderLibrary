// -------------------------------------
// Includes
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

// -------------------------------------
// Properties Stages
TEXTURE2D(_SpecGlossMap);
SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_MetallicGlossMap);
SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_OcclusionMap);
SAMPLER(sampler_OcclusionMap);

// -------------------------------------
// Functions

#ifdef _SPECULAR_SETUP
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif
half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

    #ifdef _METALLICSPECGLOSSMAP
    specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    specGloss.a = albedoAlpha * _Smoothness;
    #else
    specGloss.a *= _Smoothness;
    #endif
    #else // _METALLICSPECGLOSSMAP
    #if _SPECULAR_SETUP
    specGloss.rgb = _SpecColor.rgb;
    #else
    specGloss.rgb = _Metallic.rrr;
    #endif

    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    specGloss.a = albedoAlpha * _Smoothness;
    #else
    specGloss.a = _Smoothness;
    #endif
    #endif

    return specGloss;
}

half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor, TEXTURE2D_PARAM(specMap, sampler_specMap))
{
    half4 specularSmoothness = half4(0, 0, 0, 1);
    #ifdef _SPECGLOSSMAP
    specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
    #elif defined(_SPECULAR_COLOR)
    specularSmoothness = specColor;
    #endif

    #ifdef _GLOSSINESS_FROM_BASE_ALPHA
    specularSmoothness.a = alpha;
    #endif

    return specularSmoothness;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
    #else
    return half(1.0);
    #endif
}

// -------------------------------------
// SurfaceData
void InitSurfaceData(Varyings input, out SurfaceData surfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(input.uv,_BaseMap, sampler_BaseMap);
    
    surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(input.uv, albedoAlpha.a);
    #ifdef _SPECULAR_SETUP
        surfaceData.metallic = 1.0;
        surfaceData.specular = specGloss.rgb;
    #else
        surfaceData.metallic = specGloss.r;
        surfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    #endif
    surfaceData.smoothness = specGloss.a;

    surfaceData.normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    surfaceData.occlusion = SampleOcclusion(input.uv);
    surfaceData.emission = SampleEmission(input.uv, _EmissionColor.rgb, _EmissionMap, sampler_EmissionMap);
    
    surfaceData.clearCoatMask = 0.0;
    surfaceData.clearCoatSmoothness = 0.0;
}
