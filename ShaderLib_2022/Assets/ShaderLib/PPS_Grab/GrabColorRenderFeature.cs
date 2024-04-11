using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrabColorRenderFeature : ScriptableRendererFeature
{

    GrabColorPass m_ScriptablePass;
    public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingTransparents;


    // 初始化的时候调用
    public override void Create()
    {
        m_ScriptablePass = new GrabColorPass();
        m_ScriptablePass.renderPassEvent = m_RenderPassEvent;
    }

    // 每帧调用，将Pass添加进流程
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldExecute(renderingData)) return; // 判断Game窗口

        renderer.EnqueuePass(m_ScriptablePass);
    }

    // 设置Pass时调用
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (!ShouldExecute(renderingData)) return; // 判断Game窗口

        m_ScriptablePass.Setup(renderer.cameraColorTargetHandle);
    }

    // 清除时调用
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_ScriptablePass.OnDispose();
    }
    
    // 判断Game窗口
    bool ShouldExecute(in RenderingData data)
    {
        if (data.cameraData.cameraType != CameraType.Game)
        {
            return false;
        }
        return true;
    }

}

public class GrabColorPass : ScriptableRenderPass
{
    ProfilingSampler m_Sampler = new("GrabColorPass"); // 采样器命名
    RTHandle _cameraColor; // 源颜色
    RTHandle _GrabColorTexture; // 目标颜色

    // 传递源贴图
    public void Setup(RTHandle cameraColor)
    {
        _cameraColor = cameraColor;
    }

    // 摄像机的装载
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor; // RT描述
        descriptor.depthBufferBits = 0;
        RenderingUtils.ReAllocateIfNeeded(ref _GrabColorTexture, descriptor); // 分配到该纹理
        cmd.SetGlobalTexture("_MyColorTexture", _GrabColorTexture.nameID);
    }

    // 摄像机的执行
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get("GrabColorPass"); // 获取一个命令缓冲区
        using (new ProfilingScope(cmd, m_Sampler)) // 确保所有在其作用域内的操作都会被
        {
            Blitter.BlitCameraTexture(cmd, _cameraColor, _GrabColorTexture); // 将源颜色拷贝到目标颜色
        }
        context.ExecuteCommandBuffer(cmd); // 执行渲染命令
        cmd.Clear(); // 清理
        cmd.Dispose(); // 释放缓冲区
    }

    // 摄像机的清理
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    public void OnDispose()
    {
        _GrabColorTexture?.Release();
    }
}
