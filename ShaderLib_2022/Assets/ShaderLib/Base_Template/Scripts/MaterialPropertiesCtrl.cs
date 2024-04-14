using UnityEngine;

public class MaterialPropertiesCtrl : MonoBehaviour
{
    void Start()
    {
        Material material = GetComponent<MeshRenderer>().material;
        // Material material = GetComponent<MeshRenderer>().sharedMaterial;

        {
            
        }
        
        material.SetColor("_BaseColor", Color.red);
    }
}
