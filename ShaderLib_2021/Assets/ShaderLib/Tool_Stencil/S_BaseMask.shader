Shader "URP/Effect/S_BaseMask"
{
    Properties 
    {
        _Hue ("Adjustment Hue", Range(-1.0, 1.0)) = 0.0
        _Saturation ("Adjustment Saturation", Range(-1.0,1.0)) = 0.0
        _Value ("Adjustment Value", Range(-1.0,1.0)) = 0.0

        _TopColor   ("Top Color",   Color) = (1.0,  0.45, 0.55, 1.0)
        _DownColor  ("Down Color",  Color) = (0.45, 0.55, 0.8,  1.0)
        _FrontColor ("Front Color", Color) = (1.0,  0.15, 0.25, 1.0)
        _BackColor  ("Back Color",  Color) = (0.35, 0.45, 0.65, 1.0)        
        _LeftColor  ("Left Color",  Color) = (0.6,  0.25, 0.25, 1.0)
        _RightColor ("Right Color", Color) = (0.25, 0.25, 0.45, 1.0)

        [Toggle] _EnableColorShadow ("Enable ColorShadow", Float) = 1.0
        _ColorShadowInstensity ("ColorShadowInstensity", Range(0.0, 2.0)) = 1.0 

        [IntRange] _Stencil ("Stencil ID", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 4

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 

            Cull [_CullMode]

            Stencil
            {
                Ref [_Stencil]
                Comp [_StencilComp]
            }
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma shader_feature _ENABLECOLORSHADOW_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half _Hue;
			uniform half _Saturation;
			uniform half _Value;

			uniform half4 _TopColor;
			uniform half4 _DownColor;
			uniform half4 _FrontColor;
			uniform half4 _BackColor;
			uniform half4 _LeftColor;
			uniform half4 _RightColor;

			uniform half _EnableColorShadow;
			uniform half _ColorShadowInstensity;
            CBUFFER_END
			
            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 normalOS : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //HSL
            float3 rgb2hsv(float3 c) 
            {
              float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
              float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
              float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

              float d = q.x - min(q.w, q.y);
              float e = 1.0e-10;
              return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 hsv2rgb(float3 c) 
            {
              c = float3(c.x, clamp(c.yz, 0.0, 1.0));
              float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
              float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
              return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS.xyz);
                output.normalOS = input.normalOS;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //????????
                half3 normalWS = input.normalWS;
                half3 normalOS = input.normalOS;

                half3 NdotT = saturate(dot(normalOS, half3(0.0, 1.0, 0.0))) * _TopColor.rgb;
                half3 NdotD = saturate(dot(normalOS, half3(0.0, -1.0, 0.0))) * _DownColor.rgb;
                half3 NdotF = saturate(dot(normalOS, half3(0.0, 0.0, -1.0))) * _FrontColor.rgb;
                half3 NdotB = saturate(dot(normalOS, half3(0.0, 0.0, 1.0))) * _BackColor.rgb;
                half3 NdotL = saturate(dot(normalOS, half3(1.0, 0.0, 0.0))) * _LeftColor.rgb;
                half3 NdotR = saturate(dot(normalOS, half3(-1.0, 0.0, 0.0))) * _RightColor.rgb;
                half3 color = saturate(NdotT + NdotD + NdotF + NdotB + NdotL + NdotR);
                color = hsv2rgb(rgb2hsv(color) + half3(_Hue, _Saturation, _Value));
                half3 albedo = half3(0.0, 0.0, 0.0);
                
                //Light
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = normalize(mainLight.direction);
                float lightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 Ambient = SampleSH(normalWS);

                //HalfLambert
                #if _ENABLECOLORSHADOW_ON
                float halfLambert = saturate(dot(lightDir, normalWS) * 0.5 + 0.5);
                albedo = saturate(color * halfLambert * _ColorShadowInstensity);
                #endif

                return half4(albedo * (lightShadow +  Ambient) + color, 1.0);
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
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}
