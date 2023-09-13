using UnityEngine;
using System.Collections;

public class TranslateShaderOffset : MonoBehaviour 
{
	public string propertyName = "_MainTex";
	public Vector2 velocity;

	private Vector2 offset;

	// Use this for initialization
	void Start () 
	{
		offset = GetComponent<Renderer>().material.GetTextureOffset (propertyName);
	}
	
	// Update is called once per frame
	void Update () 
	{
		offset += velocity * Time.deltaTime;
		GetComponent<Renderer>().material.SetTextureOffset (propertyName, offset);
	}
}
