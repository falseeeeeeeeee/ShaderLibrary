#ifndef SIH_STYLIZED_OUTLINE_PASS_INCLUDED
#define SIH_STYLIZED_OUTLINE_PASS_INCLUDED

#include "./SIH_StylizedOutlinePassTypes.hlsl"

ShellVaryings OutlinePassVertex(ShellAttributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    return ShellPassVertex(input, GetOutlineWidth());
}

half4 OutlinePassFragment(ShellVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if !defined(_OUTLINE_ON)
    clip(-1.0);
    return 0;
#else
    // Zero width must not leave a back-face color or depth contribution.
    clip(GetOutlineWidth() - 1e-5);
    half4 baseMap = SampleShellBaseMap(input);
    half3 color = lerp(baseMap.rgb, half3(0.025h, 0.025h, 0.025h), 0.9h);
    return half4(color, baseMap.a);
#endif
}

#endif
