Shader "URP/Sky/S_CustomSkybox"
{
    Properties 
    {
        _Tint ("染色", Color) = (0.5, 0.5, 0.5, 0.5)
        [Gamma] _Exposure ("曝光", Range(0, 8)) = 1.0
        _Mipmap ("模糊", Range(0, 10)) = 0.0
        _Rotation ("旋转", Range(0, 360)) = 0
        [NoScaleOffset]_SkyCube ("天空球", Cube) = "Skybox" {}
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            //"RenderType" = "Opaque"
            "Queue"="Background"
            "RenderType"="Background"
            "PreviewType"="Skybox"
        }

        Pass {
            Name "SKY_FORWARD"
            //Tags { "LightMode" = "UniversalForward" }
             
            Cull Off
            ZWrite Off

			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _Tint;
            uniform half _Exposure;
            uniform half _Mipmap;
            uniform float _Rotation;
			uniform half4 _SkyCube_HDR;
            CBUFFER_END
			
			TEXTURECUBE(_SkyCube);	    SAMPLER(sampler_SkyCube);

			//Y轴旋转
            float3 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }

			//取HDR图W通道
			inline half3 DecodeHDR (half4 data, half4 decodeInstructions)
            {
                // If Linear mode is not supported we can skip exponent part
                #if defined(UNITY_NO_LINEAR_COLORSPACE)
                    return (decodeInstructions.x * data.a) * data.rgb;
                #else
                    return (decodeInstructions.x * pow(abs(data.a), decodeInstructions.y)) * data.rgb;
                #endif
            }

			//判断Gamma空间
			#ifdef UNITY_COLORSPACE_GAMMA
            #define unity_ColorSpaceDouble half4(2.0, 2.0, 2.0, 2.0)
            #else // Linear values
            #define unity_ColorSpaceDouble half4(4.59479380, 4.59479380, 4.59479380, 2.0)
            #endif
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float3 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                float3 rotated = RotateAroundYInDegrees(input.positionOS.xyz, _Rotation);
                output.positionHCS = TransformObjectToHClip(rotated);
                output.uv = input.positionOS.xyz;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);
			    
                half4 var_SkyCube = SAMPLE_TEXTURECUBE_LOD(_SkyCube, sampler_SkyCube, input.uv, _Mipmap);
			    half3 skyCube = DecodeHDR (var_SkyCube, _SkyCube_HDR);
			    skyCube = skyCube * _Tint.rgb * unity_ColorSpaceDouble.rgb;
			    skyCube *= _Exposure;
                
                return half4(skyCube, 1);
            } 
            ENDHLSL
        }
    }
}
