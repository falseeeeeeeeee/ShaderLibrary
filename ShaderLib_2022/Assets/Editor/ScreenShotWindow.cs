using System.IO;
using UnityEditor;
using UnityEngine;

public class ScreenShotWindow : EditorWindow
{
    private Camera m_Camera;
    private string filePath;
    private bool m_IsEnableAlpha = false;
    private CameraClearFlags m_CameraClearFlags;

    [MenuItem("Tools/屏幕截图")]
    private static void Init()
    {
        ScreenShotWindow window = GetWindowWithRect<ScreenShotWindow>(new Rect(0, 0, 300, 150));
        window.titleContent = new GUIContent("屏幕截图");
        window.Show();
    }

    private void OnGUI()
    {
        EditorGUILayout.Space();
        m_Camera = EditorGUILayout.ObjectField("选择摄像机", m_Camera, typeof(Camera), true) as Camera;

        if (GUILayout.Button("选择保存位置"))
        {
            filePath = EditorUtility.OpenFolderPanel("", "", "");
        }
        
        m_IsEnableAlpha = EditorGUILayout.Toggle("是否使用纯色背景", m_IsEnableAlpha);  //是否开启透明通道
        EditorGUILayout.Space();
        if (GUILayout.Button("单摄像机截图"))
        {
            TakeShot();
        }
        if (GUILayout.Button("窗口截图（含UI）"))
        {
            string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
            ScreenCapture.CaptureScreenshot(fileName);
        }
        EditorGUILayout.Space();
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

    private void TakeShot()
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
        string fileName = filePath + "/" + $"{System.DateTime.Now:yyyy-MM-dd_HH-mm-ss}" + ".png";
        File.WriteAllBytes(fileName, bytes);
        Debug.Log("截图成功");
    }
}