using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class LevelEnvironment : MonoBehaviour
{
    private static readonly List<LevelEnvironment> ActiveEnvironments = new();
    private static          int                    enableOrder;

    [Header("Environment")] [SerializeField]
    private Material skyboxMaterial;

    [SerializeField, Min(0f)] private float ambientIntensity = 1f;
    [SerializeField]          private Light sun;

    private int currentOrder;

    private void OnEnable()
    {
        if (!ActiveEnvironments.Contains(this))
            ActiveEnvironments.Add(this);

        currentOrder = ++enableOrder;
        Apply();
    }

    private void OnDisable()
    {
        ActiveEnvironments.Remove(this);

        // 当前环境被关闭后，恢复到最后启用的其他环境
        LevelEnvironment latest = GetLatestActive();
        if (latest != null)
            latest.Apply();
    }

    public void Apply()
    {
        if (skyboxMaterial == null)
            return;

        RenderSettings.skybox = skyboxMaterial;
        RenderSettings.sun    = sun;

        RenderSettings.ambientMode      = AmbientMode.Skybox;
        RenderSettings.ambientIntensity = ambientIntensity;

        // 更新天空盒对应的环境光照
        DynamicGI.UpdateEnvironment();
    }

    private static LevelEnvironment GetLatestActive()
    {
        LevelEnvironment latest      = null;
        int              latestOrder = int.MinValue;

        foreach (var environment in ActiveEnvironments)
        {
            if (environment == null || !environment.isActiveAndEnabled)
                continue;

            if (environment.currentOrder > latestOrder)
            {
                latest      = environment;
                latestOrder = environment.currentOrder;
            }
        }

        return latest;
    }
}