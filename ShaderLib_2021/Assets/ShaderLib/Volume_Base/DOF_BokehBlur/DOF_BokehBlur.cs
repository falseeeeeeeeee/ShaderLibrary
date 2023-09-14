using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu(CustomVolumeDefine.Blur + "散景景深模糊 (DOF_BokehBlur)")]
public class DOF_BokehBlur : CustomVolumeComponent
{
    //散景模糊
    public ClampedFloatParameter blurSize = new ClampedFloatParameter(0f, 0f, 0.01f); //模糊强度
    public ClampedFloatParameter iterations = new ClampedFloatParameter(5f, 1f, 500f); //迭代次数

    public ClampedIntParameter RTDownSample = new ClampedIntParameter(1, 1, 10); //降采样次数   

    //景深
    public ClampedFloatParameter distance = new ClampedFloatParameter(0.001f, 0f, 2f);
    public ClampedFloatParameter lensCoeff = new ClampedFloatParameter(0f, 0f, 1f);
    public ClampedFloatParameter maxCoC = new ClampedFloatParameter(0.001f, 0f, 2f);
    public ClampedFloatParameter rcpMaxCoC = new ClampedFloatParameter(0f, 0f, 1f);
    public ClampedFloatParameter rcpAspect = new ClampedFloatParameter(1f, 0f, 10f);
    public ClampedFloatParameter taaParams = new ClampedFloatParameter(1f, 0f, 10f);

    internal static readonly int BufferRT1 = Shader.PropertyToID("_BufferRT1");

    Material material;
    const string shaderName = "URP/PPS/DOF_BokehBlurShader";

    public override CustomPostProcessInjectionPoint InjectionPoint => CustomPostProcessInjectionPoint.BeforePostProcess;

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

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
        if (material == null)
            return;

        //散景模糊
        material.SetFloat("_Iteration", iterations.value);
        material.SetFloat("_BlurSize", blurSize.value);
        material.SetInt("_DownSample", RTDownSample.value);
        //景深
        // material.SetFloat("_Distance", distance.value);
        // material.SetFloat("_LensCoeff", lensCoeff.value);
        // material.SetFloat("_RcpMaxCoC", rcpMaxCoC.value);
        material.SetFloat("_Distance", distance.value);
        material.SetFloat("_LensCoeff", lensCoeff.value);
        material.SetFloat("_MaxCoC", maxCoC.value);
        material.SetFloat("_RcpMaxCoC", rcpMaxCoC.value);
        material.SetFloat("_RcpAspect", rcpAspect.value);
        material.SetFloat("_TaaParams", taaParams.value);
        //利用缩放对图像进行降采样
        int RTWidth = (int) (Screen.width / RTDownSample.value);
        int RTHeight = (int) (Screen.height / RTDownSample.value);
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
        CoreUtils.Destroy(material); //在Dispose中销毁材质
    }
}