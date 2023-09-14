Shader "URP/PPS/GaussianBlurShader"
{
    Properties 
    {
        _MainTex ("Texture", 2D) = "white" { }
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
        #include "Assets/Arts/Shaders/HLSLInclude/FengHLSL.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        half _BlurSize;
        CBUFFER_END

		TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

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
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float2 uv[5] : TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };

        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // 高斯模糊 水平 顶点着色器
        Varyings vertHorizontal (Attributes input)
        {
            Varyings output = (Varyings)0;

            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            float2 uv = CorrectUV(input.texcoord, _MainTex_TexelSize);

            output.uv[0] = uv;
            output.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            output.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            output.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            output.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            
            return output;
        }

        // 高斯模糊 垂直 顶点着色器
        Varyings vertVertical (Attributes input)
        {
            Varyings output = (Varyings)0;

            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            float2 uv = CorrectUV(input.texcoord, _MainTex_TexelSize);

            output.uv[0] = uv;
            output.uv[1] = uv + float2(0.0, _MainTex_TexelSize.x * 1.0) * _BlurSize;
            output.uv[2] = uv - float2(0.0, _MainTex_TexelSize.x * 1.0) * _BlurSize;
            output.uv[3] = uv + float2(0.0, _MainTex_TexelSize.x * 2.0) * _BlurSize;
            output.uv[4] = uv - float2(0.0, _MainTex_TexelSize.x * 2.0) * _BlurSize;
            
            return output;
        }
        
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // 基本 片段着色器
        half4 frag(Varyings input) : SV_Target
        {
            //高斯核
            float weight[3] =
            {
                0.4026, 0.2442, 0.0545
            };
            
            half3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[0]).rgb * weight[0];
            
            for (int it = 1; it < 3; it ++)
            {
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[2 * it - 1]).rgb * weight[it];
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[2 * it]).rgb * weight[it];
            }
            
            return half4(sum, 1);
        }
        
        ENDHLSL
        
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        ///———————————————————————————————————————————————————————————————————————————————————————————
        // Horizontal Pass
        Pass 
        {
            NAME "GAUSSIAN_HOR"
			HLSLPROGRAM
			
            #pragma vertex vertHorizontal
            #pragma fragment frag
			
            ENDHLSL
        }        
        
        // Vertical Pass
        Pass 
        {
            NAME "GAUSSIAN_VERT"
			HLSLPROGRAM
			
            #pragma vertex vertVertical
            #pragma fragment frag
			
            ENDHLSL
        }
        
    }
}
