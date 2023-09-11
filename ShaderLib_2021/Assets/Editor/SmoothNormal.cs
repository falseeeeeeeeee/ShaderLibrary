using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class SmoothNormal : EditorWindow
{
    // Statue Vals
    private static bool isTangentSpace = false;
    
    private void OnGUI()
    {
        // Get Object
        if (Selection.activeGameObject == null)
        {
            return;
        }        
        Transform selectedObject = Selection.activeGameObject.transform;
        
        // Check is null
        if (selectedObject == null)
        {
            EditorGUILayout.LabelField("Please Select a gameObject that you want to smooth normal!");    
            return;
        }
        
        // Get Mesh
        var meshFilter          = selectedObject.GetComponent<MeshFilter>();
        var skinnedMeshRenderer = selectedObject.GetComponent<SkinnedMeshRenderer>();
        Mesh mesh = null;
        if (meshFilter != null)
        {
            mesh = meshFilter.sharedMesh;
        }
        else if(skinnedMeshRenderer != null)
        {
            mesh = skinnedMeshRenderer.sharedMesh;
        }
        else
        {
            EditorGUILayout.LabelField("Selected object without mesh");
            return;
        }

        // Draw GUI
        EditorGUILayout.BeginVertical();
        EditorGUILayout.LabelField("You are selecting: " + selectedObject.name);
        
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Is normal data is in TangentSpace?");
        isTangentSpace = EditorGUILayout.Toggle(isTangentSpace);
        
        EditorGUILayout.EndHorizontal();
        
        // Set data to channel
        if (GUILayout.Button("Generate smooth normals into color  channel"))
        {
            SetObject2Channel(ref mesh, Channel.color);
        }
        if (GUILayout.Button("Generate smooth normals into normal  channel"))
        {
            SetObject2Channel(ref mesh, Channel.normal);
        }
        if (GUILayout.Button("Generate smooth normals into tangent  channel"))
        {
            SetObject2Channel(ref mesh, Channel.tangent);
        }
        
        EditorGUILayout.EndVertical();
    }

    [MenuItem("Tools/Smooth Normal")]
    private static void OpenWindows()
    {
        GetWindow<SmoothNormal>(false, "smooth normal", true).Show();
    }

    private enum Channel
    {
        color,
        normal,
        tangent
    }
    
    private static Vector3[] GenerateSmoothNormals(Mesh srcMesh)
    {
        Vector3[] verticies = srcMesh.vertices;
        Vector3[] normals = srcMesh.normals;
        Vector3[] smoothNormals = normals;

        var averageNormalsDict = new Dictionary<Vector3, Vector3>();
        for (int i = 0; i < verticies.Length; i++)
        {
            if (!averageNormalsDict.ContainsKey(verticies[i]))
            {
                averageNormalsDict.Add(verticies[i], normals[i]);
            }
            else
            {
                averageNormalsDict[verticies[i]] = (averageNormalsDict[verticies[i]] + normals[i]).normalized;
            }
        }

        for (int i = 0; i < smoothNormals.Length; i++)
        {
            smoothNormals[i] = averageNormalsDict[verticies[i]];
        }

        if (isTangentSpace)
        {
            return GetTangentSpaceNormal(smoothNormals, srcMesh);    
        }
        return smoothNormals;
    }
    
    private static Vector3[] GetTangentSpaceNormal(Vector3[] smoothedNormals, Mesh srcMesh)
    {
        Vector3[] normals = srcMesh.normals;
        Vector4[] tangents = srcMesh.tangents;

        Vector3[] smoothedNormals_TS = new Vector3[smoothedNormals.Length];

        for (int i = 0; i < smoothedNormals_TS.Length; i++)
        {
            Vector3 normal  = normals[i];
            Vector4 tangent = tangents[i];

            Vector3 tangentV3 = new Vector3(tangent.x, tangent.y, tangent.z);

            var bitangent = Vector3.Cross(normal, tangentV3) * tangent.w;
            bitangent        = bitangent.normalized;

            var TBN = new Matrix4x4(tangentV3, bitangent, normal, Vector4.zero);
            TBN = TBN.transpose;

            var smoothedNormal_TS = TBN.MultiplyVector(smoothedNormals[i]).normalized;
            
            smoothedNormals_TS[i] = smoothedNormal_TS;
        }

        return smoothedNormals_TS;
    }
    
    private static Vector4[] ConvertV3ToV4Array(Vector3[] v_Array)
    {
        Vector4[] v_Array_AfterConvert = new Vector4[v_Array.Length];

        for (int i = 0; i < v_Array_AfterConvert.Length; i++)
        {
            Vector4 v4 = new Vector4();
            Vector3 v3 = v_Array[i];
            v4.x = v3.x;
            v4.y = v3.y;
            v4.z = v3.z;
            v4.w = 1.0f;

            v_Array_AfterConvert[i] = v4;
        }

        return v_Array_AfterConvert;
    }
    
    private static Color[] ConvertV3ToColor(Vector3[] v_Array)
    {
        Color[] v_Array_AfterConvert = new Color[v_Array.Length];

        for (int i = 0; i < v_Array_AfterConvert.Length; i++)
        {
            Color v4 = new Color();
            Vector3 v3 = v_Array[i];
            v4.r = v3.x;
            v4.g = v3.y;
            v4.b = v3.z;
            v4.a = 1.0f;

            v_Array_AfterConvert[i] = v4;
        }

        return v_Array_AfterConvert;
    }
    
    /*private static bool SetObject2Channel(ref Mesh selectedMesh, Channel channel)
    {
        switch (channel)
        {
            case Channel.color:
                selectedMesh.colors   = ConvertV3ToColor(GenerateSmoothNormals(selectedMesh));
                break;
            case Channel.normal:
                selectedMesh.normals  = GenerateSmoothNormals(selectedMesh);
                break;
            case Channel.tangent:
                selectedMesh.tangents = ConvertV3ToV4Array(GenerateSmoothNormals(selectedMesh));
                break;
            
            default:
                return false;
        }

        return true;
    }*/
    
    private static bool SetObject2Channel(ref Mesh selectedMesh, Channel channel)
    {
        Mesh newMesh = Instantiate(selectedMesh); // 创建一个新的Mesh
        string newPath = "Assets/ShaderLib/Render_Townscaper/Townscaper/SmoothMeshes/" + selectedMesh.name + "_SmoothNormal.asset"; // 创建新的路径

        switch (channel)
        {
            case Channel.color:
                newMesh.colors = ConvertV3ToColor(GenerateSmoothNormals(newMesh));
                break;
            case Channel.normal:
                newMesh.normals = GenerateSmoothNormals(newMesh);
                break;
            case Channel.tangent:
                newMesh.tangents = ConvertV3ToV4Array(GenerateSmoothNormals(newMesh));
                break;

            default:
                return false;
        }

        AssetDatabase.CreateAsset(newMesh, newPath); // 将新的Mesh保存到.asset文件中
        AssetDatabase.SaveAssets(); // 保存所有更改

        var meshFilter = Selection.activeGameObject.GetComponent<MeshFilter>();
        var skinnedMeshRenderer = Selection.activeGameObject.GetComponent<SkinnedMeshRenderer>();

        if (meshFilter != null)
        {
            meshFilter.sharedMesh = newMesh; // 设置新的Mesh
        }
        else if(skinnedMeshRenderer != null)
        {
            skinnedMeshRenderer.sharedMesh = newMesh; // 设置新的Mesh
        }

        return true;
    }
}

