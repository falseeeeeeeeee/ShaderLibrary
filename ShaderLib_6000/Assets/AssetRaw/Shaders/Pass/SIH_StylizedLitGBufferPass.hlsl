#ifndef STYLIZED_LIT_GBUFFER_PASS_INCLUDED
#define STYLIZED_LIT_GBUFFER_PASS_INCLUDED
#define THIS_IS_GBUFFER // 这个宏用于标记当前是 GBuffer Pass，方便在Types中做条件编译

// 为了与 LitGBufferPass 保持一致，两个文件共用一个引用
// 引用包含了：结构体输入、结构体输出、顶点函数
#include "./SIH_StylizedLitPassTypes.hlsl"
#include "./Include/SIH_StylizedGBuffer.hlsl"       
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GBufferOutput.hlsl"


// keep this file in sync with LitForwardPass.hlsl

///////////////////////////////////////////////////////////////////////////////
//                        Fragment functions                                 //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Not Physically Based) shader
GBufferFragOutput LitGBufferPassFragment(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    // 初始化表面数据：Alpha、Albedo、MRO、Normal、Emission
    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);

    // LOD 相关
#ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
#endif

    // 初始化结构体顶点输入数据：positionWS、normalWS、viewDirectionWS、normalizedScreenSpaceUV、shadowCoord、fog、vertexLight
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, UNDO_TRANSFORM_TEX(input.uv, _BaseMap));

    // Decal混合相关
#if defined(_DBUFFER)
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
#endif

    // 初始化全局光照数据：bakedGI、shadowMask
    InitializeBakedGIData(input, inputData);
    
    // ---------------------------------------------------------------------
    // 简化版的 UniversalFragmentPBR()

    // 初始化 BRDF 数据
    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    // 准备光照信息
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);

    // 计算全局光照
    half3 color = GlobalIllumination(brdfData, (BRDFData)0, 0,
                                              inputData.bakedGI, surfaceData.occlusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
    
    // 官方的 GBuffer 输出函数
    // return PackGBuffersBRDFData(brdfData, inputData, surfaceData.smoothness, surfaceData.emission + color, surfaceData.occlusion);
    
    // GPT的 GBuffer 输出函数
    GBufferFragOutput output = PackGBuffersBRDFData(brdfData, inputData, surfaceData.smoothness, surfaceData.emission + color, surfaceData.occlusion);
    uint flags = UnpackGBufferMaterialFlags(output.gBuffer0.a);
    output.gBuffer0.a = PackGBufferMaterialFlags(flags | SIH_MATERIAL_FLAG_CEL);
    return output;
}

#endif
