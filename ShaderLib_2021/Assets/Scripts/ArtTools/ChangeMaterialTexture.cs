using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ChangeMaterialTexture : MonoBehaviour
{
    [System.Serializable]
    public class TextureSet
    {
        public string shaderProperty; // Shader属性名
        public Texture[] textures; // 贴图数组
    }

    public List<TextureSet> textureSets = new List<TextureSet>(); // 存储所有的TextureSet

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
            UpdateTextures();
            previousIndex = textureIndex;
        }
    }

    // 当Inspector的值发生变化时调用
    private void OnValidate()
    {
        UpdateTextures();
    }

    // 使用此方法来切换贴图
    private void UpdateTextures()
    {
        if (rend)
        {
            foreach (var textureSet in textureSets)
            {
                if (textureSet.textures.Length > 0)
                {
                    int index = Mathf.Clamp(textureIndex, 0, textureSet.textures.Length - 1);
                    rend.material.SetTexture(textureSet.shaderProperty, textureSet.textures[index]);
                }
            }
        }
    }
}
