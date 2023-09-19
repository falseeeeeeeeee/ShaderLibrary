using UnityEngine;

[ExecuteInEditMode]
public class ChangeMaterialTexture : MonoBehaviour
{
    public Texture[] textures; // 贴图数组
    public string shaderProperty = "_RampTex"; // Shader属性名

    [Range(0, 10)] // 默认最大值为10，但会在Start()中根据textures的长度进行调整
    public int textureIndex = 0; // 滑条

    private Renderer rend; // 渲染器
    private int previousIndex = -1; // 用于跟踪上一个贴图索引

    private void OnEnable()
    {
        rend = GetComponent<Renderer>();
    }

    private void Update()
    {
        if (textureIndex != previousIndex) // 如果索引发生变化
        {
            UpdateTexture();
            previousIndex = textureIndex;
        }
    }

    // 当Inspector的值发生变化时调用
    private void OnValidate()
    {
        UpdateTexture();
    }

    // 使用此方法来切换贴图
    private void UpdateTexture()
    {
        if (rend && textures.Length > 0)
        {
            textureIndex = Mathf.Clamp(textureIndex, 0, textures.Length - 1);
            rend.material.SetTexture(shaderProperty, textures[textureIndex]);
        }
    }
}
