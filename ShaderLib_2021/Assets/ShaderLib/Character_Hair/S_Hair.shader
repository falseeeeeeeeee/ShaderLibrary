Shader "URP/Character/Hair"
{
    Properties 
    {
        [Header(Base)][Space(6)]
    	_Hue ("Hue", Range(0.0, 1.0)) = 0.0
        _BaseColor ("Hair Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _BaseMap ("Hair Map", 2D) = "white" {}
    	_SpeculerInt ("Speculer Intensity", Range(0.0, 1.0)) = 0.5
    	_SpeculerScale ("Speculer Scale", Range(0.0, 1.0)) = 0.1
        
        [Header(Normal)][Space(6)]
        _BumpScale("Normal Scale", Float) = 1.0
        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
    	
        [Header(Gradient)][Space(6)]
    	[Toggle] _EnableGradient ("Enable Gradient", Float) = 1.0
    	_TopColor ("Top Color", Color) = (1.0, 0.7, 0.7, 1.0)
        _DownColor ("Down Color", Color) = (1.0, 0.5, 0.7, 1.0)
		_GradientInt ("Gradient Intensity", Range(0.0, 1.0)) = 1.0

        [Header(Anisotropic)][Space(6)]
    	[Toggle] _EnableAnisotropic ("Enable Anisotropic", Float) = 1.0
    	[Toggle] _UseSecondUV ("Use 2U?", Float) = 0.0
    	
    	[Space(6)]
        _HighLightColor ("High Light Color", Color) = (1.0, 0.8, 0.8, 1.0)
        _HighLightScale ("High Light Scale", Range(0.0, 1.0)) = 0.02
        _HighLightRange ("High Light Range", Range(1.0, 96.0)) = 6.0

        [Space(6)]
        _NoiseHighFreq ("Noise High Freq", Float) = 800.0
        _NoiseLowFreq ("Noise Low Freq", Float) = 100.0
        _NoiseHighAmp ("Noise High Amp", Float) = 0.1
        _NoiseLowAmp ("Noise Low Amp", Float) = 0.3
    	
    	[Space(6)]
    	_HighLightOffset ("High Light Offset", Range(-1.0, 1.0)) = 0.0
    	[Toggle] _EnableDoubleAnisotropic ("Double Anisotropic?", Float) = 0.0
    	_SecondHighLightOffset ("Second High Light Offset",  Range(-1.0, 1.0)) = 0.3
    	
    	[Header(Rim)][Space(6)]
    	_RimColor ("Rim Color", Color) = (1.0, 0.6, 0.7, 1.0)
        _RimPower("Rim Power", Float) = 4.0        

        [Header(Other)][Space(6)]
    	[Toggle] _EnableShadow ("Enable Receive Shadow", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" } 

            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

			#pragma shader_feature _ENABLEGRADIENT_ON
			#pragma shader_feature _ENABLEANISOTROPIC_ON
			#pragma shader_feature _ENABLEDOUBLEANISOTROPIC_ON
			#pragma shader_feature _USESECONDUV_ON
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
			uniform half4 _BaseColor;
			uniform float4 _BaseMap_ST;
			uniform float _SpeculerInt;
			uniform float _SpeculerScale;
			uniform float _BumpScale;
			
			uniform float _GradientInt;
			uniform half4 _TopColor;
			uniform half4 _DownColor;
			
			uniform half4 _HighLightColor;
			uniform float _HighLightScale;

			uniform float _HighLightRange;
			uniform float _NoiseHighFreq;
			uniform float _NoiseLowFreq;
			uniform float _NoiseHighAmp;
			uniform float _NoiseLowAmp;

			uniform float _HighLightOffset;
			uniform float _SecondHighLightOffset;
			
			uniform half4 _RimColor;
			uniform float _RimPower;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			TEXTURE2D(_BumpMap);	SAMPLER(sampler_BumpMap);

			
            struct Attributes
			{
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
            	#if _USESECONDUV_ON
            		float2 texcoord1 : TEXCOORD1;
            	#endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            	float3 normalWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float fogFactor: TEXCOORD3;
            	float2 uv : TEXCOORD4;
            	float2 uvTex : TEXCOORD5;
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
            	
                output.uv = input.texcoord;
				#if _USESECONDUV_ON
            		output.uv = input.texcoord1;
            	#endif
                output.uvTex = TRANSFORM_TEX(input.texcoord, _BaseMap);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

				// Normal
			    float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
				float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uvTex), _BumpScale);
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
				float blinnPhong0 = saturate(dot(normalWS, halfDirWS));
				float blinnPhong1 = pow(blinnPhong0, _SpeculerScale * 128.0 + 0.0001);
				float lambert = saturate(dot(mainlightDir, normalWS));
				float halfLambert = lambert * 0.5 + 0.5;
				float fresnel = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _RimPower);



				// HighLight
				float3 highLightColor = float3(0.0, 0.0, 0.0);
				#if _ENABLEANISOTROPIC_ON
					float noiseHigh = (MyUnity_SimpleNoise_float(input.uv.rr, _NoiseHighFreq) * 2.0 - 1.0) * _NoiseHighAmp;
					float noiseLow = (MyUnity_SimpleNoise_float(input.uv.rr, _NoiseLowFreq) * 2.0 - 1.0) * _NoiseLowAmp;
					float noise = noiseHigh + noiseLow;
				
					float blinnPhong2 = pow(blinnPhong0, _HighLightScale * 128.0 + 0.0001);
					
					float highLight0 = input.uv.y - viewDirWS.y * 0.5;
					
					float highLight1 = highLight0 - _HighLightOffset + noise;
					highLight1 = saturate((min(highLight1, 1.0 - highLight1) - 0.25) * 4.0);
					highLight1 = pow(highLight1, _HighLightRange);
					
					float highLight2 = 0;
					#if _ENABLEDOUBLEANISOTROPIC_ON
						highLight2 = highLight0 - _SecondHighLightOffset + noise;
						highLight2 = saturate((min(highLight2, 1.0 - highLight2) - 0.25) * 4.0);
						highLight2 = pow(highLight2, _HighLightRange);
					#endif
					
					float highLightBlend = (highLight1 + highLight2) * blinnPhong2;
					highLightColor = highLightBlend * _HighLightColor.rgb * _HighLightColor.a;
				#endif
				
				// Specular
				float3 specularColor = blinnPhong1 * _SpeculerInt;

				// BaseColor & Gradient
				float3 rampColor = float3(1.0, 1.0, 1.0);
				#if _ENABLEGRADIENT_ON
					float3 topColor =  lerp(1.0, _TopColor.rgb, _TopColor.a * _GradientInt);
					float3 downColor =  lerp(1.0, _DownColor.rgb, _DownColor.a * _GradientInt);
					rampColor = lerp(downColor, topColor, input.uv.y);
				#endif
				
				float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uvTex);
				float3 baseColor =  var_BaseMap.rgb * _BaseColor.rgb * rampColor;

				 // Rim
                half3 rimLight = _RimColor.a * _RimColor.rgb * fresnel;

				// Environment Diffuse
				float3 Ambient = SampleSH(input.normalWS);

				// Blend
				baseColor = Unity_Hue_Radians_float(baseColor, _Hue);
				highLightColor = Unity_Hue_Radians_float(highLightColor, _Hue);
				rimLight = Unity_Hue_Radians_float(rimLight, _Hue);
				half3 color = (baseColor + specularColor) * lambert * mainlightColor * mainlightShadow
							+ highLightColor * mainlightColor * halfLambert
							+ rimLight
							+ Ambient * baseColor;
                half alpha = var_BaseMap.a * _BaseColor.a;
				
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