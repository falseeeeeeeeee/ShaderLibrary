using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace GammaUIRenderGraph
{
    /// <summary>
    /// Put this on the root Canvas (or a parent containing the target UI).
    ///
    /// It replaces ONLY Graphics whose current material shader is "UI/Default"
    /// with a cloned material using "GammaUI/Default".
    ///
    /// TMP and custom shaders/materials are left untouched.
    ///
    /// Mask/Stencil remains supported because Graphic.materialForRendering will
    /// still create its normal stencil-modified material from the replacement base material.
    /// </summary>
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public sealed class GammaUIDefaultMaterialRouter : MonoBehaviour
    {
        [SerializeField] Shader gammaDefaultShader;

        [Tooltip("Keep enabled if UI Graphics are created dynamically at runtime.")]
        [SerializeField] bool refreshBeforeCanvasRender = true;

        readonly List<Graphic> graphics = new();
        readonly Dictionary<Material, Material> replacements = new();

        Shader unityDefaultShader;

        void OnEnable()
        {
            unityDefaultShader = Shader.Find("UI/Default");

            if (gammaDefaultShader == null)
                gammaDefaultShader = Shader.Find("URP/UI/S_UIDefault");

            Refresh();

            if (refreshBeforeCanvasRender)
                Canvas.willRenderCanvases += OnWillRenderCanvases;
        }

        void OnDisable()
        {
            Canvas.willRenderCanvases -= OnWillRenderCanvases;
            RestoreAndDestroy();
        }

        void OnDestroy()
        {
            Canvas.willRenderCanvases -= OnWillRenderCanvases;
            RestoreAndDestroy();
        }

        void OnValidate()
        {
            if (!isActiveAndEnabled)
                return;

            unityDefaultShader = Shader.Find("UI/Default");

            if (gammaDefaultShader == null)
                gammaDefaultShader = Shader.Find("URP/UI/S_UIDefault");

            Refresh();
        }

        void OnWillRenderCanvases()
        {
            Refresh();
        }

        /// <summary>
        /// Safe to call manually after creating/changing UI materials.
        /// </summary>
        public void Refresh()
        {
            if (unityDefaultShader == null)
                unityDefaultShader = Shader.Find("UI/Default");

            if (gammaDefaultShader == null)
                gammaDefaultShader = Shader.Find("URP/UI/S_UIDefault");

            if (unityDefaultShader == null || gammaDefaultShader == null)
                return;

            graphics.Clear();
            GetComponentsInChildren(true, graphics);

            for (int i = 0; i < graphics.Count; ++i)
            {
                var graphic = graphics[i];
                if (graphic == null)
                    continue;

                var current = graphic.material;
                if (current == null)
                    continue;

                // Already routed.
                if (current.shader == gammaDefaultShader)
                    continue;

                // TMP / custom shader / any non-UI-Default material:
                // deliberately untouched.
                if (current.shader != unityDefaultShader)
                    continue;

                if (!replacements.TryGetValue(current, out var replacement) ||
                    replacement == null)
                {
                    replacement = new Material(current)
                    {
                        shader = gammaDefaultShader,
                        name = current.name + " [GammaUI Default]",
                        hideFlags = HideFlags.HideAndDontSave
                    };

                    replacements[current] = replacement;
                }

                if (graphic.material != replacement)
                {
                    graphic.material = replacement;
                    graphic.SetMaterialDirty();
                }
            }
        }

        void RestoreAndDestroy()
        {
            // Restore Graphics that still use one of our generated materials.
            graphics.Clear();
            GetComponentsInChildren(true, graphics);

            foreach (var graphic in graphics)
            {
                if (graphic == null || graphic.material == null)
                    continue;

                Material original = null;

                foreach (var pair in replacements)
                {
                    if (graphic.material == pair.Value)
                    {
                        original = pair.Key;
                        break;
                    }
                }

                if (original != null)
                {
                    graphic.material = original;
                    graphic.SetMaterialDirty();
                }
            }

            foreach (var pair in replacements)
            {
                if (pair.Value == null)
                    continue;

                if (Application.isPlaying)
                    Destroy(pair.Value);
                else
                    DestroyImmediate(pair.Value);
            }

            replacements.Clear();
            graphics.Clear();
        }
    }
}
