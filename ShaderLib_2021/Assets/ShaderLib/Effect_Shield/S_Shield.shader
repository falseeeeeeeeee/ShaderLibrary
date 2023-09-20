Shader "URP/Effect/S_Shield" 
{
    Properties 
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}

        [HDR] _FresnelColor ("Fresnel Color", Color) = (1, 1, 1, 1)
        _FresnelPower ("Fresnel Power", Float) = 1

        [HDR] _DepthEdgeColor ("DepthEdge Color", Color) = (1, 1, 1, 1)
        _DepthOffset ("Depth Offset", Float) = 1

        [HDR] _ScanLineColor ("ScanLine Color", Color) = (1, 1, 1, 1)
        _ScanLineSpeed ("ScanLine Speed", Float) = 1

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" } 

            Cull [_CullMode]
            Blend SrcAlpha OneMinusSrcAlpha
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _BaseColor;
			uniform float4 _BaseMap_ST;
			uniform half4 _FresnelColor;
			uniform half4 _DepthEdgeColor;
			uniform half4 _ScanLineColor;
            uniform half _FresnelPower;
			uniform half _DepthOffset;
			uniform half _ScanLineSpeed;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
            SAMPLER(_CameraDepthTexture);
			
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
                float4 positionSS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS.xyz));
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                //屏幕空间顶点坐标，xy保存为未透除的屏幕UV，ZW不变
                output.positionSS.xy = output.positionHCS.xy * 0.5 + float2(output.positionHCS.w, output.positionHCS.w) * 0.5;
                output.positionSS.zw = output.positionHCS.zw;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //BaseMap
                float2 uv = input.uv;
                       //uv.x += _Time.y * 0.1;
                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;

                //计算屏幕UV
                //透除得到正常的屏幕uv，也可以通过input.positionHCS.xy/_ScreenParams.xy来得到屏幕uv
                input.positionSS.xy /= input.positionSS.w; 
                //判断当前的平台是OpenGL还是DirectX
                #ifdef UNITY_UV_STARTS_AT_TOP
                input.positionSS.y = 1.0 - input.positionSS.y;
                #endif

                //计算缓冲区深度
                float4 depthColor = tex2D(_CameraDepthTexture, input.positionSS.xy);
                float depthBuffer = LinearEyeDepth(depthColor.r, _ZBufferParams);  //得到线性的深度缓冲

                //计算模型深度
                float depth = input.positionHCS.z;
                      depth = LinearEyeDepth(depth, _ZBufferParams);   //得到模型的线性深度
                float4 edge = saturate(1 - (depthBuffer - depth) * _DepthOffset) * _DepthEdgeColor;    //计算接触光
                
                //fresnel
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);
                float4 fresnel = pow(saturate(1.0 - dot(viewDirWS, input.normalWS)), _FresnelPower) * _FresnelColor;

                //计算扫光
                float flow = saturate(pow(1 - abs(frac(input.positionWS.y * 0.5 - _Time.y * _ScanLineSpeed) - 0.5), 10));
                float4 flowColor = flow * _ScanLineColor;

                //color
                half3 color = lerp(var_BaseMap.rgb, fresnel.rgb + edge.rgb, fresnel.a + edge.a) + flowColor.rgb;
                half alpha = saturate(var_BaseMap.a * fresnel.a + edge.a);

                return half4(color,alpha);
                //return fresnel + edge;
            } 
            ENDHLSL
        }

    }
}
