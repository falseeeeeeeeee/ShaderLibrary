using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace GammaUIRenderGraph
{
    /// <summary>
    /// Unity 6000.3 / URP 17.3, Render Graph.
    ///
    /// IMPORTANT:
    /// This feature DOES NOT override UI shaders/materials.
    /// It only:
    /// 1) converts the current camera color Linear -> Gamma-encoded values,
    /// 2) renders the selected UI layer with each renderer's ORIGINAL shader/material,
    /// 3) converts the result Gamma -> Linear.
    ///
    /// UI/TMP/custom shaders that participate in this pass must encode their final
    /// un-premultiplied RGB with GammaUIEncodeIfActive() before blending.
    /// </summary>
    public sealed class GammaUIRenderFeature : ScriptableRendererFeature
    {
        [Tooltip("The Camera must include this layer. Exclude it from the Renderer Data's normal Opaque/Transparent Layer Masks.")]
        public LayerMask uiLayer = 1 << 5;

        [Tooltip("Optional. The bundled conversion shader is loaded automatically from Resources when empty.")]
        [SerializeField] Shader shader;

        [Tooltip("Log READY, ENQUEUE, RECORD, or the reason this camera was skipped.")]
        public bool diagnostics = true;

        public bool showInSceneView;

        internal const string ShaderResource = "S_GammaUIConvert";

        // Read by GammaUI.hlsl / patched UI shaders.
        static readonly int Active = Shader.PropertyToID("_GammaUIRGActive");

        readonly HashSet<string> messages = new();
        Material conversionMaterial;
        GammaPass pass;

        public override void Create()
        {
            CoreUtils.Destroy(conversionMaterial);
            messages.Clear();

            if (shader == null)
                shader = Resources.Load<Shader>(ShaderResource);

            conversionMaterial = shader != null
                ? CoreUtils.CreateEngineMaterial(shader)
                : null;

            pass = new GammaPass(this, conversionMaterial);

            if (diagnostics)
            {
                Debug.Log(
                    conversionMaterial != null
                        ? "[GammaUI] READY: conversion feature created. Original UI shaders/materials will be preserved."
                        : "[GammaUI] Shader missing. Keep Resources/GammaUIRenderGraph.shader, or assign the Shader field.",
                    this);
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var data = renderingData.cameraData;
            var camera = data.camera;

            if (data.cameraType != CameraType.Game &&
                !(showInSceneView && data.isSceneViewCamera))
            {
                if (data.isSceneViewCamera)
                    Report(camera, "SKIP: Scene View. Inspect Game View, or enable Show In Scene View.");
                return;
            }

            string reason = null;

            if (conversionMaterial == null)
                reason = "Shader missing. Keep Resources/GammaUIRenderGraph.shader, or assign the Shader field.";
            else if (QualitySettings.activeColorSpace != ColorSpace.Linear)
                reason = "Project Color Space must be Linear.";
            else if (uiLayer.value == 0)
                reason = "UI Layer is Nothing. Select the layer used by the Canvas and its children.";
            else if ((camera.cullingMask & uiLayer.value) == 0)
                reason = "Camera Culling Mask excludes the UI Layer. Include it on the camera; exclude it on Renderer Data Filtering instead.";
            else if (data.cameraTargetDescriptor.msaaSamples != 1)
                reason = "This version requires URP Asset MSAA Disabled (1x). Camera post-process AA is not blocked.";
            else if (camera.stereoEnabled)
                reason = "XR is not implemented by this version.";
            else if (camera.allowDynamicResolution || camera.rect != new Rect(0, 0, 1, 1))
                reason = "Use a full-screen viewport without Dynamic Resolution.";
            else if (HDROutputSettings.main != null && HDROutputSettings.main.active)
                reason = "HDR display output is not implemented. HDR scene rendering is allowed.";
            else if (!SystemInfo.IsFormatSupported(
                         GraphicsFormat.R16G16B16A16_SFloat,
                         GraphicsFormatUsage.Blend))
                reason = "This device cannot blend into an RGBA16F render target.";

            if (reason != null)
            {
                Report(camera, "SKIP: " + reason, true);
                return;
            }

            pass.layerMask = uiLayer;
            renderer.EnqueuePass(pass);

            Report(
                camera,
                "ENQUEUE: cameraType=" + data.renderType +
                ", AA=" + data.antialiasing +
                ". Original UI shaders are preserved.");
        }

        void Report(Camera camera, string message, bool warning = false)
        {
            if (!warning && !diagnostics)
                return;

            string key = camera.GetInstanceID() + ":" + message;
            if (!messages.Add(key))
                return;

            string text = "[GammaUI] Camera '" + camera.name + "': " + message;

            if (warning)
                Debug.LogWarning(text, camera);
            else
                Debug.Log(text, camera);
        }

        protected override void Dispose(bool disposing)
        {
            CoreUtils.Destroy(conversionMaterial);
            conversionMaterial = null;

            // Defensive cleanup for editor/domain/camera changes.
            Shader.SetGlobalFloat(Active, 0);

            messages.Clear();
        }

        sealed class GammaPass : ScriptableRenderPass
        {
            readonly GammaUIRenderFeature owner;
            readonly Material conversionMaterial;

            public LayerMask layerMask;

            sealed class BlitData
            {
                public TextureHandle source;
                public Material material;
                public int shaderPass;
                public float gammaUIActiveAfterBlit;
            }

            sealed class DrawData
            {
                public RendererListHandle renderers;
            }

            public GammaPass(
                GammaUIRenderFeature owner,
                Material conversionMaterial)
            {
                this.owner = owner;
                this.conversionMaterial = conversionMaterial;

                renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
                requiresIntermediateTexture = true;
            }

            public override void RecordRenderGraph(
                RenderGraph graph,
                ContextContainer frameData)
            {
                var resources = frameData.Get<UniversalResourceData>();
                var cameraData = frameData.Get<UniversalCameraData>();
                var rendering = frameData.Get<UniversalRenderingData>();
                var lights = frameData.Get<UniversalLightData>();
                var camera = cameraData.camera;

                if (resources.isActiveTargetBackBuffer)
                {
                    owner.Report(
                        camera,
                        "SKIP in RECORD: active color is the back buffer. Set this camera's Renderer Data > Intermediate Texture to Always.",
                        true);
                    return;
                }

                var source = resources.activeColorTexture;

                if (!source.IsValid())
                {
                    owner.Report(
                        camera,
                        "SKIP in RECORD: no valid active camera color texture.",
                        true);
                    return;
                }

                var colorDesc = graph.GetTextureDesc(source);

                if (colorDesc.msaaSamples != MSAASamples.None)
                {
                    owner.Report(
                        camera,
                        "SKIP in RECORD: active color is multisampled. Disable MSAA on the active URP Asset.",
                        true);
                    return;
                }

                // Raw float target:
                // RGB contains gamma-encoded NUMERIC values, without automatic sRGB write conversion.
                colorDesc.name = "GammaUI Gamma Color";
                colorDesc.colorFormat = GraphicsFormat.R16G16B16A16_SFloat;
                colorDesc.clearBuffer = false;
                colorDesc.bindTextureMS = false;
                colorDesc.useMipMap = false;
                colorDesc.autoGenerateMips = false;

                var gamma = graph.CreateTexture(colorDesc);

                var depthDesc = cameraData.cameraTargetDescriptor;
                depthDesc.width = colorDesc.width;
                depthDesc.height = colorDesc.height;
                depthDesc.graphicsFormat = GraphicsFormat.None;
                depthDesc.depthStencilFormat =
                    SystemInfo.GetGraphicsFormat(DefaultFormat.DepthStencil);
                depthDesc.msaaSamples = 1;
                depthDesc.bindMS = false;
                depthDesc.useMipMap = false;
                depthDesc.autoGenerateMips = false;

                var depth = UniversalRenderer.CreateRenderGraphTexture(
                    graph,
                    depthDesc,
                    "GammaUI Depth Stencil",
                    true);

                // Pass 0 in GammaUIRenderGraph.shader:
                // camera Linear -> gamma-encoded numeric values.
                // Afterwards set _GammaUIRGActive = 1 so original UI shaders can
                // encode their source RGB before blending.
                RecordBlit(
                    graph,
                    source,
                    gamma,
                    shaderPass: 0,
                    gammaUIActiveAfterBlit: 1.0f,
                    name: "GammaUI 1 - Linear To Gamma");

                // IMPORTANT:
                // No overrideShader / overrideMaterial here.
                // Every UI renderer keeps its original material, shader, blend state,
                // stencil state, textures, TMP SDF code, and custom effects.
                var drawing = RenderingUtils.CreateDrawingSettings(
                    new ShaderTagId("SRPDefaultUnlit"),
                    rendering,
                    cameraData,
                    lights,
                    SortingCriteria.CommonTransparent);

                // Extra common URP LightMode tags for custom UI shaders.
                // The first matching pass is used.
                drawing.SetShaderPassName(1, new ShaderTagId("UniversalForward"));
                drawing.SetShaderPassName(2, new ShaderTagId("UniversalForwardOnly"));
                drawing.SetShaderPassName(3, new ShaderTagId("Universal2D"));

                var filtering = new FilteringSettings(
                    RenderQueueRange.transparent,
                    layerMask);

                var list = graph.CreateRendererList(
                    new RendererListParams(
                        rendering.cullResults,
                        drawing,
                        filtering));

                using (var builder =
                       graph.AddRasterRenderPass<DrawData>(
                           "GammaUI 2 - Draw UI (Original Shaders)",
                           out var data))
                {
                    data.renderers = list;

                    builder.UseRendererList(list);
                    builder.SetRenderAttachment(
                        gamma,
                        0,
                        AccessFlags.ReadWrite);
                    builder.SetRenderAttachmentDepth(
                        depth,
                        AccessFlags.ReadWrite);

                    builder.AllowPassCulling(false);

                    builder.SetRenderFunc(
                        static (DrawData d, RasterGraphContext context) =>
                            context.cmd.DrawRendererList(d.renderers));
                }

                // Pass 1 in GammaUIRenderGraph.shader:
                // composite gamma values -> Linear.
                // Afterwards reset _GammaUIRGActive = 0.
                RecordBlit(
                    graph,
                    gamma,
                    source,
                    shaderPass: 1,
                    gammaUIActiveAfterBlit: 0.0f,
                    name: "GammaUI 3 - Gamma To Linear");

                owner.Report(
                    camera,
                    "RECORD: conversion + original-shader UI draw + conversion registered.");
            }

            void RecordBlit(
                RenderGraph graph,
                TextureHandle source,
                TextureHandle destination,
                int shaderPass,
                float gammaUIActiveAfterBlit,
                string name)
            {
                using var builder =
                    graph.AddRasterRenderPass<BlitData>(
                        name,
                        out var data);

                data.source = source;
                data.material = conversionMaterial;
                data.shaderPass = shaderPass;
                data.gammaUIActiveAfterBlit = gammaUIActiveAfterBlit;

                builder.UseTexture(source, AccessFlags.Read);
                builder.SetRenderAttachment(
                    destination,
                    0,
                    AccessFlags.Write);

                // Required because this pass sets _GammaUIRGActive globally.
                builder.AllowGlobalStateModification(true);
                builder.AllowPassCulling(false);

                builder.SetRenderFunc(
                    static (BlitData d, RasterGraphContext context) =>
                    {
                        Blitter.BlitTexture(
                            context.cmd,
                            d.source,
                            new Vector4(1, 1, 0, 0),
                            d.material,
                            d.shaderPass);

                        context.cmd.SetGlobalFloat(
                            Active,
                            d.gammaUIActiveAfterBlit);
                    });
            }
        }
    }
}
