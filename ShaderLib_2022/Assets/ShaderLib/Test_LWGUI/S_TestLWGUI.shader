Shader "URP/Test/S_TestLWGUI"
{
    Properties
    {
        [Title(Base Group)][Space(6)]
        [Main(BaseGroup, _, on, off)] _BaseGroup ("BaseGroup", Int) = 0
        [Tex(BaseGroup, _BaseColor)] _BaseMap ("BaseMap", 2D) = "white" {}
        [HideInInspector] _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [Tex(BaseGroup, _BaseMapChannel)] _BaseMap2 ("BaseMap", 2D) = "white" {}
        [HideInInspector] _BaseMapChannel("BaseMap Channel", Vector) = (0, 0, 0, 1)
        [Color(BaseGroup, _Color2, _Color3, _Color4)] _Color1 ("Color", Color) = (1, 0, 0, 1)
        [HideInInspector] _Color2 ("Color", Color) = (0, 1, 0, 1)
        [HideInInspector] _Color3 ("Color", Color) = (0, 0, 1, 1)
        [HideInInspector] _Color4 ("Color", Color) = (1, 1, 1, 1)
        [Channel(BaseGroup)] _Channel("Channel", Vector) = (0, 0, 0, 1)
        [Ramp(BaseGroup, T_RampMap, Assets.ShaderLib.Test_LWGUI, 512)] _Ramp ("Ramp Map", 2D) = "white" {}

        
        [Title(Sub Group)][Space(6)]
        [Main(SubGroup, _, on, off)] _SubGroup ("Sub Group", Int) = 0
        [SubToggle(SubGroup)] _Toggle ("Sub Toggle", Int) = 0
        [SubToggle(SubGroup, _TOGGLE_KEYWORD)] _Toggle2 ("Sub Toggle", Int) = 0

        [SubPowerSlider(SubGroup, 4)] _PowerSlider ("Power Slider", Range(0, 1)) = 0
        [SubIntRange(SubGroup)] _IntSlider ("Int Slider", Range(0, 10)) = 0

        [MinMaxSlider(SubGroup, _MinMaxSliderStart, _MinMaxSliderEnd)] _MinMaxSlider ("Min Max Slider", Range(0, 1)) = 1
        [HideInInspector] _MinMaxSliderStart ("Start", Range(0.0, 0.5)) = 0.0
        [HideInInspector] _MinMaxSliderEnd ("End", Range(0.5, 1.0)) = 1.0
        
        [Title(Enum)][Space(6)]
        //        [KWEnum(Name1, _KEY1, Name2, _KEY2, Name3, _KEY3)] _KWEnum ("KWEnum", float) = 0
        //        [ShowIf(_KWEnum, Equal, 0)] _key1_Float1 ("Key1 Float", float) = 0
        //        [ShowIf(_KWEnum, Equal, 1)] _key2_Float2 ("Key2 Float", float) = 0.5
        //        [ShowIf(_KWEnum, Equal, 2)] _key3_Float3 ("Key3 Float", float) = 1
        [KWEnum(SubGroup, Name1, _KEY1, Name2, _KEY2, Name3, _KEY3)] _KWEnum ("KWEnum", Float) = 0
        [Sub(SubGroup_KEY1)] _key1_Float1 ("Key1 Float", Float) = 0
        [Sub(SubGroup_KEY2)] _key2_Float2 ("Key2 Float", Float) = 0.5
        [Sub(SubGroup_KEY3)] _key3_Float3 ("Key3 Float", Float) = 1
        [SubEnum(SubGroup, Name1, 0, Name2, 1, Name3, 2)] _SubEnum ("Sub Enum", Float) = 0
        [SubKeywordEnum(SubGroup, Key1, Key2)] _SubKeywordEnum ("Sub Keyword Enum", Float) = 0
        
        [Title(Setting Group)][Space(6)]
        [Main(SettingsGroup, _, on, off)] _SettingGroup ("Setting Group", Float) = 0
		[Preset(SettingsGroup, LWGUI_BlendModePreset)] _BlendMode ("Blend Mode Preset", Float) = 0
        [SubToggle(SubGroup, _ALPHATEST_ON)] _AlphaTest ("Alpha Clipping", Int) = 0
        [Sub(SubGroup)][ShowIf(_AlphaTest, Equal, 1)] _Cutoff ("Threshold", Range(0.0, 1.0)) = 0.5
		[SubEnum(SettingsGroup, UnityEngine.Rendering.BlendOp)]  _BlendOp  ("BlendOp", Float) = 0
		[SubEnum(SettingsGroup, UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
		[SubEnum(SettingsGroup, UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
		[SubEnum(SettingsGroup, Off, 0, On, 1)] _ZWriteMode ("ZWriteMode ", Float) = 1
		[SubEnum(SettingsGroup, UnityEngine.Rendering.CompareFunction)] _ZTestMode ("ZTestMode", Float) = 4
        [SubEnum(SettingsGroup, UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
		[SubEnum(SettingsGroup, RGB, 14, RGBA, 15)] _ColorMask ("ColorMask", Float) = 15
        
        [Title(Decorator Group)][Space(6)]
        [Main(DecoratorGroup, _, on, off)] _DecoratorGroup ("DecoratorGroup", Float) = 0
        [Title(Decorator Group, 22)][Space(6)]
        [Title(DecoratorGroup, Decorator Group)]
        [Title(DecoratorGroup, Decorator Group, 22)]
        [SubTitle(DecoratorGroup, Decorator Group)]
        [SubTitle(DecoratorGroup, Decorator Group, 22)]
        
        [Tooltip(Tooltip, Only Write Engish)]
        [Tooltip()]         // 占一行
        [Tooltip(You Know M3)]
        [Sub(DecoratorGroup)] _TestTooltips ("Test Tooltips#这是中文Tooltip#これは日本語Tooltipです", Float) = 1
        [Helpbox(Test multiline Helpbox)]
        [Helpbox()]
        [Helpbox(You Know M3)]
        [Sub(DecoratorGroup)] _TestHelpbox ("Float with Helpbox%这是中文Helpbox%これは日本語Helpboxです", Float) = 1
        
        [SubToggle(DecoratorGroup)][PassSwitch(UniversalForward)] _PassSwitch ("Pass Switch Group", Float) = 1
        
        [Advanced][Sub(DecoratorGroup)] _AdvancedFloat0 ("Float 0", Float) = 0
        [Advanced][Sub(DecoratorGroup)] _AdvancedFloat1 ("Float 1", Float) = 0
        [Advanced(Advanced Header Test)][Sub(DecoratorGroup)] _AdvancedFloat2 ("Float 2", Float) = 0
        [Advanced][Sub(DecoratorGroup)] _AdvancedFloat3 ("Float 3", Float) = 0
        
        [AdvancedHeaderProperty][Tex(DecoratorGroup, _AdvancedColor0)] _AdvancedTex0 ("Texture 0", 2D) = "white" { }
        [Advanced][HideInInspector] _AdvancedColor0 ("Color 7", Color) = (1, 1, 1, 1)
        [Advanced] _AdvancedRange1 ("Range 1", Range(0, 1)) = 0
        [Hidden] _AdvancedRange2 ("Range 2", Range(0, 1)) = 0
        
        [SubToggle(SubGroup)] _ShowIfToggle0 ("ShowIf Toggle 0", Int) = 0
        [ShowIf(_ShowIfToggle0, Equal, 1)][Sub(DecoratorGroup)] _AdvancedRange3 ("Range 3", Range(0, 1)) = 0
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
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // -------------------------------------
        // Properties Stages
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);

        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float4 _BaseMapChannel;
            float _Cutoff;
            float _Float;
            float _key1_Float1;
            float _key2_Float2;
            float _key3_Float3;
            float _SubEnum;
            float _Advancedfloat7;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Unlit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            BlendOp [_BlendOp]
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWriteMode]
            ZTest [_ZTestMode]
            Cull [_CullMode]
            ColorMask [_ColorMask]
            
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _KEY1 _KEY2 _KEY3
            #pragma shader_feature _SUBKEYWORDENUM_KEY1 _SUBKEYWORDENUM_KEY2

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // -------------------------------------
            // Includes


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fogFactor : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                output.positionCS = TransformWorldToHClip(positionInputs.positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                
                half3 color = baseMap.rgb;
                half alpha = baseMap.a * _BaseColor.a;

                #ifdef _ALPHATEST_ON
                    clip(alpha - _Cutoff);
                #endif

                color.rgb = MixFog(color.rgb, input.fogFactor);

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}