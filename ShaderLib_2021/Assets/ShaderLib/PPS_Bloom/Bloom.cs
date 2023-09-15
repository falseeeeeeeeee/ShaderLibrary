using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(CustomVolumeDefine.Environment + "辉光 (Bloom)")]
public class Bloom : CustomVolumeComponent
{
    //属性
    public ClampedIntParameter iterations  = new ClampedIntParameter(0, 0, 40);        //迭代次数
    public ClampedFloatParameter blurSpread  = new ClampedFloatParameter(0.6f, 0.3f, 3.0f);      //模糊大小
    public ClampedIntParameter downSample  = new ClampedIntParameter(2, 1, 8);             //降采样次数
    public ClampedFloatParameter luminanceThreshold  = new ClampedFloatParameter(0.6f, 0.0f, 4.0f); //亮度阈值
    
    private const int EXTRACT_PASS = 0;
    private const int GAUSSIAN_HOR_PASS = 1;
    private const int GAUSSIAN_VERT_PASS = 2;
    private const int BLOOM_PASS = 3;
    
    internal static readonly int BufferRT0 = Shader.PropertyToID("_BufferRT0");
    internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
    
    Material material;
    const string shaderName = "URP/PPS/BloomShader";
    
    //插入位置
    public override CustomPostProcessInjectionPoint InjectionPoint => CustomPostProcessInjectionPoint.BeforePostProcess;

    //初始化装载
    public override void Setup()
    {
        if (material == null)
        {
            //使用CoreUtils.CreateEngineMaterial来从Shader创建材质
            //CreateEngineMaterial：使用提供的着色器路径创建材质。hideFlags将被设置为 HideFlags.HideAndDontSave。
            material = CoreUtils.CreateEngineMaterial(shaderName);
        }
    }
    
    //需要注意的是，IsActive方法最好要在组件无效时返回false，避免组件未激活时仍然执行了渲染，
    //原因之前提到过，无论组件是否添加到Volume菜单中或是否勾选，VolumeManager总是会初始化所有的VolumeComponent。
    public override bool IsActive() => material != null && iterations.value > 0f;
    
    //执行渲染
    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;
        
        //利用缩放对图像进行采样
        int RTWidth = Screen.width / downSample.value;
        int RTHeight = Screen.height / downSample.value;
        cmd.GetTemporaryRT(BufferRT0, RTWidth, RTHeight, 0, FilterMode.Bilinear);
        cmd.GetTemporaryRT(BufferRT1, RTWidth, RTHeight, 0, FilterMode.Bilinear);
        
        //源纹理到临时RT
        cmd.Blit(source,BufferRT0, material, EXTRACT_PASS);
        material.SetFloat("_LuminanceThreshold", luminanceThreshold.value);

        //循环模糊
        for (int i = 0; i < iterations.value; i++)
        {
            material.SetFloat("_BlurSize", blurSpread.value);        
            cmd.Blit(BufferRT0,BufferRT1, material, GAUSSIAN_HOR_PASS);
            cmd.Blit(BufferRT1,BufferRT0, material, GAUSSIAN_VERT_PASS);
        }
        
        //模糊结果 塞进 BufferRT0 > _BloomTex
        cmd.SetGlobalTexture("_BloomTex", BufferRT0);
        cmd.ReleaseTemporaryRT(BufferRT0);
        
        //源纹理 塞进 BufferRT1
        if (downSample.value > 1)
        {
            cmd.ReleaseTemporaryRT(BufferRT1);
            cmd.GetTemporaryRT(BufferRT1, Screen.width, Screen.height, 0, FilterMode.Bilinear);
        }
        cmd.Blit(source,BufferRT1, material, BLOOM_PASS);
        
        //临时RT到目标纹理
        cmd.Blit(BufferRT1, destination, material);
        
        //释放临时RT
        cmd.ReleaseTemporaryRT(BufferRT1);
    }

    public override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        CoreUtils.Destroy(material);
    }

}
