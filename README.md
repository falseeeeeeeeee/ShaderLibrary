# 【ShaderLibrary】

[TOC]

------

# 😉约定

​		在Unity里有[**Shader Forge (SF)**](https://www.acegikmo.com/shaderforge/)、[**Amplify Shader Editor (ASE)**](http://amplify.pt/unity/amplify-shader-editor/)、[**Shader Graph (SG)**](https://docs.unity3d.com/cn/Packages/com.unity.shadergraph@10.5/manual/index.html) 三种连连看，代码虽然都是[**ShaderLab**](https://docs.unity3d.com/cn/current/Manual/SL-Reference.html)语法但也主要分了[**CG**](https://en.wikipedia.org/wiki/Cg_%28programming_language%29)和[**HLSL**](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl)两种，故在此假定我个人的使用规范。

​		因为CG语言NVIDIA不再更新，Unity也逐渐放弃，手机成为主流，故大多Shader使用[**URP**](https://docs.unity3d.com/cn/Packages/com.unity.render-pipelines.universal@12.1/manual/index.html)管线编写，该工程以[**2021.3.0f1c1以上URP**](https://unity.cn/releases/lts)为基准，我更希望向上升级，尽量不向下兼容，不要再乘坐旧时代的大船了，如果说新的东西不好，那么为什么大家费时费力费钱的去更新这么些的东西。

​		命名前缀按照制作Shader的工具类型当作前缀。如：ASE_XXX、SG_XXX...

​		Shader路径按照使用的管线分类，一级为管线类型，二级为类别。如：Default/Base/ASE_XXX、URP/Base/SG_XXX...

​		Shader采用模块化路径，每一个Shader分为一个文件夹，相关的模型材质引用都放在根目录的**ShaderLib**文件夹下，如：Assets/ShaderLib/Base_XXX/S_XXX.shader

## 命名

| 使用工具                       | 前缀缩写 | 命名方式：前缀缩写_名称.xxx    |
| :----------------------------- | :------- | :----------------------------- |
| Shader Forge                   | SF_      | SF_SimpleLit.shader            |
| Amplify Shader Editor          | ASE_     | ASE_SimpleLit.shader           |
| Amplify Shader Editor 材质函数 | ASEF_    | ASEF_CustomLight.asset         |
| Shader Graph                   | SG_      | SG_SimpleLit.shadergraph       |
| Shader Graph 子图              | SGS_     | SGS_CustomLight.shadersubgraph |
| Shader Graph HLSL引用          | SGH_     | SGH_CustomLight.hlsl           |
| 代码                           | S_       | S_SimpleLit.shader             |
| CG引用                         | SIC_     | SIC_CustomLight.cg             |
| HLSL引用                       | SIH_     | SIH_CustomLight.hlsl           |
| GLSL引用（几乎不用）           | SIG_     | SIG_CustomLight.glsl           |

## 路径

| 管线                    | 命名方式：管线类型/类别/文件名  |
| :---------------------- | :------------------------------ |
| Default（默认渲染管线） | Default/Base/S_SimpleLit.shader |
| LWRP（轻量渲染管线）    | LWRP/Base/S_SimpleLit.shader    |
| **URP（通用渲染管线）** | **URP/Base/S_SimpleLit.shader** |
| HDRP（高清渲染管线）    | HDRP/Base/S_SimpleLit.shader    |

**引用材质函数/子图路径**

如果不通用只用一次就放在原材质旁边，如果通用就要放在对应的Include文件夹内，如项目文件夹路径：Assets/Arts/**Shaders**/Include/ASE

| 使用工具                       | 文件夹路径                       | 命名方式 |
| ------------------------------ | -------------------------------- | -------- |
| Shader Forge 材质函数          | Assets/Arts/Shaders/Include/SF   | SFF_xxx  |
| Amplify Shader Editor 材质函数 | Assets/Arts/Shaders/Include/ASE  | ASEF_xxx |
| Shader Graph 子图              | Assets/Arts/Shaders/Include/SG   | SGS_xxx  |
| Shader Graph HLSL引用          | Assets/Arts/Shaders/Include/SG   | SGH_xxx  |
| CG引用                         | Assets/Arts/Shaders/Include/CG   | SIC_xxx  |
| HLSL引用                       | Assets/Arts/Shaders/Include/HLSL | SIH_xxx  |
| GLSL引用                       | Assets/Arts/Shaders/Include/GLSL | SIG_xxx  |

## 类别

​		该工程为模块化文件夹，是为了方便导出，以及导出后的在新工程的顺利的检索和迁移，与实际项目工程文件夹会有所出入。如：

​		模块化文件夹路径：Assets/ShaderLib/**Base_SimpleLit**/S_SimpleLit.shader

​		项目文件夹路径：Assets/Arts/Shader/**Base**/S_SimpleLit.shader

| 类别                  | 文件名             | 文件夹名称：类别_名称 |
| :-------------------- | :----------------- | :-------------------- |
| Base（基本的）        | S_SimpleLit.shader | Base_SimpleLit        |
| Car（车漆相关）       |                    |                       |
| Character（角色相关） |                    |                       |
| Cloud（云相关）       |                    |                       |
| Effect（效果类型的）  |                    |                       |
| Fog（雾效相关）       |                    |                       |
| FX（给特效使用的）    |                    |                       |
| Glass（玻璃相关的）   |                    |                       |
| PPS（后处理相关）     |                    |                       |
| Render（渲染效果）    |                    |                       |
| Sky（天空盒相关）     |                    |                       |
| Tool（功能性材质）    |                    |                       |
| Vertex（顶点相关的）  |                    |                       |
| Water（水相关的）     |                    |                       |



------



# 🤡目录

## Base

### Base_SimplePBR

![](./ShaderLib_2021/Recordings/Base_SimplePBR/Base_SimplePBR.png)

![](./ShaderLib_2021/Recordings/Base_SimplePBR/Base_SimplePBR.gif)

------

### Base_Unlit

![](./ShaderLib_2021/Recordings/Base_Unlit/Base_Unlit.png)

![](./ShaderLib_2021/Recordings/Base_Unlit/Base_Unlit.gif)

------

## Car

### Car_CarPaint

![](./ShaderLib_2021/Recordings/Car_CarPaint/Car_CarPaint.png)

![](./ShaderLib_2021/Recordings/Car_CarPaint/Car_CarPaint.gif)

------

## Character

### Character_Hair（**Anisotropic Highlight Calculation**）

![](./ShaderLib_2021/Recordings/Character_Hair/Character_Hair.png)

![](./ShaderLib_2021/Recordings/Character_Hair/Character_Hair.gif)

------

### Character_Hair2（UVNoise）

![](./ShaderLib_2021/Recordings/Character_Hair2/Character_Hair2.png)

![](./ShaderLib_2021/Recordings/Character_Hair2/Character_Hair2.gif)

------

### Character_SimpleSSS

![](./ShaderLib_2021/Recordings/Character_SimpleSSS/Character_SimpleSSS.png)

![](./ShaderLib_2021/Recordings/Character_SimpleSSS/Character_SimpleSSS.gif)

------

### Character_Stockings

![](./ShaderLib_2021/Recordings/Character_Stockings/Character_Stockings.png)

![](./ShaderLib_2021/Recordings/Character_Stockings/Character_Stockings.gif)

------

## Cloud

### Cloud_ParallaxCloud

![](./ShaderLib_2021/Recordings/Cloud_ParallaxCloud/Cloud_ParallaxCloud.png)

![](./ShaderLib_2021/Recordings/Cloud_ParallaxCloud/Cloud_ParallaxCloud.gif)

------

## Effect

### Effect_BoxWire

![](./ShaderLib_2021/Recordings/Effect_BoxWire/Effect_BoxWire.png)

![](./ShaderLib_2021/Recordings/Effect_BoxWire/Effect_BoxWire.gif)

------

### Effect_Dissolve

![](./ShaderLib_2021/Recordings/Effect_Dissolve/Effect_Dissolve.png)

![](./ShaderLib_2021/Recordings/Effect_Dissolve/Effect_Dissolve.gif)

------

### Effect_Fluid

![](./ShaderLib_2021/Recordings/Effect_Fluid/Effect_Fluid.png)

![](./ShaderLib_2021/Recordings/Effect_Fluid/Effect_Fluid.gif)

------

### Effect_HexagonDiffusion

![](./ShaderLib_2021/Recordings/Effect_HexagonDiffusion/Effect_HexagonDiffusion.png)

![](./ShaderLib_2021/Recordings/Effect_HexagonDiffusion/Effect_HexagonDiffusion.gif)

------

### Effect_RhythmLED

![](./ShaderLib_2021/Recordings/Effect_RhythmLED/Effect_RhythmLED.png)

![](./ShaderLib_2021/Recordings/Effect_RhythmLED/Effect_RhythmLED.gif)

------

### Effect_Shield

![](./ShaderLib_2021/Recordings/Effect_Shield/Effect_Shield.png)

![](./ShaderLib_2021/Recordings/Effect_Shield/Effect_Shield.gif)

------

### Effect_TextureDiffusion

![](./ShaderLib_2021/Recordings/Effect_TextureDiffusion/Effect_TextureDiffusion.png)

![](./ShaderLib_2021/Recordings/Effect_TextureDiffusion/Effect_TextureDiffusion.gif)

------

### Effect_ThermalChange

![](./ShaderLib_2021/Recordings/Effect_ThermalChange/Effect_ThermalChange.png)

![](./ShaderLib_2021/Recordings/Effect_ThermalChange/Effect_ThermalChange.gif)

------

### Effect_Transitions

![](./ShaderLib_2021/Recordings/Effect_Transitions/Effect_Transitions.png)

![](./ShaderLib_2021/Recordings/Effect_Transitions/Effect_Transitions.gif)

------

### Effect_Transitions2

![](./ShaderLib_2021/Recordings/Effect_Transitions2/Effect_Transitions2.png)

![](./ShaderLib_2021/Recordings/Effect_Transitions2/Effect_Transitions2.gif)

------

### Effect_Transitions3

![](./ShaderLib_2021/Recordings/Effect_Transitions3/Effect_Transitions3.png)

![](./ShaderLib_2021/Recordings/Effect_Transitions3/Effect_Transitions3.gif)

------

### Effect_XRay

![](./ShaderLib_2021/Recordings/Effect_XRay/Effect_XRay.png)

![](./ShaderLib_2021/Recordings/Effect_XRay/Effect_XRay.gif)

------

## Fog

### Fog_HeighFog

![](./ShaderLib_2021/Recordings/Fog_HeighFog/Fog_HeighFog.png)

![](./ShaderLib_2021/Recordings/Fog_HeighFog/Fog_HeighFog.gif)

------

### Fog_UnderWaterFog

![](./ShaderLib_2021/Recordings/Fog_UnderWaterFog/Fog_UnderWaterFog.png)

![](./ShaderLib_2021/Recordings/Fog_UnderWaterFog/Fog_UnderWaterFog.gif)

------

## FX

### FX_UniversalParticleTransparent

![](./ShaderLib_2021/Recordings/FX_UniversalParticleTransparent/FX_UniversalParticleTransparent.png)

![](./ShaderLib_2021/Recordings/FX_UniversalParticleTransparent/FX_UniversalParticleTransparent.gif)

------

## Glass

### Glass_BlurGlass

![](./ShaderLib_2021/Recordings/Glass_BlurGlass/Glass_BlurGlass.png)

![](./ShaderLib_2021/Recordings/Glass_BlurGlass/Glass_BlurGlass.gif)

------

### Glass_MatcapGlass

![](./ShaderLib_2021/Recordings/Glass_MatcapGlass/Glass_MatcapGlass.png)

![](./ShaderLib_2021/Recordings/Glass_MatcapGlass/Glass_MatcapGlass.gif)

------

## PPS

### PPS_Bloom

![](./ShaderLib_2021/Recordings/PPS_Bloom/PPS_Bloom.png)

![](./ShaderLib_2021/Recordings/PPS_Bloom/PPS_Bloom.gif)

------

### PPS_BokehBlur

![](./ShaderLib_2021/Recordings/PPS_BokehBlur/PPS_BokehBlur.png)

![](./ShaderLib_2021/Recordings/PPS_BokehBlur/PPS_BokehBlur.gif)

------

### PPS_DOF_BokehBlur

![](./ShaderLib_2021/Recordings/PPS_DOF_BokehBlur/PPS_DOF_BokehBlur.png)

![](./ShaderLib_2021/Recordings/PPS_DOF_BokehBlur/PPS_DOF_BokehBlur.gif)

------

### PPS_GaussianBlur

![](./ShaderLib_2021/Recordings/PPS_GaussianBlur/PPS_GaussianBlur.png)

![](./ShaderLib_2021/Recordings/PPS_GaussianBlur/PPS_GaussianBlur.gif)

------

### PPS_HueBrightnessSaturationContrast

![](./ShaderLib_2021/Recordings/PPS_HueBrightnessSaturationContrast/PPS_HueBrightnessSaturationContrast.png)

![](./ShaderLib_2021/Recordings/PPS_HueBrightnessSaturationContrast/PPS_HueBrightnessSaturationContrast.gif)

------

### PPS_Mosaic

![](./ShaderLib_2021/Recordings/PPS_Mosaic/PPS_Mosaic.png)

![](./ShaderLib_2021/Recordings/PPS_Mosaic/PPS_Mosaic.gif)

------

### PPS_VolumeLighting

![](./ShaderLib_2021/Recordings/PPS_VolumeLighting/PPS_VolumeLighting.png)

![](./ShaderLib_2021/Recordings/PPS_VolumeLighting/PPS_VolumeLighting.gif)

------

## Render

### Render_Ink

![](./ShaderLib_2021/Recordings/Render_Ink/Render_Ink.png)

![](./ShaderLib_2021/Recordings/Render_Ink/Render_Ink.gif)

------
### Render_Ink2

![](./ShaderLib_2021/Recordings/Render_Ink2/Render_Ink2.png)

![](./ShaderLib_2021/Recordings/Render_Ink2/Render_Ink2.gif)

------

### Render_SimpleToon

![](./ShaderLib_2021/Recordings/Render_SimpleToon/Render_SimpleToon.png)

![](./ShaderLib_2021/Recordings/Render_SimpleToon/Render_SimpleToon.gif)

------

### Render_SimpleJelly

![](./ShaderLib_2021/Recordings/Render_SimpleJelly/Render_SimpleJelly.png)

![](./ShaderLib_2021/Recordings/Render_SimpleJelly/Render_SimpleJelly.gif)

------

### Render_Townscaper

![](./ShaderLib_2021/Recordings/Render_Townscaper/Render_Townscaper.png)

![](./ShaderLib_2021/Recordings/Render_Townscaper/Render_Townscaper.gif)

------

## Sky

### Sky_CustomSkybox

![](./ShaderLib_2021/Recordings/Sky_CustomSkybox/Sky_CustomSkybox.png)

![](./ShaderLib_2021/Recordings/Sky_CustomSkybox/Sky_CustomSkybox.gif)

------

### Sky_StylizedSky

![](./ShaderLib_2021/Recordings/Sky_StylizedSky/Sky_StylizedSky.png)

![](./ShaderLib_2021/Recordings/Sky_StylizedSky/Sky_StylizedSky.gif)

------

### Sky_StylizedSky2

![](./ShaderLib_2021/Recordings/Sky_StylizedSky2/Sky_StylizedSky2.png)

![](./ShaderLib_2021/Recordings/Sky_StylizedSky2/Sky_StylizedSky2.gif)

------

## Tool

### Tool_Billboard

![](./ShaderLib_2021/Recordings/Tool_Billboard/Tool_Billboard.png)

![](./ShaderLib_2021/Recordings/Tool_Billboard/Tool_Billboard.gif)

------

### Tool_BlendModePS（含GUI）

![](./ShaderLib_2021/Recordings/Tool_BlendModePS/Tool_BlendModePS.png)

![](./ShaderLib_2021/Recordings/Tool_BlendModePS/Tool_BlendModePS.gif)

------

### Tool_BlendModeUnity（含GUI）

![](./ShaderLib_2021/Recordings/Tool_BlendModeUnity/Tool_BlendModeUnity.png)

![](./ShaderLib_2021/Recordings/Tool_BlendModeUnity/Tool_BlendModeUnity.gif)

------

### Tool_CubeMap

![](./ShaderLib_2021/Recordings/Tool_CubeMap/Tool_CubeMap.png)

![](./ShaderLib_2021/Recordings/Tool_CubeMap/Tool_CubeMap.gif)

------

### Tool_Decal

![](./ShaderLib_2021/Recordings/Tool_Decal/Tool_Decal.png)

![](./ShaderLib_2021/Recordings/Tool_Decal/Tool_Decal.gif)

------

### Tool_MatCap

![](./ShaderLib_2021/Recordings/Tool_MatCap/Tool_MatCap.png)

![](./ShaderLib_2021/Recordings/Tool_MatCap/Tool_MatCap.gif)

------

### Tool_PlanarShadow

![](./ShaderLib_2021/Recordings/Tool_PlanarShadow/Tool_PlanarShadow.png)

![](./ShaderLib_2021/Recordings/Tool_PlanarShadow/Tool_PlanarShadow.gif)

------

### Tool_PolarCoord

![](./ShaderLib_2021/Recordings/Tool_PolarCoord/Tool_PolarCoord.png)

![](./ShaderLib_2021/Recordings/Tool_PolarCoord/Tool_PolarCoord.gif)

------

### Tool_ScreenSpaceOutlines

![](./ShaderLib_2021/Recordings/Tool_ScreenSpaceOutlines/Tool_ScreenSpaceOutlines.png)

![](./ShaderLib_2021/Recordings/Tool_ScreenSpaceOutlines/Tool_ScreenSpaceOutlines.gif)

------

### Tool_ScreenUV

![](./ShaderLib_2021/Recordings/Tool_ScreenUV/Tool_ScreenUV.png)

![](./ShaderLib_2021/Recordings/Tool_ScreenUV/Tool_ScreenUV.gif)

------

### Tool_Sequence（含Billboard）

![](./ShaderLib_2021/Recordings/Tool_Sequence/Tool_Sequence.png)

![](./ShaderLib_2021/Recordings/Tool_Sequence/Tool_Sequence.gif)

------

## Vertex

### Vertex_VertexAnimaionTexture

![](./ShaderLib_2021/Recordings/Vertex_VertexAnimaionTexture/Vertex_VertexAnimaionTexture.png)

![](./ShaderLib_2021/Recordings/Vertex_VertexAnimaionTexture/Vertex_VertexAnimaionTexture.gif)

------

### Vertex_VertexAnimaionUVCut

![](./ShaderLib_2021/Recordings/Vertex_VertexAnimaionUVCut/Vertex_VertexAnimaionUVCut.png)

![](./ShaderLib_2021/Recordings/Vertex_VertexAnimaionUVCut/Vertex_VertexAnimaionUVCut.gif)

------

## Water

### Water_LiquidWater

![](./ShaderLib_2021/Recordings/Water_LiquidWater/Water_LiquidWater.png)

![](./ShaderLib_2021/Recordings/Water_LiquidWater/Water_LiquidWater.gif)

------

### Water_LiquidWater2D

![](./ShaderLib_2021/Recordings/Water_LiquidWater2D/Water_LiquidWater2D.png)

![](./ShaderLib_2021/Recordings/Water_LiquidWater2D/Water_LiquidWater2D.gif)

------

### Water_RealWater

![](./ShaderLib_2021/Recordings/Water_RealWater/Water_RealWater.png)

![](./ShaderLib_2021/Recordings/Water_RealWater/Water_RealWater.gif)

------

### Water_SimpleLava

![](./ShaderLib_2021/Recordings/Water_SimpleLava/Water_SimpleLava.png)

![](./ShaderLib_2021/Recordings/Water_SimpleLava/Water_SimpleLava.gif)

------

### Water_ToonWater

![](./ShaderLib_2021/Recordings/Water_ToonWater/Water_ToonWater.png)

![](./ShaderLib_2021/Recordings/Water_ToonWater/Water_ToonWater.gif)

------


# 🥰巨人的肩膀

## 函数相关

[Cg Toolkit | NVIDIA Developer](https://developer.nvidia.com/cg-toolkit)

[Cg标准函数库 - 简书 (jianshu.com)](https://www.jianshu.com/p/c789aff2d6e9)

[Unity Shader目录-初级篇 - 简书 (jianshu.com)](https://www.jianshu.com/p/3db29c182669)

[Unity Shader目录-中级篇 - 简书 (jianshu.com)](https://www.jianshu.com/p/8c3f1b363768)

## 光照相关

[Unity URP GI，Meta Pass，脚本切换Light Map学习 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/606484690)
