// ----------------------------------------------------------------------
// 结构体
// ----------------------------------------------------------------------

// 顶点着色器输入
struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0; 
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 顶点着色器输出
struct Varyings
{
    float4 positionOS : INTERNALTESSPOS;
    float3 normalOS : TEXCOORD7;

    float4 positionHCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 positionVS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;

    //#if _NORMALMAP
		float4 tangentWS : TEXCOORD3;
    //#endif

    float2 uv : TEXCOORD4;
    float fogFactor: TEXCOORD5; 
    float3 viewDirWS : TEXCOORD6;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 几何着色器输出
struct GeometryOutput 
{
	float4 positionHCS : SV_POSITION;
	float3 positionWS : TEXCOORD0;
	float3 normalWS	: TEXCOORD1;
	float2 uv : TEXCOORD2;
	float bladeSegments : TEXCOORD3;
};


// ----------------------------------------------------------------------
// 方法
// ----------------------------------------------------------------------

// Methods
float rand(float3 seed) 
{
	return frac(sin(dot(seed.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

// Rotate
float3x3 AngleAxis3x3(float angle, float3 axis) 
{
	float c, s;
	sincos(angle, s, c);

	float t = 1 - c;
	float x = axis.x;
	float y = axis.y;
	float z = axis.z;

	return float3x3(
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c
	);
}

// ShadowCasterPass
#ifdef SHADERPASS_SHADOWCASTER
	float3 _LightDirection;

	float4 GetShadowPositionHClip(float3 positionWS, float3 normalWS) 
    {
		float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

	    #if UNITY_REVERSED_Z
		    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
	    #else
		    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
	    #endif

		return positionCS;
	}
#endif

// 世界空间转屏幕裁剪空间		ShadowCasterPass/ForwardPass
float4 WorldToHClip(float3 positionWS, float3 normalWS)
{
	#ifdef SHADERPASS_SHADOWCASTER
		return GetShadowPositionHClip(positionWS, normalWS);
	#else
		return TransformWorldToHClip(positionWS);
	#endif
}


// ----------------------------------------------------------------------
// 变量
// ----------------------------------------------------------------------
CBUFFER_START(UnityPerMaterial)
uniform half4 _BaseColor;
uniform float4 _BaseMap_ST;
uniform half4 _SpecularColor;
uniform half _SpecularRange;
uniform float4 _NormalMap_ST;
uniform float _NormalScale;
uniform float _DisplacementStrength;
uniform float _DisplacementOffset;
uniform float _Tess;
uniform float _MinTessDistance;
uniform float _MaxTessDistance;

uniform float _WaveStrength;
uniform float _WaveFrequency;
uniform float _WaveSpeed;
uniform float _WaveMask;

uniform float4 _TopColor;
uniform float4 _BottomColor;
uniform float _Width;
uniform float _RandomWidth;
uniform float _Height;
uniform float _RandomHeight;
uniform float _WindStrength;
uniform float _WindSpeed;
uniform float _DistanceStrength;
uniform float _DistanceOffset;
CBUFFER_END

TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap);	SAMPLER(sampler_NormalMap);
TEXTURE2D(_DisplacementMap);	SAMPLER(sampler_DisplacementMap);


// ----------------------------------------------------------------------
// 顶点着色器
// ----------------------------------------------------------------------
Varyings vert (Attributes input)
{
    Varyings output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

	//顶点波动
	/*
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
	float displacement = (SAMPLE_TEXTURE2D_LOD(_DisplacementMap, sampler_DisplacementMap, output.uv, 0).x - _DisplacementOffset) * _DisplacementStrength;

	input.positionOS.xyz += input.normalOS * displacement;

	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	float positionWSWaveX = sin(output.positionWS.x * _WaveFrequency + _Time.x * _WaveSpeed);
    float positionWSWaveZ = sin(output.positionWS.z * _WaveFrequency + _Time.x * _WaveSpeed);
    input.positionOS.y += (positionWSWaveX + positionWSWaveZ) * _WaveStrength * step(_WaveMask, input.positionOS.y);
	*/
    output.uv = input.texcoord;
    output.positionOS = input.positionOS;
    output.normalOS = input.normalOS;

    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionHCS = positionInputs.positionCS;
    output.positionWS = positionInputs.positionWS;
    output.positionVS = positionInputs.positionVS;


	//Normal
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.normalWS = normalInputs.normalWS;

    //#if _NORMALMAP
        real sign = input.tangentOS.w * GetOddNegativeScale();
        half4 tangentWS = half4(normalInputs.tangentWS.xyz, sign);
        output.tangentWS = tangentWS;
    //#endif
    output.fogFactor = ComputeFogFactor(input.positionOS.z);

    return output;
}


// ----------------------------------------------------------------------
// 几何着色器
// ----------------------------------------------------------------------
[maxvertexcount(BLADE_SEGMENTS * 2 + 1 + 3)]
void geom(uint primitiveID : SV_PrimitiveID, triangle Varyings input[3], inout TriangleStream<GeometryOutput> triStream) 
{
	GeometryOutput output = (GeometryOutput) 0;
	// -----------------------
	// Blade Segment Detail
	// -----------------------
	float3 cameraPos = _WorldSpaceCameraPos;
	float3 positionWS = input[1].positionWS;
    
    #ifdef _DISTANCEDETAIL_ON
		float3 vtcam = cameraPos - positionWS;
		float distSqr = dot(vtcam, vtcam);
		int bladeSegments = lerp(BLADE_SEGMENTS, 0, saturate(distSqr * _DistanceStrength - _DistanceOffset));
	#else
		int bladeSegments = BLADE_SEGMENTS;
	#endif
	output.bladeSegments = bladeSegments;
    

	// -----------------------
	// Normal 
	// -----------------------
	float v = 1 - saturate(bladeSegments);

	output.positionWS = input[0].positionWS;
	output.normalWS = input[0].normalWS;
	output.positionHCS = WorldToHClip(output.positionWS, output.normalWS);
	output.uv = float2(0, v);
	triStream.Append(output);

	output.positionWS = input[1].positionWS;
	output.normalWS = input[1].normalWS;
	output.positionHCS = WorldToHClip(output.positionWS, output.normalWS);
	output.uv = float2(0, v);
	triStream.Append(output);

	output.positionWS = input[2].positionWS;
	output.normalWS = input[2].normalWS;
	output.positionHCS = WorldToHClip(output.positionWS, output.normalWS);
	output.uv = float2(0, v);
	triStream.Append(output);

	triStream.RestartStrip();

	if (bladeSegments <= 0)
	{
		return;
	}

	if (input[0].positionVS.z > 0)
	{
		return;
	}

	// -----------------------
	// 构建世界 -> 切线矩阵（用于将草与网格法线对齐）
	// -----------------------
	float3 normal = input[0].normalWS;
	float4 tangent = input[0].tangentWS;
	float3 binormal = cross(normal, tangent.xyz) * tangent.w;

	float3x3 tangentToLocal = float3x3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);

	// -----------------------
	// 风
	// -----------------------
	float r = rand(positionWS.xyz);
	float3x3 randRotation = AngleAxis3x3(r * TWO_PI, float3(0,0,1));

	float3x3 windMatrix;
    if (_WindStrength != 0) 
    { 
        float2 wind = float2(sin(_Time.y * _WindSpeed + positionWS.x * 0.5), cos(_Time.y * _WindSpeed + positionWS.z * 0.5)) * _WindStrength * sin(_Time.y * _WindSpeed + r) * float2(0.5, 1.0);
		windMatrix = AngleAxis3x3((wind * PI).y, normalize(float3(wind.x, wind.x, wind.y)));
    }
	else
	{
		windMatrix = float3x3(1,0,0,0,1,0,0,0,1);
	}

	// -----------------------
	// 小草弯曲， 宽&高
	// -----------------------
	float3x3 transformMatrix = mul(tangentToLocal, randRotation);
	float3x3 transformMatrixWithWind = mul(mul(tangentToLocal, windMatrix), randRotation);

	float bend = rand(positionWS.xyz) - 0.5;
	float width = _Width + _RandomWidth * (rand(positionWS.zyx) - 0.5);
	float height = _Height + _RandomHeight * (rand(positionWS.yxz) - 0.5);


	// -----------------------
	// 处理 几何着色器
	// -----------------------
	// 所有草叶顶点的法线都相同
	float3 normalWS = mul(transformMatrix, float3(0, -1, 0));
	output.normalWS = normalWS;

	// 基于 2 个顶点
	output.positionWS = positionWS + mul(transformMatrix, float3(width, 0, 0));
	output.positionHCS = WorldToHClip(output.positionWS, normalWS);
	output.uv = float2(0, 0);
	triStream.Append(output);

	output.positionWS = positionWS + mul(transformMatrix, float3(-width, 0, 0));
	output.positionHCS = WorldToHClip(output.positionWS, normalWS);
	output.uv = float2(0, 0);
	triStream.Append(output);

	// 中心 (每 BLADE_SEGMENTS 2个顶点)
	for (int i = 1; i < bladeSegments; i++) 
	{
		float t = i / (float)bladeSegments;

		float h = height * t;
		float w = width * (1-t);
		float b = bend * pow(t, 2);

		output.positionWS = positionWS + mul(transformMatrixWithWind, float3(w, b, h));
		output.positionHCS = WorldToHClip(output.positionWS, normalWS);
		output.uv = float2(0, t);
		triStream.Append(output);

		output.positionWS = positionWS + mul(transformMatrixWithWind, float3(-w, b, h));
		output.positionHCS = WorldToHClip(output.positionWS, normalWS);
		output.uv = float2(0, t);
		triStream.Append(output);
	}

	// Final vertex at top of blade
	output.positionWS = positionWS + mul(transformMatrixWithWind, float3(0, bend, height));
	output.positionHCS = WorldToHClip(output.positionWS, normalWS);

	output.uv = float2(0, 1);
	triStream.Append(output);

	triStream.RestartStrip();
}
