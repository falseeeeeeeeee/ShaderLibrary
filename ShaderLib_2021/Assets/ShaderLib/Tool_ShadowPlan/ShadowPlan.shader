Shader "URP/Base/ShadowPlan"
{
    Properties
    {
        [HDR] _BaseColor("Shadow Color", Color) = (0.0, 0.0, 0.0, 0.8)
        //[Toggle] _UseAddLight("Use AddLight Shadows ?", Int) = 0
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

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } 

            Blend SrcAlpha OneMinusSrcAlpha
            //Blend One OneMinusSrcAlpha
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma shader_feature _USEADDLIGHT_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
            uniform float4 _BaseColor;
            uniform float4 _BaseMap_ST;
            CBUFFER_END

            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);

            struct Attributes
			{
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS  : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                
                Light mainlight = GetMainLight(shadowCoord);
                float3 mainlightColor = mainlight.color;  
                float3 mainlightDir = normalize(mainlight.direction);
                float mainlightShadow = mainlight.distanceAttenuation * mainlight.shadowAttenuation;
                /*
                #ifdef _USEADDLIGHT_ON
                    float addlightShadow = 0.0;
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++ lightIndex)
                    {
                        Light addlight = GetAdditionalLight(lightIndex, shadowCoord);
                        float3 addlightColor = addlight.color;  
                        float3 addlightDir = normalize(addlight.direction);
                        addlightShadow = addlight.distanceAttenuation * addlight.shadowAttenuation;
                    }
                #endif
                float lightShadow = mainlightShadow + addlightShadow;
                float ShadowAlpha = 1 - saturate(lightShadow);
                */
                float ShadowAlpha = 1 - saturate(mainlightShadow);
                return float4(_BaseColor.rgb, _BaseColor.a);
            }
            ENDHLSL
        }
        
        Pass
		{
			Name "Shadow"

			//用使用模板测试以保证alpha显示正确
			Stencil
			{
				Ref 0
				Comp equal
				Pass incrWrap
				Fail keep
				ZFail keep
			}

			//透明混合模式
			Blend SrcAlpha OneMinusSrcAlpha

			//关闭深度写入
			ZWrite off

			//深度稍微偏移防止阴影与地面穿插
			Offset -1 , 0

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
			};

			float4 _LightDir;
			float4 _ShadowColor;
			float _ShadowFalloff;

			float3 ShadowProjectPos(float4 vertPos)
			{
				float3 shadowPos;

				//得到顶点的世界空间坐标
				float3 worldPos = mul(unity_ObjectToWorld , vertPos).xyz;

				//灯光方向
				float3 lightDir = normalize(_LightDir.xyz);

				//阴影的世界空间坐标（低于地面的部分不做改变）
				shadowPos.y = min(worldPos .y , _LightDir.w);
				shadowPos.xz = worldPos .xz - lightDir.xz * max(0 , worldPos .y - _LightDir.w) / lightDir.y; 

				return shadowPos;
			}

			v2f vert (appdata v)
			{
				v2f o;

				//得到阴影的世界空间坐标
				float3 shadowPos = ShadowProjectPos(v.vertex);

				//转换到裁切空间
				o.vertex = UnityWorldToClipPos(shadowPos);

				//得到中心点世界坐标
				float3 center =float3( unity_ObjectToWorld[0].w , _LightDir.w , unity_ObjectToWorld[2].w);
				//计算阴影衰减
				float falloff = 1-saturate(distance(shadowPos , center) * _ShadowFalloff);

				//阴影颜色
				o.color = _ShadowColor; 
				o.color.a *= falloff;

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				return i.color;
			}
			ENDCG
		}
    }
}
    
