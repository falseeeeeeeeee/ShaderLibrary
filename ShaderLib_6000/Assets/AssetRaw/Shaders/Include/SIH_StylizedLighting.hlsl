#ifndef SIH_STYLIZED_LIGHTING_INCLUDED
#define SIH_STYLIZED_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


// ----------------------------------------------------------------------------
// 固定值调参
// Diffuse 三段明暗
#define CP_CEL_SHADOW_THRESHOLD    0.30h
#define CP_CEL_LIGHT_THRESHOLD     0.70h
#define CP_CEL_SOFTNESS            0.08h
#define CP_CEL_SHADOW_LEVEL        0.15h
#define CP_CEL_MID_LEVEL           0.50h
#define CP_CEL_SHADOW_TINT         half3(0.65h, 0.72h, 1.00h)
#define CP_CEL_MID_TINT            half3(1.00h, 0.93h, 0.88h)
#define CP_CEL_LIGHT_TINT          half3(1.00h, 1.00h, 1.00h)
#define CP_CEL_DIFFUSE_WRAP        0.05h   // 0 = 普通受光范围；少量正值让明暗交界更柔和
#define CP_TERMINATOR_WIDTH        0.10h   // 明暗交界处的暖色带 用于强调体积，属于艺术化染色
#define CP_TERMINATOR_STRENGTH     0.05h
#define CP_TERMINATOR_TINT         half3(1.00h, 0.30h, 0.10h)

// Specular 直接光照高光
#define CP_SPECULAR_CEL_BLEND      0.50h   // 0 = 原始 PBR 高光，1 = 全部替换为高光块
#define CP_SPECULAR_THRESHOLD      0.35h
#define CP_SPECULAR_SOFTNESS       0.10h
#define CP_SPECULAR_INTENSITY      1.00h
#define CP_SPECULAR_PEAK_LIMIT     24.0h   // 仅限制卡通高光块的峰值，不钳制原始 PBR 高光

// Rim 边缘光
#define CP_RIM_WIDTH               0.40h   // 较宽的柔亮边打底
#define CP_RIM_SOFTNESS            0.20h
#define CP_RIM_INTENSITY           1.00h
#define CP_RIM_CORE_WIDTH          0.30h   // 较窄的 HDR 亮边加强轮廓
#define CP_RIM_CORE_SOFTNESS       0.05h
#define CP_RIM_CORE_INTENSITY      8.00h
#define CP_RIM_DIRECTION_BIAS     -0.20h   // 0 为基准，增大会让更多边缘受光，减小则反之
#define CP_RIM_DIRECTION_SOFTNESS  0.10h   // 方向遮罩的软化程度
#define CP_RIM_BACKLIGHT_BOOST     4.00h   // 近似 SSS 背光渐变遮罩强度
#define CP_RIM_MATERIAL_TINT       0.70h   // 0 = 仅灯光色；增加后混入材质反射色

// Rim 边缘光独立调色
#define CP_RIM_COLOR_STRENGTH      1.00h   // 0 = 原灯光色，1 = 完整艺术化调色
#define CP_RIM_COLOR_SATURATION    2.50h   // 1 = 原饱和度；增大强调彩灯颜色
#define CP_RIM_TEMPERATURE_RANGE   0.10h   // 越小，越容易把轻微冷暖推向下方色板
#define CP_RIM_WARM_TINT           half3(1.00h, 0.28h, 0.055h) // 暖光亮边：橙色
#define CP_RIM_COOL_TINT           half3(0.055h, 0.28h, 1.00h) // 冷光亮边：蓝色

// BackLight 背光
#define CP_BACKLIGHT_INTENSITY     0.5h        // 背光强度

#define CP_ORTHO_REFLECTION_SPREAD  float2(0.35, 0.20) // 横向/纵向展开；(0, 0) 恢复原视线


// ----------------------------------------------------------------------------
// 软阈值函数
half Custom_SoftStep(half threshold, half softness, half value)
{
    half width = max(softness, 0.0001h);
    return smoothstep(threshold - width, threshold + width, value);
}

