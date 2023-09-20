#ifndef PHOTOSHOPBLENDMODE_INCLUDE
#define PHOTOSHOPBLENDMODE_INCLUDE
//https://en.wikipedia.org/wiki/Blend_modes#Normal_blend_mode
//https://www.shadertoy.com/view/MsS3Wc
//http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl

//正常
float3 Normal(float3 Src, float3 Dst)
{
    Dst = 0.;
    return Src.rgb + Dst.rgb;
}

float3 Alphablend(float4 Src, float4 Dst)
{
    float4 C = Src.a * Src + (1.0 - Src.a) * Dst;
    return C.rgb;
}

//变暗
float3 Darken(float3 Src, float3 Dst)
{
    return min(Src, Dst);
}

//正片叠底
float3 Multiply(float3 Src, float3 Dst)
{
    return Src * Dst;
}

//颜色加深
float3 ColorBurn(float3 Src, float3 Dst)
{
    return 1.0 - (1.0 - Dst) / Src;
}

// 线性加深
float3 LinearBurn(float3 Src, float3 Dst)
{
    return Src + Dst - 1.0;
}

//深色
float3 DarkerColor(float3 Src, float3 Dst)
{
    return(Src.x + Src.y + Src.z < Dst.x + Dst.y + Dst.z) ? Src : Dst;
}

//变亮
float3 Lighten(float3 Src, float3 Dst)
{
    return max(Src, Dst);
}

//滤色
float3 Screen(float3 Src, float3 Dst)
{
    return Src + Dst - Src * Dst;
}

//颜色减淡
float3 ColorDodge(float3 Src, float3 Dst)
{
    return Dst / (1.0 - Src);
}

//线性减淡
float3 LinearDodge(float3 Src, float3 Dst)
{
    return Src + Dst;
}

//浅色
float3 LighterColor(float3 Src, float3 Dst)
{
    return(Src.x + Src.y + Src.z > Dst.x + Dst.y + Dst.z) ? Src : Dst;
}

//叠加
float overlay(float Src, float Dst)
{
    return(Dst < 0.5) ? 2.0 * Src * Dst : 1.0 - 2.0 * (1.0 - Src) * (1.0 - Dst);
}

//柔光
float SoftLight(float Src, float Dst)
{
    return(Src < 0.5) ? Dst - (1.0 - 2.0 * Src) * Dst * (1.0 - Dst)
    : (Dst < 0.25) ? Dst + (2.0 * Src - 1.0) * Dst * ((16.0 * Dst - 12.0) * Dst + 3.0)
    : Dst + (2.0 * Src - 1.0) * (sqrt(Dst) - Dst);
}

float3 SoftLight(float4 Src, float4 Dst)
{
    float3 C;
    C.x = SoftLight(Src.x, Dst.x);
    C.y = SoftLight(Src.y, Dst.y);
    C.z = SoftLight(Src.z, Dst.z);
    return C;
}

//强光
float HardLight(float Src, float Dst)
{
    return(Src < 0.5) ? 2.0 * Src * Dst : 1.0 - 2.0 * (1.0 - Src) * (1.0 - Dst);
}

float3 HardLight(float3 Src, float3 Dst)
{
    float3 C;
    C.x = HardLight(Src.x, Dst.x);
    C.y = HardLight(Src.y, Dst.y);
    C.z = HardLight(Src.z, Dst.z);
    return C;
}

//亮光
float VividLight(float Src, float Dst)
{
    return(Src < 0.5) ? 1.0 - (1.0 - Dst) / (2.0 * Src) : Dst / (2.0 * (1.0 - Src));
}

float3 VividLight(float3 Src, float3 Dst)
{
    float3 C;
    C.x = VividLight(Src.x, Dst.x);
    C.y = VividLight(Src.y, Dst.y);
    C.z = VividLight(Src.z, Dst.z);
    return C;
}

// 线性光
float3 LinearLight(float3 Src, float3 Dst)
{
    return 2.0 * Src + Dst - 1.0;
}

//点光
float PinLight(float Src, float Dst)
{
    return(2.0 * Src - 1.0 > Dst) ? 2.0 * Src - 1.0 : (Src < 0.5 * Dst) ? 2.0 * Src : Dst;
}

float3 PinLight(float3 Src, float3 Dst)
{
    float3 C;
    C.x = PinLight(Src.x, Dst.x);
    C.y = PinLight(Src.y, Dst.y);
    C.z = PinLight(Src.z, Dst.z);
    return C;
}

