
Shader "URP/Cloud/S_ParallaxCloud"
{
    Properties 
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _DownColor ("Down Color", Color) = (1, 1, 1, 1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _OffsetSpeed ("Offset Speed", Vector) = (0.1, 0.1, 0.0, 0.0)
        _HeightOffset ("Height Offset", Range(0.0, 2.0)) = 0.15
        _ViewOffset ("View Offset", Range(-3.0, 3.0)) = 1.0
        _StepLayer ("Step Layer", Range(2, 64)) = 8

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent-50"
            "PreviewType" = "Plane"
            "IgnoreProjector" = "True"
            "ForceNoShadowCasting" = "True"
        }

        Pass {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 

            Blend SrcAlpha OneMinusSrcAlpha
            //Blend One One
            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _BaseColor;
			uniform half4 _DownColor;
			uniform float4 _BaseMap_ST;
            uniform half2 _OffsetSpeed;
            uniform half _HeightOffset;
            uniform half _ViewOffset;
            uniform half _StepLayer;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			
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
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
                float3 viewDirOS : TEXCOORD4;
                float2 uv : TEXCOORD5;
                float2 uv2 : TEXCOORD6;
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
                output.viewDirOS = TransformWorldToObjectDir(normalize(_WorldSpaceCameraPos.xyz - output.positionWS));
                //output.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
                
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS.xyz, input.tangentOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = normalInputs.tangentWS;
                output.bitangent = cross(output.normalWS.xyz, output.tangentWS.xyz) * input.tangentOS.w;

                //output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                //output.tangentWS = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));
                //output.bitangent = cross(output.normalWS,output.tangentWS) * input.tangentOS.w;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap) + frac(_Time.y * float2(_OffsetSpeed.x, _OffsetSpeed.y));
                output.uv2 = input.texcoord;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                //Light
                Light mainLight = GetMainLight();
                real3 lightColor = mainLight.color;

                //viewDirTS
                half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangent.xyz, input.normalWS.xyz);
                float3 viewDirTS = mul(TBN, input.viewDirOS);
                //float3 viewDirTS = normalize(TransformWorldToTangent(input.viewDirWS, TBN));
                viewDirTS.xy *= _HeightOffset;
                viewDirTS.z += _ViewOffset;

                //两张uv，z通道储存深度
                float3 uv = float3(input.uv, 0);        //动态UV
                float3 uv2 = float3(input.uv2, 0);      //静态UV
                //采样一张静态图
                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv2.xy);   
                //使用观察向量
                float3 minOffset = viewDirTS / (viewDirTS.z * _StepLayer);
                //混合贴图
                float var_FiniNoise = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv.xy).r * var_BaseMap.r;

                //保存uv
                float3 prevUV = uv;

                [unroll(100)]
                while(var_FiniNoise > uv.z)
                {
                    uv += minOffset;

                    var_FiniNoise = SAMPLE_TEXTURE2D_LOD(_BaseMap, sampler_BaseMap, uv.xy, 0).r * var_BaseMap.r;
                }

                float d1 = var_FiniNoise - uv.z;
                float d2 = var_FiniNoise - prevUV.z;
                float w = d1 / (d1 - d2 + 0.00000001);
                uv = lerp(uv, prevUV, w);
                half4 resultColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv.xy) * var_BaseMap; 
                //half3 color =  resultColor.rgb * _BaseColor.rgb * lightColor;
                half3 color = lerp(_DownColor.rgb, _BaseColor.rgb, resultColor.rgb) * lightColor;
                
                half rangeClt = var_BaseMap.a * resultColor.r + _BaseColor.a * 2.0;
                half alpha = abs(smoothstep(rangeClt, _BaseColor.a, 1.0));
                alpha = pow(alpha,5);

                return half4(color, alpha);
            } 
            ENDHLSL
        }
    }
}
/*
Shader "Unlit/01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("base color",Color) = (1,1,1,1)
        _BottomColor("Bottom Color",color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.5
        _MoveSpeed ("MoveSpeed", float) = 0.1
        _HeightOffset ("HeightOffset", Range(0, 1)) = 0.15
        _StepLayer ("StepLayer", Range(1, 64)) = 16
        
        _ViewOffset("View offset",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent-50" "RenderPipeline" = "UniversalRenderPipeline" "LightMode" = "UniversalForward"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _Alpha;
        float _MoveSpeed;
        float _HeightOffset;
        float _StepLayer;
        float4 _BottomColor;
        float _ViewOffset;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        struct a2v
        {
            float4 positionOS : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 uv : TEXCOORD0;
        };
        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 uv2 : TEXCOORD1;
            float3 normal : TEXCOORD2;
            float3 tangent : TEXCOORD3;
            float3 bTangent : TEXCOORD4;
            float3 posWS : TEXCOORD5;
            float3 vDir : TEXCOORD6;
        };
        ENDHLSL
        pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull off
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex) + float2(frac(_Time.y * _MoveSpeed), 0);
                o.uv2 = v.uv;
                o.normal = normalize(TransformObjectToWorldNormal(v.normal));
                o.tangent = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                o.bTangent = cross(o.normal,o.tangent) * v.tangent.w;
                o.posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.vDir = TransformWorldToObjectDir(normalize(_WorldSpaceCameraPos.xyz - o.posWS));
                return o;
            }
            half4 FRAG(v2f i) : SV_TARGET
            {

                float3x3 TBN = float3x3(i.tangent,i.bTangent,i.normal);
                float3 vDirTS = mul(TBN,i.vDir);//计算切线空间观察向量

                vDirTS.xy *= _HeightOffset; //添加偏移值
                vDirTS.z += _ViewOffset;

                //两张uv，z通道储存深度
                float3 uv = float3(i.uv,0);//动态uv
                float3 uv2 = float3(i.uv2,0);//静态uv

                //采样一张静态图
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv2.xy);
                
                //使用观察向量
                float3 minOffset = vDirTS / (vDirTS.z * _StepLayer);
                
                //混合贴图
                float finiNoise = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv.xy).r * var_MainTex.r;

                //保存uv
                float3 prev_uv = uv;

                [unroll(200)]
                while(finiNoise >= uv.z)
                {
                    uv += minOffset;
                    finiNoise = SAMPLE_TEXTURE2D_LOD(_MainTex,sampler_MainTex,uv.xy,0).r * var_MainTex.r;
                }
                
                

                float d1 = finiNoise - uv.z;
                float d2 = finiNoise - prev_uv.z;
                float w = d1 / (d1 - d2 + 0.0000001);
                
                uv = lerp(uv,prev_uv,w);
                
                float4 resultColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv.xy) * var_MainTex;
                
                
                float rangeClt = var_MainTex.r * resultColor.r + _Alpha * 1.5;
                
                float Alpha = abs(smoothstep(rangeClt,_Alpha,1.0));
                
                //Alpha = pow(Alpha,5);
                return float4(lerp(_BottomColor.rgb,_BaseColor.rgb,resultColor.rgb),Alpha);


            }
            ENDHLSL
        }
    }
}
*/