// ----------------------------------------------------------------------------
// 漫反射函数
half3 StylizedLighting_Diffuse(BRDFData brdfData, half signedNdotL)
{
    // 兰伯特
    half lambert = saturate(signedNdotL);
    
    // 三分色
    half wrap = max(CP_CEL_DIFFUSE_WRAP, 0.0h);
    half wrappedNdotL = saturate((signedNdotL + wrap) / (1.0h + wrap));
    half midBand = Custom_SoftStep(CP_CEL_SHADOW_THRESHOLD, CP_CEL_SOFTNESS, wrappedNdotL);    // 中线
    half litBand = Custom_SoftStep(CP_CEL_LIGHT_THRESHOLD, CP_CEL_SOFTNESS, wrappedNdotL);     // 亮线
    half3 bands = lerp(CP_CEL_SHADOW_TINT * CP_CEL_SHADOW_LEVEL, CP_CEL_MID_TINT * CP_CEL_MID_LEVEL, midBand);        // 暗部颜色、中部颜色
    bands = lerp(bands, CP_CEL_LIGHT_TINT, litBand);                                                                  // 亮部颜色
    bands *= smoothstep(0.0h, max(CP_CEL_SOFTNESS, 0.0001h), wrappedNdotL);    // 让最暗色阶在背光面归零，避免每盏灯都给整个人物加一层底色。
    
    // 边缘色带
    half Terminator = saturate(1.0h - abs(lambert - CP_CEL_SHADOW_THRESHOLD) / max(CP_TERMINATOR_WIDTH, 0.0001h));
    bands += CP_TERMINATOR_TINT * (Terminator * Terminator * CP_TERMINATOR_STRENGTH);
    
    return brdfData.diffuse * bands;
}

// ----------------------------------------------------------------------------
// 高光函数：PBR 软高光 混合 Toon 大块硬高光。宽度仍随 MRO 的粗糙度变化，金属仍保留有色反射
half3 StylizedLighting_Specular(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    // PBR
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half pbr = DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * NdotL;
    
    // Toon
    float3 halfDirection = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));
    float NdotH = saturate(dot(float3(normalWS), halfDirection));       // BlinnPhong
    float roughness2 = max((float)brdfData.roughness2, 0.00006103515625);
    float denominator = NdotH * NdotH * (roughness2 - 1.0) + 1.0;
    float normalizedLobe = roughness2 / max(denominator, 0.000001);
    normalizedLobe *= normalizedLobe;   // 使用 GGX 的归一化轮廓，阈值不受灯光强度影响。float 避免光滑表面分母精度不足
    half mask = Custom_SoftStep(CP_SPECULAR_THRESHOLD, CP_SPECULAR_SOFTNESS, (half)normalizedLobe);
    half peak = min(rcp(max(roughness2 * brdfData.normalizationTerm, 0.0001)), (float)CP_SPECULAR_PEAK_LIMIT);
    half toon = mask * peak * NdotL;
    
    return brdfData.specular * lerp(pbr, toon, saturate(CP_SPECULAR_CEL_BLEND)) * CP_SPECULAR_INTENSITY;
}

// ----------------------------------------------------------------------------
// 边缘光函数：（软轮廓 + 硬轮廓）* 方向遮罩 * 渐变遮罩 * “高光”。受光源方向控制的双层亮边，WIDTH 是 Fresnel 的范围
half3 StylizedLighting_Rim(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    // 内轮廓
    half fresnel = 1.0h - saturate(dot(normalWS, viewDirectionWS));
    half broad = Custom_SoftStep(1.0h - CP_RIM_WIDTH, CP_RIM_SOFTNESS, fresnel);             // 软轮廓
    half core = Custom_SoftStep(1.0h - CP_RIM_CORE_WIDTH, CP_RIM_CORE_SOFTNESS, fresnel);    // 硬轮廓
    
    // 灯光侧面方向遮罩
    half LdotV = dot(lightDirectionWS, viewDirectionWS);                     // 把光源方向投影到视平面。不要先乘 sideMask，否则侧后光的边缘容易消失
    half3 lateralLight = lightDirectionWS - viewDirectionWS * LdotV;         // 不归一化投影方向，避免光源恰好位于相机轴线上时除零或左右翻转
    half sideMask = dot(normalWS, lateralLight) + CP_RIM_DIRECTION_BIAS;     // 灯光与视角成侧面夹角时呈现的遮罩，增加偏移让遮罩不至于全部显示
    half directionMask = Custom_SoftStep(0.0h, CP_RIM_DIRECTION_SOFTNESS, sideMask);   // 硬化遮罩
    half backlightBoost = 1.0h + saturate(-LdotV) * CP_RIM_BACKLIGHT_BOOST;  // SSS 渐变效果
    half3 materialTint = lerp(half3(1.0h, 1.0h, 1.0h), brdfData.specular, saturate(CP_RIM_MATERIAL_TINT));
    
    return (broad * CP_RIM_INTENSITY + core * CP_RIM_CORE_INTENSITY) * directionMask * backlightBoost * materialTint;
}

