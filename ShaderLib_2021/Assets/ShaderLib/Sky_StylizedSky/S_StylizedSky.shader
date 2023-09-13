Shader "URP/Sky/S_StylizedSky"
{
    Properties 
    {
    	[Header(SkyColor)][Space(4)]
        _SkyColorA ("天空颜色", Color) = (0.48, 0.84, 0.9)
    	_SkyColorB ("云朵颜色", Color) = (0.8, 1.0, 1.0)
    	
    	[Header(Noise)][Space(4)]
    	_CloudNoiseMap ("噪波贴图", 2D) = "white" {}
    	_NoiseParam ("噪波参数", Vector) = (0.02, 12.0, 8.0, 0.5)
    	_AddNoiseRotateCenterAndRotation ("XY:旋转中心 W:旋转速度 Z:旋转角度", Vector) = (0.0, 0.1, 0.01, 0.0)
    	_AddNoiseOffsetSpeedAndScale ("XY:偏移大小 Z:偏移速度 W:缩放", Vector) = (0.1, 0.1, 0.01, 200)
    	_AddNoisePower ("次幂", Float) = 2.0
    	_AddNoiseAdd ("强度", Float) = 0.5

    	[Header(Sun)][Space(4)]
    	_SunColor ("太阳颜色", Color) = (1.0, 1.0, 1.0)
    	_SunSize ("太阳大小", Range(0.001, 1.0)) = 0.1
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            //"RenderType" = "Opaque"
            "Queue"="Background"
            "RenderType"="Background"
            "PreviewType"="Skybox"
        }

        Pass {
            Name "SKY_FORWARD"
            //Tags { "LightMode" = "UniversalForward" }
             
            Cull Off
            ZWrite Off

			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _SkyColorA;
			uniform half4 _SkyColorB;
			uniform float4 _CloudNoiseMap_ST;
			uniform float4 _NoiseParam;
			uniform float4 _AddNoiseRotateCenterAndRotation;
			uniform float4 _AddNoiseOffsetSpeedAndScale;
			uniform half _AddNoisePower;
			uniform half _AddNoiseAdd;
			uniform half4 _SunColor;
			uniform half _SunSize;
            CBUFFER_END
			
			TEXTURE2D(_CloudNoiseMap);	    SAMPLER(sampler_CloudNoiseMap);

			// SimpleNoise
			float Unity_noise_randomValue (float2 uv)
			{
			    return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
			}
			float Unity_noise_interpolate (float a, float b, float t)
			{
			    return (1.0-t)*a + (t*b);
			}
			float Unity_valueNoise (float2 uv)
			{
			    float2 i = floor(uv);
			    float2 f = frac(uv);
			    f = f * f * (3.0 - 2.0 * f);

			    uv = abs(frac(uv) - 0.5);
			    float2 c0 = i + float2(0.0, 0.0);
			    float2 c1 = i + float2(1.0, 0.0);
			    float2 c2 = i + float2(0.0, 1.0);
			    float2 c3 = i + float2(1.0, 1.0);
			    float r0 = Unity_noise_randomValue(c0);
			    float r1 = Unity_noise_randomValue(c1);
			    float r2 = Unity_noise_randomValue(c2);
			    float r3 = Unity_noise_randomValue(c3);

			    float bottomOfGrid = Unity_noise_interpolate(r0, r1, f.x);
			    float topOfGrid = Unity_noise_interpolate(r2, r3, f.x);
			    float t = Unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
			    return t;
			}
			float Unity_SimpleNoise_float(float2 UV, float Scale)
			{
			    float t = 0.0;

			    float freq = pow(2.0, float(0));
			    float amp = pow(0.5, float(3-0));
			    t += Unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

			    freq = pow(2.0, float(1));
			    amp = pow(0.5, float(3-1));
			    t += Unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

			    freq = pow(2.0, float(2));
			    amp = pow(0.5, float(3-2));
			    t += Unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
			    
			    return t;
			}

			// Rotate
			float2 Unity_Rotate_Radians(float2 UV, float2 Center, float Rotation)
			{
			    UV -= Center;
			    float s = sin(Rotation);
			    float c = cos(Rotation);
			    float2x2 rMatrix = float2x2(c, -s, s, c);
			    rMatrix *= 0.5;
			    rMatrix += 0.5;
			    rMatrix = rMatrix * 2 - 1;
			    UV.xy = mul(UV.xy, rMatrix);
			    UV += Center;
			    return UV;
			}
			
            struct Attributes
			{
                float4 positionOS : POSITION;
            	float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
            	float3 positionWS : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float2 uvDefault : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

            	float2 uvXZ = float2(input.texcoord.x, input.texcoord.z);
            	float uvY = 1.0 - saturate(input.texcoord.y);
                output.uv.xy = (uvXZ + uvXZ * uvY) * _CloudNoiseMap_ST.xy + _CloudNoiseMap_ST.zw;
            	float2 uvOffsetSpeed = _AddNoiseOffsetSpeedAndScale.xy * _AddNoiseOffsetSpeedAndScale.z * _Time.y;
            	float uvRotateSpeed = _AddNoiseRotateCenterAndRotation.w + _AddNoiseRotateCenterAndRotation.z * _Time.y;
            	output.uv.zw = Unity_Rotate_Radians(output.uv.xy, _AddNoiseRotateCenterAndRotation.xy, uvRotateSpeed) + uvOffsetSpeed;
            	output.uvDefault = input.texcoord.xy;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

				// Noise
				float var_CloudNoiseMap = SAMPLE_TEXTURE2D(_CloudNoiseMap, sampler_CloudNoiseMap, input.uv.xy).r;
				float addNoise = pow(saturate(Unity_SimpleNoise_float(input.uv.zw, _AddNoiseOffsetSpeedAndScale.w)), _AddNoisePower) + _AddNoiseAdd;
				float noise = var_CloudNoiseMap * addNoise * input.uvDefault.y;
				noise = saturate(noise);
				noise = saturate(1.0 - abs(pow(((noise + abs(_NoiseParam.x)) * abs(_NoiseParam.y)), _NoiseParam.z) - _NoiseParam.w));

				// Gradient
				float4 skyColor = saturate(lerp(_SkyColorA, _SkyColorA + _SkyColorB, noise));

				// Sun
				Light mainLight = GetMainLight();
                half3 mainlightDir = normalize(mainLight.direction);
				float sun = dot(mainlightDir, normalize(input.positionWS)) - (1 - _SunSize * 0.1);
				float sunDDXY = abs(abs(ddx(sun)) + abs(ddy(sun)));
				sun = saturate(sun / sunDDXY);
				float4 sunColor = sun * _SunColor;

				// blendColor
				float3 color = skyColor.rgb + sunColor.rgb * sunColor.a;
			    
                
                return float4(color.rgb, 1);
            } 
            ENDHLSL
        }
    }
}
