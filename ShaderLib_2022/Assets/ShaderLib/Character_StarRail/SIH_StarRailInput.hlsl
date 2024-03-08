#ifndef SIH_STARRAIL_INPUT_INCLUDED
#define SIH_STARRAIL_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

// -------------------------------------
// Sampler Texture
// BaseMap
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
#if _AREA_FACE
TEXTURE2D(_FaceColorMap);
SAMPLER(sampler_FaceColorMap);
#elif _AREA_HAIR 
TEXTURE2D(_HairColorMap);
SAMPLER(sampler_HairColorMap);
#elif _AREA_UPPERBODY
TEXTURE2D(_UpperBodyColorMap);
SAMPLER(sampler_UpperBodyColorMap);
#elif _AREA_LOWERBODY 
TEXTURE2D(_LowerBodyColorMap);
SAMPLER(sampler_LowerBodyColorMap);
#endif

// LightMap
#if _AREA_HAIR 
TEXTURE2D(_HairLightMap);
SAMPLER(sampler_HairLightMap);
#elif _AREA_UPPERBODY
TEXTURE2D(_UpperBodyLightMap);
SAMPLER(sampler_UpperBodyLightMap);
#elif _AREA_LOWERBODY 
TEXTURE2D(_LowerBodyLightMap);
SAMPLER(sampler_LowerBodyLightMap);
#endif

// RampColorMap
#if _AREA_HAIR
TEXTURE2D(_HairCoolRamp);
SAMPLER(sampler_HairCoolRamp);
TEXTURE2D(_HairWarmRamp);
SAMPLER(sampler_HairWarmRamp);
#elif _AREA_FACE || _AREA_UPPERBODY || _AREA_LOWERBODY
TEXTURE2D(_BodyCoolRamp);
SAMPLER(sampler_BodyCoolRamp);
TEXTURE2D(_BodyWarmRamp);
SAMPLER(sampler_BodyWarmRamp);
#endif

// FaceShadow
#if _AREA_FACE
TEXTURE2D(_FaceMap);
SAMPLER(sampler_FaceMap);
#endif

// Stockings
#if _AREA_UPPERBODY || _AREA_LOWERBODY
TEXTURE2D(_UpperBodyStockings);
SAMPLER(sampler_UpperBodyStockings);
TEXTURE2D(_LowerBodyStockings);
SAMPLER(sampler_LowerBodyStockings);
#endif

// -------------------------------------
// CBUFFER
CBUFFER_START(UnityPerMaterial);
float _DebugColor;
float3 _HeadForward;
float3 _HeadRight;

// BaseMap
float4 _BaseMap_ST;

// FaceTintColor
float3 _FrontFaceTintColor;
float3 _BackFaceTintColor;

// Alpha
float _Alpha;
float _AlphaClip;

// Lighting
float _IndirectLightFlattenNormal;
float _IndirectLightUsage;
float _IndirectLightOcclusionUsage;
float _IndirectLightMixBaseColor;

float _MainLightColorUsage;
float _ShadowThresholdCenter;
float _ShadowThresholdSoftness;
float _ShadowRampOffset;

// FaceShadow
// #if _AREA_FACE
float _FaceShadowOffset;
float _FaceShadowTransitionSoftness;
// #endif

// Specular
// #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY
float _SpecularExpon;
float _SpecularKsNonMetal;
float _SpecularKsMetal;
float _SpecularMetalRange;
float _SpecularBrightness;
// #endif

// Stockings
// #if _AREA_UPPERBODY || _AREA_LOWERBODY
float3 _StockingsDarkColor;
float3 _StockingsLightColor;
float3 _StockingsTransitionColor;
float _StockingsTransitionThreshold;
float _StockingsTransitionPower;
float _StockingsTransitionHardness;
float _StockingsTextureUsage;
// #endif

// RimLight
float _RimLightWidth;
float _RimLightThreshold;
float _RimLightFadeout;
float3 _RimLightTintColor;
float _RimLightBrightness;
float _RimLightMixAlbedo;

// Emission
// #if _EMISSION_ON
float _EmissionMixBaseColor;
float3 _EmissionTintColor;
float _EmissionIntensity;
// #endif

// Outline
// #if _OUTLINE_ON
float _OutlineWidth;
float _OutlineGamma;
// #endif

CBUFFER_END
#endif
