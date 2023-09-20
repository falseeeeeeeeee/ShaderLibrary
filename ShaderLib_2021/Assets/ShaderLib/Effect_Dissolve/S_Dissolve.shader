Shader "URP/Effect/S_Dissolve" 
{
    Properties 
    {
        _MainCol ("MainCol", Color)      = (1, 1, 1, 1)
        _MainTex ("MainTex", 2D)         = "white"{}
    	_DissTex ("DissTex", 2D)         = "white"{}
        [HDR]_DissCol ("DissCol", Color) = (1, 1, 1, 1)
        _DissInt ("DissInt",  Range(0.0, 1.0)) = 0.5
    	_DissAdd ("DissAdd",  Range(0.0, 1.0)) = 0.05
        _Cutoff  ("Cutoff",  Range(0.0, 1.0)) = 0.5
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="AlphaTest"                 
            "RenderType"="TransparentCutout"  
        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
		uniform half4 _MainCol;
		uniform half4 _MainTex_ST;
        uniform half4 _DissCol;
		uniform half4 _DissTex_ST;
        uniform half  _DissInt;
        uniform half  _DissAdd;
        uniform half   _Cutoff;
        CBUFFER_END
		
		TEXTURE2D(_MainTex);	    SAMPLER(sampler_MainTex);
		TEXTURE2D(_DissTex);	    SAMPLER(sampler_DissTex);
		
        struct a2v
		{
            float4 vertex : POSITION;       // 顶点位置
            float2 uv     : TEXCOORD0;      // UV信息
        };

        struct v2f
		{
            float4 pos   : SV_POSITION;     // 顶点位置
            float2 uv    : TEXCOORD0;       // UV信息
            float2 dissuv    : TEXCOORD1;       // UV信息
        };
        ENDHLSL			

        Pass {
            Name "FORWARD"
            Tags { "LightMode"="UniversalForward" } 
            
            Cull back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            v2f vert (a2v v)
			{
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);   // 顶点位置 OS>CS
                o.uv  = TRANSFORM_TEX(v.uv,_MainTex);           // UV信息 
                o.dissuv  = TRANSFORM_TEX(v.uv,_DissTex);       // UV信息 
                return o;
            }

            half4 frag(v2f i) : COLOR
			{
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
			    half4 var_DissTex = SAMPLE_TEXTURE2D(_DissTex, sampler_DissTex, i.dissuv);

				//half DissInt = _DissInt;
				half DissInt = sin(frac(_Time.y * _DissInt) * TWO_PI) * 0.5 +0.5;
				
				half noise = step(DissInt, var_DissTex.r) ;
				half noiseBig = step(DissInt, saturate(var_DissTex.r + _DissAdd));
				half noiseOut = noiseBig - noise;
				
                half3 finalRGB =  lerp(var_MainTex.rgb, _DissCol.rgb, noiseOut) * _MainCol.rgb ;
                half opacity = noiseBig * var_MainTex.a;
                clip(opacity - _Cutoff);
                return half4(finalRGB, opacity);
            }
            ENDHLSL
        }
    }
}
