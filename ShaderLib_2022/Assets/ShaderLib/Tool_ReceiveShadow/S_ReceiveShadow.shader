Shader "URP/Tool/S_ReceiveShadow" 
{
    Properties 
    {
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        
        [Toggle] _ALPHATEST ("AlphaCut", Int) = 1
        _Cutoff  ("Cutoff",  Range(0.0, 1.0)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2
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
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
		half4 _BaseColor;
        float _Cutoff;
        CBUFFER_END
        ENDHLSL

        Pass 
        {
            Name "Unlit"

            // -------------------------------------
            // Render State Commands
            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _SHADOWS_SOFT

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // -------------------------------------
            // Includes

			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS   : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS :TEXCOORD1;
                float fogFactor : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = positionInputs.positionWS;
                output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                output.positionCS = TransformWorldToHClip(positionInputs.positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

			    // Light
			    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
			    Light mainLight = GetMainLight(shadowCoord);
			    float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;


                half3 color = _BaseColor.rgb;
                half alpha = 1 - saturate(lightShadow);
			    #ifdef _ALPHATEST_ON
                    clip(alpha - _Cutoff);
                #endif
			    
                color.rgb = MixFog(color.rgb, input.fogFactor);

                return half4(color, alpha);
            } 
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}