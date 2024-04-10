using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using Unity.Jobs;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;

public class OutlineBaker : AssetPostprocessor
{
    static bool bExecuting = false; //开关

    [MenuItem("Tools/BakeMesh", false, 50)]
    public static void BakeMesh()
    {
        Object obj = Selection.activeObject;

        string path = AssetDatabase.GetAssetPath(obj);
        string ext = Path.GetExtension(path);

        if (ext == ".fbx")
        {
            bExecuting = true;

            string newPath = Path.GetDirectoryName(path) + "/copy_@@@" + Path.GetFileName(path); //../Assets/Model/copy_@@@cube.obj
            Debug.Log($"new path = {newPath}");
            AssetDatabase.CopyAsset(path, newPath);
            // AssetDatabase.ImportAsset(newPath);

        }
        else
        {
            Debug.LogError($"必须对.fbx文件进行此操作!");
        }
    }
    static void OnPostOver(string path, bool isCopy)
    {
        if (isCopy)
        {
            string srcPath = path.Replace("copy_@@@", "");
            Debug.Log($"复制体后处理完毕,本体的path={srcPath}");
            AssetDatabase.ImportAsset(srcPath);
            
            // 延迟调用删除复制体文件
            EditorApplication.delayCall += () =>
            {
                if (AssetDatabase.DeleteAsset(path))
                {
                    Debug.Log($"成功删除复制体: {path}，并且烘焙平滑法线到顶点色成功");
                }
                else
                {
                    Debug.LogError($"删除复制体失败: {path}");
                }
            };
        }
        else
        {
            Debug.Log($"烘焙完毕!关闭开关!");
            bExecuting = false;
        }
    }

    //================Inherit================
    void OnPreprocessModel()
    {
        if (!bExecuting) return;

        //导入设置
        ModelImporter importer = assetImporter as ModelImporter;

        if (!assetImporter.assetPath.Contains("copy_@@@")) return;

        importer.importNormals = ModelImporterNormals.Calculate;
        importer.normalCalculationMode = ModelImporterNormalCalculationMode.AngleWeighted;
        importer.normalSmoothingAngle = 180f;

        importer.importAnimation = false; //不导入动画
        importer.materialImportMode = ModelImporterMaterialImportMode.None; //不导入材质
    }


    void OnPostprocessModel(GameObject go)
    {
        if (!bExecuting) return;
        //导入完以后,自定义的操作
        if (go.name.Contains("copy_@@@"))
        {
            OnPostOver(assetPath, true);
        }
        else
        {
            Debug.Log($"本体进入流程!");
            string copyPath = Path.GetDirectoryName(assetPath) + "/copy_@@@" + Path.GetFileName(assetPath);
            Debug.Log($"复制体的Path = {copyPath}");
            GameObject cGo = AssetDatabase.LoadAssetAtPath<GameObject>(copyPath);

            Dictionary<string, Mesh> dic_name2mesh_src = GetMesh(go); //原本模型的各个子Mesh , 通过节点名索引
            Dictionary<string, Mesh> dic_name2mesh_copy = GetMesh(cGo); //平滑模型的各个子Mesh , 通过节点名索引

            foreach (var item in dic_name2mesh_src)
            {
                item.Value.colors = GetColor(item.Value, dic_name2mesh_copy[item.Key]);
            }
            OnPostOver("", false);
        }
    }

