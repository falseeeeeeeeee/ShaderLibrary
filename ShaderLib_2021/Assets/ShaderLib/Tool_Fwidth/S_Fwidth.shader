Shader "URP/Tool/S_Fwidth"
{
    Properties 
    {
        [MainColor] _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap ("BaseMap", 2D) = "white" {}
        [PowerSlider(2)] _EdgeRelief ("Edge Relief", Range(0.0, 10.0)) = 0.0
        [PowerSlider(2)] _EdgeLightening ("Edge Lightening", Range(0.0, 10.0)) = 0.0


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
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 

            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _BaseColor;
			uniform float4 _BaseMap_ST;
            uniform half _EdgeRelief;
            uniform half _EdgeLightening;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			
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

                //normal light halflambert
                half3 normalWS = normalize(cross(ddy(input.positionWS), ddx(input.positionWS)));
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                half NdotL = dot(normalWS, lightDir) * 0.5 + 0.5;

                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);                         
                half3 color = var_BaseMap.rgb * _BaseColor.rgb * NdotL;
                color = saturate(color + (ddx(color) + ddx(color)) * _EdgeRelief);
                color = saturate(color + (abs(ddx(color)) + abs(ddx(color))) * _EdgeLightening);
                


                half alpha = var_BaseMap.a * _BaseColor.a;
                
                return half4(color, alpha);
            } 
            ENDHLSL
        }
    }
}
