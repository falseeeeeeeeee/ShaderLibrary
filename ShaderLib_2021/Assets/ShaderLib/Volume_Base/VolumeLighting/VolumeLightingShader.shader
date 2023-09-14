Shader "URP/PPS/VolumeLightingShader"

{
    Properties 
    {
        // 基础纹理
        _MainTex ("Base (RGB)", 2D) = "white" { }
        _MaxStep ("_MaxStep", Float) = 200
        _MaxDistance ("_MaxDistance", Float) = 1000
        _LightIntensity ("_LightIntensity", Float) = 0.01
        _StepSize ("_StepSize", Float) = 0.1
    }
    SubShader 
    {
        Tags { "RenderType" = "Opaque"  "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float _MaxDistance;
        float _MaxStep;
        float _StepSize;
        float _LightIntensity;
        half4 _LightColor0;
        CBUFFER_END

		TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
        TEXTURE2D_X_FLOAT(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);

        ENDHLSL

        Pass {
        	Tags { "LightMode" = "UniversalForward" }

			// 开启深度测试 关闭剔除 关闭深度写入
			ZTest Always Cull Off ZWrite Off
        	
			HLSLPROGRAM
            // 接收阴影所需关键字
			#pragma shader_feature _AdditionalLights
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT
			
            #pragma vertex vert
            #pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;

                float2 uv : TEXCOORD0;
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.texcoord;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
				float2 uv = input.uv;
				float depth = 1 - SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
				
				//获取像素的屏幕空间位置
				float3 positionSS = float3(uv, depth);
				float4 positionNS = float4(positionSS * 2.0 - 1.0, 1.0);
				//得到NDC空间下的像素位置
				float4 positionNDC = mul(unity_CameraInvProjection, positionNS);
					   positionNDC = float4(positionNDC.xyz / positionNDC.w, 1.0);
				//得到世界空间下的像素位置
				float4 PositionSence = mul(unity_CameraToWorld, positionNDC * float4(1, 1, -1, 1));
					   PositionSence = float4(PositionSence.xyz, 1.0);
				float3 positionWS = PositionSence.xyz;

				float3 ro = _WorldSpaceCameraPos.xyz;
				float3 rd = normalize(positionWS - ro);
				float3 currentPos = ro;
				float m_length = min(length(positionWS - ro), _MaxDistance);
				float delta = _StepSize;
                float totalInt = 0;
                float d = 0;
                for(int j = 0; j < _MaxStep; j++)
                {
                    d += delta;
                    if(d > m_length) break;
                    currentPos += delta * rd;
                    totalInt += _LightIntensity * MainLightRealtimeShadow(TransformWorldToShadowCoord(currentPos));
                }

				half3 lightColor = totalInt * _LightColor0;
                half3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb;

                return real4(baseColor + lightColor, 1);
            } 
            ENDHLSL
        }
    	
    	//UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    	
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}