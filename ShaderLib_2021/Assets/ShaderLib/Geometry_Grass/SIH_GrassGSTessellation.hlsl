
#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_PSSL)
#define UNITY_CAN_COMPILE_TESSELLATION 1
#   define UNITY_domain                 domain
#   define UNITY_partitioning           partitioning
#   define UNITY_outputtopology         outputtopology
#   define UNITY_patchconstantfunc      patchconstantfunc
#   define UNITY_outputcontrolpoints    outputcontrolpoints
#endif

// 随着距相机的距离减少细分数
float CalcDistanceTessFactor(float4 positionOS, float minDist, float maxDist, float tess)
{
    float3 worldPosition = TransformObjectToWorld(positionOS.xyz);
    float dist = distance(worldPosition,  GetCameraPositionWS());
    float output = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
    return (output);
}


struct TessellationFactors 
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

TessellationFactors patchConstantFunction (InputPatch<Varyings, 3> patch)
{
	
	TessellationFactors output;
                
    #ifdef _TESSVIEW_ON
        float minDist = _MinTessDistance;
        float maxDist = _MaxTessDistance;

        float edge0 = CalcDistanceTessFactor(patch[0].positionOS, minDist, maxDist, _Tess);
        float edge1 = CalcDistanceTessFactor(patch[1].positionOS, minDist, maxDist, _Tess);
        float edge2 = CalcDistanceTessFactor(patch[2].positionOS, minDist, maxDist, _Tess);

        output.edge[0] = (edge1 + edge2) / 2;
        output.edge[1] = (edge2 + edge0) / 2;
        output.edge[2] = (edge0 + edge1) / 2;
        output.inside = (edge0 + edge1 + edge2) / 3;
    #else
        output.edge[0] = _Tess;
		output.edge[1] = _Tess;
		output.edge[2] = _Tess;
        output.inside = _Tess;
    #endif

    return output;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
Varyings hull (InputPatch<Varyings, 3> patch, uint id : SV_OutputControlPointID)
{
	return patch[id];
}

[UNITY_domain("tri")]
Varyings domain(TessellationFactors factors, OutputPatch<Varyings, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
	Varyings v;

	

	//曲面细分
	#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	// These should match Varyings struct, in Grass.hlsl

	MY_DOMAIN_PROGRAM_INTERPOLATE(positionOS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(normalOS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(positionHCS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(positionWS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(positionVS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(normalWS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangentWS)
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv)


	//顶点波动
    v.uv = TRANSFORM_TEX(v.uv, _BaseMap);
	float displacement = (SAMPLE_TEXTURE2D_LOD(_DisplacementMap, sampler_DisplacementMap, v.uv, 0).x - _DisplacementOffset) * _DisplacementStrength;

	v.positionOS.xyz += v.normalOS * displacement;

	v.positionWS = TransformObjectToWorld(v.positionOS.xyz);
	float positionWSWaveX = sin(v.positionWS.x * _WaveFrequency + _Time.x * _WaveSpeed);
    float positionWSWaveZ = sin(v.positionWS.z * _WaveFrequency + _Time.x * _WaveSpeed);
    v.positionOS.y += (positionWSWaveX + positionWSWaveZ) * _WaveStrength * step(_WaveMask, v.positionOS.y);
	v.positionWS = TransformObjectToWorld(v.positionOS.xyz);


	return v;
}