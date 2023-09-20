Shader "URP/Tool/S_Billboard"
{
      Properties
      {
            _MainTex("MainTex",2D)="white"{}
            [HDR]_BaseColor("BaseColor",Color)=(1,1,1,1)
            _Rotate("Rotate",Range(0,3.14))=0
            _PivotOffset("Pivot Offset",Vector)=(0,0,0,0)
      }
      SubShader
      {
            Tags
            {
                  "RenderPipeline"="UniversalRenderPipeline"
                  "RenderType" = "Transparent"
                  "Queue" ="Transparent"
            }
            HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            float _Rotate;
            float4 _PivotOffset;
            
            CBUFFER_END
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct a2v
            {
                  float4 positionOS:POSITION;
                  float2 texcoord:TEXCOORD;
            };
            struct v2f
            {
                  float4 positionCS:SV_POSITION;
                  float2 texcoord:TEXCOORD;
                  float4 color:COLOR;
            };
            ENDHLSL

            pass
            {
                  Tags
                  {
                        "LightMode"="UniversalForward" 
                  }
                  Blend SrcAlpha OneMinusSrcAlpha
                  ZWrite off
                  ZTest always  

                  HLSLPROGRAM
                  #pragma vertex VERT
                  #pragma fragment FRAG
                  
                  v2f VERT(a2v i)
                  {
                        v2f o;
                        o.texcoord=TRANSFORM_TEX(i.texcoord,_MainTex);
                        float4 pivotWS=mul(UNITY_MATRIX_M,float4(_PivotOffset.xyz,1));
                        float4 pivotVS=mul(UNITY_MATRIX_V,pivotWS);
                        float ScaleX=length(float3(UNITY_MATRIX_M[0].x,UNITY_MATRIX_M[1].x,UNITY_MATRIX_M[2].x));
                        float ScaleY=length(float3(UNITY_MATRIX_M[0].y,UNITY_MATRIX_M[1].y,UNITY_MATRIX_M[2].y));
                        //float ScaleZ=length(float3(UNITY_MATRIX_M[0].z,UNITY_MATRIX_M[1].z,UNITY_MATRIX_M[2].z));//暂时不用上
                        //定义一个旋转矩阵
                        float2x2 rotateMatrix={cos(_Rotate),-sin(_Rotate),sin(_Rotate),cos(_Rotate)};
                        //用来临时存放旋转后的坐标
                        float2 pos=i.positionOS.xy*float2(ScaleX,ScaleY);
                        pos=mul(rotateMatrix,pos);
                        float4 positionVS= pivotVS+float4(pos,0,1);//深度取的轴心位置深度，xy进行缩放
                        o.positionCS=mul(UNITY_MATRIX_P,positionVS);

                        float sampleCounts=3;//这个值越大，线性插值精度越高，计算量也越大
                        float singeAxisCounts=2*sampleCounts+1;
                        float totalCounts=pow(singeAxisCounts,2);
                        float passCounts=0;
                        float sampleRange=0.2;//中心区域的比例
                        float pivotDepth=-pivotVS.z;//取相机空间轴心的线性深度
                        float4 pivotCS=mul(UNITY_MATRIX_P,pivotVS);//得到裁剪空间的轴心位置
                        for(int x=-sampleCounts;x<=sampleCounts;x++)
                        {
                        for(int y=-sampleCounts;y<=sampleCounts;y++)
                        {
                        float2 samplePosition=pivotCS.xy+o.positionCS.xy*sampleRange*float2(x,y)/singeAxisCounts;//裁剪空间的采样位置
                        float2 SSuv=samplePosition/o.positionCS.w*0.5+0.5;//把裁剪空间手动透除，变换到NDC空间下，并根据当前平台判断是否翻转y轴
                        #ifdef UNITY_UV_STARTS_AT_TOP
                        SSuv.y=1-SSuv.y;
                        #endif
                              
                        if(SSuv.x<0||SSuv.x>1||SSuv.y<0||SSuv.y>1)
                        continue;//如果满足跳出本次循环进入下次循环
                        float sampleDepth=SAMPLE_TEXTURE2D_LOD(_CameraDepthTexture,sampler_CameraDepthTexture,SSuv,0).x;//采样当前像素点的深度值
                        sampleDepth=LinearEyeDepth(sampleDepth,_ZBufferParams);//把它变换到线性空间
                        passCounts+=sampleDepth>pivotDepth?1:0;//把采样点的深度和模型的轴心深度进行对比  
                        }
                        }
                        //o.positionCS=passCounts<1?float4(999,999,999,1):o.positionCS;//如果一个点也没通过，则把裁剪空间的坐标丢远些,但是有bug
                        o.color=_BaseColor*_BaseColor.a;
                        o.color*=passCounts/totalCounts;
                        o.color*=smoothstep(0.1,2,pivotDepth);//在考虑个深度方向的蒙板，深度小于0.1时，完全不可见，深度大于2时，可见；
                        return o;
                  }
                  
                  half4 FRAG(v2f i):SV_TARGET
                  {
                        half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);
                        return tex*i.color;
                  }
                  ENDHLSL
            }
      }
}