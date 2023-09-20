Shader "URP/Tool/S_BlendModeUnity"
{
    Properties
    {
        //[Header(Color)][Space(10)]
        [HDR] _BaseColor("BaseColor", Color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        //[Header(Option)][Space(20)]
        [KeywordEnum(Opacity, AlphaCut, AlphaBlend, Additive, Multiply)] _Rending ("RenderMode", float) = 0
        _Cutoff ("Cutoff", Range(0, 1)) = 0.5

        [Enum(UnityEngine.Rendering.BlendOp)]  _BlendOp  ("BlendOp", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWriteMode ("ZWriteMode", float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestMode ("ZTestMode", Float) = 4

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            //"RenderType" = "Transparent" 
            //"Queue" = "Transparent"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } 

            BlendOp [_BlendOp]
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWriteMode]
            ZTest [_ZTestMode]
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma multi_compile __ _RENDING_OPACITY _RENDING_ALPHACUT _RENDING_ALPHABLEND _RENDING_ADDITIVE _RENDING_MULTIPLY


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            uniform float4 _BaseColor;
            uniform float4 _BaseMap_ST;
            uniform float _Cutoff;
            uniform float _Rending;
            CBUFFER_END

            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);

            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS   : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv0 = TRANSFORM_TEX(input.uv, _BaseMap);
                output.vertexColor = input.vertexColor;
                return output;
            }


            half4 frag(Varyings input) : SV_Target
            {
                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);
                
                half3 Color = var_BaseMap.rgb * _BaseColor.rgb * input.vertexColor.rgb;
                half Alpha = var_BaseMap.a * _BaseColor.a * input.vertexColor.a;

                //äÖÈ¾Ä£Ê½
                half4 finalRGBA;
                #if _RENDING_OPACITY 
                finalRGBA = half4(Color, 1);
                #elif _RENDING_ALPHACUT
                finalRGBA = half4(Color, Alpha);
                clip(Alpha - _Cutoff);
                #elif _RENDING_ALPHABLEND | _RENDING_ADDITIVE | _RENDING_MULTIPLY
                finalRGBA = half4(Color, Alpha);
                #endif

                return finalRGBA;
            }
            ENDHLSL
        }
    }
    CustomEditor "BlendModeUnityGUI"
}
    