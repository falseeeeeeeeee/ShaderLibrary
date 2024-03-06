// #ifndef SIH_STARRAIL_DRAWCORE_PASS_INCLUDED
// #define SIH_STARRAIL_DRAWCORE_PASS_INCLUDED

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    float3 positionWSAndFogFactor   : TEXCOORD1;    // xyz: positionWS, w: vertex FogFactor
    float3 normalWS                 : TEXCOORD2;
    float3 viewDirectionWS           : TEXCOORD3;
    float3 SH                        : TEXCOORD4;    
    float4 positionCS               : SV_POSITION;
};

Varyings StarRailPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = positionInputs.positionCS;
    return output;
}

// half4 StarRailPassFragment(Varyings input, bool isFrontFace : SV_IsFrontFace) : SV_Target
float4 StarRailPassFragment(Varyings input) : SV_Target
{
    float4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    #if _AREA_FACE
    color = SAMPLE_TEXTURE2D(_FaceColorMap, sampler_FaceColorMap, input.uv);
    #elif _AREA_HAIR 
    color = SAMPLE_TEXTURE2D(_HairColorMap, sampler_HairColorMap, input.uv);

    #elif _AREA_UPPERBODY
    color = SAMPLE_TEXTURE2D(_UpperBodyColorMap, sampler_UpperBodyColorMap, input.uv);

    #elif _AREA_LOWERBODY 
    color = SAMPLE_TEXTURE2D(_LowerBodyColorMap, sampler_LowerBodyColorMap, input.uv);

    #endif
    return color;
}
// #endif