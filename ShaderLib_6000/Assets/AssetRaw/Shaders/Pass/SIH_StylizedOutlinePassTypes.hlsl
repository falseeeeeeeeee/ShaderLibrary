#ifndef STYLIZED_OUTLINE_PASS_TYPES_INCLUDED
#define STYLIZED_OUTLINE_PASS_TYPES_INCLUDED

// ------------------------------------------------------------------
// 在这里一次性调整基础大小；单位是参考分辨率下的像素。
// 实际宽度随渲染画面高度缩放，1080p 与 4K 保持相同的画面占比。
#define OUTLINE_REFERENCE_HEIGHT 1080.0 // 调整参数时所用的参考画面高度。
#define OUTLINE_BASE_WIDTH       1.0    // 描边基础宽度，再乘材质 _OutlineSize。
#define TOUGHNESS_BASE_WIDTH     2.0    // 描边外额外增加的最大宽度，再乘 _ToughnessSwitch。

float GetOutlineWidth()
{
    return max((float)_OutlineSize, 0.0) * max(OUTLINE_BASE_WIDTH, 0.0);
}

float GetToughnessWidth()
{
    return saturate((float)_ToughnessSwitch) * max(TOUGHNESS_BASE_WIDTH, 0.0);
}

// 这个文件包含了用于 Outline Pass 和 Toughness Pass 的通用的结构体定义和函数声明

#if defined(LOD_FADE_CROSSFADE)
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

// 该定义会使用 DCC 软件内烘焙到顶点色内的颜色法线信息
#define _OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL

// ------------------------------------------------------------------
// 结构体输入
struct ShellAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    float2 texcoord   : TEXCOORD0;
    float2 texcoord1  : TEXCOORD1;
#if defined(_OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL)
    float4 tangentOS : TANGENT;
    half4 color      : COLOR;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
// 结构体输出
struct ShellVaryings
{
    float3 uv         : TEXCOORD0; // xy: BaseMap UV; z: Toughness scan UV.
    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

// ------------------------------------------------------------------
// 获取壳体的法线向量
float3 GetShellNormalWS(ShellAttributes input)
{
#if defined(_OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL)
    VertexNormalInputs normals = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 normalTS = input.color.rgb * 2.0 - 1.0;
    if (dot(normalTS, normalTS) < 1e-6)
        return normals.normalWS;

    return SafeNormalize(normalTS.x * normals.tangentWS + normalTS.y * normals.bitangentWS + normalTS.z * normals.normalWS);
#else
    return TransformObjectToWorldNormal(input.normalOS);
#endif
}

// 获取正交投影下的壳体方向向量
float2 GetOrthographicShellDirection(float4 normalCS)
{
    return normalCS.xy;
}
// 获取透视投影下的壳体方向向量
float2 GetPerspectiveShellDirection(float4 positionCS, float4 normalCS)
{
    return normalCS.xy * positionCS.w - positionCS.xy * normalCS.w;
}
// 获取壳体在 HClip 空间的位置；传入参考分辨率下的像素宽度。
float4 GetShellPositionHClip(float3 positionWS, float3 normalWS, float widthAtReferencePixels)
{
    float4 positionCS = TransformWorldToHClip(positionWS);
    float4 normalCS = mul(GetWorldToHClipMatrix(), float4(normalWS, 0.0));
    float2 directionCS;

    if (unity_OrthoParams.w > 0.5)
        directionCS = GetOrthographicShellDirection(normalCS);
    else
        directionCS = GetPerspectiveShellDirection(positionCS, normalCS);

    // 归一化到像素坐标，以视口口宽比。
    float2 screenSize = max(GetScaledScreenParams().xy, float2(1.0, 1.0));
    float2 directionPixels = directionCS * screenSize;
    directionPixels *= rsqrt(max(dot(directionPixels, directionPixels), 1e-8));
    
    // 根据实际渲染高度进行缩放，包括 URP 渲染缩放。放大后，轮廓保持显示图像的相同比例。
    float resolutionScale = screenSize.y / max(OUTLINE_REFERENCE_HEIGHT, 1.0);
    float widthPixels = max(widthAtReferencePixels, 0.0) * resolutionScale;
    float2 offsetNDC = directionPixels * (2.0 * widthPixels / screenSize);

    // 透视投影使用 clip.w 来保持后除法宽度稳定；正交投影的 clip.w 是 1。保持深度和 reversed-Z 规范。
    positionCS.xy += offsetNDC * positionCS.w;
    return positionCS;
}

///////////////////////////////////////////////////////////////////////////////
//                         Vertex functions                                  //
///////////////////////////////////////////////////////////////////////////////

ShellVaryings ShellPassVertex(ShellAttributes input, float widthAtReferencePixels)
{
    ShellVaryings output = (ShellVaryings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.uv.z = input.texcoord1.y;
    output.positionCS = GetShellPositionHClip(TransformObjectToWorld(input.positionOS.xyz), GetShellNormalWS(input), widthAtReferencePixels);
    return output;
}

half4 SampleShellBaseMap(ShellVaryings input)
{
    #if defined(LOD_FADE_CROSSFADE)
    LODFadeCrossFade(input.positionCS);
    #endif

    half4 baseMap = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    half alpha = Alpha(baseMap.a, _BaseColor, _Cutoff);
    return half4(baseMap.rgb * _BaseColor.rgb, alpha);
}

#endif
