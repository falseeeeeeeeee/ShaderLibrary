using UnityEngine;
using UnityEditor;
using System.IO;
using System.Text;
using UnityEditor.ProjectWindowCallback;
using System.Text.RegularExpressions;

public class CreateCustomShader
{
    // 通用方法，用于从给定的模板路径创建Shader
    private static void CreateShaderTemplate(string templatePath, string defaultFileName)
    {
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0,
            ScriptableObject.CreateInstance<ShaderAsset>(),
            GetSelectedPathOrFallback() + "/" + defaultFileName,
            null,
            templatePath);
    }

    // 为Shader创建菜单项
    [MenuItem("Assets/Create/Shader/URP Unlit Shader")]
    public static void CreateURPUnlitShader()
    {
        string templatePath = "Assets/Plugins/CreateCustomShader/Shader/S_URPUnlitShader.shader";
        CreateShaderTemplate(templatePath, "S_URPUnlitShader.shader");
    }

    // 创建多个Shader
    [MenuItem("Assets/Create/Shader/Other Shader")]
    // public static void CreateOtherShader()
    // {
    //     // 替换以下路径和文件名以匹配你的第二个Shader模板
    //     string templatePath = "Assets/Plugins/CreateCustomShader/Shader/S_OtherShader.shader";
    //     CreateShaderTemplate(templatePath, "S_OtherShader.shader");
    // }

    //获取选择的路径
    public static string GetSelectedPathOrFallback()
    {
        string path = "Assets";
        foreach (UnityEngine.Object obj in Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets))
        {
            path = AssetDatabase.GetAssetPath(obj);
            if (!string.IsNullOrEmpty(path) && File.Exists(path))
            {
                path = Path.GetDirectoryName(path);
                break;
            }
        }

        return path;
    }
}

class ShaderAsset : EndNameEditAction
{
    public override void Action(int instanceId, string pathName, string resourceFile)
    {
        UnityEngine.Object o = CreateScriptAssetFromTemplate(pathName, resourceFile);
        ProjectWindowUtil.ShowCreatedAsset(o);
    }

    internal static UnityEngine.Object CreateScriptAssetFromTemplate(string pathName, string resourceFile)
    {
        string fullPath = Path.GetFullPath(pathName);
        StreamReader streamReader = new StreamReader(resourceFile);
        string text = streamReader.ReadToEnd(); //读取模板内容
        streamReader.Close();
        string fileNameWithoutExtension = Path.GetFileNameWithoutExtension(pathName);
        text = Regex.Replace(text, "#NAME#", fileNameWithoutExtension); //将模板的#NAME# 替换成文件名

        //写入文件，并导入资源
        bool encoderShouldEmitUTF8Identifier = true;
        bool throwOnInvalidBytes = false;
        UTF8Encoding encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier, throwOnInvalidBytes);
        bool append = false;
        StreamWriter streamWriter = new StreamWriter(fullPath, append, encoding);
        streamWriter.Write(text);
        streamWriter.Close();
        AssetDatabase.ImportAsset(pathName);
        return AssetDatabase.LoadAssetAtPath(pathName, typeof(UnityEngine.Object));
    }
}