Shader "URP/Fog/S_HeighFog"
{
    Properties 
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}

        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        [PowerSlider(2)] _SpecularRange ("Specular Range", Range(0.01,1)) = 0.1

        [Toggle(_NORMALMAP)] _EnableBumpMap("Enable Normal/Bump Map", Float) = 0.0
        _NormalMap("NormalMap",2D) = "bump" {}
        _NormalScale("NormalScale" ,Float) = 1.0

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Cull [_CullMode]

        HLSLINCLUDE
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x	
        #pragma target 2.0

        #pragma shader_feature _FOG_ON
        #pragma shader_feature _NORMALMAP

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile_fog

        #pragma multi_compile_instancing

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../Include/SIH_HeighFog.hlsl"

        CBUFFER_START(UnityPerMaterial)
		uniform half4 _BaseColor;
		uniform float4 _BaseMap_ST;
        uniform half4 _SpecularColor;
        uniform half _SpecularRange;
        float4 _NormalMap_ST;
        float _NormalScale;
        CBUFFER_END

        TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap);	SAMPLER(sampler_NormalMap);

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
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS:TEXCOORD1;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 2);
                float4 uv : TEXCOORD3;

                #if _NORMALMAP
				float4 tangentWS : TEXCOORD4;
                #endif

                float fogFactor: TEXCOORD5; 
                float3 positionWS : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);

                output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);

                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInputs.normalWS;

                #if _NORMALMAP
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    half4 tangentWS = half4(normalInputs.tangentWS.xyz, sign);
                    output.tangentWS = tangentWS;
                    output.uv.zw = TRANSFORM_TEX(input.texcoord, _NormalMap);
                #endif

                output.fogFactor = ComputeFogFactor(input.positionOS.z);

                OUTPUT_SH(normalInputs.normalWS, output.vertexSH);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //T2W
                #if _NORMALMAP
                    float sgn = input.tangentWS.w;
				    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    half3x3 T2W = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
                #endif

                //NormalMap
                #ifdef _NORMALMAP
                    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv.zw), _NormalScale);
				    input.normalWS = TransformTangentToWorld(normalTS, T2W);
                #endif
                half3 normalWS = input.normalWS;

                //Light
                half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWS);
                float3 Ambient = SampleSH(normalWS);
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                real3 lightColor = mainLight.color;
                float3 lightDir = normalize(mainLight.direction);
                //float lightShadow = mainLight.shadowAttenuation;
                float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;

                //LightMode
                float3 viewDirWS = normalize(input.viewDirWS);
                float lambert = saturate(dot(lightDir, normalWS));
                float phong = pow(saturate(dot(viewDirWS, reflect(-lightDir, normalWS))), _SpecularRange * 255.0);

                //diffuse
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy) * _BaseColor;  

                half3 color = saturate(baseColor.rgb * lambert * lightColor * lightShadow + _SpecularColor.rgb * phong * lightShadow + bakedGI * baseColor.rgb);

                //fog
                real fogFactor = ComputeFogFactor(input.positionHCS.z * input.positionHCS.w);
                color = MixFog(color, fogFactor);
                #if _FOG_ON
                color = ExponentialHeightFog(color, input.positionWS);
                #endif
                
                return half4(color, 1);
            } 
            ENDHLSL
        }
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

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
