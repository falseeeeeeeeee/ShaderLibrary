#ifndef STYLIZED_FORWARD_LIT_PASS_INCLUDED
#define STYLIZED_FORWARD_LIT_PASS_INCLUDED

// 为了与 LitGBufferPass 保持一致，两个文件共用一个引用
// 引用包含了：结构体输入、结构体输出、顶点函数
#include "./SIH_StylizedLitPassTypes.hlsl"

// 我是一个 CV 酱，CV 本领强
// 诶呀我的结构体
// 变呀变漂亮，变呀变漂亮 ~~

// keep this file in sync with LitGBufferPass.hlsl

///////////////////////////////////////////////////////////////////////////////
//                        Fragment functions                                 //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Not Physically Based) shader
void LitPassFragment(Varyings input
    , out half4 outColor : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out uint outRenderingLayers : SV_Target1
#endif
)
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

    half4 color = UniversalFragmentPBR(inputData, surfaceData);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    color.a = OutputAlpha(color.a, _BlendMode > 1.0);

    outColor = color;
    // outColor = float4(1,0,0,1);

#ifdef _WRITE_RENDERING_LAYERS
    outRenderingLayers = EncodeMeshRenderingLayer();
#endif
}

#endif
