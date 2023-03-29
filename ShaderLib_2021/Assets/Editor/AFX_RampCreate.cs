using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
public class AFX_RampCreate : EditorWindow
{
    Color[] colorall;
    bool isAlpha;
    public string tex2dName = "AFX_Ramp";
    public Texture tex;
    public Gradient gradient = new Gradient();
    public ParticleSystem  particle ;
    public TrailRenderer trail;
    public LineRenderer line;
    public string path = ">>还未选择保存路径";
    public string texname = "AFX_Ramp";
    private int valueRampsource = 4;
    public int serial = 1;
    public Vector2 resolution = new Vector2(256, 8);
    public float[] gaodus;
    [MenuItem("Tools/渐变图生成工具")]
    static void RampCreateWindow ()
    {
        AFX_RampCreate window = EditorWindow.GetWindow<AFX_RampCreate>();
        window.minSize = new Vector2(350, 600);
        window.titleContent = new GUIContent("渐变图生成工具");
        window.Show();
    }
    void SetPath1()
    {
        path = EditorUtility.OpenFolderPanel("", "", "");
    }
    private void OnGUI()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("搞一个新的渐变Gradient");
        gradient = EditorGUILayout.GradientField("Gradient", gradient);
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("随后设置输出分辨率");
        resolution = EditorGUILayout.Vector2Field(GUIContent.none, resolution);
        EditorGUILayout.EndHorizontal();
        if (GUILayout.Button("设为  256*8"))
            resolution = new Vector2(256, 8);
        if (GUILayout.Button("设为  512*8"))
            resolution = new Vector2(512, 8);
        EditorGUILayout.Space();
        isAlpha = EditorGUILayout.ToggleLeft("<<勾选 以导出包含Alpha通道的图", isAlpha);
        GUIStyle style = new GUIStyle("textfield");
        tex2dName = EditorGUILayout.TextField("输出文件命名：", tex2dName, style);
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("当前保存路径为：");
        EditorGUILayout.LabelField(path);
        bool ispath = GUILayout.Button("--选择保存路径--");
        if (ispath)
        {
            SetPath1();
            Debug.Log("你的保存路径为："+ path);
        }
        bool shengcheng = GUILayout.Button("--生成渐变图--");
        if (shengcheng)
        {
            OutRampTex();
        }
        EditorGUILayout.Space(20);
        EditorGUILayout.LabelField("---------------------------------------------------------");
        if (GUILayout.Button("打开导出文件夹"))
        {
            Application.OpenURL("file://" + path);
        }
        EditorGUILayout.Space(20);
        if (GUILayout.Button("查看使用教程（视频）"))
            Application.OpenURL("https://space.bilibili.com/7234711/channel/detail?cid=112022");
    }
    void OutRampTex()
    {
        colorall = new Color[(int)(resolution.x* resolution.y)];
        if (isAlpha == false)
        {
            gaodus = new float[(int)resolution.y];
            gaodus[0] = 0;
            float gao = 0;
            for (int g = 0; g < resolution.y; g++)
            {
                if (g == 0)
                {
                }
                else
                {
                    gao += resolution.x;
                    gaodus[g] = gao;
                }
            }
            for (int a = 0; a < resolution.y; a++)
            {
                for (int c = 0; c < resolution.x; c++)
                {
                    float temp = c / resolution.x;
                    colorall[(int)gaodus[a] + c] = gradient.Evaluate(temp);
                }
            }
        }
        else
        {
            gaodus = new float[(int)resolution.y];
            gaodus[0] = 0;
            float gao = 0;
            for (int g = 0; g < resolution.y; g++)
            {
                if (g == 0)
                {
                }
                else
                {
                    gao += resolution.x;
                    gaodus[g] = gao;
                }
            }
            for (int a = 0; a < resolution.y; a++)
            {
                for (int c = 0; c < resolution.x; c++)
                {
                    float temp = c / resolution.x;
                    colorall[(int)gaodus[a] + c] = gradient.Evaluate(temp);
                    colorall[(int)gaodus[a] + c].a = gradient.Evaluate(temp).a;
                }
            }
        }
        Save(colorall);
        Debug.Log("Ramp图已生成,"+"名称："+ tex2dName+",保存路径："+ path);
    }
    void Save(Color[] colors)
    {
        TextureFormat _texFormat;
        if (isAlpha)
        {
            _texFormat = TextureFormat.ARGB32;
        }
        else
        {
            _texFormat = TextureFormat.RGB24;
        }
        Texture2D tex = new Texture2D((int)resolution.x, (int)resolution.y, _texFormat, false);
        tex.SetPixels(colors);
        tex.Apply();
        byte[] bytes;
        bytes = tex.EncodeToPNG();
        string sname = tex2dName + "_" + serial;
        serial += 1;
            File.WriteAllBytes(path + "/" + sname + ".png", bytes);
        AssetDatabase.Refresh();
    }
}
