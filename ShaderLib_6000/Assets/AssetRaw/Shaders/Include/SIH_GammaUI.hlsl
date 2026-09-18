#ifndef SIH_GAMMA_UI_INCLUDED
#define SIH_GAMMA_UI_INCLUDED

// Set globally by GammaUIRenderFeature.
// 1 while UI is being rendered into the gamma-compositing target.
// 0 everywhere else.
float _GammaUIRGActive;

inline float3 GammaUILinearToSRGB(float3 c)
{
    c = max(c, 0.0);

    float3 low  = c * 12.92;
    float3 high = 1.055 * pow(c, 1.0 / 2.4) - 0.055;

    return lerp(low, high, step(0.0031308, c));
}

// Use this on the FINAL, UN-PREMULTIPLIED RGB produced by your UI shader,
// immediately before the shader performs premultiplication / returns.
//
// Example for straight alpha:
//     color.rgb = GammaUIEncodeIfActive(color.rgb);
//     return color;
//
// Example for premultiplied alpha:
//     color.rgb = GammaUIEncodeIfActive(color.rgb);
//     color.rgb *= color.a;
//     return color;
inline float3 GammaUIEncodeIfActive(float3 linearRGB)
{
    if (_GammaUIRGActive <= 0.5)
        return linearRGB;

    return GammaUILinearToSRGB(linearRGB);
}

#endif
