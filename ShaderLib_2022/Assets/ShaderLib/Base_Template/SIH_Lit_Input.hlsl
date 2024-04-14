
// -------------------------------------
// InputData
void InitInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

    inputData.positionWS = input.positionWS;

    #ifdef _NORMALMAP
        float sgn = input.tangentWS.w;
        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
        half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
        inputData.tangentToWorld = tangentToWorld;
        inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    #else
        inputData.normalWS = input.normalWS;
        half3 viewDirectionWS = GetWorldSpaceViewDir(input.positionWS);
    #endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);;

    // 阴影坐标
    #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(_MAIN_LIGHT_SHADOWS_CASCADE)
        inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    #else
        inputData.shadowCoord = half4(0, 0, 0, 0);
    #endif

    // 雾&点光源
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
        inputData.fogCoord = input.fogFactorAndVertexLight.x;
    #else
        inputData.vertexLighting = half3(0, 0, 0);
        inputData.fogCoord = input.fogFactor.x;
    #endif

    // GI
    #ifdef DYNAMICLIGHTMAP_ON
        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, input.normalWS);
    #else
        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, input.normalWS);
    #endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
}