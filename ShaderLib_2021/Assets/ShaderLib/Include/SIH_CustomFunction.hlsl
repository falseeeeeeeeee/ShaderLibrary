#ifndef SIH_CUSTOM_FUNCTION_INCLUDED
#define SIH_CUSTOM_FUNCTION_INCLUDED

//1D
float Random1DTo1D(float value,float a,float b){
	//make value more random by making it bigger
	float random = frac(sin(value+b)*a);
        return random;
}

float2 Random1DTo2D(float value){
    return float2(
        Random1DTo1D(value,14375.5964,0.546),
        Random1DTo1D(value,18694.2233,0.153)
    );
}

float3 Random1DTo3D(float value){
    return float3(
        Random1DTo1D(value,14375.5964,0.546),
        Random1DTo1D(value,18694.2233,0.153),
        Random1DTo1D(value,19663.6565,0.327)
    );
}

float4 Random1DTo4D(float value){
    return float4(
        Random1DTo1D(value,14375.5964,0.546),
        Random1DTo1D(value,18694.2233,0.153),
        Random1DTo1D(value,19663.6565,0.327),
        Random1DTo1D(value,12748.4774,0.688)
    );
}
//2D
float Random2DTo1D(float2 value,float a ,float2 b)
{			
	//avaoid artifacts
	float2 smallValue = sin(value);
	//get scalar value from 2d vector	
	float  random = dot(smallValue,b);
	random = frac(sin(random) * a);
	return random;
}

float2 Random2DTo2D(float2 value){
	return float2(
		Random2DTo1D(value,14375.5964, float2(15.637, 76.243)),
		Random2DTo1D(value,14684.6034,float2(45.366, 23.168))
	);
}

float3 Random2DTo3D(float2 value){
    return float3(
        Random2DTo1D(value,14375.5964,float2(15.637, 76.243)),
        Random2DTo1D(value,18694.2233,float2(45.366, 23.168)),
        Random2DTo1D(value,19663.6565,float2(62.654, 88.467))
    );
}

float4 Random2DTo4D(float2 value){
    return float4(
        Random2DTo1D(value,14375.5964,float2(15.637, 76.243)),
        Random2DTo1D(value,18694.2233,float2(45.366, 23.168)),
        Random2DTo1D(value,19663.6565,float2(62.654, 88.467)),
        Random2DTo1D(value,17635.1739,float2(44.383, 38.174))
    );
}
//3D
float Random3DTo1D(float3 value,float a,float3 b)
{			
	float3 smallValue = sin(value);
	float  random = dot(smallValue,b);
	random = frac(sin(random) * a);
	return random;
}

float2 Random3DTo2D(float3 value){
	return float2(
		Random3DTo1D(value,14375.5964, float3(15.637,76.243,37.168)),
		Random3DTo1D(value,14684.6034,float3(45.366, 23.168,65.918))
	);
}

float3 Random3DTo3D(float3 value){
	return float3(
		Random3DTo1D(value,14375.5964, float3(15.637,76.243,37.168)),
		Random3DTo1D(value,14684.6034,float3(45.366, 23.168,65.918)),
		Random3DTo1D(value,17635.1739,float3(62.654, 88.467,25.111))
	);
}

float4 Random3DTo4D(float3 value){
	return float4(
		Random3DTo1D(value,14375.5964, float3(15.637,76.243,37.168)),
		Random3DTo1D(value,14684.6034,float3(45.366, 23.168,65.918)),
		Random3DTo1D(value,17635.1739,float3(62.654, 88.467,25.111)),
        Random3DTo1D(value,17635.1739,float3(44.383, 38.174,67.688))	
	);
}
//4D
float Random4DTo1D(float4 value,float a ,float4 b)
{			
	float4 smallValue = sin(value);
	float  random = dot(smallValue,b);
	random = frac(sin(random) * a);
	return random;
}

float2 Random4DTo2D(float4 value)
{			
    return float2(		
        Random4DTo1D(value,14375.5964,float4(15.637,76.243,37.168,83.511)),
        Random4DTo1D(value,14684.6034,float4(45.366, 23.168,65.918,57.514))
	);
}

