Shader "URP/Tool/S_PlanarShadow"
{
    Properties
    {
        [Header(Base Color)]
        [MainColor] _BaseColor("_BaseColor", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("_BaseMap (albedo)", 2D) = "white" {}

        [Header(Alpha)]
	    [Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 1
        _Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5 // alpha clip threshold
        
        [Header(Shadow)]
        // _GroundHeight("_GroundHeight", Range(-100, 100)) = 0
        _GroundHeight("_GroundHeight", Float) = 0
        _ShadowColor("_ShadowColor", Color) = (0,0,0,1)
	    _ShadowFalloff("_ShadowFalloff", Range(0,1)) = 0.05

        // Blending state
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }
    SubShader
    {       
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"
        }
        LOD 300

        // 物体自身着色使用URP自带的ForwardLit pass
        USEPASS "Universal Render Pipeline/Lit/ForwardLit"
        
        // Planar Shadows平面阴影
        Pass
        {
            Name "PlanarShadow"

            //用使用模板测试以保证alpha显示正确
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            Cull Off

            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha

            //关闭深度写入
            ZWrite off

            //深度稍微偏移防止阴影与地面穿插
            Offset -1 , 0

            HLSLPROGRAM
            #pragma shader_feature _CLIPPING
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            
            float _GroundHeight;
            float4 _ShadowColor;
            float _ShadowFalloff;
            half4 _BaseColor;
            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            float _Clipping;
            half _Cutoff;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            float3 ShadowProjectPos(float4 vertPos)
            {
                float3 shadowPos;

                //得到顶点的世界空间坐标
                float3 worldPos = mul(unity_ObjectToWorld , vertPos).xyz;

                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);

                //阴影的世界空间坐标（低于地面的部分不做改变）
                shadowPos.y = min(worldPos .y , _GroundHeight);
                shadowPos.xz = worldPos .xz - lightDir.xz * max(0 , worldPos .y - _GroundHeight) / lightDir.y; 

                return shadowPos;
            }

            float GetAlpha (v2f i) {
                float alpha = _BaseColor.a;
                alpha *= tex2D(_BaseMap, i.uv.xy).a;
                return alpha;
            }

            v2f vert (appdata v)
            {
                v2f o;

                //得到阴影的世界空间坐标
                float3 shadowPos = ShadowProjectPos(v.vertex);

                //转换到裁切空间
                // o.vertex = UnityWorldToClipPos(shadowPos);
                o.vertex = TransformWorldToHClip(shadowPos);

                //得到中心点世界坐标
                float3 center = float3(unity_ObjectToWorld[0].w , _GroundHeight , unity_ObjectToWorld[2].w);
                //计算阴影衰减
                float falloff = 1-saturate(distance(shadowPos , center) * _ShadowFalloff);

                //阴影颜色
                o.color = _ShadowColor;
                o.color.a *= falloff;
                
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                if (_Clipping)
                {
                    float alpha = GetAlpha(i);
                    // clip(alpha - _Cutoff);
                    i.color.a *= step(_Cutoff, alpha);
                    // i.color.a = alpha;
                }
                return i.color;
            }
            ENDHLSL
        }
    }
}