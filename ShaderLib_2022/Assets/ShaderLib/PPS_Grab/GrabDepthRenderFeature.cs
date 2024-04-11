#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrabDepthRenderFeature : ScriptableRendererFeature
{
    GrabDepthRenderPass m_ScriptablePass;
    public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingTransparents;

    public override void Create()
    {
        m_ScriptablePass = new GrabDepthRenderPass();
        m_ScriptablePass.OnCreate();
        m_ScriptablePass.renderPassEvent = m_RenderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldExecute(renderingData)) return; // 判断Game窗口
        renderer.EnqueuePass(m_ScriptablePass);
    }
    
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData) {
        if (!ShouldExecute(renderingData)) return;
        m_ScriptablePass.Setup(renderer.cameraDepthTargetHandle);
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


public class GrabDepthRenderPass : ScriptableRenderPass
{
    ProfilingSampler m_Sampler = new("GrabDepthPass"); // 采样器命名
    RTHandle _cameraDepth; // 源深度
    RTHandle _GrabDepthTexture; // 源深度
    Material m_Material;

    public void OnCreate()
    {
        m_Material = CoreUtils.CreateEngineMaterial("Hidden/Universal Render Pipeline/CopyDepth"); // 初始化材质
    }

    // 传递源贴图
    public void Setup(RTHandle cameraColor)
    {
        _cameraDepth = cameraColor;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor; // RT描述
        
        // Debug.Log($"当前相机的AAlevel = {descriptor.msaaSamples}");
        descriptor.depthBufferBits = 32;
        descriptor.colorFormat = RenderTextureFormat.Depth;
        descriptor.msaaSamples = 1; 
        descriptor.bindMS = false;

        RenderingUtils.ReAllocateIfNeeded(ref _GrabDepthTexture, descriptor); // 分配到该纹理
        cmd.SetGlobalTexture("_MyDepthTexture", _GrabDepthTexture.nameID);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get("GrabDepthPass"); // 获取一个命令缓冲区
        using (new ProfilingScope(cmd, m_Sampler)) // 确保所有在其作用域内的操作都会被
        {
            // 可以根据当前相机的AAlevel配置关键字,None/x2/x4/x8 对应的msaaSamples为1234
            m_Material.EnableKeyword("_DEPTH_MSAA_2");
            m_Material.DisableKeyword("_DEPTH_MSAA_4");
            m_Material.DisableKeyword("_DEPTH_MSAA_8");
            m_Material.EnableKeyword("_OUTPUT_DEPTH");
            Blitter.BlitCameraTexture(cmd, _cameraDepth, _GrabDepthTexture, m_Material, 0); // 将源颜色拷贝到目标颜色
        }
        context.ExecuteCommandBuffer(cmd); // 执行渲染命令
        cmd.Clear(); // 清理
        cmd.Dispose(); // 释放缓冲区
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    public void OnDispose()
    {
        #if UNITY_EDITOR
        if (EditorApplication.isPlaying) // 如果在编辑器下，并且运行状态
        {
            if (m_Material != null)
            {
                Object.Destroy(m_Material);
            }
        }
        else
        {
            if (m_Material != null)
            {
                Object.DestroyImmediate(m_Material);
            }
        }
        #else
            if (m_Material != null)
            {
                Object.Destroy(m_Material);
            }
        #endif
    }
}
