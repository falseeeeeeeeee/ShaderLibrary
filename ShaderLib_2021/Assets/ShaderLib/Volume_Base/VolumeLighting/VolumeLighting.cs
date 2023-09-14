using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(CustomVolumeDefine.Environment + "体积光 (VolumeLighting)")]
public class VolumeLighting : CustomVolumeComponent
{
    //颜色属性
    [Tooltip("每次不仅叠加的光照强度")]
    public ClampedFloatParameter lightIntensity = new ClampedFloatParameter(0f, 0f, 2f);
    [Tooltip("每次步进距离")]
    public ClampedFloatParameter stepSize = new ClampedFloatParameter(0.1f, 0f, 1f);
    [Tooltip("最大步进距离")]
    public ClampedFloatParameter maxDistance = new ClampedFloatParameter(1000f, 0f, 2000f);
    [Tooltip("设置最大步数")]
    public ClampedIntParameter maxStep = new ClampedIntParameter(200, 0, 400);
    
    internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");

    Material material;
    const string shaderName = "URP/PPS/VolumeLightingShader";
    
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
    public override bool IsActive() => material != null && lightIntensity.value > 0;
    
    //执行渲染
    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        //色彩调整
        material.SetFloat("_LightIntensity", lightIntensity.value);
        material.SetFloat("_StepSize", stepSize.value);
        material.SetFloat("_MaxDistance", maxDistance.value);
        material.SetInt("_MaxStep", maxStep.value);
        
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
