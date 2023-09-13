using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SetMainLightMatrix : MonoBehaviour {
    
    private int property = Shader.PropertyToID("_WorldToMainLightMatrix");
    
    void Update() {
        // Create Rotation Matrix from transform.
        // Basically transform.localToWorldMatrix, but only rotation.
        Matrix4x4 matrix = Matrix4x4.Rotate(transform.rotation);

        // Set Global Matrix shader property
        Shader.SetGlobalMatrix(property, matrix);
    }
}
