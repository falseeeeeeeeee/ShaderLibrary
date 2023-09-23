Shader "URP/Base/GrassGS"
{
    Properties 
    {
        // ----------------------------------------------------------------------
        // Diffuse & Specular & Normal
        // ----------------------------------------------------------------------
        [Foldout(1,1,0,1)] _foldout_Ground ("Ground_Foldout", Float) = 1
        [Foldout(2,2,0,1)] _foldout_Diffuse ("Diffuse_Foldout", Float) = 1
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}

        [Foldout(2,2,0,1)] _foldout_Specular ("Specular_Foldout", Float) = 1
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        [PowerSlider(2)] _SpecularRange ("Specular Range", Range(0,1)) = 0.1

        [Foldout(2,2,1,1)] _NORMALMAP ("Normal_Foldout", Float) = 1
        [NoScaleOffset] _NormalMap("Normal Map",2D) = "bump" {}
        _NormalScale("Normal Scale" ,Float) = 1.0


        // ----------------------------------------------------------------------
        // Displacement & Tessellation
        // ----------------------------------------------------------------------
        [Foldout(2,2,1,1)] _DISPLACEMENT ("Displacement_Foldout", Float) = 1
        [NoScaleOffset] _DisplacementMap ("Displacement Map", 2D) = "white" {}
        _DisplacementStrength ("Displacement Strength", Float) = 1.0
        _DisplacementOffset ("Displacement Offset", Float) = 0.5

        _WaveStrength ("Wave Strength", Range(0.0, 1.0)) = 0.5
        _WaveMask ("Wave Mask", Range(0.0, 1.0)) = 0.5
        _WaveFrequency ("Wave Frequency", Float) = 1
        _WaveSpeed ("Wave Speed", Float) = 1

		[IntRange] _Tess ("Tessellation", Range(1.0, 64.0)) = 1.0
        [Foldout(3,2,1,0)] _TESSVIEW ("Tessellation View_Foldout", Float) = 0
        _MinTessDistance ("Min Tess Distance", Range(1.0, 32)) = 1.0
        _MaxTessDistance ("Max Tess Distance", Range(1.0, 32)) = 16.0



        // ----------------------------------------------------------------------
        // Grass
        // ----------------------------------------------------------------------
        [Foldout(1,1,0,1)] _foldout_Grass("Grass_Foldout", Float) = 1
        [Foldout(2,2,0,1)] _foldout_GrassStyle("GrassStyle_Foldout", Float) = 1
        _TopColor ("Top Color", Color) = (0.2, 0.8, 0.5, 1.0)
		_BottomColor ("Bottom Color", Color) = (0.5, 0.9, 0.6, 1.0)
		_Width ("Width", Float) = 0.1
		_Height ("Height", Float) = 0.8

        [Foldout(2,2,0,1)] _foldout_GrassSeed("GrassSeed_Foldout", Float) = 1
        _RandomWidth ("Random Width", Float) = 0.1
		_RandomHeight ("Random Height", Float) = 0.1
		_WindStrength("Wind Strength", Float) = 0.1
		_WindSpeed("Wind Speed", Float) = 0.1
        [Foldout(3,2,1,0)] _DISTANCEDETAIL ("Camera Distance_Foldout", Float) = 0
		_DistanceStrength("Distance Strength", Float) = 0.005
		_DistanceOffset("Distance Offset", Float) = 0.1


        // ----------------------------------------------------------------------
        // Other
        // ----------------------------------------------------------------------
        [Foldout(1,1,0,0)] _foldout_Other ("Other_Foldout", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
        }

        // ----------------------------------------------------------------------
        // Forward Pass
        // ----------------------------------------------------------------------
        Pass {
            Name "FORWARD"
            Tags             { 
                "LightMode"="UniversalForward" 
                "RenderType" = "Opaque"
                "Queue" = "Geometry"
            }
            
            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x gles
            #pragma target 4.6

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _DISPLACEMENT
            #pragma shader_feature _TESSVIEW_ON
            #pragma shader_feature _DISTANCEDETAIL_ON
            //#pragma shader_feature_local _ DISTANCE_DETAIL
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #pragma multi_compile_instancing
            
            #pragma require geometry
            #pragma geometry geom
            
            #pragma require tessellation
            #pragma hull hull
			#pragma domain domain
            
            #pragma vertex vert
            #pragma fragment frag

            #define SHADERPASS_FORWARD
			#define BLADE_SEGMENTS 3

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "SIH_GrassGSGeometry.hlsl"
            #include "SIH_GrassGSTessellation.hlsl"

            // ----------------------------------------------------------------------
            // 片段着色器
            // ----------------------------------------------------------------------
            float4 frag (GeometryOutput input, bool isFrontFace : SV_IsFrontFace) : SV_Target 
            {
				input.normalWS = isFrontFace ? input.normalWS : -input.normalWS;

                //Light
				#if SHADOWS_SCREEN
					float4 clipPos = TransformWorldToHClip(input.positionWS);
					float4 shadowCoord = ComputeScreenPos(clipPos);
				#else
					float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
				#endif

				float3 ambient = SampleSH(input.normalWS);
				Light mainLight = GetMainLight(shadowCoord);

                //LightMode
				float lambert = saturate(saturate(dot(input.normalWS, mainLight.direction)));
                float3 rDir = reflect(-mainLight.direction, input.normalWS);
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float phong = pow(saturate(dot(vDir, rDir)), _SpecularRange * 128.0 + 0.00001);

                //Final
                float3 color = lambert * mainLight.shadowAttenuation * mainLight.color;
                float3 specular = phong * _SpecularColor.rgb * _SpecularColor.a * mainLight.shadowAttenuation;
				float up = saturate(dot(float3(0,1,0), mainLight.direction) + 0.5);

				float3 shading = color * up + specular + ambient;
				
				return lerp(_BottomColor, _TopColor, input.uv.y) * float4(shading, 1) * _BaseColor;
			}
            ENDHLSL
        }

        // ----------------------------------------------------------------------
        // ----------------------------------------------------------------------
        // Shadow Pass
        Pass 
        {
			Name "ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x gles
			#pragma target 4.5

			#pragma vertex vert
			#pragma fragment emptyFrag

			#pragma require geometry
			#pragma geometry geom

			#pragma require tessellation
			#pragma hull hull
			#pragma domain domain

			#define BLADE_SEGMENTS 3
			#define SHADERPASS_SHADOWCASTER

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _DISPLACEMENT
            #pragma shader_feature _DISTANCEDETAIL_ON
            //#pragma shader_feature_local _ DISTANCE_DETAIL

            #pragma multi_compile_fog

            #pragma multi_compile_instancing

			//#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#include "SIH_GrassGSGeometry.hlsl"
            #include "SIH_GrassGSTessellation.hlsl"

			half4 emptyFrag(GeometryOutput input) : SV_TARGET
            {
				return 0;
			}

			ENDHLSL
		}
    }
    CustomEditor "Scarecrow.SimpleShaderGUI"
}
