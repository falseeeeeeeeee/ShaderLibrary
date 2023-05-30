using System;
using System.IO;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

public class ScreenShotWindow : EditorWindow
{
    private static Camera m_Camera;
    private string filePath= System.Environment.CurrentDirectory+"/Recordings";
    
    private bool m_IsEnableAlpha = false;
    private CameraClearFlags m_CameraClearFlags;

    private bool ChoosingPath = false;
    private bool CustomName = false;

    private Vector2 scrollPosition;

    public string Name= new string("{PathName}");

    [MenuItem("Tools/屏幕截图")]
    private static void Init()
    {
        ScreenShotWindow window = GetWindowWithRect<ScreenShotWindow>(new Rect(0, 0, 300, 300));
        window.titleContent = new GUIContent("屏幕截图");
        window.Show();
        m_Camera=Camera.main;
    }
    
    private void OnGUI()
    {
        if (!Directory.Exists(filePath))
        {
            Directory.CreateDirectory(filePath);
        }
        
        EditorGUILayout.Space();
        m_Camera = EditorGUILayout.ObjectField( new GUIContent("选择摄像机", 
            "默认为Main Camera，可以选择别的摄像机"), m_Camera, typeof(Camera), true) as Camera;
        m_IsEnableAlpha = EditorGUILayout.Toggle(new GUIContent("使用透明背景", 
            "勾选后，在不开启后期处理的情况，把摄像机的背景改为纯色，它就会生效"), m_IsEnableAlpha);
        ChoosingPath = EditorGUILayout.Toggle(new GUIContent("自定义保存位置", 
            "默认保存位置为当前选中选中的文件夹。当勾选自定义内容后，默认保存位置为项目文件夹下的Recordings目录，然后可以手动选择指定路径"), ChoosingPath);
        CustomName = EditorGUILayout.Toggle(new GUIContent("自定义文件名称",
            "默认名称为当前时间，勾选后即可自定义内容，{PathName}为当前选择到的文件夹名称"), CustomName);
        
        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);

        if (ChoosingPath)
        {
            EditorGUILayout.Space(2f);
            if (CustomName)
            {
                Name = EditorGUILayout.TextField("文件名称：", Name);
            }

            EditorGUILayout.Space(4f);
            if (GUILayout.Button("使用选择的摄像机截图"))
            {
                TakeShotInPath();
            }
            if (GUILayout.Button("Game窗口截图（含UI）"))
            {
                string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
                if (CustomName)
                {
                    string name = GetFileName(Name,filePath);
                    name = FindAvailableName(filePath, name);
                    fileName = filePath + "/" + name + ".png";
                }
                ScreenCapture.CaptureScreenshot(fileName);
            }
            EditorGUILayout.Space(12f);

            if (GUILayout.Button("选择保存位置"))
            {
                filePath = EditorUtility.OpenFolderPanel("", "", "");
            }
            
            if (GUILayout.Button("打开导出文件夹"))
            {
                if (string.IsNullOrEmpty(filePath))
                {
                    Debug.LogError("<color=red>" + "没有选择截图保存位置" + "</color>");
                    return;
                }
                Application.OpenURL("file://" + filePath);
            }
        }
        else
        {
            EditorGUILayout.Space(2f);
            if (CustomName)
            {
                Name = EditorGUILayout.TextField("文件名称：", Name);
            }

            EditorGUILayout.Space(4f);
            if (GUILayout.Button("使用选择的摄像机截图"))
            {
                TakeShot();
            }
            if (GUILayout.Button("Game窗口截图（含UI）"))
            {
                string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
                if (CustomName)
                {
                    string _filePath = GetCurrentAssetDirectory();
                    string name = GetFileName(Name, _filePath);
                    name = FindAvailableName(_filePath, name);
                    fileName = _filePath + "/" + name + ".png";
                }
                ScreenCapture.CaptureScreenshot(fileName);
            }
            EditorGUILayout.Space(12f);
        }
        
