#ifndef SIH_STYLIZED_CHARACTER_INPUT_INCLUDED
#define SIH_STYLIZED_CHARACTER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "./SIH_StylizedSurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"

// SRP Batcher 支持
CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _BaseMap_TexelSize;
    // PBR
    float4 _BaseMapST;      // 自定义的Tile
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

// DOTS Instancing 支持，需要将数据写在四个结构体中
#ifdef UNITY_DOTS_INSTANCING_ENABLED

// 1、DOTS 实例化属性元数据
UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseMapST)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecularColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float , _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float , _Roughness)
    UNITY_DOTS_INSTANCED_PROP(float , _Occlusion)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float , _BlendMode)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

// 2、DOTS 实例化属性缓存
static float4 unity_DOTS_Sampled_BaseMapST;
static float4 unity_DOTS_Sampled_BaseColor;
static float4 unity_DOTS_Sampled_SpecularColor;
static float4 unity_DOTS_Sampled_EmissionColor;
static float  unity_DOTS_Sampled_Metallic;
static float  unity_DOTS_Sampled_Roughness;
static float  unity_DOTS_Sampled_Occlusion;
static float  unity_DOTS_Sampled_BumpScale;
static float  unity_DOTS_Sampled_Cutoff;
static float  unity_DOTS_Sampled_BlendMode;

// 3、DOTS 实例化属性缓存初始化
void SetupDOTSLitMaterialPropertyCaches()
{
    unity_DOTS_Sampled_BaseMapST            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _BaseMapST);
    unity_DOTS_Sampled_BaseColor            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _BaseColor);
    unity_DOTS_Sampled_SpecularColor        = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SpecularColor);
    unity_DOTS_Sampled_EmissionColor        = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _EmissionColor);
    unity_DOTS_Sampled_Metallic             = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Metallic);
    unity_DOTS_Sampled_Roughness            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Roughness);
    unity_DOTS_Sampled_Occlusion            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Occlusion);
    unity_DOTS_Sampled_BumpScale            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BumpScale);
    unity_DOTS_Sampled_Cutoff               = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _Cutoff);
    unity_DOTS_Sampled_BlendMode            = UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float , _BlendMode);
}

#undef UNITY_SETUP_DOTS_MATERIAL_PROPERTY_CACHES
#define UNITY_SETUP_DOTS_MATERIAL_PROPERTY_CACHES() SetupDOTSLitMaterialPropertyCaches()

// 4、DOTS 实例化属性访问器
#define _BaseMapST              unity_DOTS_Sampled_BaseMapST
#define _BaseColor              unity_DOTS_Sampled_BaseColor
#define _SpecularColor          unity_DOTS_Sampled_SpecularColor
#define _EmissionColor          unity_DOTS_Sampled_EmissionColor

#define _Metallic               unity_DOTS_Sampled_Metallic
#define _Roughness              unity_DOTS_Sampled_Roughness
#define _Occlusion              unity_DOTS_Sampled_Occlusion
#define _BumpScale              unity_DOTS_Sampled_BumpScale
#define _Cutoff                 unity_DOTS_Sampled_Cutoff
#define _BlendMode              unity_DOTS_Sampled_BlendMode

#endif

// Texture Samplers
TEXTURE2D(_MROMap);             SAMPLER(sampler_MROMap);
TEXTURE2D(_DistortMap);         SAMPLER(sampler_DistortMap);
TEXTURE2D(_MatcapMap);          SAMPLER(sampler_MatcapMap);
TEXTURE2D(_ChaBuffMap);         SAMPLER(sampler_ChaBuffMap);

// ---------------------------------------------------------------------------------------------------------------------
// 采样金属度、粗糙度、遮挡贴图
half3 SampleMetallicRoughnessOcclusion(float2 uv)
{
    half3 mroMap = SAMPLE_TEXTURE2D(_MROMap, sampler_MROMap, uv).rgb;
    
    half metallic = mroMap.r * _Metallic;
    half roughness = 1.0 - (mroMap.g * _Roughness);
    half occlusion = LerpWhiteTo(mroMap.b, _Occlusion);

    return float3(metallic, roughness, occlusion);
}

// ---------------------------------------------------------------------------------------------------------------------
// 初始化标准光照表面数据
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
