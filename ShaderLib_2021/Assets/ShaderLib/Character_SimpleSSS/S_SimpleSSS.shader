Shader "URP/Character/S_SimpleSSS"
{
    Properties
    {
        [Header(Base)][Space(6)]
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Header(SSS)][Space(6)]
        _InteriorColor ("Interior Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _FrontSubsurfaceDistortion ("Front Subsurface Distortion", Range(0, 1)) = 0.5
        _BackSubsurfaceDistortion ("Back Subsurface Distortion", Range(0, 1)) = 0.5
        _FrontSssIntensity ("Front SSS Intensity", Range(0, 1)) = 0.2
        _BackSssIntensity ("Back Sss Intensity", Range(0, 1)) = 0.2
        _InteriorColorPower ("Interior Color Power", Range(0,5)) = 2

        [Header(Specular)][Space(6)]
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Specular ("Specular", Range(0,1)) = 0.5
        _Gloss ("Gloss", Range(0.01,1) ) = 0.5
        
        [Header(Matcap)] [Space(4)]
        [Toggle(_USEMATCAPMAP)] _UseMatcapMap ("Use Matcap Map", Float) = 0.0
        _MatcapMapOpacity ("Matcap Map Opacity", Range(0.0, 1.0) ) = 1.0
        [Enum(None,0,Overwrite,1,Multiply,2,Additive,3,Mix,4,Screen,5,Overlay,6)] _MatcapBlendMode ("Matcap Blend Mode", Range(0, 6)) = 1
        [NoScaleOffset] _MatcapMap ("Matcap Map", 2D) = "white" {}
        _MatcapMapHue ("Matcap Map Hue", Range(0.0, 1.0) ) = 1.0
        _MatcapMapSaturation ("Matcap Map Saturation", Range(0.0, 4.0) ) = 1.0
        _MatcapMapLightness ("Matcap Map Lightness", Range(0.0, 4.0) ) = 1.0
        
        [Header(Rim)][Space(6)]
        _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower("Rim Power", Range(0.0, 36)) = 0.1
        _RimIntensity("Rim Intensity", Range(0, 1)) = 0.2
        
        [Header(Other)][Space(6)]
        [Enum(None,0,VertexColor,1,SSSMask,2,Lambert,3)] _DebugColor ("Debug Color", Range(0, 2)) = 0
        [Toggle] _ALPHACUT("AlphaCut", Int) = 1
        _Cutoff ("Cutoff",  Range(0.0, 1.0)) = 0.5
        _LambertEdgeSoft ("LambertEdge Soft", Float) = 1.0
        _LambertEdgeOffset ("LambertEdge Offset", Range(-1.0, 1.0)) = 0.0
        _LambertLightColor ("LambertLight Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _LambertShadowColor ("LambertShadow Color", Color) = (0.0, 0.0, 0.0, 1.0)

        [ToggleOff]_Receive_Shadows("Receive Shadows", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "AlphaTest"
            "RenderType" = "Opaque"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST, _MatcapMap_ST;
        float4 _BaseColor, _InteriorColor, _SpecularColor, _RimColor, _LambertLightColor, _LambertShadowColor;
        half _FrontSubsurfaceDistortion, _BackSubsurfaceDistortion, _FrontSssIntensity, _BackSssIntensity, _InteriorColorPower;
        half _Specular, _Gloss, _RimPower, _RimIntensity;
        half _MatcapBlendMode, _MatcapMapOpacity, _MatcapMapHue, _MatcapMapSaturation, _MatcapMapLightness;
        half _DebugColor, _Cutoff, _LambertEdgeSoft, _LambertEdgeOffset;
        CBUFFER_END

        TEXTURE2D(_BaseMap);	        SAMPLER(sampler_BaseMap);
        TEXTURE2D(_MatcapMap);	        SAMPLER(sampler_MatcapMap);

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
            #pragma multi_compile_instancing
            
            // My keywords
            #pragma shader_feature _USEMATCAPMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature _ALPHACUT_ON
            #pragma shader_feature _RECEIVE_SHADOWS_OFF 

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../Include/SIH_CustomFunction.hlsl"


            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float3 color : COLOR;
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
                float3 color : TEXCOORD10;
                float3 viewDirWS : TEXCOORD5;
            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                float4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
            #else
                half  fogFactor : TEXCOORD6;
            #endif
                half2 normalizedScreenSpaceUV : TEXCOORD7;
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
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                output.color = input.color;
                // VertexLight Fog
                half fogFactor = 0;
            #if !defined(_FOG_FRAGMENT)
                    fogFactor = ComputeFogFactor(output.positionHCS.z);
            #endif
            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                output.fogFactorAndVertexLight = float4(fogFactor, VertexLighting(vertexInput.positionWS, output.normalWS.rgb));
            #else
                output.fogFactor = fogFactor;
            #endif
                output.normalizedScreenSpaceUV = float2(0,0);
                // Light
                    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #ifdef DYNAMICLIGHTMAP_ON
                    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                    // Shadow
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                
                return output;
            }

            half3 CustomLightingLambert(half3 lightColor, half3 lightDir, half3 normal)
            {
                half customLambert = saturate(dot(normal, lightDir));
                return lightColor * customLambert;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Light
                float3 bakeGI = SampleSH(input.normalWS);

                #if defined(DYNAMICLIGHTMAP_ON)
                    bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, input.normalWS);
                #else
                    bakeGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, input.normalWS);
                #endif
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                #else
                    float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                input.normalWS = NormalizeNormalPerPixel(input.normalWS);
                Light mainLight = GetMainLight(shadowCoord);
                half3 mainLightDir = normalize(mainLight.direction);
                half lambert = max(dot(input.normalWS, mainLightDir), 0);
                half3 customLambert = lerp(_LambertShadowColor.rgb, _LambertLightColor.rgb, abs(pow(saturate(dot(input.normalWS, mainLightDir)*0.5+0.5 - _LambertEdgeOffset),_LambertEdgeSoft)));
                half3 mainLightColor = mainLight.color;
                float mainLightShadow = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
                mainLightShadow = lerp(1.0,mainLightShadow,lambert);
                #if defined(_SCREEN_SPACE_OCCLUSION)
                if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_AMBIENT_OCCLUSION))
                {
                    input.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionHCS);
                    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(input.normalizedScreenSpaceUV, 1);
                    bakeGI *= aoFactor.indirectAmbientOcclusion * aoFactor.directAmbientOcclusion;
                    mainLightColor *= aoFactor.indirectAmbientOcclusion * aoFactor.directAmbientOcclusion;
                }
                #endif
                
                half3 diffuseLight = mainLightColor * mainLight.distanceAttenuation * customLambert * mainLightShadow;
                // half3 diffuseLight = CustomLightingLambert(mainLightColor * mainLight.distanceAttenuation, mainLight.direction, input.normalWS) * mainLightShadow;
                half3 specularLight = LightingSpecular(mainLightColor * mainLight.distanceAttenuation, mainLight.direction, normalize(input.normalWS), normalize(input.viewDirWS), _SpecularColor, _Gloss) * mainLightShadow;
                //计算附加光照
                float3 adddiffuseLight = float3(0,0,0);
                float3 addspecularLight = float3(0,0,0);
                float addlightShadow = 0;
                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS.xyz,shadowCoord);
                    addlightShadow = light.shadowAttenuation * light.distanceAttenuation;
                    adddiffuseLight += LightingLambert(light.color, light.direction, input.normalWS) * addlightShadow;
                }
                #endif
            #if defined(_ADDITIONAL_LIGHTS_VERTEX)
                adddiffuseLight += input.fogFactorAndVertexLight.yzw;
            #endif
                
                // Toon
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                
                float3 nDirVS = mul((float3x3)UNITY_MATRIX_V, input.normalWS);    // 计算视角方向法线

                //////////////////////
                /// // Directional light SSS
                float sssValue = SubsurfaceScattering ( input.viewDirWS, mainLightDir, input.normalWS, 
                    _FrontSubsurfaceDistortion, _BackSubsurfaceDistortion,
                    _FrontSssIntensity, _BackSssIntensity);
                half3 sssColor = lerp(_InteriorColor.rgb, mainLightColor, saturate(pow(sssValue, _InteriorColorPower))).rgb * sssValue;
                
                // Diffuse
                half4 albedo = baseMap * _BaseColor;
                half4 unlitCol = baseMap * _InteriorColor * 0.5;
                half3 diffCol = lerp(unlitCol.rgb, albedo.rgb, customLambert).rgb;   // SSSMask加在这里
                // diffCol = albedo.rgb;
                

                // Specular
                float specularPow = exp2((1 - _Gloss) * 10.0 + 1.0);
                float3 specularColor = ColorAlphaStrength(_SpecularColor, 1.0);
                float3 halfVector = normalize (mainLightDir + input.viewDirWS);
                float3 directSpecular = pow (max (0,dot (halfVector, input.normalWS)), specularPow) * specularColor * _Specular;
                float3 specular = directSpecular * mainLightColor;

                // Matcap
            #ifdef _USEMATCAPMAP
                half3 matcapMap = SAMPLE_TEXTURE2D(_MatcapMap, sampler_MatcapMap, nDirVS.rg * 0.5 + 0.5).rgb;
                matcapMap = RgbToHsv(matcapMap);
                matcapMap.x += _MatcapMapHue;
                matcapMap.y *= _MatcapMapSaturation;
                matcapMap.z *= _MatcapMapLightness;
                matcapMap = HsvToRgb(saturate(matcapMap));
                diffCol.rgb = MatcapBlend(diffCol.rgb, matcapMap, _MatcapMapOpacity, _MatcapBlendMode);
            #endif
                
                // Rim
                float rimValue = 1.0 - max(0, dot(input.normalWS, input.viewDirWS));
                float3 rimCol = lerp(_InteriorColor.rgb, mainLightColor, rimValue) * pow(abs(rimValue), _RimPower) * _RimIntensity;  
                
                // final color
                float3 diffColor = diffCol * (diffuseLight + adddiffuseLight);                    // 计算漫反射颜色
                float3 specColor = diffCol * specular * (specularLight + addspecularLight);       // 计算镜面反射颜色
                float3 DirectLightResult = diffColor + specColor;                           // 计算直接光照结果
                float3 IndirectResult = bakeGI * diffCol;
                // return ((DirectLightResult)).rgbr;
                half3 color = sssColor + DirectLightResult + IndirectResult + rimCol;
                half alpha = input.color.r;

                // Fog
            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                half fogFactor = input.fogFactorAndVertexLight.x;
            #else
                half fogFactor = input.fogFactor;
            #endif
            #ifdef _ALPHACUT_ON
                clip(alpha - _Cutoff);
            #endif

                float4 result = float4(color, alpha);

                // Debug
                switch (_DebugColor)
                {
                    case 1:     // VertexColor
                        result = float4(input.color, 1);
                        break;
                    case 2:     // SSSMask
                        result = float4(sssValue.rrr, 1);
                        break;
                    case 3:     // Lambert
                        result = float4(customLambert.rrr, 1);
                        break;
                    default:
                        break;
                }
                return result;
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

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            
            #pragma shader_feature _ALPHACUT_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float3 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 color : COLOR;
                float4 positionCS : SV_POSITION;
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

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.color = input.color;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                // Texture
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);

                // half alpha = baseMap.a * _BaseColor.a;
                half alpha = input.color.r;
            #ifdef _ALPHACUT_ON
                clip(alpha - _Cutoff);
            #endif
                return float4(0,0,0, alpha);
            }
            
            ENDHLSL
        }
        

        // DepthPass
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			struct Attributes
			{
			    float4 position     : POSITION;
			    float2 texcoord     : TEXCOORD0;
                float4 color        : COLOR;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
			    float2 uv           : TEXCOORD0;
			    float4 positionCS   : SV_POSITION;
			    float4 color        : COLOR;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			    UNITY_VERTEX_OUTPUT_STEREO
			};
            
            half Alpha(half albedoAlpha, half4 color, half cutoff, half vertexColor)
			{
			
			    half alpha = color.a * vertexColor;

			#if defined(_ALPHATEST_ON)
			    clip(alpha - cutoff);
			#endif

			    return alpha;
			}

			Varyings DepthOnlyVertex(Attributes input)
			{
			    Varyings output = (Varyings)0;
			    UNITY_SETUP_INSTANCE_ID(input);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
			    output.positionCS = TransformObjectToHClip(input.position.xyz);
                output.color = input.color;
			    return output;
			}
			half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
			{
			    return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
			}
			half4 DepthOnlyFragment(Varyings input) : SV_TARGET
			{
			    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
			
			    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff, input.color.r);
			    return 0;
			}
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
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
            Cull[_CullMode]

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
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Includes
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float4 tangentOS      : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float3 normal       : NORMAL;
                float4 color        : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD1;
                half3 normalWS     : TEXCOORD2;

                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                half4 tangentWS    : TEXCOORD4;    // xyz: tangent, w: sign
                #endif

                half3 viewDirWS    : TEXCOORD5;

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS     : TEXCOORD8;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            half Alpha(half albedoAlpha, half4 color, half cutoff, half vertexColor)
			{
			
			    half alpha = color.a * vertexColor;

			#if defined(_ALPHATEST_ON)
			    clip(alpha - cutoff);
			#endif

			    return alpha;
			}

			half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
			{
			    return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
			}

            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color      = input.color;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                output.normalWS = half3(normalInput.normalWS);
                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                    float sign = input.tangentOS.w * float(GetOddNegativeScale());
                    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                #endif

                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                    output.tangentWS = tangentWS;
                #endif

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
                    output.viewDirTS = viewDirTS;
                #endif

                return output;
            }

            void DepthNormalsFragment( Varyings input, out half4 outNormalWS : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff, input.color.r);

                #ifdef LOD_FADE_CROSSFADE
                    LODFadeCrossFade(input.positionCS);
                #endif

                #if defined(_GBUFFER_NORMALS_OCT)
                    float3 normalWS = normalize(input.normalWS);
                    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
                    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
                    half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
                    outNormalWS = half4(packedNormalWS, 0.0);
                #else
                    float2 uv = input.uv;
       
                        float3 normalWS = input.normalWS;
                    #endif

                    outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);

                #ifdef _WRITE_RENDERING_LAYERS
                    uint renderingLayers = GetMeshRenderingLayer();
                    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                #endif
            }
            ENDHLSL
        }

    }
}