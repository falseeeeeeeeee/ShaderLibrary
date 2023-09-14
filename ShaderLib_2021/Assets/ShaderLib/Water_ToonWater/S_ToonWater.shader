Shader "URP/Water/S_ToonWater"
{
    Properties 
    {
        [Header(Depth)] [Space(6)]
        _DepthShallowColor ("Depth Shallow Color", Color) = (0.0, 1.0, 1.0, 1.0)
        _DepthDeepColor ("Depth Deep Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _DepthMaxDistance ("Depth Max Distance", Float) = 1.0
        _Transparent ("Transparent", Range(0.0, 1.0)) = 0.75

        [Header(Foam)] [Space(6)]
        _FoamColor ("Foam Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [NoScaleOffset] _FoamNoiseMap ("Foam Noise Map", 2D) = "white" {}
        _FoamAmount ("Foam Amount", Range(0.0, 1.0)) = 1.0
        _FoamMinDistence ("Foam Min Distance", Float) = 0.1
        _FoamMaxDistence ("Foam Max Distance", Float) = 0.5
        _FoamParams ("Foam Params XY: Scale ZW: Speed", Vector) = (1.0, 1.0, 1.0, 1.0)

        [Header(Distortion)] [Space(6)]
        [NoScaleOffset] _DistortionMap ("Distortion Map", 2D) = "white" {}
        _DistortionStrength ("Distortion Strength", Float) = 1.0

        [Header(Other)] [Space(6)]
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
            uniform float _Transparent;

            uniform float4 _DepthShallowColor;
            uniform float4 _DepthDeepColor;
            uniform float _DepthMaxDistance;

            uniform float _DistortionStrength;

            uniform float4 _FoamColor;
            uniform float _FoamAmount;
            uniform float _FoamMinDistence;
            uniform float _FoamMaxDistence;
            uniform float4 _FoamParams;
            CBUFFER_END
			
			TEXTURE2D(_FoamNoiseMap);	SAMPLER(sampler_FoamNoiseMap);
			TEXTURE2D(_DistortionMap);	SAMPLER(sampler_DistortionMap);

			//TEXTURE2D(_CameraOpaqueTexture);	        SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D(_CameraDepthNormalsTexture);      SAMPLER(sampler_CameraDepthNormalsTexture);
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);     SAMPLER(sampler_CameraDepthTexture);
			
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
                float2 uv0 : TEXCOORD2;     //Normal  UV
                float2 uvSS : TEXCOORD3;    //屏幕空间 UV
                float3 normalDirVS : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionSS = ComputeScreenPos(output.positionHCS);
                output.uvSS = output.positionSS.xy / output.positionSS.w;

                output.uv0 = input.texcoord;

                float3 normalDirWS = TransformObjectToWorldNormal(input.normalOS);
                output.normalDirVS = TransformWorldToViewDir(normalDirWS);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //深度
                float depth01 = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.uvSS).r;   //采样深度值
                float depthLinear = LinearEyeDepth(depth01, _ZBufferParams);   //线性深度
                float depthDifference = depthLinear - input.positionHCS.w;     //不同的深度值
                
                //水颜色
                float waterdepthDifference01 = saturate(depthDifference / _DepthMaxDistance);            //深度百分比 = 不同的深度值 / 深度最大距离
                float4 waterColor = lerp(_DepthShallowColor, _DepthDeepColor, waterdepthDifference01);  //混合深浅颜色
                
                //泡沫扭曲UV
                float2 distortionMap = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, input.uv0).xy;
                float2 distortion = (distortionMap * 2 - 1) * _DistortionStrength;
                float2 foamNoiseUV = input.uv0 * _FoamParams.xy + _Time.y * _FoamParams.zw + distortion;     // XY: Scale, ZW: OffsetSpeed

                //深度法线
                float3 depthNormal = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, input.uvSS).xyz;
                float normalDot = saturate(dot(depthNormal, input.normalDirVS));

                //泡沫
                float foamNoiseMap = SAMPLE_TEXTURE2D(_FoamNoiseMap, sampler_FoamNoiseMap, foamNoiseUV).r;
                float foamDistance = lerp(_FoamMinDistence, _FoamMaxDistence, normalDot);
                float foamdepthDifference01 = saturate(depthDifference / foamDistance);         //深度百分比 = 不同的深度值 / 深度最大距离
                float foamNoise = foamNoiseMap > foamdepthDifference01 * _FoamAmount ? 1 : 0;   //截断
                float3 foamColor = foamNoise * _FoamColor.rgb * _FoamColor.a * _Transparent;

                //最终颜色
                float3 color = waterColor.rgb + foamColor;
                float alpha = waterColor.a * _Transparent;
                
                return float4(color, alpha);
            } 
            ENDHLSL
        }
    }
}