    Dictionary<string, Mesh> GetMesh(GameObject go)
    {
        Dictionary<string, Mesh> dic = new();
        foreach (var item in go.GetComponentsInChildren<MeshFilter>())
        {
            string n = item.name.Replace("copy_@@@", "");
            dic.Add(n, item.sharedMesh);
        }
        if (dic.Count == 0)
        {
            foreach (var item in go.GetComponentsInChildren<SkinnedMeshRenderer>())
            {
                string n = item.name.Replace("copy_@@@", "");
                dic.Add(n, item.sharedMesh);
            }
        }

        return dic;
    }
    Color[] GetColor(Mesh srcMesh, Mesh smthMesh)
    {
        //按照顶点位置索引,来烘焙信息
        int lenSrc = srcMesh.vertices.Length;
        int lenSmth = smthMesh.vertices.Length;
        int maxOverlap = 10;

        NativeArray<Vector3> arr_vert_smth = new(smthMesh.vertices, Allocator.Persistent);
        NativeArray<Vector3> arr_normal_smth = new(smthMesh.normals, Allocator.Persistent);
        NativeArray<UnsafeParallelHashMap<Vector3, Vector3>> arr_vert2normal = new(maxOverlap, Allocator.Persistent);
        NativeArray<UnsafeParallelHashMap<Vector3, Vector3>.ParallelWriter> arr_vert2normal_writer = new(maxOverlap, Allocator.Persistent);
        for (int i = 0; i < maxOverlap; i++)
        {
            Debug.Log($"Lenth = {lenSmth}");
            arr_vert2normal[i] = new UnsafeParallelHashMap<Vector3, Vector3>(lenSmth, Allocator.Persistent);
            arr_vert2normal_writer[i] = arr_vert2normal[i].AsParallelWriter();
        }

        CollectNormalJob collectJob = new()
        {
            verts = arr_vert_smth,
            normals = arr_normal_smth,
            arr_vert2normal = arr_vert2normal_writer
        };
        JobHandle collectHandle = collectJob.Schedule(lenSmth, 128); //开始收集顶点信息
        collectHandle.Complete();

        NativeArray<Vector3> arr_vert_src = new(srcMesh.vertices, Allocator.Persistent);
        NativeArray<Vector3> arr_nor_src = new(srcMesh.normals, Allocator.Persistent);
        NativeArray<Vector4> arr_tgt_src = new(srcMesh.tangents, Allocator.Persistent);

        NativeArray<Color> arr_color = new(lenSrc, Allocator.Persistent);

        BakeNormalJob bakeJob = new()
        {
            normals = arr_nor_src,
            verts = arr_vert_src,
            tangents = arr_tgt_src,
            bakedNormals = arr_vert2normal,
            colors = arr_color
        };
        JobHandle bakeHandle = bakeJob.Schedule(lenSrc, 128); //开始烘焙顶点色
        bakeHandle.Complete(); //烘焙完成

        Color[] cols = new Color[lenSrc];
        arr_color.CopyTo(cols);


        foreach (var item in arr_vert2normal)
        {
            item.Dispose();
        }
        arr_vert_smth.Dispose();
        arr_normal_smth.Dispose();
        arr_vert2normal.Dispose();
        arr_vert2normal_writer.Dispose();
        arr_vert_src.Dispose();
        arr_nor_src.Dispose();
        arr_tgt_src.Dispose();
        arr_color.Dispose();

        return cols;
    }

    struct CollectNormalJob : IJobParallelFor
    {
        [ReadOnly] public NativeArray<Vector3> verts;
        [ReadOnly] public NativeArray<Vector3> normals;

        //顶点 - 法线 的映射
        [NativeDisableContainerSafetyRestriction] //解除安全锁
        // public NativeArray<UnsafeHashMap<Vector3, Vector3>.ParallelWriter> arr_vert2normal; //顶点 - 法线
        public NativeArray<UnsafeParallelHashMap<Vector3, Vector3>.ParallelWriter> arr_vert2normal; //顶点 - 法线

        public void Execute(int index)
        {
            //每一次执行
            for (int i = 0; i <= arr_vert2normal.Length; i++)
            {
                if (i == arr_vert2normal.Length)
                {
                    Debug.LogError($"超出顶点限制!");
                    break;
                }
                if (arr_vert2normal[i].TryAdd(verts[index], normals[index]))
                {
                    Debug.Log($"当前添加:顶点:{verts[index]}, 法线:{normals[index]}");
                    break;
                }
            }
        }
    }

    struct BakeNormalJob : IJobParallelFor
    {
        //切线空间  切线,法线,顶点位置,烘焙好的法线  输出-颜色数组

        [ReadOnly] public NativeArray<Vector3> normals;
        [ReadOnly] public NativeArray<Vector3> verts;
        [ReadOnly] public NativeArray<Vector4> tangents;
        [ReadOnly][NativeDisableContainerSafetyRestriction] public NativeArray<UnsafeParallelHashMap<Vector3, Vector3>> bakedNormals;

        public NativeArray<Color> colors;

        public void Execute(int index)
        {

            Vector3 newNormal = Vector3.zero;

            for (int i = 0; i < bakedNormals.Length; i++)
            {
                if (bakedNormals[i][verts[index]] != Vector3.zero)
                {
                    newNormal += bakedNormals[i][verts[index]];
                }
                else
                {
                    break;
                }
            }
            newNormal = newNormal.normalized;

            Vector3 bitangent = (Vector3.Cross(normals[index], tangents[index]) * tangents[index].w).normalized;

            Matrix4x4 tbn = new(
                tangents[index],
                bitangent,
                normals[index],
                Vector4.zero
                );
            tbn = tbn.transpose;

            Vector3 finalNormal = tbn.MultiplyVector(newNormal).normalized;


            Color col = new(
                finalNormal.x * 0.5f + 0.5f,
                finalNormal.y * 0.5f + 0.5f,
                finalNormal.z * 0.5f + 0.5f,
                1
                );

            colors[index] = col;
        }
    }
}
