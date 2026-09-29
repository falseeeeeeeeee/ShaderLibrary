#ifndef SIH_STYLIZED_CHARACTER_MASK_PASS_INCLUDED
#define SIH_STYLIZED_CHARACTER_MASK_PASS_INCLUDED

#if defined(LOD_FADE_CROSSFADE)
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

// ------------------------------------------------------------------
// 结构体输入
struct CharacterMaskAttributes
{
    float4 positionOS : POSITION;
#if defined(_ALPHATEST_ON)
    float2 uv : TEXCOORD0;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct CharacterMaskVaryings
{
    float4 positionCS : SV_POSITION;
#if defined(_ALPHATEST_ON)
    float2 uv : TEXCOORD0;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

///////////////////////////////////////////////////////////////////////////////
//                         Vertex functions                                  //
///////////////////////////////////////////////////////////////////////////////

CharacterMaskVaryings CharacterMaskPassVertex(CharacterMaskAttributes input)
{
    CharacterMaskVaryings output = (CharacterMaskVaryings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
#if defined(_ALPHATEST_ON)
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
#endif
    return output;
}

half4 CharacterMaskPassFragment(CharacterMaskVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
#if defined(LOD_FADE_CROSSFADE)
    LODFadeCrossFade(input.positionCS);
#endif
#if defined(_ALPHATEST_ON)
    half alpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a;
    Alpha(alpha, _BaseColor, _Cutoff);
#endif
    // ColorMask 0: only the successful stencil test writes to the target.
    return 0;
}

#endif
