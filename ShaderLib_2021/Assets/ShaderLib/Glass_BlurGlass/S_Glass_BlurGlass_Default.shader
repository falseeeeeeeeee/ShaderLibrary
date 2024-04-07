Shader "Default/Glass/S_Glass_BlurGlass_Default"
{
    Properties
    {
        _GlassColor ("Glass Color", Color) = (1, 1, 1)
        _GlassTransparent ("Glass Transparent", Range(0, 1)) = 1
        _GlassBlurStrength ("Glass Blur Strength", Range(0, 4)) = 1
        _GlassThickness ("Glass Thickness", Range(-1, 1)) = 0
    }
    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent"               // 调整渲染顺序
            "RenderType"="Transparent"          // 对应改为Cutout
            "ForceNoShadowCasting"="True"       // 关闭阴影投射
            "IgnoreProjector"="True"            // 不响应投射器
        }
        
        // 抓屏，贴图名称随便填
        GrabPass 
        {
            "_BackgroundTex"
        }

        Pass
        {
            Name "Forward"
            Tags 
            {
                "LightMode"="ForwardBase"
            }
            
            Blend One OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 grabPosition : TEXCOORD1;
                float4 positionHCS : SV_POSITION;
            };

            float3 _GlassColor;
            half _GlassTransparent;
            half _GlassBlurStrength;
            half _GlassThickness;
            
            sampler2D _BackgroundTex;
            half4 _BackgroundTex_TexelSize;

            // 方法
            
            float3 SampleSceneColor(float2 uv)
            {
                return tex2D(_BackgroundTex, uv).rgb;
            }

            // 高斯模糊算法
            float3 GetBlurredScreenColor(in const float2 UVSS)
            {
                #define OFFSET_X(kernel) float2(_BackgroundTex_TexelSize.x * kernel * _GlassBlurStrength, 0)
                #define OFFSET_Y(kernel) float2(0, _BackgroundTex_TexelSize.y * kernel * _GlassBlurStrength)

                #define BLUR_PIXEL(weight, kernel) float3(0, 0, 0) \
                    + (SampleSceneColor(UVSS + OFFSET_Y(kernel)) * weight * 0.125) \
                    + (SampleSceneColor(UVSS - OFFSET_Y(kernel)) * weight * 0.125) \
                    + (SampleSceneColor(UVSS + OFFSET_X(kernel)) * weight * 0.125) \
                    + (SampleSceneColor(UVSS - OFFSET_X(kernel)) * weight * 0.125) \
                    + (SampleSceneColor(UVSS + ((OFFSET_X(kernel) + OFFSET_Y(kernel)))) * weight * 0.125) \
                    + (SampleSceneColor(UVSS + ((OFFSET_X(kernel) - OFFSET_Y(kernel)))) * weight * 0.125) \
                    + (SampleSceneColor(UVSS - ((OFFSET_X(kernel) + OFFSET_Y(kernel)))) * weight * 0.125) \
                    + (SampleSceneColor(UVSS - ((OFFSET_X(kernel) - OFFSET_Y(kernel)))) * weight * 0.125) \

                float3 Sum = 0;

                Sum += BLUR_PIXEL(0.02, 10.0);
                Sum += BLUR_PIXEL(0.02, 9.0);
                
                Sum += BLUR_PIXEL(0.06, 8.5);
                Sum += BLUR_PIXEL(0.06, 8.0);
                Sum += BLUR_PIXEL(0.06, 7.5);
                
                Sum += BLUR_PIXEL(0.05, 7);
                Sum += BLUR_PIXEL(0.05, 6.5);
                Sum += BLUR_PIXEL(0.05, 6);
                Sum += BLUR_PIXEL(0.05, 5.5);
                
                Sum += BLUR_PIXEL(0.065, 4.5);
                Sum += BLUR_PIXEL(0.065, 4);
                Sum += BLUR_PIXEL(0.065, 3.5);
                Sum += BLUR_PIXEL(0.065, 3);
                
                Sum += BLUR_PIXEL(0.28, 2);
                
                Sum += BLUR_PIXEL(0.04, 0);

                #undef BLUR_PIXEL
                #undef OFFSET_X
                #undef OFFSET_Y

                return Sum;
            }

            v2f vert (appdata input)
            {
                v2f output;
                
                output.positionHCS = UnityObjectToClipPos(input.positionOS);
                // output.grabPosition = ComputeGrabScreenPos(output.positionHCS);
                output.grabPosition = ComputeGrabScreenPos(UnityObjectToClipPos(input.positionOS - input.normalOS * _GlassThickness) * 0.5);
                return output;
            }

            half4 frag (v2f input) : SV_Target
            {
                half3 backgroundTex = GetBlurredScreenColor(input.grabPosition.xy / input.grabPosition.w);

                half3 color = backgroundTex.rgb * _GlassColor * _GlassTransparent;
                half alpha = _GlassTransparent;
                return half4(color, alpha);
            }
            ENDCG
        }
    }
}
