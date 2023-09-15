Shader "URP/PPS/BloomShader"
{
    Properties 
    {
        _MainTex ("Texture", 2D) = "white" { }
        _LuminanceThreshold ("Luminance Threshold", Range(0, 1)) = 0.5
        _BlurSize ("Blur Size", Range(0, 5)) = 2
    }
    SubShader 
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Geometry" 
            "RenderType" = "Opaque" 
            "IgnoreProjector" = "True" 
        }
        
        Cull Off
        ZWrite Off
        ZTest Always
        
        HLSLINCLUDE

        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 2.0
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "../Include/SIH_Volume.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        half _LuminanceThreshold;
        half _BlurSize;
        CBUFFER_END

		TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_BloomTex);    SAMPLER(sampler_BloomTex);

        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // 基本属性
        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        // 基本属性变化
        struct Varyings_Extract
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        // 辉光属性变化
        struct Varyings_Bloom
        {
            float4 positionCS : SV_POSITION;
            float4 uv : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // 基本 顶点着色器
        Varyings_Extract vertExtract (Attributes input)
        {
            Varyings_Extract output = (Varyings_Extract)0;

            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = CorrectUV(input.texcoord, _MainTex_TexelSize);
            
            return output;
        }
        
        // 基本 片段着色器
        half4 fragExtract(Varyings_Extract input) : SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
            half val = saturate(CustomLuminance(col.rgb) - _LuminanceThreshold);
            
            return col * val;
        }
        
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // 辉光 顶点着色器
        Varyings_Bloom vertBloom(Attributes input)
        {
            Varyings_Bloom output = (Varyings_Bloom)0;
            
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            output.uv.xy = input.texcoord;
            output.uv.zw = CorrectUV(input.texcoord, _MainTex_TexelSize);
            
            return output;
        }

        // 辉光 片段着色器
        half4 fragBloom(Varyings_Bloom input): SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy) + SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, input.uv.zw);
        }
        
        ENDHLSL
        
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // Extract Pass
        Pass 
        {
			HLSLPROGRAM
			
            #pragma vertex vertExtract
            #pragma fragment fragExtract
			
            ENDHLSL
        }        
        
        // Gaussian Double Pass
        UsePass "URP/PPS/GaussianBlurShader/GAUSSIAN_HOR"
        UsePass "URP/PPS/GaussianBlurShader/GAUSSIAN_VERT"
        
        // Bloom Pass
        Pass 
        {
			HLSLPROGRAM
			
            #pragma vertex vertBloom
            #pragma fragment fragBloom
			
            ENDHLSL
        }
    }
}
