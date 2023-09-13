Shader "URP/Car/S_CarFlowingLight"
{
    Properties 
    {
        [Foldout(1,1,0,1)] _foldout1 ("Base Layer_Foldout", Float) = 1
        [Tex(_BaseColor)] [NoScaleOffset] _BaseMap ("Base Map", 2D) = "white" {}
        [HideInInspector] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        [Tex(_Metallic)] [NoScaleOffset] _MetallicMap ("Metallic Map", 2D) = "white" {}
        [Tex(_Smoothness)] [NoScaleOffset] _RoughnessMap ("Roughness Map", 2D) = "white" {}
        [HideInInspector] _Metallic ("Metallic", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness ("Smoothness", Range(0.0, 1.0)) = 1.0

        [Tex(_BumpScale)] [NoScaleOffset] _BumpMap ("Normal Map", 2D) = "Bump" {}
        [HideInInspector] _BumpScale ("Normal Scale", Float) = 1.0

        [Tex(_Occlusion)] [NoScaleOffset] _OcclusionMap ("Occlusion Map", 2D) = "white" {}   
        [HideInInspector] _Occlusion ("Occlusion", Range(0.0, 1.0)) = 1.0


        [Foldout(2,2,1,0)] _LightSwitch ("Light Switch_Foldout", Float) = 0
        [HDR] _LightColor ("Light Color", Color) = (0, 0, 0, 1)
        _FlowSpeed ("Flow Speed", Float) = 1.0
        

        [Foldout(1,1,0,0)] _foldout3 ("Other Layer_Foldout", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2

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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" } 

            ZWrite On
            ZTest LEqual
            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #define _SPECULAR_SETUP

            #include "SIH_CarFlowingLightInput.hlsl"
            #include "SIH_CarFlowingLightForwardPass.hlsl"
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "Scarecrow.SimpleShaderGUI"
}