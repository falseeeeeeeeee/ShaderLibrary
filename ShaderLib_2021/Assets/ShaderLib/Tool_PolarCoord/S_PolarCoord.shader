Shader "URP/Tool/S_PolarCoord" 
{
    Properties 
    {
        _MainCol  ("MainCol",  Color)    = (1, 1, 1, 1)
        _MainTex  ("MainTex",  2D)       = "white"{}
    	_Speed    ("Speed",    Range(-10, 10)) = 1
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
			uniform half4  _MainCol;
			uniform float4 _MainTex_ST;
			uniform half   _Speed;
            CBUFFER_END

			TEXTURE2D(_MainTex);	    SAMPLER(sampler_MainTex);
			
            struct a2v
			{
                float4 vertex : POSITION;       // 顶点位置
                float4 color  : COLOR;          // 顶点颜色
            	float2 uv     : TEXCOORD0;      // UV信息
            	            	
            };

            struct v2f
			{
                float4 pos   : SV_POSITION;     // 顶点位置
                float4 color : TEXCOORD0;       // 顶点颜色
                float2 uv   : TEXCOORD1;        // 颜色贴图
            };

            v2f vert (a2v v)
			{
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);   // 顶点位置 OS>CS
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);           // 颜色贴图
            	o.color  = v.color;                             // 顶点颜色
                return o;
            }

			//极坐标方法
			float2 RectToPolar(float2 uv, float2 centerUV)
			{
                uv = uv - centerUV;
                float theta = atan2(uv.y, uv.x);    // atan()值域[-π/2, π/2]一般不用; atan2()值域[-π, π]
                float r = length(uv);
                return float2(theta, r);
            }
			
            half4 frag(v2f i) : COLOR
			{
				 // 直角坐标转极坐标
                float2 thetaR = RectToPolar(i.uv, float2(_MainTex_ST.xy/2));
                // 极坐标转纹理采样UV
                float2 polarUV = float2(
                    thetaR.x / 3.141593 * 0.5 + 0.5,    // θ映射到[0, 1]
                    thetaR.y + frac(_Time.y * _Speed)      // r随时间流动
                );
                // 采样贴图
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, polarUV.xy+0.5);    
                // 混合颜色
                half3 finalRGB =  var_MainTex.rgb * _MainCol.rgb * i.color.rgb;
                // 混合透明
                half opacity = var_MainTex.a * _MainCol.a * i.color.a;
			    
                return half4(finalRGB * opacity , opacity);
            } 
            ENDHLSL
        }
    }
}