// ----------------------------------------------------------------------------
// 边缘光颜色函数：亮边颜色保留灯光最大通道强度，增强色彩；弱冷暖映射到橙/蓝色板。中性白光不会凭空判定日夜；已经鲜艳的彩灯减少色板重映射。
half3 StylizedLighting_RimColor(half3 lightColor)
{
    float3 rgb = max((float3)lightColor, 0.0);
    float peak = max(rgb.r, max(rgb.g, rgb.b));
    float3 hue = rgb / max(peak, 0.00001);
    float temperature = hue.r - hue.b;
    float saturation = 1.0 - min(hue.r, min(hue.g, hue.b));
    float paletteWeight = saturate(abs(temperature) / max((float)CP_RIM_TEMPERATURE_RANGE, 0.0001)) * (1.0 - smoothstep(0.25, 0.65, saturation));
    float3 palette = lerp((float3)CP_RIM_COOL_TINT, (float3)CP_RIM_WARM_TINT, step(0.0, temperature));
    float gray = dot(hue, float3(0.2126, 0.7152, 0.0722));
    float3 artistic = saturate(lerp(gray.xxx, hue, max((float)CP_RIM_COLOR_SATURATION, 0.0)));
    artistic = lerp(artistic, max(palette, 0.0), paletteWeight);
    artistic /= max(max(artistic.r, max(artistic.g, artistic.b)), 0.00001);
    return (half3)(lerp(hue, artistic, saturate(CP_RIM_COLOR_STRENGTH)) * peak);
}

// ----------------------------------------------------------------------------
// 背光函数：SSS * -Lambert * Fresnel
half3 StylizedLighting_BackLight(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    half backView = saturate(dot(-lightDirectionWS, viewDirectionWS));  // 反向视图方向，近似SSS
    half backSurface = saturate(-dot(normalWS, lightDirectionWS));      // 反向 Lambert
    half fresnel = 1.0h - saturate(dot(normalWS, viewDirectionWS));
    
    return brdfData.diffuse * (Pow4(backView) * backSurface * fresnel * CP_BACKLIGHT_INTENSITY);
}


// ---------------------------------------------------------------------------------------------------------------------
// 前向渲染直接光照，含 Diffuse、Specular、Rim、Backlight
half3 StylizedLightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, float lightAttenuation, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    // Diffuse
    half3 lighting = StylizedLighting_Diffuse(brdfData, dot(normalWS, lightDirectionWS));
    // Specular
    #ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        lighting += StylizedLighting_Specular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
    }
    #endif
    // BackLight
    lighting += StylizedLighting_BackLight(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
    // Rim
    half3 rim = StylizedLighting_Rim(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
    half3 rimColor = StylizedLighting_RimColor(lightColor);
    
    return (lighting * lightColor + rim * rimColor) * lightAttenuation;
}

// 延迟渲染用此函数，与上方函数区别是 distanceAttenuation * shadowAttenuation，只乘一次。
half3 StylizedLightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    return StylizedLightingPhysicallyBased(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, specularHighlightsOff);
}


// ---------------------------------------------------------------------------------------------------------------------
// 自定义 GI 混合；保留官方反射探针、AO、Environment Reflections 开关、Debug
half3 StylizedGlobalIllumination(BRDFData brdfData, half3 bakedGI, half occlusion, float3 positionWS, half3 normalWS, half3 viewDirectionWS, float2 normalizedScreenSpaceUV)
{
    // 正交相机的环境镜面反射，正交时按屏幕覆盖范围产生角度变化，透视时保持原视线
    if (!IsPerspectiveProjection())
    {
        float2 positionVS = TransformWorldToView(positionWS).xy;
        float2 slope = positionVS * abs(UNITY_MATRIX_P._m11) * float2(0.35, 0.20);  // P[1][1] 的绝对值为正交半高度的倒数；横纵共用它以保留纵横比。(0, 0) 恢复原视线
        viewDirectionWS =  SafeNormalize(viewDirectionWS - UNITY_MATRIX_V[0].xyz * slope.x - UNITY_MATRIX_V[1].xyz * slope.y);  // V[0]/V[1] 是相机世界空间的右/上方向；视线从表面指向相机，因此取负偏移。
    }
    
    return GlobalIllumination(brdfData, (BRDFData)0, 0, bakedGI, occlusion, positionWS, normalWS, viewDirectionWS, normalizedScreenSpaceUV);
}


// ---------------------------------------------------------------------------------------------------------------------
// 前向渲染直接用此整合函数；含BRDF数据、GI 混合、灯光循环、Light Layers、Debug
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
    LightingData lightingData = CreateLightingData(inputData, surfaceData);                 // 初始化光照数据结构
    
    // 计算全局光照
    lightingData.giColor = StylizedGlobalIllumination(brdfData,
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
    // 计算点光源光照（集群光照、像素光照、顶点光照）
    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    // 计算点光源光照（集群光照）
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
