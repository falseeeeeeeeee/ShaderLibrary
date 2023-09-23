Shader "URP/Tool/S_DisplacementMap"
{
    Properties 
    {
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
		_DisplacementStrength ("Displacement Strength", Float) = 1.0
        [NoScaleOffset] _DisplacementMap ("Displacement Map", 2D) = "white" {}

		[IntRange] _Tess ("Tessellation", Range(1.0, 64.0)) = 1.0
		[Toggle] _TessView ("Enable Tessellation View?", Float) = 1.0
        _MinTessDistance ("Min Tess Distance", Range(1.0, 32)) = 1.0
        _MaxTessDistance ("Max Tess Distance", Range(1.0, 32)) = 16.0


        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2
    }
    SubShader 
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass {
            Name "Tessellation"
            Tags { "LightMode" = "UniversalForward" } 

            Cull [_CullMode]
            
			HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 4.6

            //#pragma multi_compile_instancing
            
            #pragma shader_feature _TESSVIEW_ON

            #pragma require tessellation
            #pragma require geometry

            #pragma vertex beforeTessVertProgram
            #pragma hull hullProgram
            #pragma domain domainProgram
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
			uniform half4 _BaseColor;
			uniform float4 _BaseMap_ST;
            uniform float _DisplacementStrength;
            uniform float _Tess;
            uniform float _MinTessDistance;
            uniform float _MaxTessDistance;
            CBUFFER_END
			
			TEXTURE2D(_BaseMap);	SAMPLER(sampler_BaseMap);
			TEXTURE2D(_DisplacementMap);	SAMPLER(sampler_DisplacementMap);
			
            // 顶点着色器的输入
            struct Attributes
			{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            // 片段着色器的输入
            struct Varyings
			{
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };


            // ---------------------         
            // -------曲面细分-------  
            // ---------------------      
            
            // 定义Path
            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            // 曲面细分着色器的输入
            struct ControlPoint
            {
                float4 positionOS : INTERNALTESSPOS;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            // 顶点着色器，此时只是将Attributes里的数据递交给曲面细分阶段
            ControlPoint beforeTessVertProgram (Attributes input)
            {
                ControlPoint output;
        
                output.positionOS = input.positionOS;
                output.uv = input.uv;
                output.normalOS = input.normalOS;
                output.color = input.color;
        
                return output;
            }

            // 随着距相机的距离减少细分数
            float CalcDistanceTessFactor(float4 positionOS, float minDist, float maxDist, float tess)
            {
                float3 worldPosition = TransformObjectToWorld(positionOS.xyz);
                float dist = distance(worldPosition,  GetCameraPositionWS());
                float output = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
                return (output);
            }

            // 设定Patch
            TessellationFactors MyPatchConstantFunction(InputPatch<ControlPoint, 3> patch)
            {
                TessellationFactors output;
                
                #ifdef _TESSVIEW_ON
                    float minDist = _MinTessDistance;
                    float maxDist = _MaxTessDistance;

                    float edge0 = CalcDistanceTessFactor(patch[0].positionOS, minDist, maxDist, _Tess);
                    float edge1 = CalcDistanceTessFactor(patch[1].positionOS, minDist, maxDist, _Tess);
                    float edge2 = CalcDistanceTessFactor(patch[2].positionOS, minDist, maxDist, _Tess);

                    output.edge[0] = (edge1 + edge2) / 2;
                    output.edge[1] = (edge2 + edge0) / 2;
                    output.edge[2] = (edge0 + edge1) / 2;
                    output.inside = (edge0 + edge1 + edge2) / 3;
                #else
                    output.edge[0] = _Tess;
			        output.edge[1] = _Tess;
			        output.edge[2] = _Tess;
                    output.inside = _Tess;
                #endif

                return output;
            }

            // 设定一些曲面细分的相关设置
            [domain("tri")]                                 
            [outputcontrolpoints(3)]                       
            [outputtopology("triangle_cw")]                
            [partitioning("fractional_odd")]               
            [patchconstantfunc("MyPatchConstantFunction")]  

            // Hull Shader
            ControlPoint hullProgram(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            // 顶点着色器
			Varyings AfterTessVertProgram (Attributes input)
			{
				Varyings output;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                float displacement = (SAMPLE_TEXTURE2D_LOD(_DisplacementMap, sampler_DisplacementMap, output.uv, 0).x - 0.5) * _DisplacementStrength;
                input.normalOS = normalize(input.normalOS);
                input.positionOS.xyz += input.normalOS * displacement;

				output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
				output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                return output;
			}

            // Domain Shader
            [domain("tri")]
            Varyings domainProgram (TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                Attributes output;
        
                #define DomainInterpolate(fieldName) output.fieldName = \
                        patch[0].fieldName * barycentricCoordinates.x + \
                        patch[1].fieldName * barycentricCoordinates.y + \
                        patch[2].fieldName * barycentricCoordinates.z;
    
                DomainInterpolate(positionOS)
                DomainInterpolate(uv)
                DomainInterpolate(color)
                DomainInterpolate(normalOS)
                    
                return AfterTessVertProgram(output);
            }

            // --------------------------------------------------------------------------------

            // 片段着色器
            half4 frag(Varyings input) : SV_Target
			{

                float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);                         
                half3 color =  var_BaseMap.rgb * _BaseColor.rgb;
                half alpha = var_BaseMap.a * _BaseColor.a;
                
                return half4(color, alpha);
            } 
            ENDHLSL
        }
    }
}