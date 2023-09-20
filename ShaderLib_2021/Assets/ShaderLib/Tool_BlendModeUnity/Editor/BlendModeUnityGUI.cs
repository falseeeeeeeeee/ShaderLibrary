using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class BlendModeUnityGUI : ShaderGUI
{
    MaterialEditor materialEditor;
    MaterialProperty[] materialProperty;
    Material targetMat;

    enum RenderingMode
    {
        Opaque, 
        AlphaCut,
        AlphaBlend,
        Additive,
        Multiply
    }
    enum CullMode
    {
        Off,
        Front,
        Back
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.materialEditor = materialEditor;
        this.materialProperty = properties;
        this.targetMat = materialEditor.target as Material;

        SetupCullMode();
        SetupRendingMode();

        DoMain();

        BaseColorPropertyShow();

        materialEditor.RenderQueueField();
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
    }

    void SetupRendingMode()
    {
        MaterialProperty rending = FindProperty("_Rending", materialProperty);

        string[] blendeModeNames = System.Enum.GetNames(typeof(RenderingMode));

        rending.floatValue = EditorGUILayout.Popup("Rending Mode", (int)rending.floatValue, blendeModeNames);
        int value = (int)rending.floatValue;

        switch (value)
        {
            case 0:
                targetMat.SetInt("_BlendOp", (int)UnityEngine.Rendering.BlendOp.Add);
                targetMat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                targetMat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                targetMat.SetInt("_ZWrite", 1);
                targetMat.EnableKeyword("_RENDING_OPACITY");
                targetMat.DisableKeyword("_RENDING_ALPHACUT");
                targetMat.DisableKeyword("_RENDING_ALPHABLEND");
                targetMat.DisableKeyword("_RENDING_ADDITIVE");
                targetMat.DisableKeyword("_RENDING_MULTIPLY");
                targetMat.renderQueue = 2000;
                break;
            case 1:
                targetMat.SetInt("_BlendOp", (int)UnityEngine.Rendering.BlendOp.Add);
                targetMat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                targetMat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                targetMat.SetInt("_ZWrite", 1);
                targetMat.DisableKeyword("_RENDING_OPACITY");
                targetMat.EnableKeyword("_RENDING_ALPHACUT");
                targetMat.DisableKeyword("_RENDING_ALPHABLEND");
                targetMat.DisableKeyword("_RENDING_ADDITIVE");
                targetMat.DisableKeyword("_RENDING_MULTIPLY");
                targetMat.renderQueue = 2450;

                DoAlphaCutoff();
                break;
            case 2:
                targetMat.SetInt("_BlendOp", (int)UnityEngine.Rendering.BlendOp.Add);
                targetMat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                targetMat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                targetMat.SetInt("_ZWrite", 0);
                targetMat.EnableKeyword("_RENDING_OPACITY");
                targetMat.DisableKeyword("_RENDING_ALPHACUT");
                targetMat.EnableKeyword("_RENDING_ALPHABLEND");
                targetMat.DisableKeyword("_RENDING_ADDITIVE");
                targetMat.DisableKeyword("_RENDING_MULTIPLY");
                targetMat.renderQueue = 3000;
                break;
            case 3:
                targetMat.SetInt("_BlendOp", (int)UnityEngine.Rendering.BlendOp.Add);
                targetMat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                targetMat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusDstColor);
                targetMat.SetInt("_ZWrite", 0);
                targetMat.DisableKeyword("_RENDING_OPACITY");
                targetMat.DisableKeyword("_RENDING_ALPHACUT");
                targetMat.DisableKeyword("_RENDING_ALPHABLEND");
                targetMat.EnableKeyword("_RENDING_ADDITIVE");
                targetMat.DisableKeyword("_RENDING_MULTIPLY");
                targetMat.renderQueue = 3000;
                break;
            case 4:
                targetMat.SetInt("_BlendOp", (int)UnityEngine.Rendering.BlendOp.Add);
                targetMat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.DstColor);
                targetMat.SetInt("_Dstend", (int)UnityEngine.Rendering.BlendMode.Zero);
                targetMat.SetInt("_ZWrite", 0);
                targetMat.DisableKeyword("_RENDING_OPACITY");
                targetMat.DisableKeyword("_RENDING_ALPHACUT");
                targetMat.DisableKeyword("_RENDING_ALPHABLEND");
                targetMat.DisableKeyword("_RENDING_ADDITIVE");
                targetMat.EnableKeyword("_RENDING_MULTIPLY");
                targetMat.renderQueue = 3000;
                break;

        }
    }

    void SetupCullMode()
    {
        MaterialProperty cullMode = FindProperty("_CullMode", materialProperty);
        string[] cullModeNames = System.Enum.GetNames(typeof(CullMode));
        cullMode.floatValue = EditorGUILayout.Popup("Cull Mode", (int)cullMode.floatValue, cullModeNames);

    }

    void DoMain()
    {
        GUILayout.Label("Base", EditorStyles.boldLabel);
        GUILayout.Space(4);
    }

    void BaseColorPropertyShow()
    {
        MaterialProperty baseColor = FindProperty("_BaseColor", materialProperty);
        MaterialProperty baseMap = FindProperty("_BaseMap", materialProperty);

        GUIContent content = new GUIContent(baseMap.displayName, baseMap.textureValue, "This is a main texture");

        materialEditor.TexturePropertySingleLine(content, baseMap, baseColor);
        using (new EditorGUI.IndentLevelScope())
        {
            materialEditor.TextureScaleOffsetProperty(baseMap);
        }
    }

    void DoAlphaCutoff()
    {
        MaterialProperty cutoff = FindProperty("_Cutoff", materialProperty);
        EditorGUI.indentLevel += 1;
        materialEditor.ShaderProperty(cutoff, cutoff.displayName);
        EditorGUI.indentLevel -= 1;
    }

    static void SetKeyword(Material m, string keyword, bool state)
    {
        if (state)
            m.EnableKeyword(keyword);
        else
            m.DisableKeyword(keyword);
    }
}
