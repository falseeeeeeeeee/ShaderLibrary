#ifndef TONEMAPPING_INCLUDE
#define TONEMAPPING_INCLUDE

// POST PROCESSING PARAMTERS
//float _ExposureEV = 1.319508;
//half3 _LogLut_Params = half3(0.0009765625,0.03125,31);
//TEXTURE2D(_LogLut);		SAMPLER(sampler_LogLut);
#define _ExposureEV 1.319508;
//const static float3 _LogLut_Params = (0.0009765625, 0.03125, 31);
//#define _LogLut_Params float3(0.0009765625,0.03125,31);


struct MyParamsLogC
{
    half cut;
    half a, b, c, d, e, f;
};

static const MyParamsLogC MyLogC =
{
    0.011361, // cut
    5.555556, // a
    0.047996, // b
    0.244161, // c
    0.386036, // d
    5.301883, // e
    0.092819  // f
};

half3 GammaToLinearSpace (half3 sRGB)
{
    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

    // Precise version, useful for debugging.
    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
}

half3 LinearToGammaSpace (half3 linRGB)
{
    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
    // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);

    // Exact version, useful for debugging.
    //return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b));
}

//half3 ApplyLut2d(TEXTURE2D_PARAM(_LogLut, sampler_LogLut), half3 uvw, half3 scaleOffset)
half3 ApplyLut2d(UnityTexture2D LogLut, half3 uvw, half3 scaleOffset)
{
    // Strip format where `height = sqrt(width)`
    uvw.z *= scaleOffset.z;
    half shift = floor(uvw.z);

    uvw.xy = uvw.xy * scaleOffset.z * scaleOffset.xy + scaleOffset.xy * 0.5;
    uvw.x += shift * scaleOffset.y;
    //uvw.xyz = lerp(SAMPLE_TEXTURE2D(_LogLut, sampler_LogLut, uvw.xy).rgb, SAMPLE_TEXTURE2D(_LogLut, sampler_LogLut, uvw.xy + half2(scaleOffset.y, 0)).rgb, uvw.z - shift);
    uvw.xyz = lerp(LogLut.Sample(LogLut.samplerstate, uvw.xy).rgb,
                   LogLut.Sample(LogLut.samplerstate, uvw.xy + half2(scaleOffset.y, 0)).rgb,
                   uvw.z - shift);


    return uvw;
}

half3 LinearToLogC(half3 x)
{
    return MyLogC.c * log10(MyLogC.a * x + MyLogC.b) + MyLogC.d;
}

half4 ApplyColorGrading(UnityTexture2D LogLut, half4 outputColor)
{

    // Gamma space... Gah.
    #if UNITY_COLORSPACE_GAMMA
    {
        outputColor.rgb = GammaToLinearSpace(outputColor.rgb);
    }
    #endif

    //float _ExposureEV = 1.319508;
    outputColor.rgb *= _ExposureEV; // Exposure is in ev units (or 'stops')

    half3 colorLogC = saturate(LinearToLogC(outputColor.rgb));
    //outputColor.rgb = ApplyLut2d(TEXTURE2D_ARGS(_LogLut, sampler_LogLut), colorLogC, _LogLut_Params);
    //outputColor.rgb = ApplyLut2d(LogLut, colorLogC, _LogLut_Params);
    outputColor.rgb = ApplyLut2d(LogLut, colorLogC, float3(0.0009765625,0.03125,31));

    outputColor.rgb = saturate(outputColor.rgb);

    // Back to gamma space if needed
    #if UNITY_COLORSPACE_GAMMA
    {
        outputColor.rgb = LinearToGammaSpace(outputColor.rgb);
    }
    #endif
    return outputColor;
}

void ApplyColorGradingShaderGraph_float(UnityTexture2D LogLut, float4 inputColor, out float4 outputColor)
{
#ifdef SHADERGRAPH_PREVIEW
    outputColor = real4(1,1,1,1);
#else
    outputColor = ApplyColorGrading(LogLut, inputColor);
#endif
}

void ApplyColorGradingShaderGraph_half(UnityTexture2D LogLut, half4 inputColor, out half4 outputColor)
{
    ApplyColorGradingShaderGraph_float(LogLut, inputColor, outputColor);
}


#endif