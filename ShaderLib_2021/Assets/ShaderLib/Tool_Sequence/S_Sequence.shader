Shader "URP/Tool/S_Sequence" 
{
    Properties 
    {
        _MainCol  ("MainCol",  Color)    = (1, 1, 1, 1)
        _MainTex  ("MainTex",  2D)       = "white"{}
        _Sequence ("Sequence", 2D)       = "gray"{}      // 序列帧图
        _RowCount ("RowCount", Int)      = 2             // 行数
        _ColCount ("ColCount", Int)      = 2             // 列数
    	_SequID   ("SequID",   Int)      = 0             // 序号
        _Speed    ("Speed",    Range(-10, 10)) = 0		 // 速度
    	[Space(10)]
    	[KeywordEnum(BILLBOARD_ON,BILLBOARD_OFF)]_BILLBOARD_SWITCH("Billboard_Switch",float)=1 //定义一个是否开启Billboard
    	[KeywordEnum(LOCK_Z,FREE_Z)]_Z_STAGE("Z_Stage",float)=1//定义一个是否锁定Z轴
    	
    	
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
            
            Cull off
            Blend One OneMinusSrcAlpha

			HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature_local _Z_STAGE_LOCK_Z
			#pragma shader_feature_local _BILLBOARD_SWITCH_BILLBOARD_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			

            CBUFFER_START(UnityPerMaterial)
			uniform half4     _MainCol;
			uniform float4    _MainTex_ST;
			uniform float4    _Sequence_ST;
			uniform half	  _RowCount;
			uniform half	  _ColCount;
			uniform half	  _SequID;
			uniform half	  _Speed;
            CBUFFER_END

			TEXTURE2D(_MainTex);	    SAMPLER(sampler_MainTex);
			TEXTURE2D(_Sequence);	    SAMPLER(sampler_Sequence);
			
            struct a2v
			{
                float4 vertex : POSITION;       // 顶点位置
            	float3 normal : NORMAL;			// 法线信息
                float4 color  : COLOR;          // 顶点颜色
            	float2 uv     : TEXCOORD0;      // UV信息
            	            	
            };

            struct v2f
			{
                float4 pos   : SV_POSITION;     // 顶点位置
                float4 color : TEXCOORD0;       // 顶点颜色
                float2 uv0   : TEXCOORD1;       // 颜色贴图
            	float2 uv1   : TEXCOORD2;       // 序列帧图
            };

            v2f vert (a2v v)
			{
                v2f o;
                //先构建一个新的Z轴朝向相机的坐标系，这时我们需要在模型空间下计算新的坐标系的3个坐标基
                //由于三个坐标基两两垂直，故只需要计算2个即可叉乘得到第三个坐标基
                //先计算新坐标系的Z轴
                float3 newZ=TransformWorldToObject(_WorldSpaceCameraPos);//获得模型空间的相机坐标作为新坐标的z轴
                #ifdef _Z_STAGE_LOCK_Z		//判断是否开启了锁定Z轴  
                newZ.y=0;
                #endif
                newZ=normalize(newZ);
                //根据Z的位置去判断x的方向
                float3 newX= abs(newZ.y)<0.99?cross(float3(0,1,0),newZ):cross(newZ,float3(0,0,1));
                newX=normalize(newX);
                float3 newY=cross(newZ,newX);
                newY=normalize(newY);
                float3x3 Matrix={-newX,newY,newZ};		// 这里应该取矩阵的逆 但是hlsl没有取逆矩阵的函数(newX取负值镜像一下)    
                float3 newpos=mul(v.vertex.xyz,Matrix); // 故在mul函数里进行右乘 等同于左乘矩阵的逆（正交阵的转置等于逆）

            	o.pos = TransformObjectToHClip(v.vertex.xyz);   // 顶点位置 OS>CS
            	
            	#ifdef _BILLBOARD_SWITCH_BILLBOARD_ON		//判断是否开启了锁定Z轴  
                o.pos = TransformObjectToHClip(newpos);     // 顶点位置 VS>CS
                #endif
                
            	
            	
            	o.color  = v.color;                             // 顶点颜色
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);          // 颜色贴图
            	o.uv1 = TRANSFORM_TEX(v.uv, _Sequence);			// 序列帧图 float2(-v.uv.x,v.uv.y)
            	
				// float id  = floor(_SequID + _Time.y * _Speed);
				// float idV = floor(id / _ColCount);				// 计算V轴id    全舍(序号/列数)
				// float idU = id - idV * _ColCount;				// 计算U轴id    序号-列号*列数
				// float stepU = 1.0 / _ColCount;					// 计算U轴步幅
				// float stepV = 1.0 / _RowCount;					// 计算V轴步幅
				// float2  initUV = o.uv1 * float2(stepU, stepV) + float2(0.0, stepV * (_ColCount - 1.0));   // 计算初始UV
				// o.uv1 = initUV + float2(idU * stepU, -idV * stepV);
            	
				float id  = floor(_SequID + _Time.y * _Speed);
				o.uv1.x = o.uv1.x / _ColCount + (id - floor(id / _ColCount) * _ColCount) / _ColCount;
				o.uv1.y = o.uv1.y / _RowCount + 1 / _RowCount * (_ColCount - 1.0) - floor(id / _ColCount) / _RowCount;

				// o.uv1.x = o.uv1.x/_ColCount + frac(floor(_Time.y*_Speed+_SequID)/_ColCount);
				// o.uv1.y = o.uv1.y/_RowCount+1-frac(floor((_Time.y*_Speed+_SequID)/_ColCount)/_RowCount);

                return o;
            }

            half4 frag(v2f i) : COLOR
			{
                // 采样贴图 RGB颜色 A透贴
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
				half4 var_Sequence = SAMPLE_TEXTURE2D(_Sequence, sampler_Sequence, i.uv1);      
                // 混合颜色
				half3 finalLerp = lerp(var_Sequence.rgb , var_MainTex.rgb , 1-var_Sequence.a);
                half3 finalRGB =  finalLerp * _MainCol.rgb * i.color.rgb;
                // 混合透明
                half opacity = var_MainTex.a * _MainCol.a * i.color.a;
			    
                return half4(finalRGB * opacity , opacity);
            } 
            ENDHLSL
        }
    }
}