Shader "URP/PPS/HueBrightnessSaturationContrastShader"
{
    Properties 
    {
        // 基础纹理
        _MainTex ("Base (RGB)", 2D) = "white" { }
        // 色相
        _Hue ("Hue", Float) = 1        
        // 亮度
        _Brightness ("Brightness", Float) = 1
        // 饱和度
        _Saturation ("Saturation", Float) = 1
        // 对比度
        _Contrast ("Contrast", Float) = 1
    }
    SubShader 
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half _Hue;
        half _Brightness;
        half _Saturation;
        half _Contrast;
        CBUFFER_END

		TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);

        ENDHLSL

        Pass {

            // 开启深度测试 关闭剔除 关闭深度写入
            ZTest Always Cull Off ZWrite Off
            
			HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);

                return output;
            }

            // Hue方法
			float3 HueDegrees(float3 In, float Offset)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 P = lerp(float4(In.bg, K.wz), float4(In.gb, K.xy), step(In.b, In.g));
                float4 Q = lerp(float4(P.xyw, In.r), float4(In.r, P.yzx), step(P.x, In.r));
                float D = Q.x - min(Q.w, Q.y);
                float E = 1e-10;
                float3 hsv = float3(abs(Q.z + (Q.w - Q.y)/(6.0 * D + E)), D / (Q.x + E), Q.x);

                float hue = hsv.x + Offset;
                hsv.x = (hue < 0)
                        ? hue + 1
                        : (hue > 1)
                            ? hue - 1
                            : hue;

                float4 K2 = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 P2 = abs(frac(hsv.xxx + K2.xyz) * 6.0 - K2.www);
                return hsv.z * lerp(K2.xxx, saturate(P2 - K2.xxx), hsv.y);
            }
			
            half4 frag(Varyings input) : SV_Target
			{
                half4 renderTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                // 调整亮度 = 原颜色 * 亮度值
                half3 finalColor = renderTex.rgb * _Brightness;
                
                // 调整饱和度
                // 亮度值（饱和度为0的颜色） = 每个颜色分量 * 特定系数
                half luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                half3 luminanceColor = half3(luminance, luminance, luminance);
                // 插值亮度值和原图
                finalColor = lerp(luminanceColor, finalColor, _Saturation);
                
                // 调整对比度
                // 对比度为0的颜色
                half3 avgColor = half3(0.5, 0.5, 0.5);
                finalColor = lerp(avgColor, finalColor, _Contrast);

			    // 调整色相
                finalColor = HueDegrees(finalColor, _Hue);

                return half4(finalColor, renderTex.a);
            } 
            ENDHLSL
        }
    }
}
