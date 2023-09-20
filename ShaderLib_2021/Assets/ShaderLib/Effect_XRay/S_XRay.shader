Shader "URP/Effect/S_XRay"
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

        [Foldout(1,1,0,0)] _foldout_XRay ("XRay_Foldout", Float) = 1
        [Enum_Switch(Color,XRay)] _XRayStyle ("XRay Sytle", Float) = 0
        [Switch(Color,XRay)] _XRayColor ("XRay Color", Color) = (0, 1, 1, 1) 
        [Switch(XRay)] _XRayPower ("XRay Power", Range(0.0, 8.0)) = 0.5

        [Foldout(1,1,0,0)] _foldout_Other ("其它_Foldout", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
		uniform half4 _BaseColor;
		uniform float4 _BaseMap_ST;
        uniform half4 _ShadowColor;
        uniform half _ShadowOffset;
        uniform half _ShadowNum;
        uniform half4 _XRayColor;
		uniform half _XRayPower;
        CBUFFER_END
		
		TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
		TEXTURE2D(_RampMap);	SAMPLER(sampler_RampMap);

        ENDHLSL

        Pass 
        {
            Name "Forward"
            Tags 
            { 
                "LightMode"="UniversalForward"             
                "RenderType" = "Opaque"
                "Queue" = "Geometry"
            } 

            ZTest LEqual
            ZWrite On
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

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            
			
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

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //Light
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = normalize(mainLight.direction);
                float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 Ambient = SampleSH(input.normalWS);

                //Ramp
                half NdotL = dot(input.normalWS, lightDir) * 0.5 + 0.5;
                half3 rampColor;
                #if _RAMPSYTLE_DOUBLE 
                rampColor = step(_ShadowOffset, NdotL).rrr;
                #elif _RAMPSYTLE_CUSTOMNUM
                rampColor = (floor(NdotL * _ShadowNum) / _ShadowNum).rrr;
                #elif _RAMPSYTLE_RAMPMAP
                rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(NdotL, 1.0)).rgb;
                #endif
                half3 shadowColor = lerp(_ShadowColor.rgb, half3(1.0, 1.0, 1.0), rampColor);

                //Color
                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);                         
                half3 color =  var_BaseMap.rgb * _BaseColor.rgb * shadowColor;
                half alpha = 1;
                
                //return half4((lightShadow + Ambient) * color, alpha);
                return half4(color, alpha);
            } 
            ENDHLSL
        }
        
        // Shadow
        Pass
        {
        	Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
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
            Name "XRay"
            Tags 
            { 
                "LightMode"="SRPDefaultUnlit" 
                "RenderType" ="Transparent" 
                "Queue" = "Transparent" 
            } 

            Blend SrcAlpha OneMinusSrcAlpha 
            ZTest Greater
            ZWrite Off
            Cull Back
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma shader_feature _XRAYSTYLE_COLOR _XRAYSTYLE_XRAY

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(input.positionOS.xyz));
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);

                return output;
            }
            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                half3 color;
                half alpha;

                #if _XRAYSTYLE_COLOR                    
                    color = _XRayColor.rgb;
                    alpha = _XRayColor.a;
                #elif _XRAYSTYLE_XRAY
                    half4 fresnel = pow(saturate(1.0 - dot(input.viewDirWS, input.normalWS)), _XRayPower) * _XRayColor;
                    color = fresnel.rgb;
                    alpha = fresnel.a;
                #endif

                return half4(color, alpha);
            } 
            ENDHLSL
        }
    }
    CustomEditor "Scarecrow.SimpleShaderGUI"
}