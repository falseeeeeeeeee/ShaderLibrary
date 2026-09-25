#ifndef SIH_STYLIZED_LIGHTING_INCLUDED
#define SIH_STYLIZED_LIGHTING_INCLUDED

// 引用官方 Lighting.hlsl 中的宏
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


// 定义GBuffer Pass 中的宏
#define SIH_CEL_THRESHOLD          0.5h
#define SIH_CEL_SOFTNESS           0.02h
#define SIH_CEL_SPECULAR_THRESHOLD 0.8h

#define SIH_RIM_POWER      1.5h
#define SIH_RIM_THRESHOLD  0.35h
#define SIH_RIM_SOFTNESS   0.02h
#define SIH_RIM_INTENSITY  0.8h

// 1：出现在受光侧边缘
// 0：出现在背光侧边缘
#define SIH_RIM_LIGHT_SIDE 1

half3 SIH_LightRim(half NdotL, half3 normalWS, half3 viewDirectionWS)
{
    half NdotV = saturate(dot(normalWS, viewDirectionWS));

    // 视角边缘：越接近轮廓，值越高
    half viewRim = pow(saturate(1.0h - NdotV), SIH_RIM_POWER);

    #if SIH_RIM_LIGHT_SIDE
    // 受光侧边缘
    half lightDirectionMask = NdotL;
    #else
    // 背光侧边缘
    half lightDirectionMask = 1.0h - NdotL;
    #endif

    half rimValue = viewRim * lightDirectionMask;

    // 卡通边缘带
    half rimMask = smoothstep(
        SIH_RIM_THRESHOLD - SIH_RIM_SOFTNESS,
        SIH_RIM_THRESHOLD + SIH_RIM_SOFTNESS,
        rimValue
    );

    // 每盏灯拥有自己的颜色和距离衰减

    return rimMask * SIH_RIM_INTENSITY;
}



////////////////////////////////////////////////////////////////////////////////
/// Stylized 光照模型，用于 MainLight 和 AddLight 计算，比如 Lambert 就是写在这
////////////////////////////////////////////////////////////////////////////////

// Deferred 用此函数
half3 StylizedLightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, float lightAttenuation, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    // 官方光照模型为 (diffuse + specular) * lightColor * lightAttenuation * NdotL
    
    half NdotL = saturate(dot(normalWS, lightDirectionWS)); // Lambert
    half celDiffuse = smoothstep(SIH_CEL_THRESHOLD - SIH_CEL_SOFTNESS, SIH_CEL_THRESHOLD + SIH_CEL_SOFTNESS, NdotL);    // 测试代码，目前0.8
    half3 radiance = lightColor * lightAttenuation;         // LightRadiance

    
    // Diffuse
    half3 brdf = brdfData.diffuse * celDiffuse;  // 此处的漫反射为，当金属度为 0 时，Albedo * 0.96，当金属度为 1 时，Albedo * 0.04
    
    // Specular
    #ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        half3 specular = brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
        brdf += specular * NdotL;
    }
    #endif
    
    // Rim
    half3 rim = SIH_LightRim(NdotL, normalWS, viewDirectionWS);
    
    // Blend
    float3 lighting = brdf  + rim;
    lighting *= radiance;

    return lighting;
}

// Forward 用此函数，功能同上，只是把 light.distanceAttenuation 和 light.shadowAttenuation 进行了相乘
half3 StylizedLightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    return StylizedLightingPhysicallyBased(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, specularHighlightsOff);
}


////////////////////////////////////////////////////////////////////////////////
/// Stylized PBR lighting...
////////////////////////////////////////////////////////////////////////////////

// 前向渲染光照使用此函数
half4 StylizedFragmentPBR(InputData inputData, SurfaceData surfaceData)
{
    // 高光点的显示开关
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    
    // 初始化 BRDF 数据
    BRDFData brdfData;
    InitializeBRDFData(surfaceData, brdfData);

    // Debug
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;
    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // ---------------------------------------------------------------------
    // 准备光照信息
    half4 shadowMask = CalculateShadowMask(inputData);                                      // Shadow Mask
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData); // Ambient Occlusion
    uint meshRenderingLayers = GetMeshRenderingLayer();                                     // 模型渲染层
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);                        // 获取主光源
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);                // 通过主光源合并实时GI和烘焙GI
    LightingData lightingData = CreateLightingData(inputData, surfaceData);
    
    // 计算全局光照
    lightingData.giColor = GlobalIllumination(brdfData, (BRDFData)0, 0,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);

    // 计算主光源光照
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor = StylizedLightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, specularHighlightsOff);
    }

    // ---------------------------------------------------------------------
    // 点光源光照（集群光照、像素光照、顶点光照）
    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    // 点光源光照（集群光照）
    #if USE_CLUSTER_LIGHT_LOOP
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += StylizedLightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, specularHighlightsOff);
        }
    }
    #endif

    // 点光源光照（像素光照）
    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += StylizedLightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, specularHighlightsOff);
        }
    LIGHT_LOOP_END
    #endif

    // 点光源光照（顶点光照）
    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    // ---------------------------------------------------------------------
    // 输出颜色，含 Debug 各种信息
#if REAL_IS_HALF
    return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
#else
    return CalculateFinalColor(lightingData, surfaceData.alpha);
#endif
}

#endif
