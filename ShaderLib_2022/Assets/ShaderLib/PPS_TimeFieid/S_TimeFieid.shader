Shader "Hidden/S_TimeFieid"
{
    Properties
    {
        _ScreenCenterOffsetX ("ScreenCenterOffsetX", Range(0, 1)) = 0.5
        _ScreenCenterOffsetY ("ScreenCenterOffsetY", Range(0, 1)) = 0.5
        _ScreenCenterStrength ("ScreenCenterStrength", Float) = 10
        _ScreenCenterScatter ("ScreenCenterScatter", Float) = 0
        _Concentration ("Concentration", Float) = 100
    }
    SubShader
    {
        Pass
        {
            Name "TimeFieid"
            
            HLSLPROGRAM
            // -------------------------------------
            // Shader Stages
            #pragma vertex Vert
            #pragma fragment CustomFrag

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            // -------------------------------------
            // Properties Stages
            float _ScreenCenterOffsetX;
            float _ScreenCenterOffsetY;
            float _ScreenCenterStrength;
            float _ScreenCenterScatter;
            float _Concentration;

            // -------------------------------------
            // Function
            real3 HSVToRGB(real3 c)
            {
                real4 K = real4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                real3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            real3 RGBToHSV(real3 c)
            {
                real4 K = real4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                real4 p = lerp(real4(c.bg, K.wz), real4(c.gb, K.xy), step(c.b, c.g));
                real4 q = lerp(real4(p.xyw, c.r), real4(c.r, p.yzx), step(p.x, c.r));
                real d = q.x - min(q.w, q.y);
                real e = 1.0e-10;
                return real3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            half4 CustomFrag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);

				#if !UNITY_REVERSED_Z
					_ScreenCenterOffsetY = 1 - _ScreenCenterOffsetY;
                #endif

				// 圆环
			    half2 uvSS = input.texcoord - float2(_ScreenCenterOffsetX, _ScreenCenterOffsetY);
			    uvSS.x = uvSS.x * _ScreenParams.x / _ScreenParams.y;
			    half centerDistanceSquare = dot(uvSS, uvSS);		// 与中心点距离的平方
			    half roundDistanceSquare = (_ScreenCenterScatter * _ScreenCenterScatter - centerDistanceSquare);	// 与圆环距离的平方
				half colorIntensity = saturate(roundDistanceSquare);	// 圆的浓度,其余为黑,实心
				colorIntensity = 1 - pow(1 - colorIntensity, 10);
				half tortIntensity = 1 - saturate(roundDistanceSquare * roundDistanceSquare);	// 扭曲强度
				tortIntensity = pow(tortIntensity, _Concentration) * _ScreenCenterStrength;		// 圆环的宽度
				
			    // 获取BlitTexture
				input.texcoord += tortIntensity * roundDistanceSquare * 0.1 * _ScreenCenterScatter;
                float4 blitTexture = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);

			    // Final
                half3 color = blitTexture.rgb;
				half3 hsvColor = RGBToHSV(color);
                hsvColor.y = saturate(hsvColor.y - colorIntensity);
                color = HSVToRGB(hsvColor);
                half alpha = blitTexture.a;
			    
                return half4(color, alpha);
            } 
            ENDHLSL
        }
    }
}
