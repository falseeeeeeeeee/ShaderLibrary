Shader "URP/Character/Hair2"
{
    Properties 
    {
        [Header(Base)][Space(6)]
    	_Hue ("Hue", Range(0.0, 1.0)) = 0.0
        _BaseColor ("Hair Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _BaseMap ("Hair Map", 2D) = "white" {}
    	
    	[Header(Specular)][Space(6)]
    	_SpeculerColor ("Speculer Color", Color) = (1.0, 1.0, 1.0, 1.0)
    	_SpeculerInt ("Speculer Intensity", Range(0.0, 1.0)) = 1.0
    	_SpeculerInt1 ("Speculer Intensity1", Range(0.0, 1.0)) = 0.7
    	_SpeculerInt2 ("Speculer Intensity2", Range(0.0, 1.0)) = 1.0
    	_Gloss1 ("Gloss 1", Range(0.0, 1.0)) = 0.5
    	_Gloss2 ("Gloss 2", Range(0.0, 1.0)) = 1.0
        _Shift1 ("Shift 1", Float) = 0.8
        _Shift2 ("Shift 2", Float) = 1.5
    	
    	[Space(6)]
        _ShiftMap ("Shift Noise Map", 2D) = "white" {}
		[Toggle] _UseCustomNoise ("Use Custom Noise?", Float) = 1.0
        _NoiseHighFreq ("Noise High Freq", Float) = 800.0
        _NoiseLowFreq ("Noise Low Freq", Float) = 100.0
        _NoiseHighAmp ("Noise High Amp", Float) = 0.1
        _NoiseLowAmp ("Noise Low Amp", Float) = 0.3

    	[Header(Normal)][Space(6)]
        _BumpScale("Normal Scale", Float) = 1.0
        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

        [Header(Gradient)][Space(6)]
    	[Toggle] _EnableGradient ("Enable Gradient", Float) = 1.0
    	_GradientInt ("Gradient Intensity", Range(0.0, 1.0)) = 1.0
    	_TopColor ("Top Color", Color) = (1.0, 0.7, 0.7, 1.0)
        _DownColor ("Down Color", Color) = (1.0, 0.5, 0.7, 1.0)
    	
    	[Header(Rim)][Space(6)]
    	_RimColor ("Rim Color", Color) = (1.0, 0.6, 0.7, 1.0)
        _RimPower("Rim Power", Float) = 4.0        

        [Header(Other)][Space(6)]
    	_Cutoff  ("Alpha Cutoff",  Range(0.0, 1.0)) = 0.5
    	[Toggle] _EnableShadow ("Enable Receive Shadow", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
        }

        Pass {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" } 

            Cull [_CullMode]
        	Blend Off
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

			#pragma shader_feature _USECUSTOMNOISE_ON
			#pragma shader_feature _ENABLEGRADIENT_ON
			#pragma shader_feature _ENABLESHADOW_ON

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
	        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
	        #pragma multi_compile _ _SHADOWS_SOFT
	        #pragma multi_compile_fog
			
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform float _Hue;
			uniform float4 _BaseColor;
			uniform float4 _BaseMap_ST;
			
			uniform half4 _SpeculerColor;
			uniform float _SpeculerInt;
			uniform float _SpeculerInt1;
			uniform float _SpeculerInt2;
			uniform float _Gloss1;
			uniform float _Gloss2;
			uniform float _Shift1;
			uniform float _Shift2;
			
			uniform float4 _ShiftMap_ST;
			uniform float _NoiseHighFreq;
			uniform float _NoiseLowFreq;
			uniform float _NoiseHighAmp;
			uniform float _NoiseLowAmp;
			
			uniform float _BumpScale;

			uniform float _GradientInt;
			uniform half4 _TopColor;
			uniform half4 _DownColor;
			
			uniform half4 _RimColor;
			uniform float _RimPower;
			
			uniform float _Cutoff;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			TEXTURE2D(_ShiftMap);	SAMPLER(sampler_ShiftMap);
			TEXTURE2D(_BumpMap);	SAMPLER(sampler_BumpMap);

			
            struct Attributes
			{
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            	float3 normalWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float fogFactor: TEXCOORD3;
            	float4 uv : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			// SimpleNoise
			float Myunity_noise_randomValue (float2 uv)
			{
			    return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
			}
			float Myunity_noise_interpolate (float a, float b, float t)
			{
			    return (1.0-t)*a + (t*b);
			}
			float Myunity_valueNoise (float2 uv)
			{
			    float2 i = floor(uv);
			    float2 f = frac(uv);
			    f = f * f * (3.0 - 2.0 * f);

			    uv = abs(frac(uv) - 0.5);
			    float2 c0 = i + float2(0.0, 0.0);
			    float2 c1 = i + float2(1.0, 0.0);
			    float2 c2 = i + float2(0.0, 1.0);
			    float2 c3 = i + float2(1.0, 1.0);
			    float r0 = Myunity_noise_randomValue(c0);
			    float r1 = Myunity_noise_randomValue(c1);
			    float r2 = Myunity_noise_randomValue(c2);
			    float r3 = Myunity_noise_randomValue(c3);

			    float bottomOfGrid = Myunity_noise_interpolate(r0, r1, f.x);
			    float topOfGrid = Myunity_noise_interpolate(r2, r3, f.x);
			    float t = Myunity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
			    return t;
			}
			float MyUnity_SimpleNoise_float(float2 UV, float Scale)
			{
			    float t = 0.0;

			    float freq = pow(2.0, float(0));
			    float amp = pow(0.5, float(3-0));
			    t += Myunity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

			    freq = pow(2.0, float(1));
			    amp = pow(0.5, float(3-1));
			    t += Myunity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

			    freq = pow(2.0, float(2));
			    amp = pow(0.5, float(3-2));
			    t += Myunity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;
			    
			    return t;
			}

			// Hue
			float3 Unity_Hue_Radians_float(float3 In, float Offset)
			{
			    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			    float4 P = lerp(float4(In.bg, K.wz), float4(In.gb, K.xy), step(In.b, In.g));
			    float4 Q = lerp(float4(P.xyw, In.r), float4(In.r, P.yzx), step(P.x, In.r));
			    float D = Q.x - min(Q.w, Q.y);
			    float E = 1e-10;
			    float3 hsv = float3(abs(Q.z + (Q.w - Q.y)/(6.0 * D + E)), D / (Q.x + E), Q.x);

			    float hue = hsv.x + Offset;
			    hsv.x = (hue < 0)
			            ? hue + 1
			            : (hue > 1)
			                ? hue - 1
			                : hue;

			    // HSV to RGB
			    float4 K2 = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
			    float3 P2 = abs(frac(hsv.xxx + K2.xyz) * 6.0 - K2.www);
			    return hsv.z * lerp(K2.xxx, saturate(P2 - K2.xxx), hsv.y);
			}

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
            	
            	VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = half4(normalInputs.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
            	
            	output.fogFactor = ComputeFogFactor(input.positionOS.z);
            	
                output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
				#if _USECUSTOMNOISE_ON
					output.uv.zw = input.texcoord;
				#else
				    output.uv.zw = TRANSFORM_TEX(input.texcoord, _ShiftMap);
				#endif

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

				// Normal
			    float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
				float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy), _BumpScale);
				half3 normalWS = normalize(TransformTangentToWorld(normalTS, TBN));

				// MainLight
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                float3 mainlightColor = mainLight.color;
                float3 mainlightDir = normalize(mainLight.direction);
				#if _ENABLESHADOW_ON
					float mainlightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
				#else
					float mainlightShadow = 1;
				#endif

				// lightMode
				half3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
				half3 halfDirWS = normalize(viewDirWS + mainlightDir);
				
				float blinnPhong = saturate(dot(normalWS, halfDirWS));
				float lambert = saturate(dot(mainlightDir, normalWS));
				float halfLambert = lambert * 0.5 + 0.5;
				float fresnel = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _RimPower);

				// BaseColor & Gradient
				float3 rampColor = float3(1.0, 1.0, 1.0);
				#if _ENABLEGRADIENT_ON
					float3 topColor =  lerp(1.0, _TopColor.rgb, _TopColor.a * _GradientInt);
					float3 downColor =  lerp(1.0, _DownColor.rgb, _DownColor.a * _GradientInt);
					rampColor = lerp(downColor, topColor, input.uv.y);
				#endif
				
				float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
				float3 baseColor =  var_BaseMap.rgb * _BaseColor.rgb * rampColor;

				// Diffuse
				float3 diffuse = baseColor * lambert;

				// ShiftNosie
				#if _USECUSTOMNOISE_ON
					float noiseHigh = (MyUnity_SimpleNoise_float(input.uv.zz, _NoiseHighFreq) * 2.0 - 1.0) * _NoiseHighAmp;
					float noiseLow = (MyUnity_SimpleNoise_float(input.uv.zz, _NoiseLowFreq) * 2.0 - 1.0) * _NoiseLowAmp;
					float shiftNoise = noiseHigh + noiseLow;
				#else
					float shiftNoise = SAMPLE_TEXTURE2D(_ShiftMap, sampler_ShiftMap, input.uv.zw).r;
				#endif
				
				// Shift
				float shift1 = shiftNoise - _Shift1;
				float shift2 = shiftNoise - _Shift2;
				float3 bitangentWS1 = normalize(bitangent + shift1 * normalWS);
				float3 bitangentWS2 = normalize(bitangent + shift2 * normalWS);

				// Specular 1
				float dotTH1 = dot(bitangentWS1, halfDirWS);
				float sinTH1 = sqrt(1.0 - dotTH1 * dotTH1);
				float attenDir1 = smoothstep(-1, 0, dotTH1);
				float specular1 = attenDir1 * pow(sinTH1, _Gloss1 * 256.0 + 0.1) * _SpeculerInt1;

				// Specular 2
				float dotTH2 = dot(bitangentWS2, halfDirWS);
				float sinTH2 = sqrt(1.0 - dotTH2 * dotTH2);
				float attenDir2 = smoothstep(-1, 0, dotTH2);
				float specular2 = attenDir2 * pow(sinTH2, _Gloss2 * 256.0 + 0.1) * _SpeculerInt2;
				
				// Specular Blend
				float3 specular = (specular1 + specular2 * baseColor) * _SpeculerInt * _SpeculerColor;
				specular *= saturate(diffuse * 2);	// 到这里啦到这里啦到这里啦到这里啦到这里啦

				// Rim
                half3 rimLight = _RimColor.a * _RimColor.rgb * fresnel;

				// Environment Diffuse
				float3 ambient = SampleSH(input.normalWS);

				// Hue
				diffuse = Unity_Hue_Radians_float(diffuse, _Hue);
				specular = Unity_Hue_Radians_float(specular, _Hue);
				rimLight = Unity_Hue_Radians_float(rimLight, _Hue);

				// Color
				half3 color = (diffuse + specular) * mainlightColor * mainlightShadow
							+ ambient * baseColor
							+ rimLight;
				
				// Alpha
                half alpha = var_BaseMap.a * _BaseColor.a;
				clip(alpha - _Cutoff);
				
				// Fog
                half fogFactor = ComputeFogFactor(input.positionCS.z * input.positionCS.w);
                color = MixFog(color, fogFactor);
                
                return half4(color, alpha);
            } 
            ENDHLSL
        }
    	
    	Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
        	
        	Cull Off
            
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            
            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                    float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
            	
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }

            ENDHLSL
        }
    }
}