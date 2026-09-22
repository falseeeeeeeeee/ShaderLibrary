using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class LevelEnvironment : MonoBehaviour
{
    static readonly List<LevelEnvironment> Active = new();
    static int order;

    [SerializeField, Range(0f, 8f)] float ambientIntensity = 1f;
    [SerializeField] Material skyboxMaterial;
    [SerializeField] Light directionalLight;
    [SerializeField] ReflectionProbe reflectionProbe;

    int currentOrder;

    void OnEnable()
    {
        if (!Active.Contains(this))
            Active.Add(this);

        currentOrder = ++order;
        Apply();
    }

    void OnDisable()
    {
        Active.Remove(this);

        LevelEnvironment latest = GetLatest();

        if (latest != null)
            latest.Apply();
    }

    public void Apply()
    {
        if (skyboxMaterial == null) 
            return;

        RenderSettings.skybox           = skyboxMaterial;
        RenderSettings.sun              = directionalLight;
        RenderSettings.ambientMode      = AmbientMode.Skybox;
        RenderSettings.ambientIntensity = ambientIntensity;

        if (reflectionProbe != null)
            reflectionProbe.RenderProbe();

        DynamicGI.UpdateEnvironment();
    }

    static LevelEnvironment GetLatest()
    {
        LevelEnvironment latest = null;

        foreach (LevelEnvironment environment in Active)
        {
            if (environment != null && environment.isActiveAndEnabled && 
                (latest == null || environment.currentOrder > latest.currentOrder))
            {
                latest = environment;
            }
        }

        return latest;
    }
}