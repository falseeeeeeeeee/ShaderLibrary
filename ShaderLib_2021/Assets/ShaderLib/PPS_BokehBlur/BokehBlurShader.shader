Shader "URP/PPS/BokehBlurShader"
{
    Properties 
    {
        // 基础纹理
        _MainTex ("Base (RGB)", 2D) = "white" { }
    }
    SubShader 
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        half4 _MainTex_TexelSize;
        float4 _DepthOfFieldTex_TexelSize;

        float _BlurSize; //模糊强度
        float _Iteration; //迭代次数
        float _DownSample; //降采样次数
        CBUFFER_END

		TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);

        ENDHLSL

        Pass {
            
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
                output.uv = input.texcoord;

                return output;
            }

            //散景模糊方法
            half4 BokehBlur(Varyings input)
            {
                //预计算旋转
                float c = cos(2.39996323f);
                float s = sin(2.39996323f);
                half4 _GoldenRot = half4(c, s, -s, c);

                half2x2 rot = half2x2(_GoldenRot);
                half4 accumulator = 0.0; //累加器
                half4 divisor = 0.0;     //因子

                half r = 1.0;
                half2 angle = half2(0.0, _BlurSize);

                for (int j = 0; j < _Iteration; j++)
                {
                    r += 1.0 / r; //每次 + r分之一 1.1
                    angle = mul(rot, angle);
                    half4 bokeh = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(input.uv + (r - 1.0) * angle));
                    accumulator += bokeh * bokeh;
                    divisor += bokeh;
                }
                return half4(accumulator / divisor);
            }
			
            half4 frag(Varyings input) : SV_Target
			{
                return BokehBlur(input);
            } 
            ENDHLSL
        }
    }
}
