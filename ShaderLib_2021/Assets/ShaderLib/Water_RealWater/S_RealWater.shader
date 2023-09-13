Shader "URP/Water/S_RealWater"
{
    Properties 
    {
        [Header(Base)] [Space(6)]
        _BaseColor ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Transparent ("Transparent", Range(0.0, 1.0)) = 0.75

        [Header(Specular)] [Space(6)]
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularRange ("Specular Range", Range(1.0, 128.0)) = 30.0        
        
        [Header(Fresnel)] [Space(6)]
        _FresnelColor ("Fresnel Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _FresnelRange ("Fresnel Range", Range(0.01, 8.0)) = 1.0

        [Header(Depth)] [Space(6)]
        _DepthShallowColor ("Depth Shallow Color", Color) = (0.0, 1.0, 1.0, 1.0)
        _DepthDeepColor ("Depth Deep Color", Color) = (0.0, 0.0, 1.0, 1.0)
        _DepthMaxDistance ("Depth Max Distance", Float) = 1.0
        
        [Header(Refraction)] [Space(6)]
        _RefractionStrength ("Refraction Strength", Float) = 1.0
        _RefractionMaxDistance ("Refraction Max Distance", Float) = 1.0
        
        [Header(Foam)] [Space(6)]
        _FoamColor ("Foam Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [NoScaleOffset] _FoamNoiseMap ("Foam Noise Map", 2D) = "white" {}
        _FoamAmount ("Foam Amount", Range(0.01, 1.0)) = 1.0
        _FoamParams ("Foam Params XY: Scale ZW: Speed", Vector) = (1.0, 1.0, 1.0, 1.0)
        
        [Header(Normal)] [Space(6)]
        [NoScaleOffset] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Float) = 1.0
        _NormalParams ("Normal Params XY: Scale ZW: Speed", Vector) = (1.0, 1.0, 1.0, 0.5)
        _DetailNormalScale ("Detail Normal Scale", Float) = 1.0
        _DetailNormalParams ("Detail Normal Params XY: Scale ZW: Speed", Vector) = (1.0, 1.0, 1.0, 0.5)
        
        [Header(Warp)] [Space(6)]
        [NoScaleOffset] _WrapMap ("Warp Map", 2D) = "gray" {}
        _Wrap1Scale ("Wrap1 Scale", Range(-1.0, 1.0)) = 0.1
        _Wrap1Params ("Wrap1 Params XY: Scale ZW: Speed", Vector) = (1.0, 1.0, 1.0, 0.5)        
        _Wrap2Scale ("Wrap2 Scale", Range(-1.0, 1.0)) = 0.1
        _Wrap2Params ("Wrap2 Params XY: Scale ZW: Speed", Vector) = (2.0, 2.0, 0.5, 0.5)
        
        [Header(Wave)] [Space(6)]
        _WaveStrength ("Wave Strength", Range(0.0, 1.0)) = 0.5
        _WaveMask ("Wave Mask", Range(0.0, 1.0)) = 0.5
        _WaveFrequency ("Wave Frequency", Float) = 1
        _WaveSpeed ("Wave Speed", Float) = 1
        
        [Header(Environment)] [Space(6)]
        _CubeMapIntensity ("CubeMap Intensity", Range(0.0, 1.0)) = 0.5
        [NoScaleOffset] _CubeMap ("Cube Map", CUBE) = "skybox" {}
        _CubeMapMipmap ("Cube Map Mipmap", Range(0.0, 8.0)) = 0.0
        
        [Header(Emission)] [Space(6)]
        [HDR] _EmissionColor ("Emission Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform float4 _BaseColor;
            uniform float _Transparent;

            uniform float4 _SpecularColor;
            uniform float _SpecularRange;
        
            uniform float4 _FresnelColor;
            uniform float _FresnelRange;

            uniform float4 _DepthShallowColor;
            uniform float4 _DepthDeepColor;
            uniform float _DepthMaxDistance;

            uniform float _RefractionStrength;
            uniform float _RefractionMaxDistance;;

            uniform float4 _FoamColor;
            uniform float _FoamAmount;
            uniform float4 _FoamParams;

            uniform float _NormalScale;
            uniform float4 _NormalParams;
            uniform float _DetailNormalScale;
            uniform float4 _DetailNormalParams;
            

            uniform float _Wrap1Scale;
            uniform float4 _Wrap1Params;    
            uniform float _Wrap2Scale;
            uniform float4 _Wrap2Params;

            uniform float _WaveStrength;
            uniform float _WaveFrequency;
            uniform float _WaveSpeed;
            uniform float _WaveMask;
                
            uniform float _CubeMapIntensity;
            uniform float _CubeMapMipmap;

            uniform float4 _EmissionColor;
            CBUFFER_END
			
			TEXTURE2D(_FoamNoiseMap);	SAMPLER(sampler_FoamNoiseMap);
			TEXTURE2D(_NormalMap);	    SAMPLER(sampler_NormalMap);
			TEXTURE2D(_WrapMap);	    SAMPLER(sampler_WrapMap);
            TEXTURECUBE(_CubeMap);      SAMPLER(sampler_CubeMap);

			TEXTURE2D(_CameraOpaqueTexture);	    SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);     SAMPLER(sampler_CameraDepthTexture);
			
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
                float4 positionSS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float2 uv0 : TEXCOORD2;     //Normal  UV
                float2 uv1 : TEXCOORD3;     //WrapMap UV1
                float2 uv2 : TEXCOORD4;     //WrapMap UV2
                float2 uv3 : TEXCOORD5;     //FoamMap UV
                float2 uvSS : TEXCOORD6;    //屏幕空间 UV
                float3 normalDirWS : TEXCOORD7;
                float3 tangentDirWS : TEXCOORD8;
                float3 bitangentDirWS : TEXCOORD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                //顶点坐标
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float positionWSWaveX = sin(output.positionWS.x * _WaveFrequency + _Time.x * _WaveSpeed);
                float positionWSWaveZ = sin(output.positionWS.z * _WaveFrequency + _Time.x * _WaveSpeed);
                input.positionOS.y += (positionWSWaveX + positionWSWaveZ) * _WaveStrength * step(_WaveMask, input.positionOS.y);
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                
                //TBN
                output.normalDirWS = TransformObjectToWorldNormal(input.normalOS);
                output.tangentDirWS = normalize(mul(unity_ObjectToWorld, float4(input.tangentOS.xyz, 0.0)).xyz);
                output.bitangentDirWS = normalize(cross(output.normalDirWS, output.tangentDirWS) * (input.tangentOS.w * GetOddNegativeScale()));

                //UV
                output.uv0 = input.texcoord;
                output.uv1 = input.texcoord * _Wrap1Params.xy - frac(_Time.x * _Wrap1Params.zw);
                output.uv2 = input.texcoord * _Wrap2Params.xy - frac(_Time.x * _Wrap2Params.zw);
                output.uv3 = input.texcoord * _FoamParams.xy - frac(_Time.x * _FoamParams.zw);
                /*
                //扰动UV，采样法线贴图，并使用扰动UV
                float2 wrapMap1 = SAMPLE_TEXTURE2D_LOD(_WrapMap, sampler_WrapMap, output.uv1, 0).xy;
                float2 wrapMap2 = SAMPLE_TEXTURE2D_LOD(_WrapMap, sampler_WrapMap, output.uv2, 0).xy;
                float2 wrapMapBlend = (wrapMap1 - 0.5) * _Wrap1Scale + (wrapMap2 - 0.5) * _Wrap2Scale;  //-0.5 是让UV从[0,1]到[-0.5,0.5]
                output.uv0 += wrapMapBlend;
                */
                //屏幕顶点坐标
                VertexPositionInputs positionInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionSS = ComputeScreenPos(positionInput.positionCS);
                //output.positionSS = output.positionHCS * 0.5;   //找到中点位置
                //output.positionSS.xy = float2(output.positionSS.x, output.positionSS.y * _ProjectionParams.x) + output.positionSS.w;
                //output.positionSS.zw = output.positionHCS.zw;
                output.uvSS = output.positionSS.xy / output.positionSS.w;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //灯光
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = normalize(mainLight.direction);
                float3 lightColor = mainLight.color;
                float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;

                //扰动UV，采样法线贴图，并使用扰动UV
                float2 wrapMap1 = SAMPLE_TEXTURE2D(_WrapMap, sampler_WrapMap, input.uv1).xy;
                float2 wrapMap2 = SAMPLE_TEXTURE2D(_WrapMap, sampler_WrapMap, input.uv2).xy;
                float2 wrapMapBlend = (wrapMap1 - 0.5) * _Wrap1Scale + (wrapMap2 - 0.5) * _Wrap2Scale;  //-0.5 是让UV从[0,1]到[-0.5,0.5]
                input.uv0 += wrapMapBlend;

                //法线 和 其它向量
                float3 normalMap = UnpackNormalScale(SAMPLE_TEXTURE2D_LOD(_NormalMap, sampler_NormalMap, input.uv0 * _NormalParams.xy - frac(_Time.x * _NormalParams.zw), 0), _NormalScale);
                float3 detailNormalMap = UnpackNormalScale(SAMPLE_TEXTURE2D_LOD(_NormalMap, sampler_NormalMap, input.uv0 * _DetailNormalParams.xy - frac(_Time.x * _DetailNormalParams.zw), 0), _DetailNormalScale);
                float3 normalBlend = normalize(float3(normalMap.xy + detailNormalMap.xy, normalMap.z * detailNormalMap.z));

                float3 normalDirTS = normalBlend;
                float3x3 TBN = float3x3(input.tangentDirWS, input.bitangentDirWS, input.normalDirWS);
                float3 normalDirWS = normalize(mul(normalDirTS, TBN));
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 halfDir = normalize(lightDir + viewDirWS);

                //直接光 光照模型
                float lambert = saturate(dot(normalDirWS, lightDir));
                float blinnPhong = pow(saturate(dot(normalDirWS, halfDir)), _SpecularRange);
                float3 dirLighting = lambert * _BaseColor.rgb * lightColor * lightShadow * _Transparent + blinnPhong * _SpecularColor.rgb * lightShadow;

                //环境光 光照模型
                //float3 Ambient = SampleSH(normalDirWS);
                float3 cubeMap = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflect(-viewDirWS, normalDirWS), _CubeMapMipmap).rgb;
                float fresnel = pow(saturate(1 - dot(viewDirWS, normalDirWS)), _FresnelRange);
                float3 envLighting = cubeMap * fresnel * _CubeMapIntensity * _BaseColor.rgb;// + _FresnelColor.rgb * fresnel;

                //深度
                float depthColor = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, input.uvSS).r;   //采样深度值
                float depthColorEye = LinearEyeDepth(depthColor, _ZBufferParams);   //线性深度
                float depthDifference = depthColorEye - input.positionHCS.w;     //不同的深度值
                
                //深度渐变
                float waterScenesDepth01 = saturate(depthDifference / _DepthMaxDistance);   //水底 深度百分比 = 不同的深度值 / 深度最大距离
                float4 waterColor1 = lerp(_DepthShallowColor, _DepthDeepColor, waterScenesDepth01);  //混合深浅颜色
                
                //泡沫
                float foamNoiseMap = SAMPLE_TEXTURE2D(_FoamNoiseMap, sampler_FoamNoiseMap, input.uv3).r;
                float waterScenesDepth02 = saturate(depthDifference / _FoamAmount);   //泡沫 深度百分比 = 不同的深度值 / 深度最大距离 
                float foamAlpha = mul(step(waterScenesDepth02, foamNoiseMap), _FoamColor.a);
                //float foamAlpha = mul(lerp(foamNoiseMap.r, 0, waterScenesDepth02), _FoamColor.a);
                float4 waterColor2 = lerp(waterColor1, _FoamColor, foamAlpha);
                
                //折射
                float waterScenesDepth03 = saturate(depthDifference / _RefractionMaxDistance);   //泡沫 深度百分比 = 不同的深度值 / 深度最大距离 
                float2 refractUV = normalBlend.xy * _RefractionStrength * waterScenesDepth03 * normalBlend.xy;
                float4 scenesColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.uvSS + refractUV);
                
                //自发光 光照模型
                float3 emission = waterColor1.rgb * _EmissionColor.rgb * _EmissionColor.a + scenesColor.rgb;

                //最终颜色
                float3 color = dirLighting + envLighting + waterColor2.rgb + emission;
                
                return float4(color, _Transparent);
            } 
            ENDHLSL
        }
        Pass
        {
        	Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
            };

            float3 _LightDirection;

            Varyings vert (Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                return output;
            }
            half4 frag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
