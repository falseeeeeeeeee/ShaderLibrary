Shader "URP/Tool/S_ScreenUV" 
{
    Properties 
    {
        _MainCol ("MainCol", Color)  = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("MainTex", 2D)     = "white"{}
        _ScreenTex ("ScreenTex", 2D) = "white"{}
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"               // 渲染队列 半透明
            "RenderType"="Transparent"          // AlphaBlend
            "ForceNoShadowCasting"="True"       // 关闭阴影投射
            "IgnoreProjector"="True"            // 不响应投射器
        }

        Pass 
        {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 
            
            Cull back
            Blend One OneMinusSrcAlpha

			HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
			uniform half4   _MainCol;
			uniform float4  _MainTex_ST;
			uniform float4  _ScreenTex_ST;
            CBUFFER_END

			TEXTURE2D(_MainTex);	    SAMPLER(sampler_MainTex);
			TEXTURE2D(_ScreenTex);	    SAMPLER(sampler_ScreenTex);
			
            struct a2v
			{
                float4 vertex : POSITION;       // 顶点位置
                float2 uv     : TEXCOORD0;      // UV信息
            };

            struct v2f
			{
                float4 pos   : SV_POSITION;     // 顶点位置
                float2 uv    : TEXCOORD0;       // UV信息
                float2 ScreenUV : TEXCOORD1;    // 屏幕UV
            };

            v2f vert (a2v v)
			{
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);   // 顶点位置 OS>CS
                o.uv  = TRANSFORM_TEX(v.uv,_MainTex);
                float3 posWS = TransformObjectToWorld(v.vertex.xyz);
                float3 posVS = TransformWorldToView(posWS);                       // 顶点位置 OS>VS
                float3 oposWS = TransformObjectToWorld(float3(0.0,0.0,0.0));
                float  originDist = TransformWorldToView(oposWS).z;               // 原点位置 OS>VS
                o.ScreenUV = posVS.xy / posVS.z;            // VS空间畸变校正
                o.ScreenUV *= originDist;                   // 纹理大小按距离锁定
                o.ScreenUV = o.ScreenUV * _ScreenTex_ST.xy - frac(_Time.x * _ScreenTex_ST.zw);  // 启用屏幕纹理ST
                return o;
            }

            half4 frag(v2f i) : COLOR
			{
                // 采样贴图
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
			    half  var_ScreenTex = SAMPLE_TEXTURE2D(_ScreenTex, sampler_ScreenTex, i.ScreenUV).r;
                // 最终混合
                half3 finalRGB =  var_MainTex.rgb * _MainCol.rgb;
                half opacity = var_MainTex.a * _MainCol.a * var_ScreenTex;
                return half4(finalRGB * opacity , opacity);
            } 
            ENDHLSL
        }
    }
}