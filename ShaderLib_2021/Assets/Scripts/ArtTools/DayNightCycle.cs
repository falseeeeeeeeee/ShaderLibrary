using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DayNightCycle : MonoBehaviour
{
    [Header("DirectionalLightSetting")]
    public Light DirectionalLight;
    [Range(0, 1)] public float DirectionalLightRotationY;
    [Range(0, 1)] public float DirectionalLightRotationX;
    public Vector2 DirectionalLightRotationXRange = new Vector2(20, 80);

    [Header("SkySetting")]
    public Color DayColor = Color.white;
    public Color MidColor = Color.red;
    public Color NightColor = Color.blue;
    public float DayColorIntensity = 1f;
    public float MidColorIntensity = 1f;
    public float NightColorIntensity = 1f;

    [Header("Debug")]
    public bool DebugShaderBaseColor = false;

    void Update()
    {
        RotateDirectionalLight();

        float t = DirectionalLightRotationX;

        // 根据 DirectionalLightRotationX 控制 _EmissionSwitch
        // Shader.SetGlobalFloat("_EmissionSwitch", Mathf.Clamp01(t * 5.0f));

        if (t < 0.1f) // midnight to dawn
        {
            float tt = t / 0.1f;
            DirectionalLight.color = Color.Lerp(NightColor * NightColorIntensity, MidColor * MidColorIntensity, Mathf.Pow(tt, 0.2f));
            DirectionalLight.intensity = DayColorIntensity * tt + 0.001f;

            // 设置全局Shader参数
            // Shader.SetGlobalFloat("_SkyBoxExposure", Mathf.Lerp(0.5f, 1.0f, tt));
            Shader.SetGlobalFloat("_EmissionSwitch", 2.0f);

        }
        else if (t < 0.4f) // dawn to dusk
        {
            float tt = (t - 0.2f) / 0.2f;
            DirectionalLight.color = Color.Lerp(MidColor * MidColorIntensity, DayColor * DayColorIntensity, Mathf.Pow(tt, 2f));

            // 设置Shader参数
            Shader.SetGlobalFloat("_EmissionSwitch", Mathf.Lerp(0.5f, 2.0f, tt));
        }
        else // dusk to midnight
        {
            DirectionalLight.color = DayColor * DayColorIntensity;

            // 设置Shader参数
            Shader.SetGlobalFloat("_EmissionSwitch", 0.0f);
        }

        if (DebugShaderBaseColor)
        {
            // 控制 URP Volume 的开启与关闭
            ToggleURPVolume(!DebugShaderBaseColor);
            Shader.EnableKeyword("_DEBUGBASEMAP_ON");
        }
        else
        {
            // 控制 URP Volume 的开启与关闭
            ToggleURPVolume(!DebugShaderBaseColor);
            Shader.DisableKeyword("_DEBUGBASEMAP_ON");
        }
    }

    private void ToggleURPVolume(bool enable)
    {
        Volume volume = GameObject.Find("Global Volume").GetComponent<Volume>();
        volume.enabled = enable;
    }

    private void RotateDirectionalLight()
    {
        // 光照旋转逻辑
        float yRotation = DirectionalLightRotationY * 360;
        DirectionalLight.transform.rotation = Quaternion.Euler(0, yRotation, 0);
        float xRotation = Mathf.Lerp(DirectionalLightRotationXRange.x, DirectionalLightRotationXRange.y, DirectionalLightRotationX);
        DirectionalLight.transform.localEulerAngles = new Vector3(xRotation, 0, 0);
    }
}
