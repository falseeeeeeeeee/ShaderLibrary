Shader "URP/Render/S_Ink3" 
{
    Properties 
    {
        [Space(6)][Header(BaseColor)][Space(4)]
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _BaseMap ("BaseMap", 2D) = "white" {}
    	_BaseMapFloor ("Base Map Floor", Float) = 100
        
        [Space(6)][Header(Ramp)][Space(4)]
    	_RampLightColor ("Ramp Light Color", Color) = (1, 1, 1)
    	_RampDarkColor ("Ramp Dark Color", Color) = (0, 0, 0)
        [NoScaleOffset] _RampMap ("Ramp Map", 2D) = "white" {}
		[NoScaleOffset] _StrokeMap ("Stroke Map", 2D) = "white" {}
        _InteriorNoiseMap ("Interior Noise Map", 2D) = "white" {}
        _InteriorNoiseLevel ("Interior Noise Level", Range(0, 1)) = 0.15
    	[Toggle] _RampGguassian ("Ramp Gguassian?", Int) = 1
		_GguassianRadius ("Guassian Blur Radius", Range(0,60)) = 30
        _GuassianResolution ("Guassian Resolution", Float) = 800  
        _GuassianHStep ("Guassian Horizontal Step", Range(0,1)) = 0.5
        _GuassianVStep ("Guassian Vertical Step", Range(0,1)) = 0.5  
    	
    	[Space(6)][Header(Paper)][Space(4)]
        [NoScaleOffset] _PaperMap ("Paper Map", 2D) = "white" {}
        _PaperMapScale ("Paper Map Scale", Float) = 1
    	_PaperStrength ("Paper Strength", Range(0, 1)) = 1
    	[Normal][NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpMapScale ("Normal Map Scale", Float) = 1
    	_BumpMapStrength ("Normal Map Strength", Range(0, 1)) = 1

    	[Space(6)][Header(Shadow)][Space(4)]
        [NoScaleOffset] _NoiseMap ("Noise Map", 2D) = "white" {}
        _NoiseMapScaleA ("Noise Map Scale", Float) = 1
        _NoiseMapScaleB ("Noise Map Scale", Float) = 0.5
    	_NoiseStrength ("Noise Strength", Range(0, 1)) = 1
    	_ShadowInColor ("Shadow In Color", Color) = (0.5, 0.5, 0.5)
    	_ShadowOutColor ("Shadow Out Color", Color) = (0, 0, 0)
    	_ShadowInMinStep ("Shadow In Min Step", Range(0, 1)) = 0
    	_ShadowInMaxStep ("Shadow In Max Step", Range(0, 1)) = 0.5
    	_ShadowOutMinStep ("Shadow Out Min Step", Range(0, 1)) = 0.5
    	_ShadowOutMaxStep ("Shadow Out Max Step", Range(0, 1)) = 1
    	
    	[Space(6)][Header(LineStyle)][Space(4)]
    	[KeywordEnum(SingleColor,Gold,Ink)] _LineStyle ("Line Sytle", Float) = 1
        [NoScaleOffset] _GoldMap ("Gold Map", 2D) = "white" {}
        [NoScaleOffset] _GoldRampMap ("Gold Ramp Map", 2D) = "white" {}
		_GoldFresnelPower ("Gold Fresnel Power", Range(0.1, 10.0)) = 2.0
        _GoldFresnelThred ("Gold Fresnel Thred", Range(0.0, 1.0)) = 0.5
    	_GoldFresnelBrightnessPower ("Gold Fresnel Brightness Power", Range(0.1, 10.0)) = 2.0
        _GoldFresnelBrightnessThred ("Gold Fresnel Brightness Thred", Range(0.0, 0.5)) = 0.2
        [NoScaleOffset] _InkMap ("Ink Map", 2D) = "white" {}
    	_InkMapScale ("Ink Map Scale", Float) = 1.0
    	_InkMapMin ("Ink Map Min", Float) = 0.0
    	_InkMapMax ("Ink Map Max", Float) = 1.0
    	_InkMapFresnelScale ("Ink Map Fresnel Scale", Float) = 1.0
    	_InkFresnelPower ("Ink Fresnel Power", Range(0.1, 10.0)) = 2.0
        _InkFresnelThred ("Ink Fresnel Thred", Range(0.0, 0.5)) = 0.2

    	
        [Space(6)][Header(Rim)][Space(4)]
    	_RimLightWidth("_RimLight Width", Range(0, 20)) = 2
        _RimLightThreshold("_RimLight Threshold", Range(-1, 1)) = 0.05
        _RimLightFadeout("_RimLight Fadeout", Range(0, 1)) = 1
        [HDR] _RimLightTintColor("RimLight Tint Color",Color) = (1,1,1)
        _RimLightBrightness("RimLight Brightness", Range(0, 1)) = 1
        _RimLightStrength("RimLight Strength", Range(0, 1)) = 0.9
        
        [Space(6)][Header(Outline)][Space(4)]
        [Toggle(_OUTLINE_ON)] _UseOutline("Use Outline?", float) = 1
        [Toggle] _OutlineAutoSize ("Outline Auto Size?", Int) = 0
        _OutlineColor ("Outline Color", Color) = (0, 0, 0)
        _OutlineWidth ("Outline Width", Range(0.0, 64.0)) = 0.5
        _OutlineNoiseMap ("Outline Noise Map", 2D) = "white" {}
        _OutlineNoiseWidth ("Outline Noise Width", Range(0.0, 2.0)) = 1.0
		_OutlineNoiseScale ("Outline Noise Scale", Range(0.0, 32.0)) = 1.0
        
        [Space(6)][Header(Other)][Space(4)]
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2
    	[Toggle] _DebugColor("DebugColor", Int) = 0
    	[IntRange] _DebugColorSwitch("DebugColorSwitch", Range(0,20)) = 0

    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
		half4 _BaseColor;
		float4 _BaseMap_ST;
		float _BaseMapFloor;
        
        half3 _RampLightColor;
        half3 _RampDarkColor;
        float4 _InteriorNoiseMap_ST;
        half _InteriorNoiseLevel;
        int _RampGguassian;
        float _GguassianRadius;
        float _GuassianResolution;
        float _GuassianHStep;
        float _GuassianVStep;

        float _PaperMapScale;
        float _PaperStrength;
        float _BumpMapScale;
        float _BumpMapStrength;

        
        float _NoiseMapScaleA;
        float _NoiseMapScaleB;
        float _NoiseStrength;
        float3 _ShadowInColor;
        float3 _ShadowOutColor;
        float _ShadowInMinStep;
        float _ShadowInMaxStep;
        float _ShadowOutMinStep;
        float _ShadowOutMaxStep;

        float _GoldFresnelPower;
        float _GoldFresnelThred;
        float _GoldFresnelBrightnessPower;
        float _GoldFresnelBrightnessThred;
        float _InkMapScale;
        float _InkMapMin;
        float _InkMapMax;
        float _InkMapFresnelScale;
        float _InkFresnelPower;
        float _InkFresnelThred;
        
        float _RimLightWidth;
		float _RimLightThreshold;
		float _RimLightFadeout;
		float3 _RimLightTintColor;
		float _RimLightBrightness;
		float _RimLightStrength;
        
        float4 _OutlineColor;
        float _OutlineWidth;
        float4 _OutlineNoiseMap_ST;
        float _OutlineNoiseWidth;
        float _OutlineNoiseScale;
        
        int _DebugColor;
        int _DebugColorSwitch;
        CBUFFER_END

        TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
        TEXTURE2D(_GoldMap);			SAMPLER(sampler_GoldMap);
		TEXTURE2D(_GoldRampMap);		SAMPLER(sampler_GoldRampMap);
		TEXTURE2D(_InkMap);				SAMPLER(sampler_InkMap);

        // -------------------------------------
        // Function
        // 柔光
        float3 softlight (float3 colA, float3 colB)
		{
			float3 white = float3(1, 1, 1);
			return (white - 2 * colB) * abs(pow(colA, 2)) + 2 * colB * colA;
		}

        // 三平面映射
		float4 TriPlanar(float3 normalWS, float3 positionWS, float3 pivotWS, TEXTURE2D_PARAM(baseMap, sampler_baseMap))
		{
            // 根据法线的 三个轴  ， 生成遮罩
            float3 tempNormal =  pow(abs(normalWS),1);
			float3 maskValue = tempNormal /(tempNormal.x + tempNormal.y + tempNormal.z);	
			float3 tempPos = ((positionWS - pivotWS) * 1).xyz;
			//  xy 平面的像素正常显示 但是  其他轴对应平面的值不正确，所以 乘以 maskValue.z，屏蔽掉其它轴面的值。
			float4 colorZ = SAMPLE_TEXTURE2D(baseMap, sampler_baseMap, tempPos.xy) * maskValue.z;
			float4 colorY = SAMPLE_TEXTURE2D(baseMap, sampler_baseMap, tempPos.xz) * maskValue.y;
			float4 colorX = SAMPLE_TEXTURE2D(baseMap, sampler_baseMap, tempPos.yz) * maskValue.x;
			//  三个轴面的正确结果相加，归一化
			return normalize(colorX + colorY + colorZ); 
		}

        ENDHLSL


        Pass 
        {
            Name "NPR"
            Tags 
            { 
                "LightMode" = "UniversalForward" 
            } 

            // -------------------------------------
            // Render State Commands
            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

			TEXTURE2D(_RampMap);	        SAMPLER(sampler_RampMap);
			TEXTURE2D(_StrokeMap);	        SAMPLER(sampler_StrokeMap);
			TEXTURE2D(_InteriorNoiseMap);	SAMPLER(sampler_InteriorNoiseMap);
			TEXTURE2D(_PaperMap);			SAMPLER(sampler_PaperMap);
			TEXTURE2D(_BumpMap);			SAMPLER(sampler_BumpMap);
			TEXTURE2D(_NoiseMap);			SAMPLER(sampler_NoiseMap);
            
            // -------------------------------------
            // Material Keywords
            #pragma multi_compile __ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile __ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile __ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile __ _SHADOWS_SOFT
            #pragma shader_feature _RAMPGGUASSIAN_ON
            #pragma shader_feature _LINESTYLE_SINGLECOLOR _LINESTYLE_GOLD _LINESTYLE_INK
            #pragma shader_feature _POSITIONANIMATION_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            	float4 tangent	  : TANGENT;
                float2 texcoord   : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS   : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 pivotWS		: TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
            	float3 tangentWS	: TEXCOORD3;
                float3 bitangentWS	: TEXCOORD4;
                float2 uv           : TEXCOORD5;
				float2 uvNoise      : TEXCOORD6;
				float2 uvBase       : TEXCOORD7;
                half fogFactor      : TEXCOORD8; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = positionInputs.positionWS;
            	output.pivotWS = mul(UNITY_MATRIX_M, float4(0, 0, 0, 1)).xyz;
                
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = normalInputs.tangentWS;
                output.bitangentWS = normalInputs.bitangentWS;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.uvNoise = TRANSFORM_TEX(input.texcoord, _InteriorNoiseMap);
                output.uvBase = input.texcoord;

                output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                output.positionCS = TransformWorldToHClip(positionInputs.positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(input);
				// Base
				float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv)  * _BaseColor;
				float tooniness = _BaseMapFloor;
				baseMap.rgb = saturate(floor(baseMap.rgb * tooniness) / tooniness);
				
			    // Vector
			    float3 positionWS = input.positionWS;
			    float3 pivotWS = input.pivotWS;
				half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uvBase * _BumpMapScale), _BumpMapStrength);
				float3 normalWS = normalize(input.normalWS);
                normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
			    float3 normalVS = normalize(TransformWorldToViewDir(input.normalWS));
			    float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

				// ShadowNoise
				float shadowNoiseMapA = TriPlanar(normalWS, positionWS/100 * _NoiseMapScaleA, pivotWS, TEXTURE2D_ARGS(_NoiseMap, sampler_NoiseMap)).r * 0.5;
				float shadowNoiseMapB = TriPlanar(normalWS, positionWS/100 * _NoiseMapScaleB, pivotWS, TEXTURE2D_ARGS(_NoiseMap, sampler_NoiseMap)).r * 0.5;

				float shadowNoiseMap = ((shadowNoiseMapA + shadowNoiseMapB) * 2 - 1) * _NoiseStrength;
				float3 shadowNoisePosition = float3(shadowNoiseMap, 0, shadowNoiseMap);

			    //Light
				float3 Ambient = SampleSH(normalWS);

                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz + shadowNoisePosition);
				if(_DebugColorSwitch == 7)
				{
					shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
				}
                Light mainLight = GetMainLight(shadowCoord);
                float3 mainLightColor = mainLight.color;
                float3 mainLightDir = normalize(mainLight.direction);
			    float mainLightShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
				float mainLightShadowIn = smoothstep(_ShadowInMinStep, _ShadowInMaxStep, mainLightShadow);
				float mainLightShadowOut = smoothstep(_ShadowOutMinStep, _ShadowOutMaxStep, mainLightShadow);
				float3 mainLightShadowColor = lerp(_ShadowInColor, _ShadowOutColor, mainLightShadowIn);
				mainLightShadowColor = lerp(mainLightShadowColor, float3(1, 1, 1), mainLightShadowOut);

			    // LightMode
			    half lambert = dot(normalWS, mainLightDir);
			    half lightMode = lambert * 0.5 + 0.5;

			    /// Ramp
			    // Noise
			    float interiorNoiseMap = SAMPLE_TEXTURE2D(_InteriorNoiseMap, sampler_InteriorNoiseMap, input.uvNoise).r;                         
			    float strokeMap = SAMPLE_TEXTURE2D(_StrokeMap, sampler_StrokeMap, input.uvBase).r;
			    // float matcapMap = SAMPLE_TEXTURE2D(_StrokeMap, sampler_StrokeMap, normalVS.xy * 0.5 + 0.5).x;
				float2 noiseUV = float2(clamp(lightMode + strokeMap * interiorNoiseMap * _InteriorNoiseLevel, 0, 1), 0);

				half3 rampColor = float3(1, 1, 1);
				#if _RAMPGGUASSIAN_ON
					// Guassian Blur
					float4 sum = float4(0.0, 0.0, 0.0, 0.0);
	                float2 tc = noiseUV;
	                float hstep = _GuassianHStep;
	                float vstep = _GuassianVStep;
	                // blur radius in pixels
	                float blur = _GguassianRadius/_GuassianResolution/4;     
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 4.0 * blur * hstep, tc.y - 4.0 * blur * vstep)) * 0.0162162162;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 3.0 * blur * hstep, tc.y - 3.0 * blur * vstep)) * 0.0540540541;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 2.0 * blur * hstep, tc.y - 2.0 * blur * vstep)) * 0.1216216216;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x - 1.0 * blur * hstep, tc.y - 1.0 * blur * vstep)) * 0.1945945946;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x, tc.y)) * 0.2270270270;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 1.0 * blur * hstep, tc.y + 1.0 * blur * vstep)) * 0.1945945946;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 2.0 * blur * hstep, tc.y + 2.0 * blur * vstep)) * 0.1216216216;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 3.0 * blur * hstep, tc.y + 3.0 * blur * vstep)) * 0.0540540541;
	                sum += SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(tc.x + 4.0 * blur * hstep, tc.y + 4.0 * blur * vstep)) * 0.0162162162;
					rampColor = sum.rgb;
				#else
					rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, noiseUV).rgb;
				#endif
			    rampColor = lerp(_RampDarkColor, _RampLightColor, rampColor);

				// Paper
				float3 paperMap = TriPlanar(input.normalWS, positionWS * _PaperMapScale, pivotWS, TEXTURE2D_ARGS(_PaperMap, sampler_PaperMap)).rgb;;

				// Rim
			    float linearEyeDepth = LinearEyeDepth(input.positionCS.z, _ZBufferParams) * 1;
			    // float3 normalVS = mul((float3x3)UNITY_MATRIX_V, normalWS);
			    float2 uvOffset = float2(sign(normalVS.x), sign(normalVS.y) * 0.05) * _RimLightWidth / pow(abs(1 + linearEyeDepth), 0.3) / 100;    // 法线的横坐标确定采样UV的偏移方向，乘偏移量，除以深度实现近粗远细，加1限制最大宽度
			    int2 loadTexPos = input.positionCS.xy + uvOffset * _ScaledScreenParams.xy;   // 采样深度缓冲，把UV偏移转换成坐标偏移
			    loadTexPos = min(loadTexPos, _ScaledScreenParams.xy - 1);
			    float offsetSceneDepth = LoadSceneDepth(loadTexPos);   // 在深度缓存上采样偏移像素的深度
			    float offsetLinearEyeDepth = LinearEyeDepth(offsetSceneDepth, _ZBufferParams);  // 将非线性的深度缓存转换成线性的
			    float rimLight = saturate(offsetLinearEyeDepth - (linearEyeDepth + _RimLightThreshold)) / _RimLightFadeout;

				// LineStyle
				float3 rimLightColor = float3(0, 0, 0);
				float fresnel = 0;
				float3 fresnelColor = float3(0, 0, 0);
				#if _LINESTYLE_SINGLECOLOR 
                    rimLightColor = _RimLightTintColor.rgb;
                #elif _LINESTYLE_GOLD
                    float3 goldMap = SAMPLE_TEXTURE2D(_GoldMap, sampler_GoldMap, input.uvBase).rgb;
					float3 goldRampMap = SAMPLE_TEXTURE2D(_GoldRampMap, sampler_GoldRampMap, lightMode).rgb;
					half goldFresnel = saturate(pow(saturate(dot(normalWS, viewDirWS)), _GoldFresnelBrightnessPower));
					goldFresnel = (goldFresnel > _GoldFresnelBrightnessThred) ? goldFresnel * goldFresnel : goldFresnel;
					rimLightColor = goldRampMap * goldMap;
					rimLightColor *= lerp(0.8, 3, goldFresnel);
					fresnel = 1 - saturate(pow(saturate(dot(normalWS, viewDirWS)), _GoldFresnelBrightnessPower));
					float inkFresnelMap = TriPlanar(input.normalWS, positionWS * _InkMapFresnelScale, pivotWS, TEXTURE2D_ARGS(_InkMap, sampler_InkMap)).r;
					fresnel = smoothstep(_GoldFresnelBrightnessThred, 1 - _GoldFresnelBrightnessThred, fresnel) * inkFresnelMap;
					fresnelColor = rimLightColor;
				
                #elif _LINESTYLE_INK
                    float inkRimMap = TriPlanar(input.normalWS, positionWS * _InkMapScale, pivotWS, TEXTURE2D_ARGS(_InkMap, sampler_InkMap)).r;
					float inkFresnelMap = TriPlanar(input.normalWS, positionWS * _InkMapFresnelScale, pivotWS, TEXTURE2D_ARGS(_InkMap, sampler_InkMap)).r;
					rimLightColor = lerp(_InkMapMin, _InkMapMax, inkRimMap);

					fresnel = 1 - saturate(pow(saturate(dot(normalWS + inkRimMap * 0.2, viewDirWS)), _InkFresnelPower));
					fresnel = smoothstep(_InkFresnelThred, 1 - _InkFresnelThred, fresnel);
					fresnelColor = lerp(_InkMapMin, _InkMapMax, inkFresnelMap);
				#endif

				// BlendLightMode
				half3 directLight = baseMap.rgb * rampColor * mainLightColor * mainLightShadowColor;
				half3 indirectLight = baseMap.rgb * Ambient;

				// Color
			    half3 color = directLight;	// 颜色+RampLambert+灯光
				color += indirectLight;		// 颜色*环境光
				color = lerp(color, softlight(paperMap, color), _PaperStrength);	// 混合纸张
				#if _LINESTYLE_INK
					rimLightColor *= color;
					fresnelColor *= color;
				#endif

				color = lerp(color, lerp(color, rimLightColor * _RimLightBrightness, saturate(rimLight)), _RimLightStrength);		// 混合边缘光
				color = lerp(color, fresnelColor, fresnel);		// 混合菲涅尔

				// Alpha
                half alpha = baseMap.a;
				if (_DebugColor >0)
                {
	                color = baseMap.rgb * lightMode * mainLightColor * mainLightShadow + baseMap.rgb * Ambient;
                }

			    // UnityFog
                color.rgb = MixFog(color.rgb, input.fogFactor);

				switch(_DebugColorSwitch)
	            {
	                case 1:	// 基本贴图
	                    color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb  * _BaseColor.rgb;
	                    break;
	                case 2:	// 减少基本贴图色阶
	                    color = baseMap.rgb;
	                    break;
					case 3:	// 混合半兰伯特，叠加一点点法线贴图
	                    color = baseMap.rgb * lightMode;
	                    break;
					case 4:	// 混合Ramp图（豪华版半兰伯特）
	                    color = baseMap.rgb * SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, lightMode).rgb;
	                    break;
					case 5:	// Ramp添加噪波偏移
	                    color = baseMap.rgb * SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, noiseUV).rgb;
	                    break;
	                case 6:	// Ramp高斯模糊
	                    color = baseMap.rgb * rampColor;
	                    break;
					case 7:	// 混合灯光和低分辨率阴影
	                    color = baseMap.rgb * rampColor * mainLightColor * mainLightShadow;	//最上层加if了
	                    break;
	                case 8:	// 阴影位置添加噪波
	                    color = baseMap.rgb * rampColor * mainLightColor * mainLightShadow;
	                    break;
	                case 9:	// 阴影映射双颜色
	                    color = baseMap.rgb * rampColor * mainLightColor * mainLightShadowColor;
	                    break;
	                case 10:	// 混合环境光
	                    color = baseMap.rgb * rampColor * mainLightColor * mainLightShadowColor + baseMap.rgb * Ambient;
	                    break;
	                case 11:	// 叠加纸张效果
	                	color = directLight + indirectLight;
	                    color = lerp(color, softlight(paperMap, color), _PaperStrength);
	                    break;
					case 12:	// 叠加深度检测的边缘光
						color = directLight + indirectLight;
	                    color = lerp(color, softlight(paperMap, color), _PaperStrength);
						color = lerp(color, 1, saturate(rimLight));
	                    break;
					case 13:	// 鎏金边缘光（叠加Ramp图和金粉图）
	                    color = directLight + indirectLight;
	                    color = lerp(color, softlight(paperMap, color), _PaperStrength);
						color = lerp(color, lerp(color, rimLightColor * _RimLightBrightness, saturate(rimLight)), _RimLightStrength);
	                    break;
					case 14:	// 鎏金边缘光（给个菲涅尔）
						color = directLight + indirectLight;
	                    color = lerp(color, softlight(paperMap, color), _PaperStrength);
						color = lerp(color, lerp(color, rimLightColor * _RimLightBrightness, saturate(rimLight)), _RimLightStrength);
	                    color = lerp(color, fresnelColor, fresnel);
	                    break;
					case 15:	// 鎏金法线外扩描边（近大远小）
	                    break;
					case 16:	// 水墨边缘光（叠加噪波图）
	                    break;
					case 17:	// 水墨边缘光（给个菲涅尔）
	                    break;
					case 18:	// 水墨边缘光法线外扩描边（近大远小）
	                    break;
					case 19:	// 混合雾
	                    break;
	                default:
	                    break;
	            }
                
                return half4(color, alpha);
            } 
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fog
            
            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                #if defined(_ALPHATEST_ON)
                    float2 uv       : TEXCOORD0;
                #endif
                float fogFactor : TEXCOORD1;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

            #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
            #else
                float3 lightDirectionWS = _LightDirection;
            #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #endif

                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                #if defined(_ALPHATEST_ON)
                    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                #endif

                output.positionCS = GetShadowPositionHClip(input);
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                
                float alpha = 1;
                /*#ifdef _ALPHATEST_ON
                    alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a;
                    clip(alpha - _Cutoff);
                #endif*/

                float3 color = float3(0, 0, 0);
                color = MixFog(color.rgb, input.fogFactor);

                return float4(color, alpha);
            }
            ENDHLSL
        }

		Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			struct Attributes
			{
			    float4 position     : POSITION;
			    float2 texcoord     : TEXCOORD0;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
			    float2 uv           : TEXCOORD0;
			    float4 positionCS   : SV_POSITION;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			    UNITY_VERTEX_OUTPUT_STEREO
			};
            
            half Alpha(half albedoAlpha, half4 color, half cutoff)
			{
			#if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
			    half alpha = albedoAlpha * color.a;
			#else
			    half alpha = color.a;
			#endif

			#if defined(_ALPHATEST_ON)
			    clip(alpha - cutoff);
			#endif

			    return alpha;
			}

			Varyings DepthOnlyVertex(Attributes input)
			{
			    Varyings output = (Varyings)0;
			    UNITY_SETUP_INSTANCE_ID(input);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
			    output.positionCS = TransformObjectToHClip(input.position.xyz);
			    return output;
			}
			half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
			{
			    return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
			}
			half4 DepthOnlyFragment(Varyings input) : SV_TARGET
			{
			    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
			
			    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, 0.5);
			    return 0;
			}
            ENDHLSL
        }

        Pass 
        {
            Name "Outline"
            Tags
            {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
                "LightMode" = "UniversalForwardOnly"
            }

            // -------------------------------------
            // Render State Commands
            Cull Front
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

			TEXTURE2D(_OutlineNoiseMap);	SAMPLER(sampler_OutlineNoiseMap);
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _OUTLINE_ON
            #pragma shader_feature _OUTLINEAUTOSIZE_ON
            #pragma shader_feature _LINESTYLE_SINGLECOLOR _LINESTYLE_GOLD _LINESTYLE_INK
            #pragma shader_feature _POSITIONANIMATION_ON


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            #if _OUTLINE_ON
            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 texcoord   : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS   : SV_POSITION;
            	float3 positionWS   : TEXCOORD0;
            	float3 pivotWS		: TEXCOORD1;
            	float3 normalWS     : TEXCOORD2;
            	float2 uv           : TEXCOORD5;
            	float2 uvBase       : TEXCOORD7;
            	half fogFactor      : TEXCOORD8; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
            {
                Varyings output;                
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

            	output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
            	output.uvBase = input.texcoord;

            	float outlineWidth = 1;
            	#if _OUTLINEAUTOSIZE_ON
            	outlineWidth = _OutlineWidth * 25;
            	#else
            	outlineWidth = _OutlineWidth;
            	#endif
            	

                float burn = SAMPLE_TEXTURE2D_LOD(_OutlineNoiseMap, sampler_OutlineNoiseMap, input.positionOS.xy * _OutlineNoiseScale, 0).x * _OutlineNoiseWidth;
                
                float4 scaledScreenParams = GetScaledScreenParams();
                float scaleX = abs(scaledScreenParams.x / scaledScreenParams.y);    //求得X因屏幕比例缩放的倍数

                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
            	output.pivotWS = mul(UNITY_MATRIX_M, float4(0, 0, 0, 1)).xyz;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 normalCS = TransformWorldToHClipDir(output.normalWS);

                float2 extendis = normalize(normalCS.xy) * (outlineWidth * 0.01);  //根据法线和线宽计算偏移量
                       extendis.x /= scaleX;   //修正屏幕比例x

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                #if _OUTLINEAUTOSIZE_ON
                    //屏幕下描边宽度会变
                    output.positionCS.xy += extendis * burn;
                #else
                    //屏幕下描边宽度不变，则需要顶点偏移的距离在NDC坐标下为固定值
                    //因为后续会转换成NDC坐标，会除w进行缩放，所以先乘一个w，那么该偏移的距离就不会在NDC下有变换
                    output.positionCS.xy += extendis * burn * output.positionCS.w;
                #endif

            	VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
            	output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);


                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

            	// Light
            	float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
                float3 mainLightColor = mainLight.color;
                float3 mainLightDir = normalize(mainLight.direction);
            	float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
            	float3 normalWS = normalize(input.normalWS);
            	float lightMode = dot(normalWS, mainLightDir);

            	// LineStyle
				float3 rimLightColor = float3(0,0,0);
				#if _LINESTYLE_SINGLECOLOR 
                    rimLightColor = _RimLightTintColor.rgb;
                #elif _LINESTYLE_GOLD
                    float3 goldMap = SAMPLE_TEXTURE2D(_GoldMap, sampler_GoldMap, input.uvBase).rgb;
					float3 goldRampMap = SAMPLE_TEXTURE2D(_GoldRampMap, sampler_GoldRampMap, lightMode).rgb;
					half goldFresnel = saturate(pow(saturate(dot(normalWS, viewDirWS)), _GoldFresnelPower));
					goldFresnel = (goldFresnel > _GoldFresnelThred) ? goldFresnel * goldFresnel : goldFresnel;
					rimLightColor = goldRampMap * goldMap;
					rimLightColor *= lerp(0.8, 3, goldFresnel);
                #elif _LINESTYLE_INK
                    float inkRimMap = TriPlanar(input.normalWS, input.positionWS.xyz * _InkMapScale, input.pivotWS, TEXTURE2D_ARGS(_InkMap, sampler_InkMap)).r;
					rimLightColor = lerp(_InkMapMin, _InkMapMax, inkRimMap);
				#endif

            	half3 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb  * _BaseColor.rgb;
            	#if _LINESTYLE_INK
					rimLightColor *= color;
				#endif
            	color = lerp(rimLightColor, color, 0.1) * _OutlineColor.rgb;
            	
            	color.rgb = MixFog(color.rgb, input.fogFactor);
                return float4(color.rgb, 1);
            }

	        #else
	            struct Attributes {};
	            struct Varyings
	            {
	                float4 positionCS : SV_POSITION;
	            };
	            Varyings vert(Attributes input)
	            {
	                return (Varyings)0;
	            }
	            float4 frag(Varyings input) : SV_TARGET
	            {
	                return 1;
	            }
	        #endif
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}