Shader "URP/PPS/InkStyleShader"
{
    Properties 
    {
        // 基础纹理
        _MainTex ("Base (RGB)", 2D) = "white" { }
        _NoiseScale ("NoiseScale", Float) = 100        
        _NoiseStrength ("NoiseStrength", Float) = 0
    }
    SubShader 
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half _NoiseScale;
        half _NoiseStrength;
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


            float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float Unity_SimpleNoise_float(float2 UV, float Scale)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                return t;
            }
			
            half4 frag(Varyings input) : SV_Target
			{
			    input.uv += (Unity_SimpleNoise_float(input.uv, _NoiseScale) * 2 - 1) * (_NoiseStrength / 10);

                half4 renderTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                half3 finalColor = renderTex.rgb;

                return half4(finalColor, renderTex.a);
            } 
            ENDHLSL
        }
    }
}