float3 Random4DTo3D(float4 value)
{			
    return float3(		
        Random4DTo1D(value,14375.5964,float4(15.637,76.243,37.168,83.511)),
        Random4DTo1D(value,14684.6034,float4(45.366, 23.168,65.918,57.514)),
        Random4DTo1D(value,14985.1739,float4(62.654, 88.467,25.111,61.875))
	);
}

float4 Random4DTo4D(float4 value)
{			
    return float4(		
        Random4DTo1D(value,14375.5964,float4(15.637,76.243,37.168,83.511)),
        Random4DTo1D(value,14684.6034,float4(45.366, 23.168,65.918,57.514)),
        Random4DTo1D(value,14985.1739,float4(62.654, 88.467,25.111,61.875)),
        Random4DTo1D(value,17635.1739,float4(44.383, 38.174,67.688,22.351))	
	);
}


float unity_noise_randomValue (float2 uv)
{
	return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
}

float unity_noise_interpolate (float a, float b, float t)
{
	return (1.0-t)*a + (t*b);
}

float unity_valueNoise (float2 uv)
{
	float2 i = floor(uv);
	float2 f = frac(uv);
	f = f * f * (3.0 - 2.0 * f);

	uv = abs(frac(uv) - 0.5);
	float2 c0 = i + float2(0.0, 0.0);
	float2 c1 = i + float2(1.0, 0.0);
	float2 c2 = i + float2(0.0, 1.0);
	float2 c3 = i + float2(1.0, 1.0);
	float r0 = unity_noise_randomValue(c0);
	float r1 = unity_noise_randomValue(c1);
	float r2 = unity_noise_randomValue(c2);
	float r3 = unity_noise_randomValue(c3);

	float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
	float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
	float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
	return t;
}

float Unity_SimpleNoise_float(float2 UV, float Scale)
{
	float t = 0.0;

	float freq = pow(2.0, float(0));
	float amp = pow(0.5, float(3-0));
	t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

	freq = pow(2.0, float(1));
	amp = pow(0.5, float(3-1));
	t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

	freq = pow(2.0, float(2));
	amp = pow(0.5, float(3-2));
	t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

	return t;
}

// SubsurfaceScattering
inline float SubsurfaceScattering (float3 viewDir, float3 lightDir, float3 normalDir, 
	float frontSubsurfaceDistortion, float backSubsurfaceDistortion, float frontSssIntensity, float backSssIntensity)
{
	float3 frontLitDir = normalDir * frontSubsurfaceDistortion - lightDir;
	float3 backLitDir = normalDir * backSubsurfaceDistortion + lightDir;
                
	float frontSSS = saturate(dot(viewDir, -frontLitDir));
	float backSSS = saturate(dot(viewDir, -backLitDir));
                
	float result = saturate(frontSSS * frontSssIntensity + backSSS * backSssIntensity);
                
	return result;
}

// ColorAlphaStrength
float3 ColorAlphaStrength(float4 Color, float Gray)
{
	return lerp(Gray.rrr, Color.rgb, Color.a);
}


// Matcap
float3 MatcapBlend(float3 Albedo, float3 MatcapMap, float MatcapOpacity, float MatcapBlendMode)
{
	half3 matcap = float3(1.0, 1.0, 1.0);
	
	switch (MatcapBlendMode)
	{
		case 1:     // 正常叠加（Normal Blending）
			matcap = MatcapMap;
		break;
		case 2:     // 乘法叠加（Multiply Blending）
			matcap = Albedo * MatcapMap;
		break;
		case 3:     // 加法叠加（Additive Blending）
			matcap = Albedo + MatcapMap;
		break;
		case 4:     // 混合叠加（Mix Blending）
			matcap = lerp(Albedo, MatcapMap, 0.5);
		break;
		case 5:     // 屏幕叠加（Screen Blending）
			matcap = 1 - (1 - Albedo) * (1 - MatcapMap);
		break;
		case 6:     // 叠加（Overlay Blending）
			matcap = Albedo < 0.5 ? (2 * Albedo * MatcapMap) : (1 - 2 * (1 - Albedo) * (1 - MatcapMap));
		break;
		default:
			matcap = Albedo;
			break;
	}

	return lerp(Albedo, matcap, MatcapOpacity);
}

// NormalBlend
float3 NormalBlend(float3 A, float3 B)
{
	return  normalize(float3(A.rg + B.rg, A.b * B.b));
}
#endif