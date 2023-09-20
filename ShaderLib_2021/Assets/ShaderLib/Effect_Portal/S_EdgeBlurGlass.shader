Shader "URP/Glass/S_EdgeBlurGlass"
{
    Properties 
    {
        [HDR] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}

        [HDR] _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        [PowerSlider(2)] _SpecularRange ("Specular Range", Range(0.01,1)) = 0.1

        [Toggle(_NORMALMAP)] _EnableBumpMap("Enable Normal Map", Float) = 0.0
        _NormalMap("Normal Map",2D) = "bump" {}
        _NormalScale("Normal Scale" ,Float) = 1.0

        _GlassBlurStrength("Blur Strength", Range(0, 1)) = 1
        _GlassThickness("Glass Thickness", Range(-1, 1)) = 0.1

        [HDR] _DepthEdgeColor ("DepthEdge Color", Color) = (1, 1, 1, 1)
        _DepthOffset ("Depth Offset", Float) = 1

        //[IntRange] _Stencil ("Stencil ID", Range(0,255)) = 0
        //[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 8
        //[Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", Float) = 3
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

        Cull [_CullMode]
        Blend SrcAlpha OneMinusSrcAlpha

        ZWrite On

        //Stencil
        //{
        //    Ref [_Stencil]
        //    Comp [_StencilComp]
        //    Pass [_StencilPass]
        //}

        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x	
        #pragma target 2.0

        #pragma shader_feature _NORMALMAP

        #pragma multi_compile_instancing

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

        


        CBUFFER_START(UnityPerMaterial)
		uniform float4 _BaseColor;
		uniform float4 _BaseMap_ST;
        uniform float4 _SpecularColor;
        uniform float _SpecularRange;
        uniform float _NormalScale;
        uniform float _GlassBlurStrength;
        uniform float _GlassThickness;
        uniform float4 _DepthEdgeColor;
        uniform float _DepthOffset;
        CBUFFER_END

        TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);	SAMPLER(sampler_NormalMap);

        float4 _CameraOpaqueTexture_TexelSize;
        SAMPLER(_CameraDepthTexture);


        //float4 _CameraColorTexture_TexelSize;   
        //SAMPLER(_CameraColorTexture);   

        ENDHLSL

        Pass {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 
            
			HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float4 positionSS :TEXCOORD6;
                float4 positionSS2 :TEXCOORD7;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS:TEXCOORD3;
                float2 uv : TEXCOORD4;

                #if _NORMALMAP
				    float4 tangentWS : TEXCOORD5;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float4 ComputeScreenPos(in const float4 PositionHCS, in const float ProjectionSign)
            {
                float4 Output = PositionHCS * 0.5f;
                Output.xy = float2(Output.x, Output.y * ProjectionSign) + Output.w;
                Output.zw = PositionHCS.zw;
                return Output;
            }

            float3 GetBlurredScreenColor(in const float2 UVSS)
            {
                #define OFFSET_X(kernel) float2(_CameraOpaqueTexture_TexelSize.x * kernel * _GlassBlurStrength, 0)
                #define OFFSET_Y(kernel) float2(0, _CameraOpaqueTexture_TexelSize.y * kernel * _GlassBlurStrength)

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

            float3 BlendWithBackground(in const float4 Color, in const float2 UVSS)
            {
                const float3 BlurredScreenColor = GetBlurredScreenColor(UVSS);
                const float3 MixedColor = BlurredScreenColor * Color.rgb;
                const float3 AlphaInterpolatedColor = lerp(MixedColor, Color.rgb, Color.a);

                return AlphaInterpolatedColor;
            }

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                

                #if _NORMALMAP
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    float4 tangentWS = float4(normalInputs.tangentWS.xyz, sign);
                    output.tangentWS = tangentWS;
                #endif

                //Glass positionSS
                float3 RefractionAdjustedPositionOS = input.positionOS.xyz - input.normalOS * _GlassThickness;
                float4 RefractionAdjustedPositionHCS = TransformObjectToHClip(RefractionAdjustedPositionOS);
                output.positionSS = RefractionAdjustedPositionHCS * 0.5;
                output.positionSS.y *= _ProjectionParams.x;
                output.positionSS.xy += output.positionSS.w;
                output.positionSS.zw = RefractionAdjustedPositionHCS.zw;
                output.positionSS = ComputeScreenPos(RefractionAdjustedPositionHCS, _ProjectionParams.x);

                //Base positionSS
                //屏幕空间顶点坐标，xy保存为未透除的屏幕UV，ZW不变
                output.positionSS2.xy = output.positionHCS.xy * 0.5 + float2(output.positionHCS.w, output.positionHCS.w) * 0.5;
                output.positionSS2.zw = output.positionHCS.zw;

                return output;
            }
			
            float4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //Normal
                #if _NORMALMAP
                    float sgn = input.tangentWS.w;
				    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    float3x3 T2W = float3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
                    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _NormalScale);
				    input.normalWS = TransformTangentToWorld(normalTS, T2W);
                #endif
                float3 normalWS = normalize(input.normalWS);
                //float3 normalWS = input.normalWS;

                //Light
                Light mainLight = GetMainLight();
                real3 lightColor = mainLight.color;
                float3 lightDir = normalize(mainLight.direction);

                //LightMode
                float3 viewDirWS = normalize(input.viewDirWS);
                float lambert = dot(lightDir, normalWS) * 0.5 + 0.5;
                float phong = pow(saturate(dot(viewDirWS, reflect(-lightDir, normalWS))), _SpecularRange * 255.0);

                //BaseColor
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;

                //Glass 
                float2 uvSS = input.positionSS.xy / input.positionSS.w;
                baseColor.rgb = BlendWithBackground(baseColor, uvSS);
                baseColor.rgb *= lambert * lightColor;
                baseColor.rgb += phong * _SpecularColor.rgb * _SpecularColor.a;

                //接触光
                input.positionSS2.xy /= input.positionSS2.w; 
                #ifdef UNITY_UV_STARTS_AT_TOP
                    input.positionSS2.y = 1.0 - input.positionSS2.y;
                #endif
                float4 depthColor = tex2D(_CameraDepthTexture, input.positionSS2.xy);
                float depthBuffer = LinearEyeDepth(depthColor.r, _ZBufferParams);  //得到线性的深度缓冲
                float depth = LinearEyeDepth(input.positionHCS.z, _ZBufferParams);   //得到模型的线性深度
                float edge = saturate(1 - (depthBuffer - depth) * _DepthOffset);    //计算接触光

                float sampleDepth01 = tex2D(_CameraDepthTexture,input.positionSS2.xy).r;
                float DepthLinear = LinearEyeDepth(sampleDepth01, _ZBufferParams);
                float depthDifference = abs(DepthLinear - input.positionHCS.z);
                float difference = saturate(depthDifference / _DepthOffset);

                return float4(lerp(_DepthEdgeColor.rgb, baseColor.rgb, difference), 1);

                return float4(lerp(baseColor.rgb, _DepthEdgeColor.rgb, edge), 1);
                return float4(baseColor.rgb, 1);
            } 
            ENDHLSL
        }
    }
}
