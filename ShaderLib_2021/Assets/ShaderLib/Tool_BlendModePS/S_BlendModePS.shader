Shader "URP/Tool/S_BlendModePS"
{
    Properties
    {
        [Header(Base is Dst Texture)]
        [Space(10)]
        [MainColor] _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("BaseMap", 2D) = "white" {}

        [Space(50)]
        [Header(Mix is Src Texture)]
        [Space(10)]
        _MixColor ("MixColor", Color) = (1, 1, 1, 1)
        _MixMap ("MixMap", 2D) = "white" { }

        
        [IntRange]_ModeID ("ModeID", Range(0, 26)) = 0
        [Toggle(_ENABLECAMERATEX_ON)] _EnableCameraTex ("EnableCameraTex", Float) = 0
        [HideInInspector][Toggle(_STYLECHOOSE_ON)] _StyleChoose("",float) = 0
        [HideInInspector] _IDChoose ("", Float) = 0
        [HideInInspector] _BlendCategoryChoose ("", Float) = 0
    }
    SubShader
    {
        
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
        }

        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } 

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #pragma shader_feature_local _ENABLECAMERATEX_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "SIH_PhotoShopBlendMode.hlsl"

            CBUFFER_START(UnityPerMaterial)
            uniform float4 _BaseColor, _MixColor;
            uniform float4 _BaseMap_ST;
            uniform float4 _MixMap_ST;
            uniform float _ModeID;
            CBUFFER_END

            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
            TEXTURE2D(_MixMap);         SAMPLER(sampler_MixMap);
            TEXTURE2D(_CameraOpaqueTexture);	    SAMPLER(sampler_CameraOpaqueTexture);


            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS   : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uvSS : TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                float4 positionSS = ComputeScreenPos(positionInput.positionCS);
                output.uvSS = positionSS.xy / positionSS.w;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                float4 Src = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, input.uv) * _MixColor;

                #ifdef _ENABLECAMERATEX_ON
                    float4 Dst = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.uvSS) * _BaseColor;
                #else
                    float4 Dst = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;  
                #endif

                return half4(saturate(OutPutMode(Src, Dst, _ModeID)), 1.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "BlendModeGrabGUI"
}