using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class PushPopLayerRenderFeature : ScriptableRendererFeature
{
    const string DefaultShaderName = "Hidden/BlendUI/BlendUILayer";

    [Header("Injection Points")]
    public RenderPassEvent push = RenderPassEvent.BeforeRendering;
    public RenderPassEvent pop = RenderPassEvent.AfterRenderingPostProcessing;

    [Header("Blend Shader")]
    [Tooltip("Optional. If empty, automatically finds: " + DefaultShaderName)] [SerializeField]
    private Shader blendShader;

    [Header("Blend State")] [Tooltip("Source factor used by: Blend [_SrcFactor] [_DstFactor]")]
    public BlendMode srcFactor = BlendMode.SrcAlpha;

    [Tooltip("Destination factor used by: Blend [_SrcFactor] [_DstFactor]")]
    public BlendMode dstFactor = BlendMode.OneMinusSrcAlpha;

    [Tooltip("Blend operation used by: BlendOp [_Opp]")]
    public BlendOp blendOp = BlendOp.Add;

    static readonly int SrcFactorId = Shader.PropertyToID("_SrcFactor");
    static readonly int DstFactorId = Shader.PropertyToID("_DstFactor");
    static readonly int BlendOpId   = Shader.PropertyToID("_Opp");

    Material runtimeBlendMaterial;

    PushLayerRenderPass m_pushPass;
    PopLayerRenderPass  m_popPass;

    public class StackLayers : ContextItem
    {
        public Stack<TextureHandle> layers = new();

        public override void Reset()
        {
            layers.Clear();
        }
    }

    class PushLayerRenderPass : ScriptableRenderPass
    {
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalResourceData resourcesData = frameData.Get<UniversalResourceData>();

            var layers = frameData.GetOrCreate<StackLayers>();

            // Save everything rendered before Push.
            layers.layers.Push(resourcesData.cameraColor);

            TextureDesc desc = resourcesData.cameraColor.GetDescriptor(renderGraph);

            desc.clearBuffer = true;
            desc.clearColor  = Color.clear;
            desc.name        = "_NewRenderTarget_" + layers.layers.Count;

            var layerColor = renderGraph.CreateTexture(desc);

            // Everything after Push is rendered into this transparent layer.
            resourcesData.cameraColor = layerColor;

            if (!GraphicsFormatUtility.HasAlphaChannel(desc.format))
            {
                Debug.LogWarning("[PushPopLayer] The temporary layer has no alpha channel. " +
                                 "Layer blending may overwrite the previous image.");
            }
        }
    }

    class PopLayerRenderPass : ScriptableRenderPass
    {
        public Material blendMaterial { get; set; }

        const string FBFKeyword = "_USE_FBF";

        public PopLayerRenderPass()
        {
            profilingSampler = new ProfilingSampler("Pop: Blend Snapshot!");
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (blendMaterial == null)
                return;

            UniversalResourceData resourcesData = frameData.Get<UniversalResourceData>();

            var layers = frameData.GetOrCreate<StackLayers>();

            if (layers.layers.Count == 0)
                return;

            var previousLayer = layers.layers.Pop();

            // This implementation doesn't use framebuffer fetch.
            blendMaterial.DisableKeyword(FBFKeyword);

            var blitParameters = new RenderGraphUtils.BlitMaterialParameters(resourcesData.cameraColor, previousLayer, blendMaterial, 0);

            renderGraph.AddBlitPass(blitParameters, "Pop: Blend Snapshot!");

            resourcesData.cameraColor = previousLayer;
        }
    }

    public override void Create()
    {
        m_pushPass = new PushLayerRenderPass();
        m_popPass  = new PopLayerRenderPass();

        EnsureShaderAndMaterial();
    }

    void EnsureShaderAndMaterial()
    {
        // No manual shader assignment required.
        if (blendShader == null)
            blendShader = Shader.Find(DefaultShaderName);

        if (runtimeBlendMaterial != null &&runtimeBlendMaterial.shader != blendShader)
        {
            CoreUtils.Destroy(runtimeBlendMaterial);
            runtimeBlendMaterial = null;
        }

        if (runtimeBlendMaterial == null && blendShader != null)
        {
            runtimeBlendMaterial = CoreUtils.CreateEngineMaterial(blendShader);

            runtimeBlendMaterial.name = "PushPopLayer Runtime Blend Material";
        }

        ApplyBlendSettings();
    }

    void ApplyBlendSettings()
    {
        if (runtimeBlendMaterial == null)
            return;

        runtimeBlendMaterial.SetFloat(SrcFactorId, (float)srcFactor);

        runtimeBlendMaterial.SetFloat(DstFactorId, (float)dstFactor);

        runtimeBlendMaterial.SetFloat(BlendOpId, (float)blendOp);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData  renderingData)
    {
        EnsureShaderAndMaterial();

        if (runtimeBlendMaterial == null)
        {
            Debug.LogWarning($"[PushPopLayer] Shader not found: {DefaultShaderName}", this);
            return;
        }

        ApplyBlendSettings();

        m_pushPass.renderPassEvent = push;

        m_popPass.renderPassEvent = pop;
        m_popPass.blendMaterial   = runtimeBlendMaterial;

        renderer.EnqueuePass(m_pushPass);
        renderer.EnqueuePass(m_popPass);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(runtimeBlendMaterial);
        runtimeBlendMaterial = null;
    }
}