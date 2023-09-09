using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[System.Serializable]
public class FXRandom : MonoBehaviour
{
    Material MyMaterial;
    public List<RandomData> randomDatas;
    private void Awake()
    {
        MyMaterial = GetComponent<MeshRenderer>().material;
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            for (int i = 0; i < randomDatas.Count; i++)
            {
                switch (randomDatas[i].Type)
                {
                    case SetType.Color:
                        MyMaterial.SetColor(randomDatas[i].Name, new Color(Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y), Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y), Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y), 1));
                        break;
                    case SetType.Float:
                        MyMaterial.SetFloat(randomDatas[i].Name, Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y));
                        break;
                    case SetType.Vector:
                        MyMaterial.SetVector(randomDatas[i].Name, new Vector4(Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y), Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y), Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y), Random.Range(randomDatas[i].RandomRange.x, randomDatas[i].RandomRange.y)));
                        break;
                    case SetType.Texture:
                        MyMaterial.SetTexture(randomDatas[i].Name, randomDatas[i].textures[Random.Range(0, randomDatas[i].textures.Count)]);
                        break;
                    default:
                        break;
                }
            }
        }
    }
    [System.Serializable]
    public class RandomData
    {
        public string Name;
        public SetType Type;
        public Vector2 RandomRange;
        public List<Texture> textures;
    }
    public enum SetType
    {
        Color,
        Float,
        Vector,
        Texture
    }
}
