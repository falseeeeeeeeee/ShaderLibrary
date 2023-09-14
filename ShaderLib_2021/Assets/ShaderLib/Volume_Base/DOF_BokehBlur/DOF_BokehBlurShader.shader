Shader "URP/PPS/DOF_BokehBlurShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        half4 _MainTex_TexelSize;
        half4 _DepthOfFieldTex_TexelSize;
        
        float _BlurSize; //模糊强度
        float _Iteration; //迭代次数
        float _DownSample; //降采样次数

        // Camera parameters
        float _Distance;
        float _LensCoeff; // f^2 / (N * (S1 - f) * film_width * 2)
        float _MaxCoC;
        float _RcpMaxCoC;
        float _RcpAspect;
        half3 _TaaParams; // Jitter.x, Jitter.y, Blending
        CBUFFER_END

        TEXTURE2D(_MainTex);                                SAMPLER(sampler_MainTex);
        TEXTURE2D_X_FLOAT(_CameraDepthTexture);             SAMPLER(sampler_CoCTex);
        TEXTURE2D_X_FLOAT(_CameraMotionVectorsTexture);     SAMPLER(sampler_CameraMotionVectorsTexture);
        TEXTURE2D_X_FLOAT(_CoCTex);                         SAMPLER(sampler_CameraDepthTexture);
        TEXTURE2D_X_FLOAT(_DepthOfFieldTex);                SAMPLER(sampler_DepthOfFieldTex);

        
        struct Attributes
		{
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct Varyings
		{
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 texcoordStereo : TEXCOORD1;
        };

        Varyings vert (Attributes input)
		{
            Varyings output;

            output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = input.texcoord;
            output.texcoordStereo = input.texcoord;

            return output;
        }

		half Luminance(half3 linearRgb)
        {
            return dot(linearRgb, float3(0.2126729, 0.7151522, 0.0721750));
        }

        half3 SRGBToLinear(half3 c)
        {
            #if USE_VERY_FAST_SRGB
                return c * c;
            #elif USE_FAST_SRGB
                return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
            #else
            half3 linearRGBLo = c / 12.92;
            half3 linearRGBHi = PositivePow((c + 0.055) / 1.055, half3(2.4, 2.4, 2.4));
            half3 linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
            return linearRGB;
            #endif
        }

		half3 LinearToSRGB(half3 c)
        {
            #if USE_VERY_FAST_SRGB
                return sqrt(c);
            #elif USE_FAST_SRGB
                return max(1.055 * PositivePow(c, 0.416666667) - 0.055, 0.0);
            #else
            half3 sRGBLo = c * 12.92;
            half3 sRGBHi = (PositivePow(c, half3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
            half3 sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
            return sRGB;
            #endif
        }

        half4 LinearToSRGB(half4 c)
        {
            return half4(LinearToSRGB(c.rgb), c.a);
        }
		
        //像素shader
        half4 frag(Varyings input) : SV_Target
        {
            float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv).r;
            float linearDepth = Linear01Depth(depth, _ZBufferParams);
            half coc = (linearDepth - _Distance) * _LensCoeff / max(depth, 1e-4);
            coc = saturate(coc * 0.5 * _RcpMaxCoC + 0.5);
            half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

            //散景模糊
            float c = cos(2.39996323f);
            float s = sin(2.39996323f);
            half4 _GoldenRot = half4(c, s, -s, c);

            half2x2 rot = half2x2(_GoldenRot);
            half4 accumulator = 0.0; //累加器
            half4 divisor = 0.0; //因子

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
            half4 BokehBlur = accumulator / divisor;

            finalColor.rgb = lerp(finalColor.rgb, BokehBlur.rgb, coc);

            return finalColor;
        }

        // // CoC calculation
        // half4 FragCoC(Varyings input) : SV_Target
        // {
        //     float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.texcoordStereo), _ZBufferParams);
        //     half coc = (depth - _Distance) * _LensCoeff / max(depth, 1e-4);
        //     return saturate(coc * 0.5 * _RcpMaxCoC + 0.5);
        // }
        //
        // // Temporal filter
        // half4 FragTempFilter(Varyings input) : SV_Target
        // {
        //     float3 uvOffs = _MainTex_TexelSize.xyy * float3(1.0, 1.0, 0.0);
        //
        //     #if UNITY_GATHER_SUPPORTED
        //
        //         half4 cocTL = GATHER_RED_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv - uvOffs.xy * 0.5)); // top-left
        //         half4 cocBR = GATHER_RED_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv + uvOffs.xy * 0.5)); // bottom-right
        //         half coc1 = cocTL.x; // top
        //         half coc2 = cocTL.z; // left
        //         half coc3 = cocBR.x; // bottom
        //         half coc4 = cocBR.z; // right
        //
        //     #else
        //
        //     half coc1 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv - uvOffs.xz)).r; // top
        //     half coc2 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv - uvOffs.zy)).r; // left
        //     half coc3 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv + uvOffs.zy)).r; // bottom
        //     half coc4 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv + uvOffs.xz)).r; // right
        //
        //     #endif
        //
        //     // Dejittered center sample.
        //     half coc0 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, UnityStereoTransformScreenSpaceTex(input.uv - _TaaParams.xy)).r;
        //
        //     // CoC dilation: determine the closest point in the four neighbors
        //     float3 closest = float3(0.0, 0.0, coc0);
        //     closest = coc1 < closest.z ? float3(-uvOffs.xz, coc1) : closest;
        //     closest = coc2 < closest.z ? float3(-uvOffs.zy, coc2) : closest;
        //     closest = coc3 < closest.z ? float3(uvOffs.zy, coc3) : closest;
        //     closest = coc4 < closest.z ? float3(uvOffs.xz, coc4) : closest;
        //
        //     // Sample the history buffer with the motion vector at the closest point
        //     float2 motion = SAMPLE_TEXTURE2D(_CameraMotionVectorsTexture, sampler_CameraMotionVectorsTexture, UnityStereoTransformScreenSpaceTex(input.uv + closest.xy)).xy;
        //     half cocHis = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(input.uv - motion)).r;
        //
        //     // Neighborhood clamping
        //     half cocMin = closest.z;
        //     half cocMax = Max3(Max3(coc0, coc1, coc2), coc3, coc4);
        //     cocHis = clamp(cocHis, cocMin, cocMax);
        //
        //     // Blend with the history
        //     return lerp(coc0, cocHis, _TaaParams.z);
        // }
        //
        // // Prefilter: downsampling and premultiplying
        // half4 FragPrefilter(Varyings input) : SV_Target
        // {
        //     #if UNITY_GATHER_SUPPORTED
        //
        //         // Sample source colors
        //         half4 c_r = GATHER_RED_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoordStereo);
        //         half4 c_g = GATHER_GREEN_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoordStereo);
        //         half4 c_b = GATHER_BLUE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoordStereo);
        //
        //         half3 c0 = half3(c_r.x, c_g.x, c_b.x);
        //         half3 c1 = half3(c_r.y, c_g.y, c_b.y);
        //         half3 c2 = half3(c_r.z, c_g.z, c_b.z);
        //         half3 c3 = half3(c_r.w, c_g.w, c_b.w);
        //
        //         // Sample CoCs
        //         half4 cocs = GATHER_TEXTURE2D(_CoCTex, sampler_CoCTex, input.texcoordStereo) * 2.0 - 1.0;
        //         half coc0 = cocs.x;
        //         half coc1 = cocs.y;
        //         half coc2 = cocs.z;
        //         half coc3 = cocs.w;
        //
        //     #else
        //
        //     float3 duv = _MainTex_TexelSize.xyx * float3(0.5, 0.5, -0.5);
        //     float2 uv0 = UnityStereoTransformScreenSpaceTex(input.uv - duv.xy);
        //     float2 uv1 = UnityStereoTransformScreenSpaceTex(input.uv - duv.zy);
        //     float2 uv2 = UnityStereoTransformScreenSpaceTex(input.uv + duv.zy);
        //     float2 uv3 = UnityStereoTransformScreenSpaceTex(input.uv + duv.xy);
        //
        //     // Sample source colors
        //     half3 c0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv0).rgb;
        //     half3 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1).rgb;
        //     half3 c2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv2).rgb;
        //     half3 c3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv3).rgb;
        //
        //     // Sample CoCs
        //     half coc0 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, uv0).r * 2.0 - 1.0;
        //     half coc1 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, uv1).r * 2.0 - 1.0;
        //     half coc2 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, uv2).r * 2.0 - 1.0;
        //     half coc3 = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, uv3).r * 2.0 - 1.0;
        //
        //     #endif
        //
        //     // Apply CoC and luma weights to reduce bleeding and flickering
        //     float w0 = abs(coc0) / (Max3(c0.r, c0.g, c0.b) + 1.0);
        //     float w1 = abs(coc1) / (Max3(c1.r, c1.g, c1.b) + 1.0);
        //     float w2 = abs(coc2) / (Max3(c2.r, c2.g, c2.b) + 1.0);
        //     float w3 = abs(coc3) / (Max3(c3.r, c3.g, c3.b) + 1.0);
        //
        //     // Weighted average of the color samples
        //     half3 avg = c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3;
        //     avg /= max(w0 + w1 + w2 + w3, 1e-4);
        //
        //     // Select the largest CoC value
        //     half coc_min = min(coc0, Min3(coc1, coc2, coc3));
        //     half coc_max = max(coc0, Max3(coc1, coc2, coc3));
        //     half coc = (-coc_min > coc_max ? coc_min : coc_max) * _MaxCoC;
        //
        //     // Premultiply CoC again
        //     avg *= smoothstep(0, _MainTex_TexelSize.y * 2, abs(coc));
        //
        //     #if defined(UNITY_COLORSPACE_GAMMA)
        //     avg = SRGBToLinear(avg);
        //     #endif
        //
        //     return half4(avg, coc);
        // }
        //
        // // Bokeh filter with disk-shaped kernels
        // half4 FragBlur(Varyings input) : SV_Target
        // {
        //     //预计算旋转
        //     float c = cos(2.39996323f);
        //     float s = sin(2.39996323f);
        //     half4 _GoldenRot = half4(c, s, -s, c);
        //
        //     half2x2 rot = half2x2(_GoldenRot);
        //     half4 accumulator = 0.0; //累加器
        //     half4 divisor = 0.0; //因子
        //
        //     half r = 1.0;
        //     half2 angle = half2(0.0, _BlurSize);
        //
        //     for (int j = 0; j < _Iteration; j++)
        //     {
        //         r += 1.0 / r; //每次 + r分之一 1.1
        //         angle = mul(rot, angle);
        //         half4 bokeh = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(input.uv + (r - 1.0) * angle));
        //         accumulator += bokeh * bokeh;
        //         divisor += bokeh;
        //     }
        //     return half4(accumulator / divisor);
        // }
        //
        // // Postfilter blur
        // half4 FragPostBlur(Varyings input) : SV_Target
        // {
        //     // 9 tap tent filter with 4 bilinear samples
        //     const float4 duv = _MainTex_TexelSize.xyxy * float4(0.5, 0.5, -0.5, 0);
        //     half4 acc;
        //     acc = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(input.uv - duv.xy));
        //     acc += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(input.uv - duv.zy));
        //     acc += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(input.uv + duv.zy));
        //     acc += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(input.uv + duv.xy));
        //     return acc / 4.0;
        // }
        //
        // // Combine with source
        // half4 FragCombine(Varyings input) : SV_Target
        // {
        //     half4 dof = SAMPLE_TEXTURE2D(_DepthOfFieldTex, sampler_DepthOfFieldTex, input.texcoordStereo);
        //     half coc = SAMPLE_TEXTURE2D(_CoCTex, sampler_CoCTex, input.texcoordStereo).r;
        //     coc = (coc - 0.5) * 2.0 * _MaxCoC;
        //
        //     // Convert CoC to far field alpha value.将CoC转换为远场alpha值
        //     float ffa = smoothstep(_MainTex_TexelSize.y * 2.0, _MainTex_TexelSize.y * 4.0, coc);
        //
        //     half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoordStereo);
        //
        //     #if defined(UNITY_COLORSPACE_GAMMA)
        //         color = SRGBToLinear(color);
        //     #endif
        //
        //     half alpha = Max3(dof.r, dof.g, dof.b);
        //
        //     // lerp(lerp(color, dof, ffa), dof, dof.a)
        //     color = lerp(color, float4(dof.rgb, alpha), ffa + dof.a - ffa * dof.a);
        //
        //     #if defined(UNITY_COLORSPACE_GAMMA)
        //     color = LinearToSRGB(color);
        //     #endif
        //
        //     return color;
        // }
        
        ENDHLSL
        
        Cull Off ZWrite Off ZTest Always

        Pass 
        {
			HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
			
            ENDHLSL
        }
        
        
//        Pass // 0
//        {
//            Name "CoC Calculation"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragCoC
//            ENDHLSL
//        }
//
//        Pass // 1
//        {
//            Name "CoC Temporal Filter"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragTempFilter
//            ENDHLSL
//        }
//
//        Pass // 2
//        {
//            Name "Downsample and Prefilter"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragPrefilter
//            ENDHLSL
//        }
//
//        Pass // 3
//        {
//            Name "Bokeh Filter"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragBlur
//            ENDHLSL
//        }
//
//        Pass // 4
//        {
//            Name "Postfilter"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragPostBlur
//            ENDHLSL
//        }
//
//        Pass // 5
//        {
//            Name "Combine"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragCombine
//            ENDHLSL
//        }
//
//        Pass // 6
//        {
//            Name "Debug Overlay"
//
//            HLSLPROGRAM
//            #pragma target 3.5
//            #pragma vertex vert
//            #pragma fragment FragDebugOverlay
//            ENDHLSL
//        }
    }
}