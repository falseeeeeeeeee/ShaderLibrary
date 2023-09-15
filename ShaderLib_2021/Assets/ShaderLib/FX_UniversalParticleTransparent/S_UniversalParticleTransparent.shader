Shader "URP/FX/S_UniversalParticleTransparent"
{
    Properties 
    {
        // 主贴图
        [HDR] _MainColor ("MainColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("MainTex", 2D) = "white" {}		
    	[KeywordEnum(Normal,Polar,Cylinder)] _MainTexUVS ("MainTexUVStyle", Float) = 0
    	[KeywordEnum(X,Y,Z)] _CylinderFace ("CylinderFace", Float) = 1
    	_CylinderCenter ("CylinderCenter", Vector) = (0.0, 0.0, 0.0, 0.0)
    	[Toggle] _MainTexAR ("MaskTexAR", Float) = 0
    	_MainTexUSpeed ("MainTexUSpeed", Float) = 0
    	_MainTexVSpeed ("MainTexVSpeed", Float) = 0
    	[Toggle] _CustomMainTex ("CustomMainTex", Float) = 0
    	[Toggle] _MainTexMulVertexColor ("MainTexMulVertexColor", Float) = 1
    	
    	// 额外贴图1：扫光
    	[Toggle(_FADDTEX1_ON)] _FAddTex1 ("FAddTex1", Float) = 0
    	[HDR] _AddColor1 ("AddColor1", Color) = (1.0, 1.0, 1.0, 1.0)
        _AddTex1 ("AddTex1", 2D) = "white" {}		
    	_AddTex1UVCenter ("AddTex1UVCenter", Vector) = (0.5, 0.5, 0.0, 0.0)
    	_AddTex1UVRotation ("AddTex1UVRotation", Range(-360.0,360.0)) = 0
    	_AddTex1Power ("AddTex1Power", Range(0.0, 10.0)) = 1.0
    	_AddTex1Intensity ("AddTex1Intensity", Range(0.0, 10.0)) = 1.0
    	[KeywordEnum(Normal,Polar,Cylinder)] _AddTex1UVS ("AddTex1UVStyle", Float) = 0
    	[Enum(Normal,0,Multiply,1,Add,2)] _AddTex1BlendStyle ("AddTex1BlendStyle", Int) = 0
    	_Add1Saturation ("Add1Saturation", Range(0.0, 4.0)) = 1.0
    	_Add1Brightness ("Add1Brightness", Range(0.0, 4.0)) = 1.0
    	_AddTex1RSpeed ("AddTex1RSpeed", Float) = 0
    	_AddTex1USpeed ("AddTex1USpeed", Float) = 0
    	_AddTex1VSpeed ("AddTex1VSpeed", Float) = 0
    	[Toggle] _CustomAddTex1 ("CustomAddTex1", Float) = 0
    	[Toggle] _AddTex1MulVertexColor ("AddTex1MulVertexColor", Float) = 1

    	// 遮罩图
    	[Toggle(_FMASKTEX_ON)] _FMaskTex ("FMaskTex", Float) = 0
    	_MaskTex ("MaskTex", 2D) = "white" {}
    	[KeywordEnum(Normal,Polar,Cylinder)] _MaskTexUVS ("MaskTexUVStyle", Float) = 0
    	[Toggle] _MaskTexReverse ("MaskTexReverse", Float) = 0
    	[Toggle] _MaskTexAR ("MaskTexAR", Float) = 1
    	_MaskTexUSpeed ("MaskTexUSpeed", Float) = 0.0
    	_MaskTexVSpeed ("MaskTexVSpeed", Float) = 0.0
    	
    	// 溶解图
    	[Toggle(_FDISSOLVETEX_ON)] _FDissolveTex ("FDissolveTex", Float) = 0
    	[HDR] _DissolveColor ("DissolveColor", Color) = (1.0, 1.0, 1.0, 1.0)
    	_DissolveTex ("DissolveTex", 2D) = "white" {}
    	_DissolveTexPower ("DissolveTexPower", Range(0.0, 10.0)) = 1.0
    	_DissolveTexIntensity ("DissolveTexIntensity", Range(0.0, 10.0)) = 1.0
    	[KeywordEnum(Normal,Polar,Cylinder)] _DissolveTexUVS ("DissolveTexUVStyle", Float) = 0
    	[Toggle] _DissolveTexAR ("DissolveTexAR", Float) = 1
    	_DissolveTexUSpeed ("DissolveTexUSpeed", Float) = 0.0
		_DissolveTexVSpeed ("DissolveTexVSpeed", Float) = 0.0
		[Toggle] _CustomDissolveTex ("CustomDissolveTex", Float) = 0
		_DissolveIntensity ("DissolveIntensity", Range(0.0, 1.0)) = 0.0
    	[Toggle] _DissolveTexSoft ("DissolveTexSoft", Float) = 0
		_DissolveSoft ("DissolveSoft", Range(0.0, 1.0)) = 0.1
		_DissolveWide ("DissolveWide", Range(0.0, 1.0)) = 0.05
    	[Toggle] _DissolveWideUseColor ("DissolveWideUseColor", Float) = 0
    	_DissolveWideSaturation ("DissolveWideSaturation", Range(0.0, 4.0)) = 2.0
    	
    	// 扭曲图
    	[Toggle(_FDISTORTTEX_ON)] _FDistortTex ("FDistortTex", Float) = 0
    	_DistortTex ("DistortTex", 2D) = "white" {}
    	[Toggle] _DistortTexAR ("DistortTexTexAR", Float) = 1
    	_DistortTexUSpeed ("DistortTexUSpeed", Float) = 0.0
    	_DistortTexVSpeed ("DistortTexVSpeed", Float) = 0.0
    	[Toggle] _CustomDistortTex ("CustomDistortTex", Float) = 0
    	_DistortIntensity ("DistortIntensity", Range(0, 1)) = 0.0
    	[Toggle] _DistortMainTex ("DistortMainTex", Float) = 1
    	[Toggle] _DistortMaskTex ("DistortMaskTex", Float) = 0
    	[Toggle] _DistortDissolveTex ("DistortDissolveTex", Float) = 0
    	
    	// 菲涅尔
    	[Toggle(_FFRESNEL_ON)] _FFresnel ("FFresnel", Float) = 0
    	[Enum(Normal,0,Multiply,1,Add,2,None,3)] _FresnelBlendStyle ("FresnelBlendStyle", Int) = 0
    	[Enum(Normal,0,Reverse,1,None,2)] _FresnelAlphaBlendStyle ("FresnelAlphaBlendStyle", Int) = 2
    	[Toggle] _FresnelMulVertexColor ("FresnelMulVertexColor", Float) = 0
    	[Toggle] _FresnelHard ("FresnelHard", Float) = 0
    	[Toggle] _FresnelReverse ("FresnelReverse", Float) = 0
		[HDR] _FresnelColor ("FresnelColor", Color) = (1.0, 1.0, 1.0, 1.0)
    	_FresnelScale ("FresnelScale", Range(0.0, 10.0)) = 1.0
		_FresnelPower ("FresnelPower", Range(0.0, 10.0)) = 1.0
    	
    	// 顶点动画
    	[Toggle(_FVERTEXOFFSETTEX_ON)] _FVertexOffsetTex ("FVertexOffsetTex", Float) = 0
    	_VertexOffsetTex ("VertexOffsetTex", 2D) = "white" {}
    	[Toggle] _VertexOffsetSinTime ("VertexOffsetSinTime", Float) = 0
    	_VertexOffsetTexUSpeed ("VertexOffsetTexUSpeed", Float) = 0.0
    	_VertexOffsetTexVSpeed ("VertexOffsetTexVSpeed", Float) = 0.0
    	_VertexOffsetXYZSpeed ("VertexOffsetXYZSpeed", Vector) = (0.0, 0.0, 0.0, 0.0)
    	[Toggle] _CustomVertexOffsetTex ("CustomVertexOffsetTex", Float) = 0
    	_VertexOffsetStrength ("VertexOffsetStrength", Float) = 0.0
        
        // 渲染设置
        _BlendMode ("BlendMode", Float) = 0
        [Toggle] _PreMulAlpha ("PreMultiplyAlpha", Float) = 0
        [Toggle] _AlphaGamma ("AlphaGamma", Float) = 0
    	_CustomAlphaGamma ("CustomAlphaGamma", Float) = 2.2
        [Toggle] _AlphaCut ("AlphaCut", Float) = 0
        _Cutoff ("Cutoff", Range(0.0, 1.0)) = 0.5
		[Toggle] _SoftParticles ("SoftParticles", Float) = 0
    	_SoftFade ("SoftFade", Float) = 1.0
    	[Toggle] _UseUIRect ("UseUIRect", Float) = 0
    	[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
        _Transparent ("Transparent", Range(0.0, 1.0)) = 1.0
        
        // 内置枚举
        [Enum(UnityEngine.Rendering.BlendOp)]  _BlendOp  ("BlendOp", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 10
    	[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
    	[Enum(UnityEngine.Rendering.ColorWriteMask)] _ColorMask ("ColorMask", Float) = 15

    	// 深度测试
        [Enum(Off, 0, On, 1)] _ZWriteMode ("ZWriteMode", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestMode ("ZTestMode", Float) = 4
    	
    	// 模板测试
    	[Toggle] _StencilToggle ("Stencil Toggle", Float) = 0
    	[IntRange] _Stencil ("Stencil ID", Range(0, 255)) = 0
        [IntRange] _StencilWriteMask ("Stencil Write Mask", Range(0, 255)) = 255
        [IntRange] _StencilReadMask ("Stencil Read Mask", Range(0, 255)) = 255
    	[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Stencil Pass", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Float) = 0
    }
	
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        	"IgnoreProjector" = "True"			// 不接受阴影
        	"ForceNoShadowCasting" = "True"		// 不投射阴影
        	"PreviewType" = "Plane"				// "Sphere" "Cube" "Cylinder" "SkyBox"
        }

        Pass 
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" } 
            
            BlendOp [_BlendOp]
            Blend [_SrcBlend] [_DstBlend]
        	Cull [_CullMode]
        	ColorMask [_ColorMask]
            ZWrite [_ZWriteMode]
            ZTest [_ZTestMode]

        	Stencil
            {
                Ref [_Stencil]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
            	Comp [_StencilComp]
                Pass [_StencilPass]
                Fail [_StencilFail]
                ZFail [_StencilZFail]
            }
            
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x	
            #pragma target 2.0

			#define REQUIRE_DEPTH_TEXTURE 1
			#define UNITY_PI            3.14159265359f
			#define UNITY_TWO_PI        6.28318530718f

			// GUI卷展栏宏开关
			#pragma shader_feature_local _FADDTEX1_ON
			#pragma shader_feature_local _FMASKTEX_ON
			#pragma shader_feature_local _FDISSOLVETEX_ON
			#pragma shader_feature_local _FDISTORTTEX_ON
			#pragma shader_feature_local _FFRESNEL_ON
			#pragma shader_feature_local _FVERTEXOFFSETTEX_ON

			// 自定义粒子
			#pragma shader_feature _CUSTOMMAINTEX_ON
			#pragma shader_feature _CUSTOMADDTEX1_ON
			#pragma shader_feature _CUSTOMDISSOLVETEX_ON
			#pragma shader_feature _CUSTOMDISTORTTEX_ON
			#pragma shader_feature _CUSTOMVERTEXOFFSETTEX_ON

			// 溶解宽度颜色
			#pragma shader_feature _DISSOLVEWIDEUSECOLOR_ON

			// 扭曲贴图开关及影响
			#pragma shader_feature _DISSOLVETEXSOFT_ON
			#pragma shader_feature _DISTORTMAINTEX_ON
			#pragma shader_feature _DISTORTMASKTEX_ON
			#pragma shader_feature _DISTORTDISSOLVETEX_ON

			// 自定义UV
			#pragma shader_feature_local _CYLINDERFACE_X _CYLINDERFACE_Y _CYLINDERFACE_Z
			#pragma shader_feature_local _MAINTEXUVS_NORMAL _MAINTEXUVS_POLAR _MAINTEXUVS_CYLINDER
			#pragma shader_feature_local _ADDTEX1UVS_NORMAL _ADDTEX1UVS_POLAR _ADDTEX1UVS_CYLINDER
			#pragma shader_feature_local _MASKTEXUVS_NORMAL _MASKTEXUVS_POLAR _MASKTEXUVS_CYLINDER
			#pragma shader_feature_local _DISSOLVETEXUVS_NORMAL _DISSOLVETEXUVS_POLAR _DISSOLVETEXUVS_CYLINDER
			
			#pragma shader_feature _PREMULALPHA_ON
			#pragma shader_feature _ALPHAGAMMA_ON
			#pragma shader_feature _ALPHACUT_ON
			#pragma shader_feature _SOFTPARTICLES_ON

			#pragma shader_feature _USEUIRECT_ON
			#pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
			
			#pragma multi_compile_instancing
			
            #pragma vertex vert
            #pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"


            CBUFFER_START(UnityPerMaterial)
			uniform float4 _MainColor;
			uniform float4 _MainTex_ST;
			uniform float4 _CylinderCenter;
			uniform half _MainTexAR;
			uniform half _MainTexUSpeed;
			uniform half _MainTexVSpeed;
			uniform half _MainTexMulVertexColor;

			uniform float4 _AddColor1;
			uniform float4 _AddTex1_ST;
			uniform float2 _AddTex1UVCenter;
			uniform half _AddTex1UVRotation;
			uniform half _AddTex1Power;
			uniform half _AddTex1Intensity;
			uniform half _AddTex1BlendStyle;
			uniform half _Add1Saturation;
			uniform half _Add1Brightness;
			uniform half _AddTex1RSpeed;
			uniform half _AddTex1USpeed;
			uniform half _AddTex1VSpeed;
			uniform half _AddTex1MulVertexColor;
			
			uniform float4 _MaskTex_ST;
			uniform half _MaskTexReverse;
			uniform half _MaskTexAR;
			uniform half _MaskTexUSpeed;
			uniform half _MaskTexVSpeed;
			
			uniform float4 _DissolveColor;
			uniform float4 _DissolveTex_ST;
			uniform half _DissolveTexAR;
			uniform half _DissolveTexPower;
			uniform half _DissolveTexIntensity;
			uniform half _DissolveTexUSpeed;
			uniform half _DissolveTexVSpeed;
			uniform half _CustomDissolveTex;
			uniform half _DissolveIntensity;
			uniform half _DissolveTexSoft;
			uniform half _DissolveSoft;
			uniform half _DissolveWide;
			uniform half _DissolveWideSaturation;
			
			uniform float4 _DistortTex_ST;
			uniform half _DistortTexAR;
			uniform half _DistortTexUSpeed;
			uniform half _DistortTexVSpeed;
			uniform half _DistortIntensity;
			uniform half _DistortMainTex;
			uniform half _DistortMaskTex;
			uniform half _DistortDissolveTex;

			uniform half _FresnelBlendStyle;
			uniform half _FresnelAlphaBlendStyle;
			uniform half _FresnelHard;
			uniform half _FresnelReverse;
			uniform half _FresnelMulVertexColor;
			uniform float4 _FresnelColor;
			uniform half _FresnelScale;
			uniform half _FresnelPower;
			
			uniform float4 _VertexOffsetTex_ST;
			uniform half _VertexOffsetSinTime;
			uniform half _VertexOffsetTexUSpeed;
			uniform half _VertexOffsetTexVSpeed;
			uniform half4 _VertexOffsetXYZSpeed;
			uniform half _VertexOffsetStrength;

            uniform half _BlendMode;
			uniform float _CustomAlphaGamma;
			uniform float _Cutoff;
			uniform float _SoftFade;
			uniform float _Transparent;
            CBUFFER_END

			float4 _TextureSampleAdd;
            float4 _ClipRect;
			float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;

			TEXTURE2D(_MainTex);			SAMPLER(sampler_MainTex);
			TEXTURE2D(_AddTex1);			SAMPLER(sampler_AddTex1);
			TEXTURE2D(_MaskTex);			SAMPLER(sampler_MaskTex);
			TEXTURE2D(_DissolveTex);		SAMPLER(sampler_DissolveTex);
			TEXTURE2D(_DistortTex);			SAMPLER(sampler_DistortTex);
			TEXTURE2D(_VertexOffsetTex);	SAMPLER(sampler_VertexOffsetTex);

			////////////////////////////////////////////////////////////////////////////////////////////////////////////
			////    方法    /////////////////////////////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////////////////////////////////

			// 饱和度
			float3 Unity_Saturation_float(float3 In, float Saturation)
			{
			    float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
			    return luma.xxx + Saturation.xxx * (In - luma.xxx);
			}

			// UV 旋转
			float2 Unity_Rotate_Degrees_float(float2 UV, float2 Center, float Rotation)
			{
			    Rotation = Rotation * (3.1415926f/180.0f);
			    UV -= Center;
			    float s = sin(Rotation);
			    float c = cos(Rotation);
			    float2x2 rMatrix = float2x2(c, -s, s, c);
			    rMatrix *= 0.5;
			    rMatrix += 0.5;
			    rMatrix = rMatrix * 2 - 1;
			    UV.xy = mul(UV.xy, rMatrix);
			    UV += Center;
			    return UV;
			}
	

            struct Attributes
			{
                float4 positionOS : POSITION;
            	float4 vertexColor : COLOR;
                float2 texcoord0 : TEXCOORD0;
            	
            	#if _CUSTOMMAINTEX_ON | _CUSTOMDISSOLVETEX_ON | _CUSTOMDISTORTTEX_ON 
            	    float4 texcoord1 : TEXCOORD1;
            	#endif

            	#if _FVERTEXOFFSETTEX_ON | _CUSTOMADDTEX1_ON
            	    float4 texcoord2 : TEXCOORD2;
            	#endif
            	
            	#if _FFRESNEL_ON | _FVERTEXOFFSETTEX_ON
            		float3 normalOS : NORMAL;
            	#endif
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
			{
                float4 positionCS : SV_POSITION;
            	float4 vertexColor : TEXCOORD0;

            	#ifdef _FMASKTEX_ON
					float4 uvMainAndMask : TEXCOORD1;
            	#else
            		float2 uvMainAndMask : TEXCOORD1;
            	#endif

            	#ifdef _FADDTEX1_ON
            		float2 uvAdd1 : TEXCOORD3;
            	#endif
            	
            	#ifdef _FDISSOLVETEX_ON
            		#ifdef _CUSTOMDISSOLVETEX_ON
						float3 uvDissolve : TEXCOORD4;
            		#else
            			float2 uvDissolve : TEXCOORD4;
            		#endif
            	#endif

            	#ifdef _FDISTORTTEX_ON
            		#ifdef _CUSTOMDISTORTTEX_ON
						float3 uvDistort : TEXCOORD5;
            		#else 
						float2 uvDistort : TEXCOORD5;
            		#endif
            	#endif

            	#if _FFRESNEL_ON | _MAINTEXUVS_CYLINDER | _MASKTEXUVS_CYLINDER | _DISSOLVETEXUVS_CYLINDER
            	    float3 positionWS : TEXCOORD6;
            		#if _FFRESNEL_ON
            			float3 normalDirWS : TEXCOORD7;
            		#endif
            	#endif

            	#ifdef _SOFTPARTICLES_ON
            		float4 positionSS : TEXCOORD8;
            	#endif

            	#ifdef _USEUIRECT_ON
					float4 mask : TEXCOORD9;
            	#endif
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes input)
			{
                Varyings output;

            	UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

            	// 顶点位移
                {
	                #ifdef _FVERTEXOFFSETTEX_ON
						float2 vertexOffsetTexUVSpeed = frac(float2(_VertexOffsetTexUSpeed, _VertexOffsetTexVSpeed) * _Time.y);
                			   //vertexOffsetTexUVSpeed = (_VertexOffsetSinTime == 0.0 ? vertexOffsetTexUVSpeed : sin(vertexOffsetTexUVSpeed));
						float2 vertexOffsetTexUV = TRANSFORM_TEX(input.texcoord0, _VertexOffsetTex) + vertexOffsetTexUVSpeed;
						float3 var_VertexOffsetTex = SAMPLE_TEXTURE2D_LOD(_VertexOffsetTex, sampler_VertexOffsetTex, vertexOffsetTexUV, 0);
                		#if _CUSTOMVERTEXOFFSETTEX_ON
                			half VertexOffsetStrength = input.texcoord2.x;
                		#else
                		    half VertexOffsetStrength = _VertexOffsetStrength;
						#endif
						input.positionOS.xyz += input.normalOS.xyz * VertexOffsetStrength * var_VertexOffsetTex;
                		input.positionOS.xyz += sin(_VertexOffsetXYZSpeed.xyz * _Time.y) * _VertexOffsetXYZSpeed.w;
					#endif
                }

            	output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            	output.vertexColor = input.vertexColor;

            	// 向量
                {
                	#ifdef _SOFTPARTICLES_ON
                		output.positionSS = ComputeScreenPos(output.positionCS);
                	#endif
                	
            		#if _FFRESNEL_ON | _MAINTEXUVS_CYLINDER | _MASKTEXUVS_CYLINDER | _DISSOLVETEXUVS_CYLINDER
                	    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                		#if _FFRESNEL_ON
                			output.normalDirWS = TransformObjectToWorldNormal(input.normalOS.xyz);
                		#endif
					#endif
                }

            	// 采样贴图UV
	            {
                	// 采样主贴图UV
            		output.uvMainAndMask.xy = input.texcoord0;
                	#ifdef _CUSTOMMAINTEX_ON
                		output.uvMainAndMask.xy += input.texcoord1.xy;	                		// 主贴图自定义UV+Offset，Custom1.xy
                	#endif
                	
                	// 采样额外贴图1
                	#ifdef _FADDTEX1_ON
                		output.uvAdd1.xy = Unity_Rotate_Degrees_float(input.texcoord0, _AddTex1UVCenter.xy, _AddTex1UVRotation + frac(_AddTex1RSpeed * _Time.y));
                	    #ifdef _CUSTOMADDTEX1_ON
							output.uvAdd1.xy += input.texcoord2.zw;								// 额外贴图自定义UV+Offset，Custom2.zw
            			#endif
                	#endif
            	
                	// 采样遮罩贴图UV
                	#ifdef _FMASKTEX_ON
                		//output.uvMainAndMask.zw = TRANSFORM_TEX(input.texcoord0, _MaskTex) + float2(_MaskTexUSpeed, _MaskTexVSpeed) * _Time.y;
                		output.uvMainAndMask.zw = input.texcoord0;
                	#endif

                	// 采样溶解贴图UV
                	#ifdef _FDISSOLVETEX_ON
                		//output.uvDissolve.xy = TRANSFORM_TEX(input.texcoord0, _DissolveTex) + float2(_DissolveTexUSpeed, _DissolveTexVSpeed) * _Time.y;
                		output.uvDissolve.xy = input.texcoord0;
                		#ifdef _CUSTOMDISSOLVETEX_ON
							output.uvDissolve.z = input.texcoord1.z;
            			#endif
                	#endif

                	// 采样扭曲贴图UV
                	#ifdef _FDISTORTTEX_ON
                		output.uvDistort.xy = TRANSFORM_TEX(input.texcoord0, _DistortTex) + frac(float2(_DistortTexUSpeed, _DistortTexVSpeed) * _Time.y);
                	    #ifdef _CUSTOMDISTORTTEX_ON
							output.uvDistort.z = input.texcoord1.w;
            			#endif
                	#endif
	            }

                {
                	// UI Rect相关
		            #ifdef _USEUIRECT_ON
            			float2 pixelSize = output.positionCS.w / abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));
            			float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
            			float2 maskUV = (input.positionOS.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
            			output.mask = half4(input.positionOS.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 /
            							(0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));
            		#endif
                }
            	
                return output;
            }

            half4 frag(Varyings input) : COLOR
			{
				UNITY_SETUP_INSTANCE_ID(input);
				
				// 扭曲贴图
				#ifdef _FDISTORTTEX_ON
	                half4 var_DistortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, input.uvDistort.xy);
					half var_DistortTexAlpha = (_DistortTexAR == 0.0 ? var_DistortTex.a : var_DistortTex.r);
					#ifdef _CUSTOMDISTORTTEX_ON
						var_DistortTexAlpha *= input.uvDistort.z;
					#else
						var_DistortTexAlpha *= _DistortIntensity;
					#endif
					half2 DistortUV = float2(var_DistortTexAlpha, var_DistortTexAlpha);

					// 贴图UV
					{
	                	#if _DISTORTMAINTEX_ON
							input.uvMainAndMask.xy += DistortUV;	// 扭曲主贴图UV
	                	#endif
						#if _FMASKTEX_ON & _DISTORTMASKTEX_ON
							input.uvMainAndMask.zw += DistortUV;	// 扭曲遮罩贴图UV
						#endif
						#if _FDISSOLVETEX_ON & _DISTORTDISSOLVETEX_ON
							input.uvDissolve.xy += DistortUV;		// 扭曲噪波UV
						#endif
					}
				#endif

				// 圆柱体UV
				#if _MAINTEXUVS_CYLINDER | _ADDTEX1UVS_CYLINDER | _MASKTEXUVS_CYLINDER | _DISSOLVETEXUVS_CYLINDER 
					float3 positionOS = TransformWorldToObject(input.positionWS);
					float3 cylinderPC =  _CylinderCenter.xyz + positionOS;	// PositionCenter
					float2 cylinderUV = float2(0.0, 0.0);
					#if defined(_CYLINDERFACE_X)
						cylinderUV = float2((atan(cylinderPC.y / cylinderPC.z) - (-0.5 * UNITY_PI)) / (( 0.5 * UNITY_PI ) - (-0.5 * UNITY_PI)) , cylinderPC.x);
					#elif defined(_CYLINDERFACE_Y)
						cylinderUV = float2((atan(cylinderPC.x / cylinderPC.z) - (-0.5 * UNITY_PI)) / (( 0.5 * UNITY_PI ) - (-0.5 * UNITY_PI)) , cylinderPC.y);
					#elif defined(_CYLINDERFACE_Z)
						cylinderUV = float2((atan(cylinderPC.x / cylinderPC.y) - (-0.5 * UNITY_PI)) / (( 0.5 * UNITY_PI ) - (-0.5 * UNITY_PI)) , cylinderPC.z);
					#endif
				#endif

				
				// 主贴图
				#if defined(_MAINTEXUVS_NORMAL)
					input.uvMainAndMask.xy = input.uvMainAndMask.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				#elif defined(_MAINTEXUVS_POLAR)
					float2 centerUV = input.uvMainAndMask.xy - float2(0.5, 0.5);
					float2 polarUV = float2(length(centerUV) * 2.0, atan2(centerUV.x, centerUV.y) * (1.0 / UNITY_TWO_PI));
					input.uvMainAndMask.xy = polarUV * _MainTex_ST.xy + _MainTex_ST.zw;
				#elif defined(_MAINTEXUVS_CYLINDER)
					input.uvMainAndMask.xy = cylinderUV * _MainTex_ST.xy + _MainTex_ST.zw;
				#endif
				input.uvMainAndMask.xy += frac(float2(_MainTexUSpeed, _MainTexVSpeed) * _Time.y);

				half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uvMainAndMask.xy);
				var_MainTex.rgb = (_MainTexAR == 0.0 ? var_MainTex.rgb : var_MainTex.rrr);
				half var_MainTexAlpha = (_MainTexAR == 0.0 ? var_MainTex.a : var_MainTex.r);
				half3 Color =  var_MainTex.rgb * _MainColor.rgb + _TextureSampleAdd.rgb;
				half Alpha = var_MainTexAlpha * _MainColor.a + _TextureSampleAdd.a;
				Color = _MainTexMulVertexColor == 1.0 ? Color * input.vertexColor.rgb : Color;	//是否与粒子顶点色相乘
				Alpha = _MainTexMulVertexColor == 1.0 ? Alpha * input.vertexColor.a : Alpha;	//是否与粒子顶点色相乘

				
				// 额外贴图1
				#ifdef _FADDTEX1_ON
					#if defined(_ADDTEX1UVS_NORMAL)
						input.uvAdd1.xy = input.uvAdd1.xy * _AddTex1_ST.xy + _AddTex1_ST.zw;
					#elif defined(_ADDTEX1UVS_POLAR)
						float2 add1CenterUV = input.uvAdd1.xy - float2(0.5, 0.5);
						float2 add1PolarUV = float2(length(add1CenterUV) * 2.0, atan2(add1CenterUV.x, add1CenterUV.y) * (1.0 / UNITY_TWO_PI));
						input.uvAdd1.xy = add1PolarUV * _AddTex1_ST.xy + _AddTex1_ST.zw;
					#elif defined(_ADDTEX1UVS_CYLINDER)
						input.uvAdd1.xy = cylinderUV * _AddTex1_ST.xy + _AddTex1_ST.zw;
					#endif
					input.uvAdd1.xy += frac(float2(_AddTex1USpeed, _AddTex1VSpeed) * _Time.y);
					half4 var_AddTex1 = SAMPLE_TEXTURE2D(_AddTex1, sampler_AddTex1, input.uvAdd1.xy);
					var_AddTex1 = saturate(pow(abs(var_AddTex1), _AddTex1Power) * _AddTex1Intensity);
					half3 Add1Color = Unity_Saturation_float(var_AddTex1.rgb * _AddColor1.rgb, _Add1Saturation) * _Add1Brightness;
					Add1Color = _AddTex1MulVertexColor == 1.0 ? Add1Color * input.vertexColor.rgb : Add1Color;	//是否与粒子顶点色相乘，只乘了颜色
					half Add1Alpha = var_AddTex1.a * _AddColor1.a;
					switch (_AddTex1BlendStyle)
					{
						case 1:
							Color = lerp(Color, Color * Add1Color, Add1Alpha);
							break;
						case 2:
							Color = lerp(Color, Color + Add1Color, Add1Alpha);
							break;
						default:
							Color = lerp(Color, Add1Color, Add1Alpha);
							break;
					}
				#endif
				
				
				// 遮罩贴图
				#ifdef _FMASKTEX_ON
					#if defined(_MASKTEXUVS_NORMAL)
						input.uvMainAndMask.zw = input.uvMainAndMask.zw * _MaskTex_ST.xy + _MaskTex_ST.zw;
					#elif defined(_MASKTEXUVS_POLAR)
						float2 maskCenterUV = input.uvMainAndMask.zw - float2(0.5, 0.5);
						float2 maskPolarUV = float2(length(maskCenterUV) * 2.0, atan2(maskCenterUV.x, maskCenterUV.y) * (1.0 / UNITY_TWO_PI));
						input.uvMainAndMask.zw = maskPolarUV * _MaskTex_ST.xy + _MaskTex_ST.zw;
					#elif defined(_MASKTEXUVS_CYLINDER)
						input.uvMainAndMask.zw = cylinderUV * _MaskTex_ST.xy + _MaskTex_ST.zw;
					#endif
					input.uvMainAndMask.zw += frac(float2(_MaskTexUSpeed, _MaskTexVSpeed) * _Time.y);
				
					half4 var_MaskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uvMainAndMask.zw);
					half var_MaskTexAlpha = (_MaskTexAR == 0.0 ? var_MaskTex.a : var_MaskTex.r);
					var_MaskTexAlpha = (_MaskTexReverse == 0.0 ? var_MaskTexAlpha : 1.0 - var_MaskTexAlpha);
					Alpha *= var_MaskTexAlpha;
				#endif

				// 菲涅尔
				#ifdef _FFRESNEL_ON
					float3 normalDirWS = normalize(input.normalDirWS);
					float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
					float Fresnel = saturate(pow(saturate(1.0- dot(viewDirWS, normalDirWS)), _FresnelPower) * _FresnelScale);
					Fresnel = (_FresnelReverse == 0.0 ? Fresnel : 1.0 - Fresnel);	//是否反向
					Fresnel = (_FresnelHard == 0.0 ? Fresnel : step(0.5, Fresnel));	//是否硬化
				
					half3 FresnelColor = _FresnelColor.rgb;
					half FresnelAlpha = Fresnel;
					FresnelColor = _FresnelMulVertexColor == 1.0 ? FresnelColor * input.vertexColor.rgb : FresnelColor;	//是否与粒子顶点色相乘
					FresnelAlpha = _FresnelMulVertexColor == 1.0 ? FresnelAlpha * input.vertexColor.a : FresnelAlpha;	//是否与粒子顶点色相乘
					switch (_FresnelBlendStyle)
					{
						case 1:
							Color = lerp(Color, Color * FresnelColor, Fresnel);
							break;
						case 2:
							Color += (FresnelColor * Fresnel);
							break;
						case 3:
							break;
						default:
							Color = lerp(Color, FresnelColor, Fresnel);
							break;
					}
				
					switch (_FresnelAlphaBlendStyle)
					{
						case 1:
							Alpha = 1.0 - FresnelAlpha;
							break;
						case 2:
							break;
						default:
							Alpha *= FresnelAlpha;
							break;
					}
				#endif
				
				// 溶解贴图
				#ifdef _FDISSOLVETEX_ON
					#if defined(_DISSOLVETEXUVS_NORMAL)
						input.uvDissolve.xy = input.uvDissolve.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
					#elif defined(_DISSOLVETEXUVS_POLAR)
						float2 dissolveCenterUV = input.uvDissolve.xy - float2(0.5, 0.5);
						float2 dissolvePolarUV = float2(length(dissolveCenterUV) * 2.0, atan2(dissolveCenterUV.x, dissolveCenterUV.y) * (1.0 / UNITY_TWO_PI));
						input.uvDissolve.xy = dissolvePolarUV * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
					#elif defined(_DISSOLVETEXUVS_CYLINDER)
						input.uvDissolve.xy = cylinderUV * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
					#endif
					input.uvDissolve.xy += frac(float2(_DissolveTexUSpeed, _DissolveTexVSpeed) * _Time.y);
				
					half4 var_DissolveTex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, input.uvDissolve.xy);
					half var_DissolveTexAlpha = _DissolveTexAR == 0.0 ? var_DissolveTex.a : var_DissolveTex.r;
					var_DissolveTexAlpha = saturate(pow(abs(var_DissolveTexAlpha), _DissolveTexPower) * _DissolveTexIntensity);

					float3 DissolveColor = _DissolveColor.rgb;
					#ifdef _DISSOLVEWIDEUSECOLOR_ON
						DissolveColor *= Unity_Saturation_float(Color, _DissolveWideSaturation);
					#endif
					
					#ifdef _CUSTOMDISSOLVETEX_ON
						half DissolveIntensity = input.uvDissolve.z;
					#else
						half DissolveIntensity = _DissolveIntensity;
					#endif
					//DissolveIntensity += 0.001;


					#ifdef _DISSOLVETEXSOFT_ON
						half SoftDissolveBig = DissolveIntensity * (_DissolveSoft + 1.0);
						half SoftDissolveSmall = SoftDissolveBig - _DissolveSoft;
						half SoftDissolve = smoothstep(SoftDissolveSmall, SoftDissolveBig, var_DissolveTexAlpha);
						Color = lerp(DissolveColor, Color, SoftDissolve);
						Alpha *= SoftDissolve;
					#else
						half HardDissolve = DissolveIntensity * (_DissolveWide + 1.0);
						half HardDissolveSmall = step(HardDissolve, var_DissolveTexAlpha);
						half HardDissolveBig = step(HardDissolve - _DissolveWide, var_DissolveTexAlpha);
						Color = lerp(DissolveColor, Color, HardDissolveSmall);
						Alpha *= HardDissolveBig;
					#endif
				#endif

				// 软粒子
				#ifdef _SOFTPARTICLES_ON
					float4 positionSS = input.positionSS;
					float4 positionSSNormal = positionSS / positionSS.w;
						   positionSSNormal.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? positionSSNormal.z : positionSSNormal.z * 0.5 + 0.5;
					float screenDepth = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(positionSSNormal.xy),_ZBufferParams);
					float distanceDepth = abs((screenDepth - LinearEyeDepth(positionSSNormal.z, _ZBufferParams)) / _SoftFade);
					Alpha *= saturate(distanceDepth);
				#endif

				// 透明裁剪
				#ifdef _ALPHACUT_ON
                    clip(Alpha - _Cutoff);
                #endif

				// 预乘
				#ifdef _PREMULALPHA_ON
                    Alpha = Color * Alpha;
                #endif

				// 伽马
				#ifdef _ALPHAGAMMA_ON
					Alpha = pow(abs(Alpha), _CustomAlphaGamma);
				#endif

				// UI Rect相关
				#ifdef _USEUIRECT_ON
					#ifdef UNITY_UI_CLIP_RECT
	                half2 clipMask = saturate((_ClipRect.zw - _ClipRect.xy - abs(input.mask.xy)) * input.mask.zw);
	                Alpha *= clipMask.x * clipMask.y;
	                #endif
				
	                #ifdef UNITY_UI_ALPHACLIP
	                clip (Alpha - 0.001);
	                #endif
				#endif
				
                return half4(Color, Alpha * _Transparent);
            } 
            ENDHLSL
        }
    }
	CustomEditor "UniversalParticleTransparentGUI"
	// 修改日期 20220726
	// 修改日期 20220827 增加Time节点上的Frac
	// 修改日期 20221222 增加UIRect适配
	// 修改日期 20230915 入库
}