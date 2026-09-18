Shader "Hidden/BlendUI/BlendUILayer"
{
   Properties
   {
        [Enum (UnityEngine.Rendering.BlendMode)] _SrcFactor("Source Blend Factor", Float) = 5  // OneMinusSrcAlpha
        [Enum (UnityEngine.Rendering.BlendMode)] _DstFactor("Destination Blend Factor", Float) = 10 // SrcAlpha
        [Enum (UnityEngine.Rendering.BlendOp)] _Opp("Blend Operation", Float) = 0      // Add
   }

   SubShader
   {
       Tags { "RenderPipeline" = "UniversalPipeline" }
        
       Blend [_SrcFactor] [_DstFactor]
       BlendOp [_Opp]
       ZWrite Off Cull Off
       
       Pass
       {
           Name "BlendLayer"

           HLSLPROGRAM
           #pragma multi_compile_local_fragment _ _USE_FBF
           #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
           #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

           #pragma vertex Vert
           #pragma fragment Frag

#ifdef _USE_FBF
           // Declares the framebuffer input as a texture 2d containing half.
           FRAMEBUFFER_INPUT_HALF(0);
#endif
           float4 Frag(Varyings input) : SV_Target0
           {
               UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
               float2 uv = input.texcoord.xy;

#ifdef _USE_FBF
               // read previous subpasses directly from the framebuffer.
               half4 color = LOAD_FRAMEBUFFER_INPUT(0, input.positionCS.xy);
#else
               // the '_X' is usually a signature associated with making this work in single pass
               // i've had issues with VR unless things are in multi-pass; need to investigate more. 
               half4 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv);
#endif
               // Modify the sampled color
               return color;
           }
           ENDHLSL
       }
   }
}