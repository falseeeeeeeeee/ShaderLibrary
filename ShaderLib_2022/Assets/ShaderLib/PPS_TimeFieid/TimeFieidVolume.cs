using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[VolumeComponentMenu("Custom/时间结界")]
public class TimeFieidVolume : VolumeComponent,IPostProcessComponent
{
    public Vector2Parameter screenPosition = new(new(0.5f,0.5f));
    public MinFloatParameter strength = new(10f, 0f);
    public ClampedFloatParameter scatter = new(0f, 0f, 2f);
    public FloatParameter concentration = new(100f);

    // 控制什么时候开关
    public bool IsActive()
    {
        return true;
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
