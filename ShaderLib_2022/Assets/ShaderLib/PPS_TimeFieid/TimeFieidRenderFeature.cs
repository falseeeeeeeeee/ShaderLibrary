using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class TimeFieidRenderFeature : ScriptableRendererFeature
{
    // 自定义的Pass
    class CustomRenderPass : ScriptableRenderPass
    {
        const string PorfilerTag = "时间结界";
        ProfilingSampler m_ProfilingSampler = new ProfilingSampler(PorfilerTag);

        public Material m_Material;
        RTHandle _cameraColorTarget;
        RTHandle _tempRT;
        public TimeFieidVolume m_Volume;

        // 设置RT
        public void GetTempRT(in RenderingData data)
        {
            RenderingUtils.ReAllocateIfNeeded(ref _tempRT, data.cameraData.cameraTargetDescriptor);     // 设置为跟摄像机一样大小
        }
        public void SetUp(RTHandle cameraColor)
        {
            _cameraColorTarget = cameraColor;
        }

        // 摄像机的装载
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureInput(ScriptableRenderPassInput .Color);
            ConfigureTarget(_cameraColorTarget);
        }

        // 摄像机的执行
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(PorfilerTag);
            m_Material.SetFloat(ScreenCenterOffsetX, m_Volume.screenPosition.value.x);
            m_Material.SetFloat(ScreenCenterOffsetY, m_Volume.screenPosition.value.y);
            m_Material.SetFloat(ScreenCenterStrength, m_Volume.strength.value);
            m_Material.SetFloat(ScreenCenterScatter, m_Volume.scatter.value);
            m_Material.SetFloat(Concentration, m_Volume.concentration.value);

            using (new ProfilingScope(cmd,m_ProfilingSampler))
            {
                CoreUtils.SetRenderTarget(cmd, _tempRT);
                Blitter.BlitTexture(cmd, _cameraColorTarget, _tempRT, m_Material, 0);   // 触发SSAA
                CoreUtils.SetRenderTarget(cmd, _cameraColorTarget);
                Blitter.BlitTexture(cmd, _cameraColorTarget, _cameraColorTarget, m_Material, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            cmd.Dispose();
        }
        
        // 摄像机的清理
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            _tempRT?.Release();
        }
    }
    
    //---------------------------------------------------------------------------------------------------------

    CustomRenderPass m_ScriptablePass;
    public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    public Material m_Material;
    VolumeStack m_Stack;
    TimeFieidVolume m_Volume;
    static readonly int ScreenCenterOffsetX = Shader.PropertyToID("_ScreenCenterOffsetX");
    static readonly int ScreenCenterOffsetY = Shader.PropertyToID("_ScreenCenterOffsetY");
    static readonly int ScreenCenterStrength = Shader.PropertyToID("_ScreenCenterStrength");
    static readonly int ScreenCenterScatter = Shader.PropertyToID("_ScreenCenterScatter");
    static readonly int Concentration = Shader.PropertyToID("_Concentration");

    // 初始化的时候调用
    public override void Create()
    {
        if(m_Material == null) return;
        m_Stack = VolumeManager.instance.stack;     // 混合Volume
        m_Volume = m_Stack.GetComponent<TimeFieidVolume>();
        m_ScriptablePass = new CustomRenderPass()
        {
            m_Material = m_Material,
            m_Volume = m_Volume
        };
        m_ScriptablePass.renderPassEvent = m_RenderPassEvent;
    }

    // 每帧调用，将Pass添加进流程
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldRender(in renderingData)) return;
        renderer.EnqueuePass(m_ScriptablePass);
        m_ScriptablePass.GetTempRT(in renderingData);
    }
    // 设置Pass时调用
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (!ShouldRender(in renderingData)) return;
        m_ScriptablePass.SetUp(renderer.cameraColorTargetHandle);
    }
    // 清除时使用
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
    #if UNITY_EDITOR
        //如有需要,在此处销毁生成的资源,如Material等
        if (EditorApplication.isPlaying) 
        {
            // Destroy(null_Material);
        } 
        else 
        {
            // DestroyImmediate(null_Material);
        }
    #else
            // Destroy(material);
    #endif
    }
    bool ShouldRender(in RenderingData data)
    {
        if (!data.cameraData.postProcessEnabled || data.cameraData.cameraType != CameraType.Game) 
        {
            return false;
        }
        if (m_ScriptablePass == null) 
        {
            Debug.LogError($"RenderPass = null!");
            return false;
        }
        return true;
    }

}


