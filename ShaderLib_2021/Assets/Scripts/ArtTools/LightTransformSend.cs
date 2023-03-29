using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public enum SelectTransform
{
    Position,
    Rotation,
    Scale
}

[ExecuteInEditMode]
public class LightTransformSend : MonoBehaviour
{
    private Transform IlluminationSource;

    public GameObject Sun;
    public List<PlanetClass> planetClasses = new List<PlanetClass>();

    public void Update()

    {
        if (Sun != null)
        {

            IlluminationSource = Sun.transform;
			
			
            for (int i = 0; i < planetClasses.Count; i++)
            {
                if (planetClasses[i] == null)
                {
                    continue;
                }
                switch (planetClasses[i].selectTransform)
                {
                    case SelectTransform.Position:
                        Vector3 targetDir = IlluminationSource.position;
                        planetClasses[i].OnRefresh(targetDir);
                        break;
                    case SelectTransform.Rotation:
                        //Vector3 dir = Quaternion.Inverse(IlluminationSource.transform.rotation) * Vector3.forward;
                        Vector3 dir = IlluminationSource.transform.rotation * Vector3.forward;
                        //Vector3 dir = IlluminationSource.transform.eulerAngles;
                        planetClasses[i].OnRefresh(dir);
                        break;
                    case SelectTransform.Scale:
                        Vector3 scale = IlluminationSource.localScale;
                        planetClasses[i].OnRefresh(scale);
                        break;
                    default:
                        break;
                }
				
            }
        }
    }
}


[System.Serializable]
public class PlanetClass
{
    public Renderer renderer;
    public string properties = "_LightSource";
    public SelectTransform selectTransform;


    private MaterialPropertyBlock _propBlockPlanet;
    public void OnRefresh(Vector3 _targetDir)
    {
        if (_propBlockPlanet == null)
        {
            _propBlockPlanet = new MaterialPropertyBlock();
        }
       
        renderer.GetPropertyBlock(_propBlockPlanet);
        _propBlockPlanet.SetVector(properties, _targetDir);
        renderer.SetPropertyBlock(_propBlockPlanet);
    }
}