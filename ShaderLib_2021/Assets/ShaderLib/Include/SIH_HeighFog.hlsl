#ifndef SIH_HEIGH_FOG
#define SIH_HEIGH_FOG

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float3 _FogColor;
float _FogGlobalDensity;
float _FogFallOff;
float _FogHeight;
float _FogStartDis;
float _FogInscatteringExp;
float _FogGradientDis;

half3 ExponentialHeightFog(half3 col, half3 posWS)
{
    half heightFallOff = _FogFallOff * 0.01;
    half falloff = heightFallOff * ( posWS.y - _WorldSpaceCameraPos.y - _FogHeight);
    half fogDensity = _FogGlobalDensity * exp2(-falloff);
    half fogFactor = (1 - exp2(-falloff))/falloff;
    half3 viewDir = _WorldSpaceCameraPos - posWS;
    half rayLength = length(viewDir);
    half distanceFactor = max((rayLength - _FogStartDis)/ _FogGradientDis, 0);
    half fog = fogFactor * fogDensity * distanceFactor;
    //如果确保每个Shader里都有灯光向量，也可以放出去
    Light mainlight = GetMainLight();
    float3 lDir = normalize(mainlight.direction);
    float3 lCol = float3(mainlight.color); 
    half inscatterFactor = pow(saturate(dot(-normalize(viewDir), lDir)), _FogInscatteringExp);
    // half inscatterFactor = pow(saturate(dot(-normalize(viewDir), WorldSpaceLightDir(half4(posWS,1)))), _FogInscatteringExp);
    inscatterFactor *= 1-saturate(exp2(falloff));
    inscatterFactor *= distanceFactor;
    half3 finalFogColor = lerp(_FogColor, lCol, saturate(inscatterFactor));
    return lerp(col, finalFogColor, saturate(fog));
}

#endif