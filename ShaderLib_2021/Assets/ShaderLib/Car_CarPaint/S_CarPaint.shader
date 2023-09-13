Shader "URP/Car/S_CarPaint"
{
    Properties 
    {
        [Foldout(1,1,0,1)] _foldoutBase ("Base Layer_Foldout", Float) = 1
        _PigmentColor ("Pigment Color", Color) = (1, 1, 1, 1)
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        [Tex] [NoScaleOffset] _BaseMap ("Base Map", 2D) = "white" {}
        [PowerSlider(4.0)] _EdgeFactor ("Edge Falloff Factor", Range(0.01, 10.0)) = 0.3

        [HideInInspector] _SpecularColor ("Specular Color", Color) = (0, 0, 0, 1)
        [Tex(_SpecularColor)] [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "white" {}
        _FacingSpecular ("Facing Specular", Range(0.01, 2.0)) = 0.1
        _PerpendicularSpecular ("Perpendicular Specular", Range(0.0, 1.0)) = 0.3
        [PowerSlider(4.0)] _SpecularFactor ("Specular Falloff Factor", Range(0.01, 10.0)) = 0.3

        [HideInInspector] _Smoothness ("Smoothness", Range(0.0, 1.0)) = 1.0
        [Tex(_Smoothness)] [NoScaleOffset] _GlossinessMap ("Glossiness Map", 2D) = "white" {}
        [HideInInspector] _BumpScale ("Normal Scale", Float) = 1.0
        [Tex(_BumpScale)] [NoScaleOffset] _BumpMap ("Normal Map", 2D) = "Bump" {}
        [HideInInspector] _Occlusion ("Occlusion", Range(0.0, 1.0)) = 1.0
        [Tex(_Occlusion)] [NoScaleOffset] _OcclusionMap ("Occlusion Map", 2D) = "white" {}        
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)
        [Tex] [NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}

        [Foldout(1,1,0,1)] _foldoutClearCoat ("Clear Coat Layer_Foldout", Float) = 1
        _ClearCoatColor ("Clear Coat Color", Color) = (0.5, 0.5, 0.5)
        _ReflectionContrast ("Reflection Contrast", Range(0.01, 2.0)) = 1.0
        _FacingReflection ("Facing Reflection", Range(0.0, 1.0)) = 0.1
        _PerpendicularReflection ("Perpendicular Reflection", Range(0.0, 1.0)) = 1.0
        [PowerSlider(4.0)] _ReflectionFactor ("Reflection Falloff Factor", Range(0.01, 10.0)) = 1.0

        [Foldout(1,1,0,1)] _foldoutFlake ("Flake Layer_Foldout", Float) = 1
        [Tex(_FlakeDensity)] [NoScaleOffset] _FlakeMap ("Flake Map And Scale", 2D) = "white" {}
        [HideInInspector] _FlakeDensity ("Flake Density", Float) = 1.0
        [PowerSlider(4.0)] _FlakeReflection ("Flake Reflection", Range(0.0, 10.0)) = 0.0
        _FlakeFactor ("Flake Falloff Factor", Range(0.01, 1.0)) = 0.1

        [Foldout(1,1,0,0)] _foldoutOther ("Other Layer_Foldout", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            //"IgnoreProjector" = "True"
            //"PreviewType" = "Plane"
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

            #include "SIH_CarPaintInput.hlsl"
            #include "SIH_CarPaintForwardPass.hlsl"
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "Scarecrow.SimpleShaderGUI"
}
