using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ControllerMatetialShader : MonoBehaviour
{
    [Header("ShaderProperties")] 
    public List<ShaderFloatList> ShaderFloatName = new List<ShaderFloatList>();
    public List<ShaderVectorList> ShaderVectorName = new List<ShaderVectorList>();
    public List<ShaderColorList> ShaderColorName = new List<ShaderColorList>();
    [Header("MaterialProperties")] 
    public List<MaterialFloatList> MaterialFloatName = new List<MaterialFloatList>();

    void Update()
    {
        for (int i = 0; i < ShaderFloatName.Count; i++)
        {
            if (ShaderFloatName[i]==null)
            {
                continue;
            }
            ShaderFloatName[i].SetShaderFloat();
        }        
        for (int i = 0; i < ShaderVectorName.Count; i++)
        {
            if (ShaderVectorName[i]==null)
            {
                continue;
            }
            ShaderVectorName[i].SetShaderVector();
        }        
        for (int i = 0; i < ShaderColorName.Count; i++)
        {
            if (ShaderColorName[i]==null)
            {
                continue;
            }
            ShaderColorName[i].SetShaderColor();
        }        
        
        for (int i = 0; i < MaterialFloatName.Count; i++)
        {
            if (MaterialFloatName[i]==null)
            {
                continue;
            }
            MaterialFloatName[i].SetMaterialFloat();
        }
    }
    
    [System.Serializable] 
    public class ShaderFloatList
    {
        public string ShaderFloatName = "_DebugSwitch";
        public float Switch;

        public void SetShaderFloat()
        {
            Shader.SetGlobalFloat(ShaderFloatName,Switch);
        }
    }    
    
    [System.Serializable] 
    public class ShaderVectorList
    {
        public string ShaderVectorName = "_DebugDir";
        public Vector4 Vector;

        public void SetShaderVector()
        {
            Shader.SetGlobalVector(ShaderVectorName,Vector);
        }
    }    
    
    [System.Serializable] 
    public class ShaderColorList
    {
        public string ShaderColorName = "_DebugColor";
        public Color Color;

        public void SetShaderColor()
        {
            Shader.SetGlobalColor(ShaderColorName,Color);
        }
    }

    [System.Serializable] 
    public class MaterialFloatList
    {
        public Material Material;
        public string MaterialFloatName = "_CloseSwitch";
        [Range(0f,1f)] public float Switch;

        public void SetMaterialFloat()
        {
            if (Material == null)
            {
                return;
            }
            Material.SetFloat(MaterialFloatName,Switch);
        }
    }
}