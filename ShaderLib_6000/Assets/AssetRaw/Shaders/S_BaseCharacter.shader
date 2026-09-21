Shader "URP/Base/S_BaseCharacter"
{
    Properties
    {
        // -------------------------------------------------------------------------------------------------------------
        // Base
        [Main(BaseGroup, _, on, off)] _BaseGroup ("Base Group", Int) = 0
        [MainTexture][Tex(BaseGroup, _BaseColor)] _BaseMap ("Base Map", 2D) = "white" {}
        [HideInInspector] _BaseColor ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // BaseMap2
        [SubToggle(BaseGroup, _BASEMAP2_ON)] _BaseMap2Toggle ("Use Base Map 2", Int) = 0
        [ShowIf(_BaseMap2Toggle, Equal, 1)][Tex(BaseGroup)] _BaseMap2 ("Base Map2", 2D) = "white" {}
        [ShowIf(_BaseMap2Toggle, Equal, 1)][Sub(BaseGroup)] _BaseMap2Switch ("Base Map2 Switch", Range(0.0, 1.0)) = 0.0
        
        // -------------------------------------------------------------------------------------------------------------
        // Metallic & Roughness & Occlusion, Normal
        [Sub(BaseGroup)] _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Tex(BaseGroup)] _MROMap ("MRO Map", 2D) = "white" {}
        [Sub(BaseGroup)] _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        [Sub(BaseGroup)] _Roughness ("Roughness", Range(0.0, 1.0)) = 1.0
        [Sub(BaseGroup)] _Occlusion ("Occlusion", Range(0.0, 2.0)) = 1.0
        [Tex(BaseGroup, _BumpScale)] _BumpMap("Normal Map", 2D) = "bump" {}
        [HideInInspector] _BumpScale("Scale", Float) = 1.0
        [Sub(BaseGroup)] _BaseMapST ("Tile & Offset", Vector) = (1.0, 1.0, 0.0, 0.0)
        
        
        // -------------------------------------------------------------------------------------------------------------
        // Emission
        [Main(EmissionGroup, _EMISSION, off, on)] _EmissionGroup ("Emission Group", Int) = 0
        [Tex(EmissionGroup, _EmissionColor)] _EmissionMap ("Emission Map", 2D) = "white" {}
        [HideInInspector][HDR] _EmissionColor ("Emission Color", Color) = (0.0, 0.0, 0.0, 1.0)
        // EmissionMap2
        [SubToggle(EmissionGroup, _EMISSIONMAP2_ON)] _EmissionMap2Toggle ("Use Emission Map2", Int) = 0
        [ShowIf(_EmissionMap2Toggle, Equal, 1)][Tex(EmissionGroup)] _EmissionMap2 ("Emission Map2", 2D) = "white" {}
        [ShowIf(_EmissionMap2Toggle, Equal, 1)][Sub(EmissionGroup)] _EmissionMap2Switch ("Emission Map2 Switch", Range(0.0, 1.0)) = 0.0
        // Emission Breathe
        [SubToggle(EmissionGroup, _EMISSIONBREATHE_ON)] _EmissionBreathe ("Use Emission Breathe", Int) = 0.0
        [ShowIf(_EmissionBreathe, Equal, 1)][SubToggle(EmissionGroup)] _EmissionBreatheRandomPosition ("Use Emission Breathe Random Position", Int) = 1
        [ShowIf(_EmissionBreathe, Equal, 1)][Sub(EmissionGroup)] _EmissionBreatheParam ("Emission Breathe Param", Vector) = (0.8, 1.2, 0.2, 4.0)    // XY: MinMax, Z:IntervalSeed, W: Speed
        // Emission Scan
        [SubToggle(EmissionGroup, _EMISSIONSCAN_ON)] _EmissionScan ("Emission Scan", Int) = 0.0
        [ShowIf(_EmissionScan, Equal, 1)][Tex(EmissionGroup)] _EmissionScanMap ("Emission Scan Map", 2D) = "white" {}
        [ShowIf(_EmissionScan, Equal, 1)][Sub(EmissionGroup)] _EmissionScanIntensity ("Emission Scan Intensity", Float) = 1.0
        [ShowIf(_EmissionScan, Equal, 1)][SubToggle(EmissionGroup)] _EmissionScanScale ("Emission Scan", Int) = 0.0
        [Tooltip(CenterScale)]
        [Tooltip(XY is MinMax)]
        [Tooltip(Z is SpeedLerpPower)]
        [Tooltip(W is Speed)]
        [Tooltip()]
        [Tooltip(OffsetScan)]
        [Tooltip(XY is Tile)]
        [Tooltip(ZW is Speed)]
        [ShowIf(_EmissionScan, Equal, 1)][Sub(EmissionGroup)] _EmissionScanParam ("Emission Scan Scale Param", Vector) = (12, 0.05, 0.1, 1.0)
        
        // -------------------------------------------------------------------------------------------------------------
        // Distort
        [Main(DistortGroup, _DISTORT_ON, off, on)] _DistortGroup ("Distort Group", Int) = 0
        [Tooltip(R is DistortA)]
        [Tooltip(G is DistortB)]
        [Tooltip(B is Distort Mask)]
        [Tex(DistortGroup)] _DistortMap ("Distort Map", 2D) = "white" {}
        [Sub(DistortGroup)] _DistortMapRStrength ("Distort Map R Strength", Range(0.0, 4.0)) = 1.0
        [Sub(DistortGroup)] _DistortMapGStrength ("Distort Map G Strength", Range(0.0, 4.0)) = 1.0
        [Sub(DistortGroup)] _DistortMapBStrength ("Distort Map B Strength", Range(0.0, 2.0)) = 1.0
        [Sub(DistortGroup)] _DistortMapRTileAndSpeed ("Distort Map R Tile And Speed", Vector) = (1.0, 1.0, 0.0, 0.0)
        [Sub(DistortGroup)] _DistortMapGTileAndSpeed ("Distort Map G Tile And Speed", Vector) = (1.0, 1.0, 0.0, 0.0)
        
        // -------------------------------------------------------------------------------------------------------------
        // Fresnel
        [Main(FresnalGroup, _FRESNEL_ON, off, on)] _FresnelGroup ("Fresnel Group", Int) = 0
        [SubEnum(FresnalGroup, Multiply, 0, Noneee, 1)] _FresnelBlendMode ("Fresnel Blend Mode", Int) = 0
        [Tooltip(CenterScale)]
        [Tooltip(X is Power)]
        [Tooltip(Y is Multiply)]
        [Tooltip(ZW is MinMax)]
        [Sub(FresnalGroup)] _FresnelParam ("Fresnel Param", Vector) = (1.0, 1.0, 0.0, 1.0)
        
        // -------------------------------------------------------------------------------------------------------------
        // Matcap
        [Main(MatcapGroup, _MATCAP_ON, off, on)] _MatcapGroup ("Matcap Group", Int) = 0
        [SubEnum(MatcapGroup, Lerp, 0, Multiply, 1, Add, 2)] _MatcapBlendMode ("Matcap Blend Mode", Int) = 0
        [Tex(MatcapGroup)] _MatcapMap ("Matcap Map", 2D) = "white" {}
        [Sub(MatcapGroup)] _MatcapParam ("Matcap Param", Float) = 1.0
        
        // -------------------------------------------------------------------------------------------------------------
        // Setting
        [Main(SettingGroup, _, on, off)] _SettingGroup ("Setting Group", Float) = 0
        [SubTitle(SettingGroup, Light)]
        [SubToggle(SettingGroup, _RECEIVE_SHADOWS_ON)] _ReceiveShadows ("Receive Shadows", Int) = 1.0
        [SubEnum(SettingGroup, UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Int) = 2
        [Preset(SettingGroup, LWGUI_BlendModePreset)] _BlendMode ("Blend Mode Preset", Float) = 1
        // Blend Mode
        [SubTitle(SettingGroup, Blend Mode, 22)]
        [SubEnum(SettingGroup, UnityEngine.Rendering.BlendOp)]  _BlendOp  ("Blend Op", Float) = 0
        [SubEnum(SettingGroup, UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [SubEnum(SettingGroup, UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [SubEnum(SettingGroup, Off, 0, On, 1)] _ZWriteMode ("ZWrite Mode ", Float) = 1
        [SubEnum(SettingGroup, UnityEngine.Rendering.CompareFunction)] _ZTestMode ("ZTest Mode", Float) = 4
        // Alpha Mode
        [SubTitle(SettingGroup, Alpha, 22)]
        [SubToggle(SettingGroup, _ALPHATEST_ON)] _AlphaTest ("Alpha Clipping", Int) = 1
        [Sub(SettingGroup)][ShowIf(_AlphaTest, Equal, 1)] _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [SubToggle(SettingGroup, _ALPHADITHER_ON)] _AlphaDither ("Alpha Dither", Int) = 0
        [Sub(SettingGroup)][ShowIf(_AlphaDither, Equal, 1)] _AlphaDitherSwitch ("Alpha Dither Switch", Range(0.0, 1.0)) = 1.0
    
        // -------------------------------------------------------------------------------------------------------------
        // State
        [Main(DynamicGroup, _, on, off)] _DynamicGroup ("Dynamic Group", Float) = 0
        // Character
        [SubTitle(DynamicGroup, Character, 22)]
        [NonModifiableTextureData][Tex(DynamicGroup)] _ChaBuffMap ("Cha Buff Map", 2D) = "white" {}
        [Sub(DynamicGroup)][HDR] _StateColor ("State Color", Color) = (1.0, 0.4455, 0.0308, 1.0)
        [Sub(DynamicGroup)] _StateSwitch ("State Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)][HDR] _AttackColor ("Attack Color", Color) = (1.0, 1.0, 1.0, 0.0)
        [Sub(DynamicGroup)] _AttackSwitch ("Attack Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)] _DissolveSwitch ("Dissolve Switch", Range(0.0, 1.0)) = 1.0
        [Sub(DynamicGroup)] _DissolveColorSwitch ("Dissolve Color Switch", Range(0.0, 2.0)) = 1.0
        [Sub(DynamicGroup)] _CritSwitch ("Crit Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)] _ThumpSwitch ("Thump Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)] _ScanSwitch ("Scan Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)] _FrozenSwitch ("Frozen Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)] _WaterSwitch ("Water Switch", Range(0.0, 1.0)) = 0.0
        [Sub(DynamicGroup)] _TouchSwitch ("Touch Switch", Range(0.0, 1.0)) = 0.0
        [SubToggle(DynamicGroup, _TOUGHNESS_ON)] _Toughness ("Toughness Toggle", Int) = 1
        [Sub(DynamicGroup)] _ToughnessSwitch ("Toughness Switch", Range(0.0, 1.0)) = 0.0
        // Other
        [SubTitle(DynamicGroup, Other, 22)]
        [SubToggle(DynamicGroup, _OUTLINE_ON)] _OutlineSwitch ("Outline Switch", Int) = 1
        [Sub(DynamicGroup)] _OutlineSize ("Outline Size", Range(0.0, 8.0)) = 1.0
        [Sub(DynamicGroup)] _LocalBrightnessSwitch ("Local Brightness Switch", Range(0.0, 1.0)) = 0.0
        [SubToggle(DynamicGroup)] _GlobalIntensityParamOn ("Global Intensity Param On", Int) = 1
        
        
//        // Specular vs Metallic workflow
//        _WorkflowMode("WorkflowMode", Float) = 1.0
//
//        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
//        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

//        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

//        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
//        _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0
//
//        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
//        _MetallicGlossMap("Metallic", 2D) = "white" {}
//
//        _SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
//        _SpecGlossMap("Specular", 2D) = "white" {}

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

//        _BumpScale("Scale", Float) = 1.0
//        _BumpMap("Normal Map", 2D) = "bump" {}
//
//        _Parallax("Scale", Range(0.005, 0.08)) = 0.005
//        _ParallaxMap("Height Map", 2D) = "black" {}
//
//        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
//        _OcclusionMap("Occlusion", 2D) = "white" {}
//
//        [HDR] _EmissionColor("Color", Color) = (0,0,0)
//        _EmissionMap("Emission", 2D) = "white" {}

//        _DetailMask("Detail Mask", 2D) = "white" {}
//        _DetailAlbedoMapScale("Scale", Range(0.0, 2.0)) = 1.0
//        _DetailAlbedoMap("Detail Albedo x2", 2D) = "linearGrey" {}
//        _DetailNormalMapScale("Scale", Range(0.0, 2.0)) = 1.0
//        [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}

        // SRP batching compatibility for Clear Coat (Not used in Lit)
//        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
//        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0

//        // Blending state
//        _Surface("__surface", Float) = 0.0
//        _Blend("__blend", Float) = 0.0
//        _Cull("__cull", Float) = 2.0
//        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
//        [HideInInspector] _SrcBlend("__src", Float) = 1.0
//        [HideInInspector] _DstBlend("__dst", Float) = 0.0
//        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
//        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
//        [HideInInspector] _ZWrite("__zw", Float) = 1.0
//        [HideInInspector] _BlendModePreserveSpecular("_BlendModePreserveSpecular", Float) = 1.0
//        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
//        [HideInInspector] _AddPrecomputedVelocity("_AddPrecomputedVelocity", Float) = 0.0
//        [HideInInspector] _XRMotionVectorsPass("_XRMotionVectorsPass", Float) = 1.0

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0

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
        }
        
        HLSLINCLUDE
        #include "Input/SIH_StylizedCharacterInput.hlsl"
        ENDHLSL

        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWriteMode]
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            // #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            // #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _EMISSION
            // #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            // #pragma shader_feature_local_fragment _SPECULAR_SETUP

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _SCREEN_SPACE_IRRADIANCE
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            // #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
            ENDHLSL
        }

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
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite[_ZWriteMode]
            ZTest LEqual
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitGBufferPassVertex
            #pragma fragment LitGBufferPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_IRRADIANCE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            // #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GBufferOutputFormat.hlsl"
            ENDHLSL
        }

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
            Cull[_CullMode]

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
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
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
            // #pragma shader_feature_local _PARALLAXMAP
            // #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            // #pragma multi_compile _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
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
            #pragma fragment UniversalFragmentMetaLit

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            // #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            // #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "MotionVectors"
            Tags { "LightMode" = "MotionVectors" }
            ColorMask RG

            HLSLPROGRAM
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_vertex _ADD_PRECOMPUTED_VELOCITY

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ObjectMotionVectors.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}
