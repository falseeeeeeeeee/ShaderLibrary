using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SoundControl : MonoBehaviour
{
    MeshRenderer MeshRenderer;
    public AudioSource Audio;
    private int m_NumSamples = 1024;
    private float[] m_Samples; 
    private float Sum, Rms;
    private Vector3 Scale;
    private float Volume = 30.0f;
    
    void Start()
    {
        MeshRenderer = GetComponent<MeshRenderer>();
        m_Samples = new float[m_NumSamples];
    }

    void Update()
    {
        Audio.GetOutputData(m_Samples, 0);
        for (int i = 0; i < m_NumSamples; i++)
        {
            Sum = m_Samples[i] * m_Samples[i];
        }
        Rms = Mathf.Sqrt(Sum / m_NumSamples);
        Scale.y = Mathf.Clamp01(Rms * Volume);
        
        MeshRenderer.material.SetFloat("_SoundStrength",Scale.y);
    }
}
