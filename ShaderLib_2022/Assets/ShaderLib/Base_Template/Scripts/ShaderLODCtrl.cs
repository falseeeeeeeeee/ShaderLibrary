using UnityEngine;

public class ShaderLODCtrl : MonoBehaviour
{
    public int lodLevel = 600;
    void Start()
    {
        Shader.globalMaximumLOD = lodLevel;

    }
}
