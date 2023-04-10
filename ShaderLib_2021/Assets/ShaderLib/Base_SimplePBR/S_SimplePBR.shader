Shader "URP/Base/S_SimplePBR"
{
    Properties
    {
        [Header(Base)] [Space(6)]
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
        [NoScaleOffset] _MetallicGlossMap ("Metallic Smoothness Map", 2D) = "white" {}
        _BumpScale ("Normal Scale", Float) = 1.0
        [Normal] [NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        [NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0)
        [NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}
        // [ToggleUI] _AlphaTest("Use Alpha Cutoff", Int) = 0.0
        // _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
                
        [Header(Other)] [Space(6)]
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
        float _Metallic;
        float _Smoothness;
        float _BumpScale;
        float _OcclusionStrength;
        float3 _EmissionColor;
        half _Cutoff;
        CBUFFER_END

        TEXTURE2D(_BaseMap);	        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
        TEXTURE2D(_MetallicGlossMap);	SAMPLER(sampler_MetallicGlossMap);
        TEXTURE2D(_EmissionMap);	    SAMPLER(sampler_EmissionMap);
        TEXTURE2D(_OcclusionMap);	    SAMPLER(sampler_OcclusionMap);
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
                half occlusionMap = LerpWhiteTo(SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv).g, _OcclusionStrength);;

                surfaceData.albedo = baseMap.rgb;
                surfaceData.alpha = baseMap.a;
                surfaceData.emission = emissionMap;                
                surfaceData.metallic = _Metallic * metallicGlossMap.r;
                surfaceData.occlusion = occlusionMap;
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

            #include "../Include/SIH_SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            
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

            #include "../Include/SIH_SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            
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
            
            #include "../Include/SIH_SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            
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
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _EMISSION

            #include "../Include/SIH_SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"
            
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}