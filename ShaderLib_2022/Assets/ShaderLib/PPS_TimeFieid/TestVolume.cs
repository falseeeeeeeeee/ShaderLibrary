using UnityEngine;
using UnityEngine.Rendering;

public class TestVolume : MonoBehaviour
{
    TimeFieidVolume m_TFV;

    [ContextMenu("Test")]
    public void Test()
    {
        m_TFV.scatter.value = 0;

        VolumeParameter<float> vp = new();
        vp.value = 0;
        m_TFV.scatter.SetValue(vp);
    }

    void Awake()
    {
        Volume golbal = GameObject.Find("Global Volume").GetComponent<Volume>();
        var list = golbal.profile.components;
        foreach (var item in list)
        {
            if (item.GetType()==typeof(TimeFieidVolume))
            {
                m_TFV = item as TimeFieidVolume;
                break;
            }
            
        }
    }

}
