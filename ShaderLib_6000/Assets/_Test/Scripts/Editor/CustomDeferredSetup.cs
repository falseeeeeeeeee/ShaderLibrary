using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public static class CustomDeferredSetup
{
    // Graphics Settings 路径
    private const string GlobalSettingsPath = "Assets/AssetRaw/Settings/URP/UniversalRenderPipelineGlobalSettings.asset";
    // ClusterDeferred Shader 官方路径
    private const string OfficialClusterDeferredPath = "Packages/com.unity.render-pipelines.universal/Shaders/Utils/ClusterDeferred.shader";

    private const string MenuRoot = "Tools/Custom Deferred/";

    [MenuItem(MenuRoot + "使用选择的 ClusterDeferred Shader")]
    private static void UseSelectedShader()
    {
        Shader selectedShader = Selection.activeObject as Shader;

        if (selectedShader == null)
        {
            Debug.LogError("请先在 Project 窗口中选中自定义的 ClusterDeferred.shader。");
            return;
        }

        ApplyClusterDeferredShader(selectedShader, "Set Custom ClusterDeferred Shader");
    }

    [MenuItem(MenuRoot + "还原官方的 ClusterDeferred Shader")]
    private static void RestoreOfficialShader()
    {
        Shader officialShader = AssetDatabase.LoadAssetAtPath<Shader>(OfficialClusterDeferredPath);

        if (officialShader == null)
        {
            Debug.LogError($"找不到官方 Shader：{OfficialClusterDeferredPath}");
            return;
        }

        ApplyClusterDeferredShader(officialShader, "Restore Official ClusterDeferred Shader");
    }

    private static void ApplyClusterDeferredShader(Shader shader, string undoName)
    {
        if (EditorApplication.isPlayingOrWillChangePlaymode)
        {
            Debug.LogError("请先退出 Play Mode。");
            return;
        }

        UniversalRendererResources resources = GraphicsSettings.GetRenderPipelineSettings <UniversalRendererResources>();

        if (resources == null)
        {
            Debug.LogError("找不到 UniversalRendererResources。");
            return;
        }

        ScriptableObject globalSettings = AssetDatabase.LoadAssetAtPath<ScriptableObject>(GlobalSettingsPath);

        if (globalSettings == null)
        {
            Debug.LogError($"找不到 URP Global Settings：{GlobalSettingsPath}");
            return;
        }

        Undo.RecordObject(globalSettings, undoName);

        resources.clusterDeferred = shader;

        EditorUtility.SetDirty(globalSettings);
        AssetDatabase.SaveAssets();

        Debug.Log($"Deferred+ Shader 已设置为：{shader.name}", shader);
    }
}