Shader "URP/Toon/S_SimpleToon"
{
    Properties 
    {
        [Foldout(1,1,0,1)] _foldout_Diffuse ("基本颜色_Foldout", Float) = 1
        [HideInInspector] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [Tex(_BaseColor)] _BaseMap ("Base Map", 2D) = "white" {}

        [Foldout(1,1,0,1)] _foldout_ToonShadow ("卡通颜色_Foldout", Float) = 1
        [Enum_Switch(Double,CustomNum,RampMap)] _RampSytle ("Ramp Sytle", Float) = 0
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 0)
        [Switch(Double)] _ShadowOffset ("Shadow Offset", Range(0.0, 1.0)) = 0.5
        [Switch(CustomNum)] _ShadowNum ("Shadow Number", Range(3.0, 16.0)) = 3.0
        [Switch(RampMap)][NoScaleOffset] _RampMap ("Ramp Map", 2D) = "white" {}

        [Foldout(1,1,0,1)] _foldout_Outline ("屏幕描边_Foldout", Float) = 1
        [Toggle] _OUTLINEAUTOSIZE ("Outline Auto Size?", Float) = 0
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width", Range(0.0, 10.0)) = 0.5

        [Foldout(1,1,0,0)] _foldout_Other ("其它_Foldout", Float) = 1
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
        
        HLSLINCLUDE	
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
		uniform half4 _BaseColor;
		uniform float4 _BaseMap_ST;
        uniform half4 _ShadowColor;
        uniform half _ShadowOffset;
        uniform half _ShadowNum;
		uniform float4 _OutlineColor;
        uniform float _OutlineWidth;
        CBUFFER_END
        
        ENDHLSL

        Pass {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 

            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma shader_feature _RAMPSYTLE_DOUBLE _RAMPSYTLE_CUSTOMNUM _RAMPSYTLE_RAMPMAP

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

			#pragma multi_compile_fog
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			TEXTURE2D(_RampMap);	SAMPLER(sampler_RampMap);
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float fogFactor: TEXCOORD3; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.fogFactor = ComputeFogFactor(input.positionOS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //Light
				float3 normalDirWS = normalize(input.normalWS);
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = normalize(mainLight.direction);
                float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 Ambient = SampleSH(input.normalWS);

			    //AddLight
				float3 addLambertColor = float3(0,0,0);
				float addNdotL = 0;
            	int addLightCounts = GetAdditionalLightsCount();
				for(int a = 0; a < addLightCounts; a++)
				{
				    Light addLight = GetAdditionalLight(a, input.positionWS.xyz,half4(1,1,1,1));
					
					float3 addLightColor = addLight.color;
					float3 addLightDir = normalize(addLight.direction);
					float addLightShadow = addLight.distanceAttenuation * addLight.shadowAttenuation ;
				    //addLambertColor += saturate(dot(normalDirWS, addLightDir)) * addLightColor * addLightShadow;
					addNdotL += dot(normalDirWS, addLightDir) * 0.5 + 0.5;
				}

				//addNdotL = step(addNdotL, 0.5);
                //Ramp
                half NdotL = dot(normalDirWS, lightDir) * 0.5 + 0.5 + addNdotL;
                half3 rampColor;
                #if _RAMPSYTLE_DOUBLE 
                rampColor = step(_ShadowOffset, NdotL).rrr;
                #elif _RAMPSYTLE_CUSTOMNUM
                rampColor = (floor(NdotL * _ShadowNum) / _ShadowNum).rrr;
                #elif _RAMPSYTLE_RAMPMAP
                rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(saturate(dot(normalDirWS, lightDir)), 1.0)).rgb;
                #endif
                half3 shadowColor = lerp(_ShadowColor.rgb, half3(1.0, 1.0, 1.0), rampColor);

                //Color
                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);                         
                half3 color =  var_BaseMap.rgb * _BaseColor.rgb * shadowColor;
                half alpha = 1;

			    //Fog
                color.rgb = MixFog(color.rgb, ComputeFogFactor(input.positionHCS.z * input.positionHCS.w));

                //return half4((lightShadow + Ambient) * color, alpha);
                return half4(color, alpha);
            } 
            ENDHLSL
        }
        Pass
        {
        	Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
            };

            float3 _LightDirection;

            Varyings vert (Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                return output;
            }
            half4 frag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
        
        Pass
        {
        	Name "Outline"
            Tags{"LightMode" = "SRPDefaultUnlit"}

            Cull Front

            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma shader_feature _OUTLINEAUTOSIZE_ON

            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"


            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;                
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float4 scaledScreenParams = GetScaledScreenParams();
                float scaleX = abs(scaledScreenParams.x / scaledScreenParams.y);    //求得X因屏幕比例缩放的倍数

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 normalCS = TransformWorldToHClipDir(normalWS);

                float2 extendis = normalize(normalCS.xy) * (_OutlineWidth * 0.01);  //根据法线和线宽计算偏移量
                       extendis.x /= scaleX;   //修正屏幕比例x

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                #if _OUTLINEAUTOSIZE_ON
                    //屏幕下描边宽度会变
                    output.positionHCS.xy += extendis;
                #else
                    //屏幕下描边宽度不变，则需要顶点偏移的距离在NDC坐标下为固定值
                    //因为后续会转换成NDC坐标，会除w进行缩放，所以先乘一个w，那么该偏移的距离就不会在NDC下有变换
                    output.positionHCS.xy += extendis * output.positionHCS.w;
                #endif

                return output;
            }
            float4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return float4(_OutlineColor.rgb, 1);
            }
            ENDHLSL
        }

    }
    CustomEditor "Scarecrow.SimpleShaderGUI"
}
