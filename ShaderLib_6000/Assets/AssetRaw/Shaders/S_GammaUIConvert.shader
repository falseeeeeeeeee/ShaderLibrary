Shader "Hidden/GammaUI/S_GammaUIConvert"
{
    SubShader
    {
        Tags { "RenderPipeline" = "GammaUIConversion"}
        Cull Off ZWrite Off ZTest Always Blend Off ColorMask RGBA
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        
        float3 GammaUI_LinearToSRGB(float3 c)
        {
            c = max(c, 0.0);
            float3 low  = c * 12.92;
            float3 high = 1.055 * pow(c, 1.0 / 2.4) - 0.055;
            return lerp(low, high, step(0.0031308, c));
        }
        
        float3 GammaUI_SRGBToLinear(float3 c)
        {
            c = max(c, 0.0);
            float3 low  = c / 12.92;
            float3 high = pow((c + 0.055) / 1.055, 2.4);
            return lerp(low, high, step(0.04045, c));
        }

        float4 LinearToGammaFrag(Varyings i) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
            float4 color = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_PointClamp, i.texcoord, 0);
            color.rgb = GammaUI_LinearToSRGB(color.rgb);
            return color;
        }
        
        float4 GammaToLinearFrag(Varyings i) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
            float4 color = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_PointClamp, i.texcoord, 0);
            color.rgb = GammaUI_SRGBToLinear(color.rgb);
            return color;
        }
        ENDHLSL

        // Pass 0:
        // Linear scene RGB -> gamma-encoded numeric RGB.
        Pass
        {
            Name "LinearToGamma"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment LinearToGammaFrag
            ENDHLSL
        }

        // Pass 1:
        // Gamma-encoded numeric RGB -> Linear RGB for the normal URP output path.
        Pass
        {
            Name "GammaToLinear"
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment GammaToLinearFrag
            ENDHLSL
        }
    }
}