        EditorGUILayout.EndScrollView();
    }

    private void TakeShot()
    {
        // 文件夹路径
        string _filePath = GetCurrentAssetDirectory();

        if (m_Camera == null)
        {
            Debug.LogError("<color=red>" + "没有选择摄像机" + "</color>");
            return;
        }

        if (string.IsNullOrEmpty(_filePath))
        {
            Debug.LogError("<color=red>" + "没有选择截图保存位置" + "</color>");
            return;
        }

        m_CameraClearFlags = m_Camera.clearFlags;
        if (m_IsEnableAlpha)
        {
            m_Camera.clearFlags = CameraClearFlags.Depth;
        }

        int resolutionX = (int)Handles.GetMainGameViewSize().x;
        int resolutionY = (int)Handles.GetMainGameViewSize().y;
        RenderTexture rt = new RenderTexture(resolutionX, resolutionY, 24);
        m_Camera.targetTexture = rt;
        Texture2D screenShot = new Texture2D(resolutionX, resolutionY, TextureFormat.ARGB32, false);
        m_Camera.Render();
        RenderTexture.active = rt;
        screenShot.ReadPixels(new Rect(0, 0, resolutionX, resolutionY), 0, 0);
        m_Camera.targetTexture = null;
        RenderTexture.active = null;
        m_Camera.clearFlags = m_CameraClearFlags;
        //Destroy(rt);
        byte[] bytes = screenShot.EncodeToPNG();

        if (CustomName)
        {
            Name = EditorGUILayout.TextField("文件名称：", Name);
            string name = GetFileName(Name, _filePath);
            name = FindAvailableName(_filePath, name);
            string fileName = _filePath + "/" + name + ".png";
            File.WriteAllBytes(fileName, bytes);
        }
        else
        {
            string fileName = _filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
            File.WriteAllBytes(fileName, bytes);
        }

        Debug.Log("截图成功");
        AssetDatabase.Refresh();
    }

    private void TakeShotInPath()
    {
        if (m_Camera == null)
        {
            Debug.LogError("<color=red>" + "没有选择摄像机" + "</color>");
            return;
        }

        if (string.IsNullOrEmpty(filePath))
        {
            Debug.LogError("<color=red>" + "没有选择截图保存位置" + "</color>");
            return;
        }

        m_CameraClearFlags = m_Camera.clearFlags;
        if (m_IsEnableAlpha)
        {
            m_Camera.clearFlags = CameraClearFlags.Depth;
        }

        int resolutionX = (int)Handles.GetMainGameViewSize().x;
        int resolutionY = (int)Handles.GetMainGameViewSize().y;
        RenderTexture rt = new RenderTexture(resolutionX, resolutionY, 24);
        m_Camera.targetTexture = rt;
        Texture2D screenShot = new Texture2D(resolutionX, resolutionY, TextureFormat.ARGB32, false);
        m_Camera.Render();
        RenderTexture.active = rt;
        screenShot.ReadPixels(new Rect(0, 0, resolutionX, resolutionY), 0, 0);
        m_Camera.targetTexture = null;
        RenderTexture.active = null;
        m_Camera.clearFlags = m_CameraClearFlags;
        //Destroy(rt);
        byte[] bytes = screenShot.EncodeToPNG();

        if (CustomName)
        {
            Name = EditorGUILayout.TextField("文件名称：", Name);
            string name=GetFileName(Name,filePath);
            name = FindAvailableName(filePath, name);
            string fileName = filePath + "/" + name+ ".png";

            File.WriteAllBytes(fileName, bytes);
        }
        else
        {
            string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
            File.WriteAllBytes(fileName, bytes);
        }
        Debug.Log("截图成功");
        AssetDatabase.Refresh();
    }

    public static string GetCurrentAssetDirectory()
    {
        string[] guids = Selection.assetGUIDs;//获取当前选中的asset的GUID
        for (int i = 0; i < guids.Length;)
        {
            string assetPath = AssetDatabase.GUIDToAssetPath(guids[i]);//通过GUID获取路径
            return assetPath;
        }
        return null;
    }

    public string GetFileName(string input,string _filePath)
    {
        // 使用正则表达式查找 {} 内的内容
        string pattern = @"\{([^}]*)\}";
        string dirName = Path.GetFileName(_filePath.TrimEnd(Path.DirectorySeparatorChar));
        string replacedString = Regex.Replace(input, pattern, dirName);

        return replacedString;
    }

    public static string FindAvailableName(string path, string inputName)
    {
        // 获取路径中的文件名列表
        string[] fileNames = Directory.GetFiles(path);

        // 遍历文件名列表
        int suffix = 1;
        string newName = inputName;

        for (int i = 0; i < fileNames.Length; i++)
        {
            if (fileNames[i].EndsWith(".png"))
            {
                fileNames[i] = fileNames[i].Substring(0,fileNames[i].Length - 4);
            }
        }

        while (Array.Exists(fileNames, name => name.Equals(Path.Combine(path, newName))))
        {
            if (suffix >= 10)
            {
                // 如果存在相同的文件名，则在输入名称后面添加一个数字后缀
                newName = $"{inputName}_{suffix}";
            }
            else
            {
                newName = $"{inputName}_0{suffix}";
            }

            suffix++;
        }

        return newName;
    }
}