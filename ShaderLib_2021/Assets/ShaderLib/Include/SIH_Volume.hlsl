#ifndef SIH_VOLUME_INCLUDED
#define SIH_VOLUME_INCLUDED

// 三颜色（顶，侧，底）插值环境光方法
float3 TriColAmbient (float3 n, float3 uCol, float3 sCol, float dCol) {
    float uMask = max(0.0, n.g);        // 获取朝上部分遮罩
    float dMask = max(0.0, -n.g);       // 获取朝下部分遮罩
    float sMask = 1.0 - uMask - dMask;  // 获取侧面部分遮罩
    float3 envCol = uCol * uMask +
                    sCol * sMask +
                    dCol * dMask;       // 混合环境色
    return envCol;
}

// 自定义亮度
float CustomLuminance(in float3 c)
{
    //根据人眼对颜色的敏感度，可以看见对绿色是最敏感的
    return 0.2125 * c.r + 0.7154 * c.g + 0.0721 * c.b;
}

// 当有多个RenderTarget时，需要自己处理UV翻转问题
float2 CorrectUV(in float2 uv, in float4 texelSize)
{
    float2 result = uv;
	
    #if UNITY_UV_STARTS_AT_TOP      // DirectX之类的
    if(texelSize.y < 0.0)           // 开启了抗锯齿
        result.y = 1.0 - uv.y;      // 满足上面两个条件时uv会翻转，因此需要转回来
    #endif

    return result;
}


///————————————————————————————————————————————————————————————————————————————————
/// 形状
///————————————————————————————————————————————————————————————————————————————————
// border : (left, right, bottom, top), all should be [0, 1]
float Rect(float4 border, float2 uv)
{
    float v1 = step(border.x, uv.x);
    float v2 = step(border.y, 1 - uv.x);
    float v3 = step(border.z, uv.y);
    float v4 = step(border.w, 1 - uv.y);
    return v1 * v2 * v3 * v4;
}

float SmoothRect(float4 border, float2 uv)
{
    float v1 = smoothstep(0, border.x, uv.x);
    float v2 = smoothstep(0, border.y, 1 - uv.x);
    float v3 = smoothstep(0, border.z, uv.y);
    float v4 = smoothstep(0, border.w, 1 - uv.y);
    return v1 * v2 * v3 * v4;
}

float Circle(float2 center, float radius, float2 uv)
{
    return 1 - step(radius, distance(uv, center));
}

float SmoothCircle(float2 center, float radius, float smoothWidth, float2 uv)
{
    return 1 - smoothstep(radius - smoothWidth, radius, distance(uv, center));
}

#endif