Shader "URP/Render/S_Ink2"
{
    Properties 
    {
        //[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
    	
        [Header(Color)] [Space(6)]
		_Color ("Tint Color 1", Color) = (1,1,1,1)
		_Color2 ("Tint Color 2", Color) = (1,1,1,1)
		_InkCol ("Ink Color", Color) = (1,1,1,1)
    	
    	[Header(Texture)] [Space(6)]
		_NoiseTex ("Noise (RGB)", 2D) = "white" {}
		_BlotchTex ("Blotches (RGB)", 2D) = "white" {}
		_DetailTex ("Detail (RGB)", 2D) = "white" {}
		_PaperTex ("Paper (RGB)", 2D) = "white" {}
		_RampTex ("Ramp (RGB)", 2D) = "white" {}
		
    	[Header(Param)] [Space(6)]
		_TintScale ("Tint Scale", Range(2,32)) = 4
		_PaperStrength ("Paper Strength", Range(0,1)) = 1
		_BlotchMulti ("Blotch Multiply", Range(0,8)) = 3
		_BlotchSub ("Blotch Subtract", Range(0,1)) = 0.5
		_BlurDist ("Blur Distance", Range(0,8)) = 1
    	
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
    	
		HLSLINCLUDE
	    #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x	
        #pragma target 2.0
		
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        
        uniform half4 _Color;
        uniform half4 _Color2;
        uniform half4 _InkCol;
        
        //uniform float4 _NoiseTex_ST;
        uniform float4 _BlotchTex_ST;
		uniform float4 _DetailTex_ST;
		uniform float4 _PaperTex_ST;
		//uniform float4 _RampTex_ST;
		
		uniform half _Glossiness;
		uniform half _Metallic;
		uniform half _BlotchMulti;
		uniform half _BlotchSub;
		uniform half _TintScale;
		uniform half _PaperStrength;

		//uniform matrix _WorldToMainLightMatrix;
		uniform float4x4 _WorldToMainLightMatrix;


        CBUFFER_END
		
		TEXTURE2D(_NoiseTex);     SAMPLER(sampler_NoiseTex);
		TEXTURE2D(_BlotchTex);    SAMPLER(sampler_BlotchTex);
		TEXTURE2D(_DetailTex);    SAMPLER(sampler_DetailTex);
		TEXTURE2D(_PaperTex);     SAMPLER(sampler_PaperTex);
		TEXTURE2D(_RampTex);      SAMPLER(sampler_RampTex);

        ENDHLSL
    	
        Pass {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } 

            Cull Back
            
			HLSLPROGRAM
    		#pragma multi_compile __ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile __ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile __ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile __ _SHADOWS_SOFT

			#pragma multi_compile_fog
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
			{
                float4 positionOS : POSITION;
    			float3 normalOS : NORMAL;
            	float2 texcoord : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
            	float3 positionWS : TEXCOORD1;
            	float3 normalDirWS : TEXCOORD2;
                float2 uv0 : TEXCOORD3;
                float4 uv_NoiseTex : TEXCOORD4;
                float2 uv_BlotchTex : TEXCOORD5;
                float2 uv_DetailTex : TEXCOORD6;
                float2 uv_PaperTex : TEXCOORD7;
            	float fogFactor: TEXCOORD8; 
            	
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
				output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    			output.normalDirWS = TransformObjectToWorldNormal(input.normalOS);
            	output.fogFactor = ComputeFogFactor(input.positionOS.z);
            	
                output.uv0 = input.texcoord;
                output.uv_NoiseTex.xy = output.positionWS.xz * 0.2;
                output.uv_NoiseTex.zw = output.positionWS.xz * 1.0;
                output.uv_BlotchTex = TRANSFORM_TEX(input.texcoord, _BlotchTex);
                output.uv_DetailTex = TRANSFORM_TEX(input.texcoord, _DetailTex);
                output.uv_PaperTex = TRANSFORM_TEX(input.texcoord, _PaperTex);
                return output;
            }

			float4 screen (float4 colA, float4 colB)
			{
				float4 white = (1,1,1,1);
				return white - (white-colA) * (white-colB);
			}
			
			float4 softlight (float4 colA, float4 colB)
			{
				float4 white = (1,1,1,1);
				return (white-2*colB)*pow(colA, 2) + 2*colB*colA;
			}
			
            half4 frag(Varyings input) : SV_Target
			{
				//Vector
				float3 normalDirWS = normalize(input.normalDirWS);

				//LightNoise
				float var_NoiseTex1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv_NoiseTex.xy).r;
				float var_NoiseTex2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv_NoiseTex.zw).r * 0.5;
				float var_NoiseTex = (var_NoiseTex1 + var_NoiseTex2) * 0.3;
				float3 var_NoisePos = float3(var_NoiseTex - 0.2, 0, var_NoiseTex);
				//input.positionWS.xyz = input.positionWS.xyz - mul(_WorldToMainLightMatrix ,var_NoisePos);
				input.positionWS.xyz = input.positionWS.xyz - var_NoisePos;
				
            	//MainLight
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
            	float3 mainLightColor = mainLight.color;
                float3 mainLightDir = normalize(mainLight.direction);
                float mainLightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                //float3 ambient = SampleSH(normalDirWS);

            	//AddLight
				float3 addLambertColor = float3(0,0,0);
            	int addLightCounts = GetAdditionalLightsCount();
				for(int a = 0; a < addLightCounts; a++)
				{
				    Light addLight = GetAdditionalLight(a, input.positionWS.xyz,half4(1,1,1,1));
					
					float3 addLightColor = addLight.color;
					float3 addLightDir = normalize(addLight.direction);
					float addLightShadow = addLight.distanceAttenuation * addLight.shadowAttenuation;
				    addLambertColor += saturate(dot(normalDirWS, addLightDir)) * addLightColor * addLightShadow;
				    //lightShadow += addLightShadow;
				}

            	//LightMode
            	half3 lambertColor = saturate(dot(normalDirWS, mainLightDir)) * mainLightColor * mainLightShadow + addLambertColor;
    
                //Ink
				float var_DetailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, input.uv_DetailTex).r;
				float var_BlotchTex = SAMPLE_TEXTURE2D(_BlotchTex, sampler_BlotchTex, input.uv_BlotchTex).r;
                float var_TintTex = SAMPLE_TEXTURE2D(_BlotchTex, sampler_BlotchTex, input.uv_BlotchTex / _TintScale);
				float4 var_PaperTex = SAMPLE_TEXTURE2D (_PaperTex, sampler_PaperTex, input.uv_PaperTex);

                float inkShadow = (1.0 - lambertColor - _BlotchSub) * _BlotchMulti;
				float inkNoise = (var_DetailTex + var_BlotchTex) * 0.5 + inkShadow;
				
				float var_RampTex = saturate(SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, half2(inkNoise, 0)).r);
				
				float4 inkColor = screen(_InkCol, float4(var_RampTex.rrr, 1));
				float4 tintColor = lerp(_Color, _Color2, var_TintTex.r);
				float4 color = inkColor * tintColor;
				color = lerp(color, softlight(var_PaperTex, color), _PaperStrength);

				//Fog
				color.rgb = MixFog(color.rgb, ComputeFogFactor(input.positionHCS.z * input.positionHCS.w));
            	
				return color;
				//return half4(lambertColor,1);
            } 
            ENDHLSL
        }
    	
    	///ShadowPass
    	Pass
        {
        	Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
        	Cull Off             
			ZWrite On             
			ZTest LEqual 
        	
            HLSLPROGRAM
            #pragma multi_compile_instancing
            
            #pragma vertex ShadowPassVert
            #pragma fragment ShadowPassFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
        	
    			UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
            };

            float3 _LightDirection;

            Varyings ShadowPassVert (Attributes input)
            {
                Varyings output;

            	UNITY_SETUP_INSTANCE_ID(input);
            	
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalDirWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalDirWS, _LightDirection));

				#if UNITY_REVERSED_Z
				    output.positionHCS.z = min(output.positionHCS.z, output.positionHCS.w * UNITY_NEAR_CLIP_VALUE);
				#else
				    output.positionHCS.z = max(output.positionHCS.z, output.positionHCS.w * UNITY_NEAR_CLIP_VALUE);
				#endif
            	
            	return output;
            }
            half4 ShadowPassFrag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    	UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}
