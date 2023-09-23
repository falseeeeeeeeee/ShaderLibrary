Shader "URP/Geometry/S_Wireframe"
{
    Properties 
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0, 0, 0, 0)
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        _LineColor ("Line Color", Color) = (0, 0, 0, 1)
        _LineThinckness ("Line Thinckness", Float) = 1

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

        Pass {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" } 

            Cull [_CullMode]
            Blend SrcAlpha OneMinusSrcAlpha
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 4.0

            #pragma require geometry
            #pragma multi_compile_instancing

            #pragma geometry WireframeGeometry
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _BaseColor;
			uniform float4 _BaseMap_ST;
			uniform half4 _LineColor;
			uniform half _LineThinckness;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			
            // 顶点着色器输入
            struct Attributes
			{
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 顶点着色器输出
            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //几何着色器输出
            struct GeometryToFragment
            {
                float4 positionHCS : POSITION;
                float2 uv : TEXCOORD0;
                float3 dist : TEXCOORD1; 
            };

            // 顶点着色器
            Varyings vert (Attributes input)
			{
                Varyings output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                return output;
            }

            [maxvertexcount(3)]
            void WireframeGeometry (triangle Varyings p[3], inout TriangleStream<GeometryToFragment> triStream)
            {
                //计算点在屏幕空间中的位置:首先positionCS中的值还没有进行其次除法，需要先除以positionCS.w转换为
				//NDC坐标，范围[-1,1]，然后*0.5+0.5后转为[0,1],最后乘以_ScreenParams转换为最终的屏幕空间位置
                float2 p0 = _ScreenParams.xy * (p[0].positionHCS.xy / p[0].positionHCS.w * 0.5 + 0.5);
                float2 p1 = _ScreenParams.xy * (p[1].positionHCS.xy / p[1].positionHCS.w * 0.5 + 0.5);
                float2 p2 = _ScreenParams.xy * (p[2].positionHCS.xy / p[2].positionHCS.w * 0.5 + 0.5);
               
                //edge vectors
                float2 v0 = p2 - p1;
                float2 v1 = p2 - p0;
                float2 v2 = p1 - p0;

                //area of the triangle
                float area = abs(v1.x*v2.y - v1.y * v2.x);

                //values based on distance to the edges
                float dist0 = area / length(v0);
                float dist1 = area / length(v1);
                float dist2 = area / length(v2);
               
				GeometryToFragment input;
               
                //add the first point
                input.positionHCS = p[0].positionHCS;
                input.uv = p[0].uv;
                input.dist = float3(dist0,0,0);
                triStream.Append(input);

                //add the second point
                input.positionHCS =  p[1].positionHCS;
                input.uv = p[1].uv;
                input.dist = float3(0,dist1,0);
                triStream.Append(input);
               
                //add the third point
                input.positionHCS = p[2].positionHCS;
                input.uv = p[2].uv;
                input.dist = float3(0,0,dist2);
                triStream.Append(input);
            }


            //片段着色器
            half4 frag(GeometryToFragment input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;

                //find the smallest distance
                float val = min( input.dist.x, min( input.dist.y, input.dist.z));
               
                //calculate power to 2 to thin the line
                val = exp2( -1/_LineThinckness * val * val );

                //丢弃不在边线上的
                if (val < 0.5f) discard;
                
                return _LineColor + baseColor;
            } 
            ENDHLSL
        }
    }
}


