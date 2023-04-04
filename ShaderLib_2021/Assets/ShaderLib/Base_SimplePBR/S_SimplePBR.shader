Shader "URP/Base/S_SimplePBR"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
        [NoScaleOffset] _MetallicGlossMap ("Metallic Smoothness Map", 2D) = "white" {}
        _BumpScale ("Normal Scale", Float) = 1.0
        [Normal] [NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0)
        [NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}
        // [ToggleUI] _AlphaTest("Use Alpha Cutoff", Int) = 0.0
        // _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
        
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            "Queue" = "Geometry"
            // "Queue" = "AlphaTest"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        half4 _BaseColor;
        float4 _BaseMap_ST;
        float _BumpScale;
        float _Metallic;
        float _Smoothness;
        float3 _EmissionColor;
        half _Cutoff;
        CBUFFER_END

        TEXTURE2D(_BaseMap);	        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_BumpMap);          SAMPLER(sampler_BumpMap);
        TEXTURE2D(_MetallicGlossMap);	SAMPLER(sampler_MetallicGlossMap);
        TEXTURE2D(_EmissionMap);	    SAMPLER(sampler_EmissionMap);
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            // #pragma shader_feature_local_fragment _ALPHATEST_ON

            // Universal Render Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            // Unity keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
                float2 staticLightmapUV   : TEXCOORD1;
                float2 dynamicLightmapUV  : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
                float3 viewDirWS : TEXCOORD5;
                half fogFactor : TEXCOORD6;
                half3 vertexLight   : TEXCOORD7;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord : TEXCOORD8;
            #endif
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 9);
            #ifdef DYNAMICLIGHTMAP_ON
                float2  dynamicLightmapUV : TEXCOORD10; // Dynamic lightmap UVs
            #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangent);
                output.normalWS = normalInput.normalWS;
                output.tangentWS = normalInput.tangentWS;
                output.bitangentWS = normalInput.bitangentWS;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);

                // Light
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
            #ifdef DYNAMICLIGHTMAP_ON
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
            #endif
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                output.fogFactor = ComputeFogFactor(output.positionHCS.z);
                output.vertexLight = VertexLighting(output.positionWS, output.normalWS);
                
                // Shadow
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                #endif
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                // SurfaceData
                SurfaceData surfaceData;
                surfaceData.normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv));
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                half4 metallicGlossMap = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
                half3 emissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor;
                surfaceData.albedo = baseMap.rgb;
                surfaceData.alpha = baseMap.a;
                surfaceData.emission = emissionMap;                
                surfaceData.metallic = _Metallic * metallicGlossMap.r;
                surfaceData.occlusion = 1.0;
                surfaceData.smoothness = _Smoothness * metallicGlossMap.a;
                surfaceData.specular = 0.0;
                surfaceData.clearCoatMask = 0.0h;
                surfaceData.clearCoatSmoothness = 0.0h;

                // InputData
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = SafeNormalize(input.viewDirWS);
                inputData.fogCoord = input.fogFactor;
                inputData.vertexLighting = input.vertexLight;
                #if defined(DYNAMICLIGHTMAP_ON)
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
                #else
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
                #endif
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionHCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                // PBR光照计算
                half4 color = UniversalFragmentPBR(inputData, surfaceData);

                // 应用雾效
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                
                return color;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            //#pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

            #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
            #else
                float3 lightDirectionWS = _LightDirection;
            #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #endif

                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                
                output.positionCS = GetShadowPositionHClip(input);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 color = baseMap.rgb * _BaseColor.rgb;
                half alpha = baseMap.a * _BaseColor.a;

                #ifdef _ALPHATEST_ON
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}
            
            Cull[_CullMode]
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.position.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 color = baseMap.rgb * _BaseColor.rgb;
                half alpha = baseMap.a * _BaseColor.a;

                #ifdef _ALPHATEST_ON
                    clip(alpha - _Cutoff);
                #endif
                
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags{"LightMode" = "DepthNormalsOnly"}

            ZWrite On

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT // forward-only variant

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float3 normal       : NORMAL;
                float4 positionOS   : POSITION;
                float4 tangentOS    : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 normalWS     : TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
                output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);

                return output;
            }

            float4 DepthNormalsFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Output...
                #if defined(_GBUFFER_NORMALS_OCT)
                    float3 normalWS = normalize(input.normalWS);
                    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);             // values between [-1, +1], must use fp32 on some platforms
                    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);     // values between [ 0,  1]
                    half3 packedNormalWS = half3(PackFloat2To888(remappedOctNormalWS)); // values between [ 0,  1]
                    return half4(packedNormalWS, 0.0);
                #else
                    return half4(NormalizeNormalPerPixel(input.normalWS), 0.0);
                #endif
            }
            ENDHLSL
        }
        
        
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #pragma shader_feature EDITOR_VISUALIZATION
            //#pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            //#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            //#pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            //#pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            #ifdef _SPECULAR_SETUP
                #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
            #else
                #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
            #endif

            half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
            {
                half4 specGloss;

            #ifdef _METALLICSPECGLOSSMAP
                specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
                #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                    specGloss.a = albedoAlpha * _Smoothness;
                #else
                    specGloss.a *= _Smoothness;
                #endif
            #else // _METALLICSPECGLOSSMAP
                #if _SPECULAR_SETUP
                    specGloss.rgb = _SpecColor.rgb;
                #else
                    specGloss.rgb = _Metallic.rrr;
                #endif

                #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                    specGloss.a = albedoAlpha * _Smoothness;
                #else
                    specGloss.a = _Smoothness;
                #endif
            #endif

                return specGloss;
            }

            half SampleOcclusion(float2 uv)
            {
                #ifdef _OCCLUSIONMAP
                    // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
                    #if defined(SHADER_API_GLES)
                        return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
                    #else
                        half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
                        return LerpWhiteTo(occ, _OcclusionStrength);
                    #endif
                #else
                    return half(1.0);
                #endif
            }


            // Returns clear coat parameters
            // .x/.r == mask
            // .y/.g == smoothness
            half2 SampleClearCoat(float2 uv)
            {
            #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
                half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

            #if defined(_CLEARCOATMAP)
                clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
            #endif

                return clearCoatMaskSmoothness;
            #else
                return half2(0.0, 1.0);
            #endif  // _CLEARCOAT
            }

            void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
            {
            #if defined(_PARALLAXMAP)
                uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
            #endif
            }

            // Used for scaling detail albedo. Main features:
            // - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
            // - No effect is applied if detailAlbedo is 0.5.
            half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
            {
                // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
                // detailAlbedo *= _DetailAlbedoMapScale;
                // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
                // return detailAlbedo * 2.0f;

                // A bit more optimized
                return half(2.0) * detailAlbedo * scale - scale + half(1.0);
            }

            half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
            {
            #if defined(_DETAIL)
                half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;

                // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
            #if defined(_DETAIL_SCALED)
                detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
            #else
                detailAlbedo = half(2.0) * detailAlbedo;
            #endif

                return albedo * LerpWhiteTo(detailAlbedo, detailMask);
            #else
                return albedo;
            #endif
            }

            half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
            {
            #if defined(_DETAIL)
            #if BUMP_SCALE_NOT_SUPPORTED
                half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
            #else
                half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
            #endif

                // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
                // For visual consistancy we going to do in all cases
                detailNormalTS = normalize(detailNormalTS);

                return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
            #else
                return normalTS;
            #endif
            }

            half Alpha(half albedoAlpha, half4 color, half cutoff)
            {
            #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
                half alpha = albedoAlpha * color.a;
            #else
                half alpha = color.a;
            #endif

            #if defined(_ALPHATEST_ON)
                clip(alpha - cutoff);
            #endif

                return alpha;
            }

            half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
            {
                return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
            }

            half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = half(1.0))
            {
            #ifdef _NORMALMAP
                half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
                #if BUMP_SCALE_NOT_SUPPORTED
                    return UnpackNormal(n);
                #else
                    return UnpackNormalScale(n, scale);
                #endif
            #else
                return half3(0.0h, 0.0h, 1.0h);
            #endif
            }

            half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
            {
            #ifndef _EMISSION
                return 0;
            #else
                return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgb * emissionColor;
            #endif
            }

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
                outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

                half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
                outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

            #if _SPECULAR_SETUP
                outSurfaceData.metallic = half(1.0);
                outSurfaceData.specular = specGloss.rgb;
            #else
                outSurfaceData.metallic = specGloss.r;
                outSurfaceData.specular = half3(0.0, 0.0, 0.0);
            #endif

                outSurfaceData.smoothness = specGloss.a;
                outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
                outSurfaceData.occlusion = SampleOcclusion(uv);
                outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

            #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
                half2 clearCoat = SampleClearCoat(uv);
                outSurfaceData.clearCoatMask       = clearCoat.r;
                outSurfaceData.clearCoatSmoothness = clearCoat.g;
            #else
                outSurfaceData.clearCoatMask       = half(0.0);
                outSurfaceData.clearCoatSmoothness = half(0.0);
            #endif

            #if defined(_DETAIL)
                half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
                float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
                outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
                outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
            #endif
            }

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UniversalMetaPass.hlsl"

            half4 UniversalFragmentMetaLit(Varyings input) : SV_Target
            {
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);

                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

                MetaInput metaInput;
                metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
                metaInput.Emission = surfaceData.emission;
                return UniversalFragmentMeta(input, metaInput);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}