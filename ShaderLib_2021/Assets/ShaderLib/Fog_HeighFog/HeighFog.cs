using UnityEngine;
[ExecuteInEditMode]
public class HeighFog : MonoBehaviour
{
    public bool enable;
    public Color fogColor;
    public float fogHeight;
    [Range(0, 1)] public float fogDensity;
    [Min(0f)] public float fogFalloff;
    public float fogStartDis;
    public float fogInscatteringExp;
    public float fogGradientDis;
    private static readonly int FogColor = Shader.PropertyToID("_FogColor");
    private static readonly int FogGlobalDensity = Shader.PropertyToID("_FogGlobalDensity");
    private static readonly int FogFallOff = Shader.PropertyToID("_FogFallOff");
    private static readonly int FogHeight = Shader.PropertyToID("_FogHeight");
    private static readonly int FogStartDis = Shader.PropertyToID("_FogStartDis");
    private static readonly int FogInscatteringExp = Shader.PropertyToID("_FogInscatteringExp");
    private static readonly int FogGradientDis = Shader.PropertyToID("_FogGradientDis");

    void OnValidate()
    {
        Shader.SetGlobalColor(FogColor, fogColor);
        Shader.SetGlobalFloat(FogGlobalDensity, fogDensity);
        Shader.SetGlobalFloat(FogFallOff, fogFalloff);
        Shader.SetGlobalFloat(FogHeight, fogHeight);
        Shader.SetGlobalFloat(FogStartDis, fogStartDis);
        Shader.SetGlobalFloat(FogInscatteringExp, fogInscatteringExp);
        Shader.SetGlobalFloat(FogGradientDis, fogGradientDis);
        if (enable)
        {
            Shader.EnableKeyword("_FOG_ON");
        }
        else
        {
            Shader.DisableKeyword("_FOG_ON");
        }
    }
}
