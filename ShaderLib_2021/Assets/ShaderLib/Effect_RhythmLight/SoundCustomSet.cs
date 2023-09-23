using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using Unity.VisualScripting;
using UnityEngine;

public class SoundCustomSet : MonoBehaviour
{
    private float[] samples=new float[8192];

    public float[] AudioStrength = new float[3];
    public string[] AudioStrengthName = new string[3];

    private float sampleRate;
    private float hertzPerSample;

    private void Start()
    {
        sampleRate = AudioSettings.outputSampleRate;
        // 计算每个频谱数据元素所对应的赫兹值
        hertzPerSample = sampleRate / 8192;
    }

    public void SetAudioStrength(float totalValue)
    {
        int index;
        float valudePerIndex = totalValue / AudioStrength.Length;

        for (int i = 0; i < samples.Length; i++)
        {
            float hertzValue = i * hertzPerSample;
            index=Mathf.Clamp((int)(hertzValue / valudePerIndex),0, AudioStrength.Length-1);

            AudioStrength[index] += samples[i];
        }

        for (int i = 0; i < AudioStrength.Length; i++)
        {
            AudioStrength[i] *= 1;
        }

    }

    private void Update()
    {
        ClearAudioStrength();
        AudioSource audioSource = GetComponent<AudioSource>();
        audioSource.GetSpectrumData(samples, 0, FFTWindow.BlackmanHarris);

        SetAudioStrength(6000);
        for (int i = 0; i < AudioStrength.Length; i++)
        {
            Shader.SetGlobalFloat(AudioStrengthName[i], AudioStrength[i]);
        }
    }

    private void ClearAudioStrength()
    {
        for (int i = 0; i < AudioStrength.Length; i++)
        {
            AudioStrength[i] = 0;
        }
    }
}
