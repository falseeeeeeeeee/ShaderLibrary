Shader "URP/Base/S_SimpleLit"
{
    Properties
    {
        [Header(Base)][Space(6)]
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)

        [Toggle(_SPECGLOSSMAP)] _SpecGlossMapToggle ("Use Specular Gloss Map", Int) = 0
        [NoScaleOffset] _SpecGlossMap ("Specular Map", 2D) = "white" {}
        _SpecColor ("Specular Color", Color) = (0.2, 0.2, 0.2)
        [Toggle(_GLOSSINESS_FROM_BASE_ALPHA)] _GlossSource ("Glossiness source, from Albedo Alpha (if on) vs from Specular (is off)", Int) = 0

        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5

        [Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Int) = 0
        [Normal][NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Float) = 1.0

        [Toggle(_EMISSION)] _EmissionToggle ("Use Emission", Int) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0.0, 0.0, 0.0)
        [NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}

        [Header(Settings)][Space(6)]
        [Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Int) = 0
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", float) = 2
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        HLSLINCLUDE
        // -------------------------------------
        // Includes
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // -------------------------------------
        // Properties Stages
        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _SpecColor;
            half _Smoothness;
            half _BumpScale;
            half4 _EmissionColor;

            half _Cutoff;
        CBUFFER_END
        ENDHLSL

        // -------------------------------------
        // Lit Pass
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex SimpleLitPassVertex
            #pragma fragment SimpleLitPassFragment

            // -------------------------------------
            // Material Keywords
            #define _SPECULAR_COLOR // 总是打开高光颜色
            #pragma shader_feature _SPECGLOSSMAP
            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            // -------------------------------------
            // Properties Stages
            TEXTURE2D(_SpecGlossMap);
            SAMPLER(sampler_SpecGlossMap);

            // -------------------------------------
            // Functions
            half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor,
                                           TEXTURE2D_PARAM(specMap, sampler_specMap))
            {
                half4 specularSmoothness = half4(0, 0, 0, 1);
                #ifdef _SPECGLOSSMAP
                specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
                #elif defined(_SPECULAR_COLOR)
                specularSmoothness = specColor;
                #endif

                #ifdef _GLOSSINESS_FROM_BASE_ALPHA
                specularSmoothness.a = alpha;
                #endif

                return specularSmoothness;
            }

            // -------------------------------------
            // Vertex Appdata
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                #ifdef _NORMALMAP
                float4 tangentOS : TANGENT;
                #endif
                float2 texcoord : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float2 dynamicLightmapUV : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // -------------------------------------
            // Vertex To Fragment
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;

                #ifdef _NORMALMAP
                float4 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                float4 bitangentWS : TEXCOORD4;
                #else
                float3 normalWS : TEXCOORD2;
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half4 fogFactorAndVertexLight : TEXCOORD5; // x: fogFactor, yzw: vertex light
                #else
                half fogFactor : TEXCOORD5;
                #endif

                #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                    float4 shadowCoord : TEXCOORD6;
                #endif

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
                #ifdef DYNAMICLIGHTMAP_ON
                    float2  dynamicLightmapUV : TEXCOORD8;
                #endif

                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // -------------------------------------
            // Vertex Shader
            Varyings SimpleLitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                // 顶点信息
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = positionInputs.positionWS;
                output.positionCS = positionInputs.positionCS;

                // 法线
                #ifdef _NORMALMAP
                    float3 viewDirectionWS = GetWorldSpaceViewDir(output.positionWS);
                    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                    output.normalWS = float4(normalInputs.normalWS.xyz, viewDirectionWS.x);
                    output.tangentWS = float4(normalInputs.tangentWS.xyz, viewDirectionWS.y);
                    output.bitangentWS = float4(normalInputs.bitangentWS.xyz, viewDirectionWS.z);
                #else
                    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                    output.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
                #endif

                // 雾&点光源
                half fogFactor = ComputeFogFactor(output.positionCS.z);
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    half3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
                    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                #else
                    output.fogFactor = fogFactor;
                #endif

                // 阴影坐标
                #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                    output.shadowCoord = GetShadowCoord(positionInputs);
                #endif

                // 贴图UV
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                // 光照相关
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #ifdef DYNAMICLIGHTMAP_ON
                    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                return output;
            }

            // -------------------------------------
            // SurfaceData
            void InitSurfaceData(Varyings input, out SurfaceData surfaceData)
            {
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                #ifdef _ALPHATEST_ON
                    clip(baseMap.a - _Cutoff);
                #endif
                surfaceData.albedo = baseMap.rgb;
                surfaceData.alpha = baseMap.a;

                _SpecColor.a *= _Smoothness;
                half4 specular = SampleSpecularSmoothness(input.uv, baseMap.a, _SpecColor, _SpecGlossMap,
                    sampler_SpecGlossMap);
                surfaceData.specular = specular.rgb;
                surfaceData.smoothness = specular.a;

                surfaceData.normalTS = SampleNormal(input.uv, _BumpMap, sampler_BumpMap, _BumpScale);;
                surfaceData.emission = SampleEmission(input.uv, _EmissionColor.rgb, _EmissionMap, sampler_EmissionMap);
                surfaceData.occlusion = 1.0;
                surfaceData.metallic = 0.0;
                surfaceData.clearCoatMask = 0.0;
                surfaceData.clearCoatSmoothness = 0.0;
            }

            // -------------------------------------
            // InputData
            void InitInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;

                inputData.positionWS = input.positionWS;

                #ifdef _NORMALMAP
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                    half3 viewDirectionWS = half3(input.tangentWS.z, input.bitangentWS.z, input.normalWS.z);
                #else
                    inputData.normalWS = input.normalWS;
                    half3 viewDirectionWS = GetWorldSpaceViewDir(input.positionWS);
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = SafeNormalize(viewDirectionWS);

                // 阴影坐标
                #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(_MAIN_LIGHT_SHADOWS_CASCADE)
                    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                #else
                    inputData.shadowCoord = half4(0, 0, 0, 0);
                #endif

                // 雾&点光源
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                    inputData.fogCoord = input.fogFactorAndVertexLight.x;
                #else
                    inputData.vertexLighting = half3(0, 0, 0);
                    inputData.fogCoord = input.fogFactor.x;
                #endif

                // GI
                #ifdef DYNAMICLIGHTMAP_ON
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, input.normalWS.xyz);
                #else
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, input.normalWS.xyz);
                #endif

                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                
            }

            // -------------------------------------
            // Fragment Shader
            float4 SimpleLitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                SurfaceData surfaceData = (SurfaceData)0;
                InitSurfaceData(input, surfaceData);

                InputData inputData = (InputData)0;
                InitInputData(input, surfaceData.normalTS, inputData);

                half4 color = UniversalFragmentBlinnPhong(inputData, surfaceData);

                return color;
            }
            ENDHLSL
        }

        // -------------------------------------
        // Shadow Pass
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        // -------------------------------------
        // Depth Pass
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // -------------------------------------
        // DepthNormals Pass
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }

        // -------------------------------------
        // Meta Pass
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // -------------------------------------
            // Render State Commands
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaSimple

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitMetaPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}