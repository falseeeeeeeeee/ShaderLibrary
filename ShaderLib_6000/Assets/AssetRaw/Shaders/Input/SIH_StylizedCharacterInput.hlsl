#ifndef STYLIZED_CHARACTER_INPUT_INCLUDED
#define STYLIZED_CHARACTER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "./SIH_StylizedSurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"

// SRP batcher
CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _BaseMap_TexelSize;
    float4 _BaseMapST;      // 自定义的Tile
    // PBR
    half4 _BaseColor;
    half _Metallic;
    half _Roughness;
    half _Occlusion;
    half _BumpScale;
    half4 _SpecularColor;
    // Emission
    half4 _EmissionColor;
    // half _EmissionMap2Switch;
    // half _EmissionBreatheRandomPosition;
    // half4 _EmissionBreatheParam; 
    // half _EmissionScanIntensity;
    // half _EmissionScanScale;
    // half4 _EmissionScanParam;
    // Distort
    // half _DistortMapRStrength;
    // half _DistortMapGStrength;
    // half _DistortMapBStrength;
    // half4 _DistortMapRTileAndSpeed;
    // half4 _DistortMapGTileAndSpeed;
    // // Fresnel
    // half _FresnelBlendMode;
    // half4 _FresnelParam;
    // Alpha
    half _Cutoff;
    // half _AlphaDitherSwitch;
    half _BlendMode;
    // 状态相关
    // float4 _StateColor;
    // half _StateSwitch;
    // float4 _AttackColor;
    // half _AttackSwitch;
    // half _DissolveSwitch;
    // half _DissolveColorSwitch;
    // half _CritSwitch;
    // half _ThumpSwitch;
    // half _ScanSwitch;
    // half _FrozenSwitch;
    // half _WaterSwitch;
    // half _TouchSwitch;
    // half _ToughnessSwitch;
    // half _OutlineSize;
    // half _LocalBrightnessSwitch;
    // half _GlobalIntensityParamOn;
UNITY_TEXTURE_STREAMING_DEBUG_VARS;
CBUFFER_END

TEXTURE2D(_MROMap);             SAMPLER(sampler_MROMap);
TEXTURE2D(_DistortMap);         SAMPLER(sampler_DistortMap);
TEXTURE2D(_MatcapMap);          SAMPLER(sampler_MatcapMap);
TEXTURE2D(_ChaBuffMap);         SAMPLER(sampler_ChaBuffMap);

half3 SampleMetallicRoughnessOcclusion(float2 uv)
{
    half3 mroMap = SAMPLE_TEXTURE2D(_MROMap, sampler_MROMap, uv).rgb;
    
    half metallic = mroMap.r * _Metallic;
    half roughness = 1.0 - (mroMap.g * _Roughness);
    half occlusion = LerpWhiteTo(mroMap.b, _Occlusion);

    return float3(metallic, roughness, occlusion);
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    half3 mro = SampleMetallicRoughnessOcclusion(uv);
    outSurfaceData.metallic   = mro.r;
    outSurfaceData.smoothness = mro.g;
    outSurfaceData.occlusion  = mro.b;
    
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

    outSurfaceData.clearCoatMask       = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
}

#endif
