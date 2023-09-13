#ifndef CAR_PAINT_INPUT_INCLUDE
#define CAR_PAINT_INPUT_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _PigmentColor;
half4 _EdgeColor;
half _EdgeFactor;

half4 _SpecularColor;
half _FacingSpecular;
half _PerpendicularSpecular;
half _SpecularFactor;
half _Smoothness;

half _BumpScale;
half _Occlusion;
half4 _EmissionColor;

half4 _ClearCoatColor;
half _ReflectionContrast;
half _FacingReflection;
half _PerpendicularReflection;
half _ReflectionFactor;

half _FlakeDensity;
half _FlakeReflection;
half _FlakeFactor;
CBUFFER_END

TEXTURE2D(_SpecularMap);     SAMPLER(sampler_SpecularMap);
TEXTURE2D(_GlossinessMap);   SAMPLER(sampler_GlossinessMap);
TEXTURE2D(_OcclusionMap);    SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_FlakeMap);        SAMPLER(sampler_FlakeMap);

//Define fresnel function
half FresnelEffect(float3 NormalWS, float3 ViewDirWS, half Power)
{
    half NdotV = saturate(dot(normalize(NormalWS), normalize(ViewDirWS)));
    return pow((1.0 - NdotV), Power);
}

//Get cubemap reflection
half3 GetReflection(float3 ViewDirWS, float3 NormalWS)
{
    float3 reflectVec = reflect(-ViewDirWS, NormalWS);

    //Sample cubemap inEnvironment and decode
    return DecodeHDREnvironment(SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, reflectVec), unity_SpecCube0_HDR);
}

//Adjust reflection contrast
half3 UnityContrast(half3 In, half Contrast)
{
    half midpoint = pow(0.5, 2.2);
    return lerp(midpoint, In, Contrast);
}

//初始化SurfaceData
inline void InitializeStandardLitSurfaceDatas(float4 uv, float3 NormalWS, float3 ViewDirWS, out SurfaceData outSurfaceData)
{
    half4 albedoTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv.xy);
    half albedoFresnel = FresnelEffect(NormalWS, ViewDirWS, _EdgeFactor);
    outSurfaceData.albedo = lerp(_PigmentColor.rgb, _EdgeColor.rgb, albedoFresnel) * albedoTex.rgb;

    half flakeTex = SAMPLE_TEXTURE2D(_FlakeMap, sampler_FlakeMap, uv.zw).r;
    half flakeFresnel = 1.0 - FresnelEffect(NormalWS, ViewDirWS, _FlakeFactor);
    half flake = flakeTex * _FacingReflection * flakeFresnel;

    half3 specularTex = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, uv.xy).rgb;
    half specularFresnel = FresnelEffect(NormalWS, ViewDirWS, _SpecularFactor);
    outSurfaceData.specular = lerp(_FacingSpecular, _PerpendicularSpecular, specularFresnel) * _SpecularColor.rgb * specularTex + flake;

    half smoothnessTex = SAMPLE_TEXTURE2D(_GlossinessMap, sampler_GlossinessMap, uv.xy).r;
    outSurfaceData.smoothness = _Smoothness * smoothnessTex + flake;

    half3 emissionTex = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv.xy).rgb;
    half clearcoatFresnel = FresnelEffect(NormalWS, ViewDirWS, _ReflectionFactor);
    half3 contrastReflection = UnityContrast(GetReflection(ViewDirWS, NormalWS), _ReflectionContrast);

    outSurfaceData.emission = saturate(lerp(_FacingReflection, _PerpendicularReflection, clearcoatFresnel) * _ClearCoatColor.rgb * contrastReflection) + _EmissionColor.rgb * emissionTex;



    half occlusionTex =  SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv.xy).r;
    outSurfaceData.occlusion = lerp(1.0, occlusionTex, _Occlusion);

    //outSurfaceData.normalTS = half3(0.0, 0.0, 1.0);
    outSurfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv.xy), _BumpScale);

    outSurfaceData.metallic = 1.0;
    outSurfaceData.clearCoatMask       = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
    outSurfaceData.alpha = 1.0 * albedoTex.a;
}

#endif