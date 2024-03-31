using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(CustomVolumeDefine.Environment + "水墨风 (InkStyle)")]
public class InkStyle : CustomVolumeComponent
{
    //颜色调整属性
    public ClampedFloatParameter noiseScale = new ClampedFloatParameter(200f, 0f, 500f);
    public ClampedFloatParameter noiseStrength = new ClampedFloatParameter(0.01f, 0f, 0.2f);

    
    internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");

    Material material;
    const string shaderName = "URP/PPS/InkStyleShader";
    
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
    public override bool IsActive() => material != null;
    
    //执行渲染
    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;
        
        //色彩调整
        material.SetFloat("_NoiseScale", noiseScale.value);
        material.SetFloat("_NoiseStrength", noiseStrength.value);
        
        // 创建临时缓冲区
        cmd.GetTemporaryRT(BufferRT1, Screen.width,  Screen.height, 0, FilterMode.Bilinear);
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