/*

Shader "BRP/Base/Geometry"
{
    Properties
    {
        _MainTex ("颜色图", 2D)             = "white" {}
		_SplatMap("分布图",2D)               = "white" {}
		_BladeHeightRandom("随机高度系数",float) = 1.0
		_BladeHeight("基础高度",float)           = 1.0
		_BladeWidthRandom("随机宽度系数",float)  = 1.0
		_BladeWidth("基础宽度",float)            = 1.0
		_TopColor("上部颜色",color)          = (1.0,1.0,1.0,1.0)
		_BottomColor("下部颜色",color)       = (1.0,1.0,1.0,1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geo

            #include "UnityCG.cginc"


		    sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _SplatMap;
            float4 _SplatMap_ST;
			float _BladeHeightRandom;
			float _BladeHeight;
			float _BladeWidthRandom;
			float _BladeWidth;
		    fixed4 _TopColor;
			fixed4 _BottomColor;

	      float3x3 AngleAxis3x3(float angle, float3 axis)
		  {
			float s, c;
			sincos(angle, s, c);
			float x = axis.x;
			float y = axis.y;
			float z = axis.z;
			return float3x3(
				x * x + (y * y + z * z) * c, x * y * (1 - c) - z * s, x * z * (1 - c) - y * s,
				x * y * (1 - c) + z * s, y * y + (x * x + z * z) * c, y * z * (1 - c) - x * s,
				x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z + (x * x + y * y) * c
				);
		   }
		   float rand(float3 seed)
		   {
			 float f = sin(dot(seed, float3(4.258, 178.31, 63.59)));
			 f  = frac(f * 43785.5453123);
			 return f;
		    }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;
            };

			struct geometryOutput
			{
			    float4 pos:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

           

            v2f vert (appdata v)
            {
                v2f o;
				o.uv=v.uv;
				o.vertex=v.vertex;
				o.normal=v.normal;
				o.tangent=v.tangent;
                return o;
            }

			 geometryOutput CreateGeoOutput(float3 pos,float2 uv){
			    geometryOutput o;
				float4 poin=float4(pos.x-0.5,pos.y,pos.z-0.5,1);//这里是为了修正了下草生成的中心点
				o.pos=UnityObjectToClipPos(pos);
				o.uv=uv;
				return o;
			 }


			 [maxvertexcount(3)]
			 void geo(triangle v2f IN[3]:SV_POSITION,inout TriangleStream<geometryOutput>triStream){
			     float3 pos = IN[0].vertex;
				 float2 uv  = IN[0].uv;
				 float3 vNormal   = IN[0].normal;
				 float4 vTangent  = IN[0].tangent;
				 float3 vBinormal = cross(vNormal,vTangent)*vTangent.w;
				
				 float4 spl = tex2Dlod(_SplatMap,float4(uv,1.0,1.0));//读取一张遮罩图用来表现草地分布
				 float height     = ((rand(pos.xyz))*_BladeHeightRandom+_BladeHeight)*spl.g;
				 float width      = ((rand(pos.xyz))*_BladeWidthRandom+_BladeWidth)*spl.g;
			 
			     float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos)*UNITY_TWO_PI,float3(0,0,1));
				 float3x3 TBN     = float3x3(
				    vTangent.x, vBinormal.x, vNormal.x,
				    vTangent.y, vBinormal.y, vNormal.y,
				    vTangent.z, vBinormal.z, vNormal.z
				 );

			    float3x3 transformationMat = mul(TBN,facingRotationMatrix);
                geometryOutput o;
			    triStream.Append(CreateGeoOutput(pos+mul(transformationMat,float3(width,0,0)),float2(0,0)));
			    triStream.Append(CreateGeoOutput(pos+mul(transformationMat,float3(-width,0,0)),float2(1,0)));
				triStream.Append(CreateGeoOutput(pos+mul(transformationMat,float3(0,0,height)),float2(0.5,1)));
			 }


            fixed4 frag (geometryOutput i) : SV_Target
            {
                fixed4 color = lerp(_BottomColor, _TopColor, i.uv.y);
				return color;
            }
            ENDCG
        }
		Pass
			{
				Tags{"LightMode" = "ForwardBase"}
				Cull Off
				CGPROGRAM
				#pragma target 4.0
				#pragma vertex vert
				#pragma fragment frag

				sampler2D _MainTex;

	       struct appdata
            {
                float4 vertex : POSITION;
				float4 normal : NORMAL;
				float3 tangent: TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

		    v2f vert (appdata v)
            {
                v2f o;
                o.pos    = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);
				o.uv=v.uv;
                return o;
            }


				fixed4 frag(v2f i) : SV_Target
				{
					
					 fixed4 col = tex2D(_MainTex, i.uv);
                     return col;
				}
				ENDCG
			}
    }    
}

*/