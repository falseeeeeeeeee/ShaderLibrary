#ifndef SGH_RHYTHMLED_INCLUDED
#define SGH_RHYTHMLED_INCLUDED

// 方法
float Unity_Rectangle(float2 UV, float Width, float Height)
{
    float2 d = abs(UV * 2 - 1) - float2(Width, Height);
    d = 1 - d / fwidth(d);
    return saturate(min(d.x, d.y));
}


// 正常倍率方块
void Normal_Square_float(float Number, float Interval, float2 UV, float UVSpeed, out float ObliqueOut, out float VerticalOut)
{
    // 初始左下角内容
    Interval = 1.0 / clamp(1.0, 999999.0, Interval);
    float RectangleSize = Interval / Number;
    float RectangleStartOffset = 0.5 - RectangleSize / 2.0;  // 保持在中心
    // float RectangleStartOffset = 0;
    
    if(fmod(Number, 2) == 0) 
    {
        RectangleStartOffset = RectangleSize / 2.0;          // 偶数
    }
    
    
    // UV偏移
    UV = UV * Interval;
    float2 ObliqueUV = UV;
    ObliqueUV.x += (UVSpeed - frac(UVSpeed)) * RectangleSize;
    float2 RectangleUV = UV;
    float RectangleUV2Center = (Number + 1) / 2;
    RectangleUV.x += ((UVSpeed + RectangleUV2Center) - frac(UVSpeed + RectangleUV2Center)) * RectangleSize;

    // 斜方块
    ObliqueOut = 0;
    for (int i = 0; i < Number; i++)
    {
        float RectangleLoop = RectangleStartOffset - RectangleSize * i;     // 偏移的幅度
        float2 ObliqueUVOut = frac(ObliqueUV + float2(RectangleLoop, RectangleLoop));
        float Rectangle = Unity_Rectangle(ObliqueUVOut, RectangleSize, RectangleSize);;
        
        ObliqueOut += Rectangle;
    };
    
    // 长方块
    float RectangleLoop = RectangleStartOffset;     // 偏移的幅度
    float2 RectangleUVOut = frac(RectangleUV + float2(RectangleLoop, RectangleLoop));
    float Rectangle = Unity_Rectangle(RectangleUVOut, RectangleSize, 1);;
    VerticalOut = Rectangle;

}

void Paper_Square_float(float Number, float Interval, float2 UV, float UVSpeed, out float PaperOut)
{
    // 通用数据
    float EdgeSize = 2.0 / Number;
    float RectangleInterval =  (UVSpeed - frac(UVSpeed)) * 1.0;

    // 奇偶区分
    float RectangleLoopAdd = 0;
    if(fmod(Number, 2) == 0) 
    {
        // 偶数处理
        RectangleLoopAdd = EdgeSize * RectangleInterval;
    }
    else 
    {
        // 奇数处理
        float NumberDivide2 = fmod(RectangleInterval, (Number - 1) / 2 + 1) * EdgeSize;
        RectangleLoopAdd = frac(NumberDivide2 - step(1, NumberDivide2) * NumberDivide2);
        if(fmod(floor(RectangleLoopAdd), 2) == 0) 
        {
            RectangleLoopAdd = RectangleLoopAdd + 0;          // Number为偶数
        }
        else 
        {
            RectangleLoopAdd = frac(RectangleLoopAdd) - 1.0 / Number;    // Number为奇数
        }
    }

    // 组装回形方块
    float RectangleOutSize = 1.0 - frac(RectangleLoopAdd);
    float RectangleInSize = RectangleOutSize - EdgeSize;
    float RectangleOut = Unity_Rectangle(UV, RectangleOutSize, RectangleOutSize);
    float RectangleIn = Unity_Rectangle(UV, RectangleInSize, RectangleInSize);
    PaperOut = RectangleOut - RectangleIn;
}
/*
void Paper_Square_float(float Number, float Interval, float2 UV, float UVSpeed, out float PaperOut)
{
    // 方块大小信息
    float EdgeSize = 2.0 / Number;
    float RectangleOutDefaultSize = 1.0;
    float RectangleInterval =  (UVSpeed - frac(UVSpeed)) * 1.0;
    float RectangleOutSize = RectangleOutDefaultSize - frac(EdgeSize * RectangleInterval);
    float RectangleInSize = RectangleOutSize - EdgeSize;

    // 组装回形方块
    float RectangleOut = Unity_Rectangle(UV, RectangleOutSize, RectangleOutSize);
    float RectangleIn = Unity_Rectangle(UV, RectangleInSize, RectangleInSize);
    PaperOut = RectangleOut - RectangleIn;
}*/



#endif
