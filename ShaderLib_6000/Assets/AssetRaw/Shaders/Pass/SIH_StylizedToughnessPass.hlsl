#ifndef SIH_STYLIZED_TOUGHNESS_PASS_INCLUDED
#define SIH_STYLIZED_TOUGHNESS_PASS_INCLUDED

#include "./SIH_StylizedOutlinePassTypes.hlsl"

ShellVaryings ToughnessPassVertex(ShellAttributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);

    // Screen-space pixels, matching Outline. Toughness is an EXTRA width.
    const float kToughnessMaxWidth = 5.0;
    float outlineWidth = 0.0;
#if defined(_OUTLINE_ON)
    outlineWidth = max((float)_OutlineSize, 0.0);
#endif
    float toughnessWidth = saturate((float)_ToughnessSwitch) * kToughnessMaxWidth;
    float width = outlineWidth + toughnessWidth;
    return ShellPassVertex(input, width);
}

half4 ToughnessPassFragment(ShellVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if !defined(_TOUGHNESS_ON)
    clip(-1.0);
    return 0;
#else
    clip(_ToughnessSwitch - 1e-5);
    half4 baseMap = SampleShellBaseMap(input);
    half3 colorA = half3(1.0h, 1.0h, 1.0h);
    half3 colorB = lerp(baseMap.rgb, half3(1.0h, 0.75h, 0.75h), 0.5h);
    float band = frac((input.uv.z - _Time.y) * 0.2);
    half mask = saturate((1.0 - band) * band * 4.0);
    return half4(lerp(colorA, colorB, mask) * 2.0h, baseMap.a);
#endif
}

#endif
