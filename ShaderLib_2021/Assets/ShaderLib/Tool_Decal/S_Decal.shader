Shader "URP/Tool/S_Decal"

{

      Properties
      {
            _MainTex("MainTex",2D)="white"{}
            _BaseColor("BaseColor",Color)=(1,1,1,1)
            _EdgeStretchPrevent("EdgeStretchPrevent",Range(-1,1))=0
      }

      SubShader
      {
            Tags
            {
                  "RenderPipeline"="UniversalRenderPipeline"
                  "RenderType"="Overlay"
                  "Queue"="Transparent-499"
                  "DisableBatch"="True"
            }
            
            HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            float _EdgeStretchPrevent;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct a2v
            {
                  float4 positionOS:POSITION;
            };
            struct v2f
            {
                  float4 positionCS:SV_POSITION;
                  float4 SStexcoord:TEXCOORD;
                  float3 cameraPosOS:TEXCOORD1;
                  float4 cam2vertexRayOS:TEXCOORD2;
            };
            
            ENDHLSL
            
            pass
            {
                  Blend SrcAlpha OneMinusSrcAlpha
                  Tags
                  {
                        "LightMode"="UniversalForward"
                  }

                  HLSLPROGRAM
                  #pragma vertex VERT
                  #pragma fragment FRAG
                  #pragma target 3.0

                  v2f VERT(a2v i)
                  {
                        v2f o;
                        o.positionCS=TransformObjectToHClip(i.positionOS.xyz);
                        o.SStexcoord.xy=o.positionCS.xy*0.5+0.5*o.positionCS.w;
                  
                        #ifdef UNITY_UV_STARTS_AT_TOP
                        o.SStexcoord.y=o.positionCS.w-o.SStexcoord.y;
                        #endif

                        o.SStexcoord.zw=o.positionCS.zw;
                        float4 posVS=mul(UNITY_MATRIX_V,mul(UNITY_MATRIX_M,i.positionOS));//得到相机空间顶点坐标
                        o.cam2vertexRayOS.w=-posVS.z;//相机空间下的z是线性深度，取负
                        o.cam2vertexRayOS.xyz=mul(UNITY_MATRIX_I_M,mul(UNITY_MATRIX_I_V,float4(posVS.xyz,0))).xyz;//忽略平移矩阵 当成向量处理
                        o.cameraPosOS=mul(UNITY_MATRIX_I_M,mul(UNITY_MATRIX_I_V,float4(0,0,0,1))).xyz;//计算模型空间下的相机坐标

                        return o;

                  }

                  half4 FRAG(v2f i):SV_TARGET

                  {
                        float2 SSUV=i.SStexcoord.xy/i.SStexcoord.w;//在片元里进行透除
                        float SSdepth=LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,SSUV).x,_ZBufferParams);
                        i.cam2vertexRayOS.xyz/=i.cam2vertexRayOS.w;//在片元里进行透除
                        float3 decalPos=i.cameraPosOS+i.cam2vertexRayOS.xyz*SSdepth;//模型空间下的计算：相机坐标+相机朝着顶点的射线（已透除）*相机空间的线性深度
                        //return float4(decalPos,1);
                        //裁剪不需要的地方
                        float mask=(abs(decalPos.x)<0.5?1:0)*(abs(decalPos.y)<0.5?1:0)*(abs(decalPos.z)<0.5?1:0);
                        float3 decalNormal=normalize(cross(ddy(decalPos),ddx(decalPos)));
                        //return float4(decalNormal,1);
                        mask*=decalNormal.y>0.2*_EdgeStretchPrevent?1:0;//边缘拉伸的防止阈值
                        float2 YdecalUV=decalPos.xz+0.5;
                        //return float4(YdecalUV,0,1);
                        float4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,YdecalUV)*mask;
                        //tex.a=mask;
                        return tex;
                  }
                  ENDHLSL
            }
      }
} 