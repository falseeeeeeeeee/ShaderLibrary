Shader "URP/Water/S_WaterBoxMask"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        
        _Cutoff  ("Cutoff",  Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } 

            Cull Back
            ZWrite On
            

            Stencil 
            {
                Ref 5
                Comp always
                Pass replace
            }

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            uniform float4 _BaseColor;
            uniform float4 _BaseMap_ST;
            half _Cutoff;
            CBUFFER_END

            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
            TEXTURE2D(_CameraOpaqueTexture);	    SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);     SAMPLER(sampler_CameraDepthTexture);

            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS   : SV_POSITION;
                float4 positionSS : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.uv0 = TRANSFORM_TEX(input.uv, _BaseMap);
                output.positionSS = ComputeScreenPos(positionInput.positionCS);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }


            half4 frag(Varyings input) : SV_Target
            {
                float4 scenesColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.positionSS / input.positionSS.w);
                float4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0) * _BaseColor;

                clip(scenesColor.a - _Cutoff);
                return scenesColor;
            }
            ENDHLSL
        }
    }
}