//实色混合
float3 HardMix(float3 Src, float3 Dst)
{
    return floor(Src + Dst);
}

//差值
float3 Difference(float3 Src, float3 Dst)
{
    return abs(Dst - Src);
}

//排除
float3 Exclusion(float3 Src, float3 Dst)
{
    return Src + Dst - 2.0 * Src * Dst;
}

//减去
float3 Subtract(float3 Src, float3 Dst)
{
    return Src - Dst;
}

//划分
float3 Divide(float3 Src, float3 Dst)
{
    return Src / Dst;
}

// RGB转HSV
float3 RGB2HSV(float3 C)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(C.bg, K.wz), float4(C.gb, K.xy), step(C.b, C.g));
    float4 q = lerp(float4(p.xyw, C.r), float4(C.r, p.yzx), step(p.x, C.r));
    
    float Dst = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * Dst + e)), Dst / (q.x + e), q.x);
}

// HSV转RGB
float3 HSV2RGB(float3 C)
{
    float3 rgb;
    rgb = clamp(abs(fmod(C.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);

    return C.z * lerp(1.0, rgb, C.y);
}

//色相
float3 Hue(float3 Src, float3 Dst)
{
    Dst = RGB2HSV(Dst);
    Dst.x = RGB2HSV(Src).x;
    return HSV2RGB(Dst);
}

//颜色
float3 Color(float3 Src, float3 Dst)
{
    Src = RGB2HSV(Src);
    Src.z = RGB2HSV(Dst).z;
    return HSV2RGB(Src);
}

//饱和度
float3 Saturation(float3 Src, float3 Dst)
{
    Dst = RGB2HSV(Dst);
    Dst.y = RGB2HSV(Src).y;
    return HSV2RGB(Dst);
}

//明度
float3 Luminosity(float3 Src, float3 Dst)
{
    float dLum = dot(Dst, float3(0.3, 0.59, 0.11));
    float sLum = dot(Src, float3(0.3, 0.59, 0.11));
    float lum = sLum - dLum;
    float3 C = Dst + lum;
    float minC = min(min(C.x, C.y), C.z);
    float maxC = max(max(C.x, C.y), C.z);
    if (minC < 0.0)
        return sLum + ((C - sLum) * sLum) / (sLum - minC);
    else if (maxC > 1.0)
        return sLum + ((C - sLum) * (1.0 - sLum)) / (maxC - sLum);
    else
        return C;
}

float3 OutPutMode(float4 Src, float4 Dst, float ID)
{
    if (ID == 0)
        return Normal(Src, Dst);
    if (ID == 1)
        return Alphablend(Src, Dst);
    if (ID == 2)
        return Darken(Src, Dst);
    if (ID == 3)
        return Multiply(Src, Dst);
    if (ID == 4)
        return ColorBurn(Src, Dst);
    if (ID == 5)
        return LinearBurn(Src, Dst);
    if (ID == 6)
        return DarkerColor(Src, Dst);
    if (ID == 7)
        return Lighten(Src, Dst);
    if (ID == 8)
        return Screen(Src, Dst);
    if (ID == 9)
        return ColorDodge(Src, Dst);
    if (ID == 10)
        return LinearDodge(Src, Dst);
    if (ID == 11)
        return LighterColor(Src, Dst);
    if (ID == 12)
        return overlay(Src, Dst);
    if (ID == 13)
        return SoftLight(Src, Dst);
    if (ID == 14)
        return HardLight(Src.rgb, Dst.rgb);
    if (ID == 15)
        return VividLight(Src.rgb, Dst.rgb);
    if (ID == 16)
        return LinearLight(Src, Dst);
    if (ID == 17)
        return PinLight(Src.rgb, Dst.rgb);
    if (ID == 18)
        return HardMix(Src, Dst);
    if (ID == 19)
        return Difference(Src, Dst);
    if (ID == 20)
        return Exclusion(Src, Dst);
    if (ID == 21)
        return Subtract(Src, Dst);
    if (ID == 22)
        return Divide(Src, Dst);
    if (ID == 23)
        return Hue(Src, Dst);
    if (ID == 24)
        return Color(Src, Dst);
    if (ID == 25)
        return Saturation(Src, Dst);
    if (ID == 26)
        return Luminosity(Src, Dst);
    
    return float3(0.0, 0.0, 0.0);
}


#endif