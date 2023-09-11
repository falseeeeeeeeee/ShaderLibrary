using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class DayNightCycle : MonoBehaviour
{
    [Header("DirectionalLightSetting")]
    public Light DirectionalLight;
    [Range(0,1)] public float DirectionalLightRotationY;
    [Range(0,1)] public float DirectionalLightRotationX;
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

    float timer = 0;
    bool Light = false;

    void Update()
    {
        if (!Application.isPlaying)
        {
            UpdateLighting();
        }

        float t = DirectionalLightRotationX;

        #region 灯光控制
        if (t == 0)
        {
            if (!Light)
            {
                Light = true;
                timer = 0;
            }
            timer += Time.deltaTime;
            if (timer > 0.5f)
            {
                Shader.SetGlobalFloat("_EmissionSwitch", 1.0f);
                timer = 0;
            }
        }
        else if (t > 0.2)
        {
            if (Light)
            {
                Light = false;
                timer = 0;
            }
            timer += Time.deltaTime;
            if (timer > 0.5f)
            {
                Shader.SetGlobalFloat("_EmissionSwitch", 0.0f);
                timer = 0;
            }
        }
        #endregion

        if (t < 0.1f) // midnight to dawn
        {
            float tt = t / 0.1f;
            DirectionalLight.color = Color.Lerp(NightColor * NightColorIntensity, MidColor * MidColorIntensity, Mathf.Pow(tt, 0.2f));
            DirectionalLight.intensity = DayColorIntensity * tt + 0.001f;
            Shader.SetGlobalFloat("_SkyBoxExposure", Mathf.Lerp(0.5f, 1.0f, tt));
        }
        else if (t < 0.4f) // dawn to dusk
        {
            float tt = (t - 0.2f) / 0.2f;
            DirectionalLight.color = Color.Lerp(MidColor * MidColorIntensity, DayColor * DayColorIntensity, Mathf.Pow(tt, 2f));
        }
        else // dusk to midnight
        {
            DirectionalLight.color = DayColor * DayColorIntensity;
            Shader.SetGlobalFloat("_SkyBoxExposure", 1.0f);
        }

        if (DebugShaderBaseColor)
        {
            GameObject.Find("Global Volume").GetComponent<Volume>().enabled = false;
            Shader.EnableKeyword("_DEBUGBASEMAP_ON");
        }
        else
        {
            GameObject.Find("Global Volume").GetComponent<Volume>().enabled = true;
            Shader.DisableKeyword("_DEBUGBASEMAP_ON");
        }
    }

    void OnValidate()
    {
        UpdateLighting();
    }

    private void UpdateLighting()
    {
        // 在世界空间坐标下旋转Y轴
        float yRotation = DirectionalLightRotationY * 360;
        DirectionalLight.transform.rotation = Quaternion.Euler(0, yRotation, 0);
        // 在局部坐标下旋转X轴
        float xRotation = Remap(DirectionalLightRotationX, 0, 1, DirectionalLightRotationXRange.x, DirectionalLightRotationXRange.y);
        DirectionalLight.transform.Rotate(xRotation, 0, 0, Space.Self);
    }

    #region [方法]

    public static float Remap(float value, float sourceRangeMin, float sourceRangeMax, float targetRangeMin, float targetRangeMax)
    {
        return (value - sourceRangeMin) / (sourceRangeMax - sourceRangeMin) * (targetRangeMax - targetRangeMin) + targetRangeMin;
    }

    #endregion
}
