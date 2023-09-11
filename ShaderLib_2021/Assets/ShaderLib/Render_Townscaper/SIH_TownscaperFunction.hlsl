#ifndef SIH_TOWNSCAPER_FUNCTION_INCLUDED
#define SIH_TOWNSCAPER_FUNCTION_INCLUDED

/* 方法 */
// 饱和度
float3 Saturation(float3 In, float Saturation)
{
    float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
    return luma.xxx + Saturation.xxx * (In - luma.xxx);
}

float ToGray(float3 In)
{
    return 0.2989 * In.r + 0.5870 * In.g + 0.1140 * In.b;
}

float3 RGB2HSV(float3 In)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(In.bg, K.wz), float4(In.gb, K.xy), step(In.b, In.g));
    float4 q = lerp(float4(p.xyw, In.r), float4(In.r, p.yzx), step(p.x, In.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSV2RGB(float3 In)
{
    float3 rgb = clamp(abs(fmod(In.x * 6.0 + float3(0.0, 4.0, 2.0), 6) - 3.0) - 1.0, 0, 1);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return In.z * lerp(float3(1, 1, 1), rgb, In.y);
}

float3 DayNightColorBlend(float3 color, float3 lightColor, float lightMode, float4 InDayColor, float4 InNightColor, float DayIntensity, float NightIntensity)
{
    

    /*float3 nightColorBlend = HSV2RGB(float3(RGB2HSV(lightColor.rgb).rg, RGB2HSV(color).b));
           nightColorBlend = Saturation(lerp(color, nightColorBlend, InNightColor.a), 0.5) * NightIntensity;*/
    // float3 nightColor = lerp(float3(1.0, 1.0, 1.0), InNightColor.rgb, InNightColor.a) * NightIntensity;
    // float3 dayColor = lerp(float3(1.0, 1.0, 1.0), InDayColor.rgb, InDayColor.a) * DayIntensity;
    // float3 daySaturation = Saturation(color * dayColor * lightColor, pow(ToGray(lightColor), 1 / 2.2));
    // float3 NightSaturation = Saturation(color * nightColor * lightColor, saturate(pow(ToGray(lightColor), 1 / 2.2) - 0.5));
    // return lerp(NightSaturation, daySaturation, lightMode);
    // return Saturation(color, ToGray(lightColor));
    // return lerp(color * nightColor, color * dayColor, ToGray(lightColor));
    float3 nightColor = lerp(float3(1.0, 1.0, 1.0), _NightColor.rgb, _NightColor.a) * _NightIntensity;
    float3 dayColor = lerp(float3(1.0, 1.0, 1.0), _DayColor.rgb, _DayColor.a) * _DayIntensity;
    float3 daySaturation = Saturation(color * dayColor * lightColor, pow(ToGray(lightColor), 1 / 2.2));
    float3 NightSaturation = Saturation(color * nightColor * lightColor, saturate(pow(ToGray(lightColor), 1 / 2.2)- 0.5));
    return lerp(NightSaturation, daySaturation, lightMode);
}

float3 LerpLightMode(float LightMode, float4 InDayColor, float4 InNightColor, float DayIntensity, float NightIntensity)
{
    // float3 lightModel = lerp(lerp(half3(0.0, 0.0, 0.0), _LamberColor.rgb, _LamberColor.a), half3(1.0, 1.0, 1.0), lambert);
    float3 nightColor = lerp(float3(0.0, 0.0, 0.0), InNightColor.rgb, InNightColor.a) * NightIntensity;
    float3 dayColor = lerp(float3(1.0, 1.0, 1.0), InDayColor.rgb, InDayColor.a) * DayIntensity;
    return lerp(nightColor, dayColor, LightMode);
}

float4 ThreeColorAmbient(float3 normalWS, float4 upColor, float4 sideColor, float4 downColor)
{
    // 计算各部位遮罩
    float upMask = max(0.0, normalWS.g);                // 获取朝上部分遮罩
    float downMask = max(0.0, -normalWS.g);             // 获取朝下部分遮罩
    float sideMask = 1.0 - upMask - downMask;           // 获取侧面部分遮罩
    // 混合环境色
    return upColor * upMask + sideColor * sideMask + downColor * downMask;
}


/// ShadowFix
float4 anhei_TransformWorldToShadowCoord(float3 positionWS)
{
    half cascadeIndex = ComputeCascadeIndex(positionWS);
  
    float4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
  
    return float4(shadowCoord.xyz, cascadeIndex);
}
  
//自定义直接指定取某个区间段级联阴影
float4 anhei_TransformWorldToShadowCoord2(int idx, float3 positionWS)
{
    half cascadeIndex = idx;
  
    float4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
  
    return float4(shadowCoord.xyz, cascadeIndex);
}
  
//常规计算当前像素点(世界坐标)处于哪个裁切球
half anhei_ComputeCascadeIndex(float3 positionWS)
{
    float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
    float3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
    float3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
    float3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
    float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));
  
    half4 weights = half4(distances2 < _CascadeShadowSplitSphereRadii);
    weights.yzw = saturate(weights.yzw - weights.xyz);
  
    return 4 - dot(weights, half4(4, 3, 2, 1));
}

half ShadowFix(float3 positionWS)
{
    int cas_idx_1 = anhei_ComputeCascadeIndex(positionWS);
      
    Light light_1;
    Light light_0;
    half shadow_mix = 1.0f;
    float mix_fact = 0;
    if (cas_idx_1 == 0)//只处理第一个裁切球,其它裁切球的太远了,在画面上可能看不见
        {
        float4 shadow_coord0 = anhei_TransformWorldToShadowCoord2(0, positionWS);
        light_0 = GetMainLight(shadow_coord0);

        float4 shadow_coord1 = anhei_TransformWorldToShadowCoord2(1, positionWS);
        light_1 = GetMainLight(shadow_coord1);
        shadow_mix = light_1.shadowAttenuation;

        //离第一个裁切球心距离
        float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
        float3 first_sphere_dis = length(fromCenter0);
        //第一个裁切球的半径
        float first_sphere_rad = sqrt(_CascadeShadowSplitSphereRadii.x);

        //做一个简单的插值
        mix_fact = clamp((first_sphere_dis) / (first_sphere_rad / 1.0f), 0.0f, 1.0f).r;
        shadow_mix = light_0.shadowAttenuation* (1 - mix_fact) + light_1.shadowAttenuation * mix_fact;
        }
    else
    {
        float4 shadow_coord1 = anhei_TransformWorldToShadowCoord2(1, positionWS);
        light_1 = GetMainLight(shadow_coord1);
        shadow_mix = light_1.shadowAttenuation;
    }
    return shadow_mix;
}
#endif
