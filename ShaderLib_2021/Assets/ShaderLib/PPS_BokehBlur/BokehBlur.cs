using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(CustomVolumeDefine.Blur + "散景模糊 (Bokeh Blur)")]
public class BokehBlur : CustomVolumeComponent
{
    //散景模糊
    public ClampedFloatParameter blurSize = new ClampedFloatParameter(0f, 0f, 0.01f); //模糊强度
    public ClampedFloatParameter iterations = new ClampedFloatParameter(5, 1f, 500f); //迭代次数
    public ClampedIntParameter RTDownSample = new ClampedIntParameter(1, 1, 10); //降采样次数
    
    internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");
    
    Material material;
    const string shaderName = "URP/PPS/BokehBlurShader";
    
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
    public override bool IsActive() => material != null && blurSize.value > 0f;
    
    //执行渲染
    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;
        
        //散景模糊
        material.SetFloat("_Iteration", iterations.value);
        material.SetFloat("_BlurSize", blurSize.value);
        material.SetFloat("_DownSample", RTDownSample.value);
        
        //利用缩放对图像进行采样
        int RTWidth = Screen.width / RTDownSample.value;
        int RTHeight = Screen.height / RTDownSample.value;
        cmd.GetTemporaryRT(BufferRT1, RTWidth, RTHeight, 0, FilterMode.Bilinear);
        //源纹理到临时RT
        cmd.Blit(source, BufferRT1);
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
