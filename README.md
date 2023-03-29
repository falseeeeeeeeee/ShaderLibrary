# 【ShaderLibrary】
> 希望开源能够帮到所有人。

[TOC]



# 😉约定

​		在Unity里有[**Shader Forge (SF)**](https://www.acegikmo.com/shaderforge/)、[**Amplify Shader Editor (ASE)**](http://amplify.pt/unity/amplify-shader-editor/)、[**Shader Graph (SG)**](https://docs.unity3d.com/cn/Packages/com.unity.shadergraph@10.5/manual/index.html) 三种连连看，代码虽然都是**[ShaderLab](https://docs.unity3d.com/cn/current/Manual/SL-Reference.html)**语法但也主要分了**[CG](https://en.wikipedia.org/wiki/Cg_%28programming_language%29)**和**[HLSL](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl)**两种，故在此假定我个人的使用规范。

​		因为CG语言NVIDIA不再更新，Unity也逐渐放弃，手机成为主流，故大多Shader使用[**URP**](https://docs.unity3d.com/cn/Packages/com.unity.render-pipelines.universal@12.1/manual/index.html)管线编写，该工程以[**2021.3.0f1c1以上**](https://unity.cn/releases/lts)为基准，我主张向上升级，不赞同向下兼容，不要再乘坐旧时代的大船了，如果说新的东西不好，那么为什么大家费时费力费钱的去更新这么些的东西。

​		命名前缀按照制作Shader的工具类型当作前缀。如：ASE_XXX、SG_XXX...

​		Shader路径按照使用的管线分类，一级为管线类型，二级为文件夹分类路径。如：CG/Base/ASE_XXX、URP/Base/SG_XXX...

## 命名规范

| 使用工具                       | 前缀缩写 | 命名方式：前缀缩写_名称.xxx    |
| ------------------------------ | -------- | ------------------------------ |
| Shader Forge                   | SF_      | SF_SimpleLit.shader            |
| Amplify Shader Editor          | ASE_     | ASE_SimpleLit.shader           |
| Amplify Shader Editor 材质函数 | ASF_     | ASF_CustomLight.asset          |
| Shader Graph                   | SG_      | SG_SimpleLit.shadergraph       |
| Shader Graph 子图              | SGS_     | SGS_CustomLight.shadersubgraph |
| Shader Graph HLSL引用          | SGH_     | SGH_CustomLight.hlsl           |
| 代码                           | S_       | S_SimpleLit.shader             |
| CG引用                         | SIC_     | SIC_CustomLight.cg             |
| HLSL引用                       | SIH_     | SIH_CustomLight.hlsl           |
| GLSL引用（几乎不用）           | SIG_     | SIG_CustomLight.glsl           |

## 路径规范

| 管线                    | 路径规范：管线类型/目录/文件名 |
| ----------------------- | ------------------------------ |
| CG（默认渲染管线）      | CG/Base/S_XXX                  |
| LWRP（轻量渲染管线）    | LWRP/Base/S_XXX                |
| **URP（通用渲染管线）** | URP/Base/S_XXX                 |
| HDRP（高清渲染管线）    | HDRP/Base/S_XXX                |



# 🤡目录

## Base

## Effect

## Vertex





# 🥰相关链接

[Cg Toolkit | NVIDIA Developer](https://developer.nvidia.com/cg-toolkit)

[Cg标准函数库 - 简书 (jianshu.com)](https://www.jianshu.com/p/c789aff2d6e9)

[Unity Shader目录-初级篇 - 简书 (jianshu.com)](https://www.jianshu.com/p/3db29c182669)

[Unity Shader目录-中级篇 - 简书 (jianshu.com)](https://www.jianshu.com/p/8c3f1b363768)

