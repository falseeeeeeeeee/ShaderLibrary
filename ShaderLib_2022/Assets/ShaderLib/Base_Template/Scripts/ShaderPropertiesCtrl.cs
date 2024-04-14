using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderPropertiesCtrl : MonoBehaviour
{
    public Texture2D[] ordinaryTextures;
    private Texture2DArray texture2DArray;
    public int curLayer = 0;

    private void CreateTextureArray()
    {
        // 创建贴图数组
        texture2DArray = new Texture2DArray(ordinaryTextures[0].width, ordinaryTextures[0].height,
            ordinaryTextures.Length, TextureFormat.RGBA32, true, false);
        // 应用设置
        texture2DArray.filterMode = FilterMode.Bilinear;
        texture2DArray.wrapMode = TextureWrapMode.Repeat;
        // 循环
        for (int i = 0; i < ordinaryTextures.Length; i++)
        {
            texture2DArray.SetPixels(ordinaryTextures[i].GetPixels(0), i, 0);
        }

        // 应用
        texture2DArray.Apply();
    }

    void Start()
    {
        CreateTextureArray();
    }

    private void Update()
    {
        if (curLayer < ordinaryTextures.Length)
        {
            Shader.SetGlobalFloat("_CurLayer", curLayer);
            Shader.SetGlobalTexture("_MultiTextures", texture2DArray);
        }
    }
}