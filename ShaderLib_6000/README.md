# 【ShaderLibrary_Unity 6000】

[TOC]

------

# 😉约定








------



# 🤡目录

## 渲染相关

### GammaUI

![](Source/GammaUI/GammaUIScreen.png)

* 所有的UI图片依旧保持sRGB勾选，结果是RGB依然保持原样功能，A通道始终是Gamma

* RenderFeature 中添加GammaUI

* Canvas下复写所有默认的UI材质

* 自定义UIShader自己进行色彩矫正，加到Alpha预乘前面

  ```c#
  #include "Assets/AssetRaw/Shaders/Include/SIH_GammaUI.hlsl"
  
  input.color.rgb = GammaUIEncodeIfActive(input.color.rgb);
  ```

### UI 后处理与场景分离

![](Source/BlendUILayer/BlendUILayerScreen.png)

* 添加RenderFeature

  * UI渲染之前定帧>渲染UI>后处理>混合，BeforeRendering，AfterRenderingPostProcessing
  * 混合的模式跟普通的Alpha一样，SrcApha，OneMinusSrcAlpha

* 摄像机设置，后处理设置

  * |                                   | Main Camera | UI Camera |
    | --------------------------------- | ----------- | --------- |
    | Layer（后处理物体右上角的层名称） | Default     | UI        |
    | CullingMask（渲染哪些层）         | 除了UI      | UI        |
    | VolumeMask（后处理应用哪些层）    | Default     | UI        |


# UI Camera 堆栈启用 TAA

* 如果直接使用TAA会没效果以及弹警告
  ![](Source/TAASetting/TAASettingScreen.png)

* 将URP Universal包进行本地化，否则只改Library没办法同步其他人电脑
  ![](Source/TAASetting/TAASettingScreen2.png)

* 修改两处源码

  * 将 `TemporalAA.cs` 中的检测警告注释掉

  * ```c#
    internal static string ValidateAndWarn(UniversalCameraData cameraData, bool isSTPRequested = false)
    {
        ...
    
        if (reasonWarning == null && cameraData.cameraTargetDescriptor.msaaSamples != 1)
        {
            if (cameraData.xr != null && cameraData.xr.enabled)
                reasonWarning = "because MSAA is on. MSAA must be disabled globally for all cameras in XR mode.";
            else
                reasonWarning = "because MSAA is on. Turn MSAA off on the camera or current URP Asset.";
        }
    	
        // 注释掉这一段警告Log
        // if(reasonWarning == null && cameraData.camera.TryGetComponent<UniversalAdditionalCameraData>(out var additionalCameraData))
        // {
        //     if (additionalCameraData.renderType == CameraRenderType.Overlay ||
        //         additionalCameraData.cameraStack.Count > 0)
        //     {
        //         reasonWarning = "because camera is stacked.";
        //     }
        // }
    
        if (reasonWarning == null && cameraData.camera.allowDynamicResolution)
            reasonWarning = "because camera has dynamic resolution enabled. You can use a constant render scale instead.";
    
        ...
    }
    
  * 将 `UniversalCameraData.cs` 中的开启规则进行修改，是主相机继续TAA，Overlay相机不继续TAA
  
  
  * ```c#
    internal bool IsTemporalAAEnabled()
    {
        UniversalAdditionalCameraData additionalCameraData;
        camera.TryGetComponent(out additionalCameraData);
    
        return IsTemporalAARequested()          			// Requested
            && postProcessEnabled            			    // Postprocessing Enabled
            && (taaHistory != null)                         // Initialized
            && (cameraTargetDescriptor.msaaSamples == 1)    // No MSAA
            // && !(additionalCameraData?.renderType == CameraRenderType.Overlay || additionalCameraData?.cameraStack.Count > 0)  // No Camera stack
            && additionalCameraData?.renderType != CameraRenderType.Overlay  // 当前Camera不是Overlay类型
            && !camera.allowDynamicResolution               // No Dynamic Resolution
            && renderer.SupportsMotionVectors();     	    // Motion Vectors implemented
    }
  
  









------



------


# 🥰巨人的肩膀

* UI在线性空间下的Gamma矫正
  * [unity - Rendering transparent UI in Linear Color Space - Game Development Stack Exchange](https://gamedev.stackexchange.com/questions/212135/rendering-transparent-ui-in-linear-color-space)
  * https://cmwdexint.com/2019/05/30/3d-scene-need-linear-but-ui-need-gamma/
* UI后处理与场景后处理分离
  * [Fix UI Post-Processing in Unity! (Finally!) - Render Graph URP Camera Stacking Tutorial (2025)](https://www.youtube.com/watch?v=7_Vy0jDqjvM)
