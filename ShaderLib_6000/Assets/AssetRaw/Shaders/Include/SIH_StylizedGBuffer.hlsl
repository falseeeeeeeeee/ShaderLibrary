#ifndef SIH_STYLIZED_GBUFFER_INCLUDED
#define SIH_STYLIZED_GBUFFER_INCLUDED

// 自定义材质标记：使用风格化光照
#define kMaterialFlagStylizedLighting (1u << 4)

// 官方的 GBuffer 材质标记在 GBufferCommon.hlsl 中， 使用到 1、2、4、8
// 我们的自定义材质标记 (1u << 4) 表示：整数 1，前进 4 位，得到 00010000，对应 16，等价于写 u16

/* 
 * ----------------------------------------------------------
 * 标记                                   十进制      二进制
 * kMaterialFlagReceiveShadowsOff           1        00000001
 * kMaterialFlagSpecularHighlightsOff       2        00000010
 * kMaterialFlagSpecularHighlightsOff       2        00000010
 * kMaterialFlagSubtractiveMixedLighting    4        00000100
 * kMaterialFlagSpecularSetup               8        00001000
 * kMaterialFlagStylizedLighting            16       00010000
 * ----------------------------------------------------------
 * 上面这个表格展示的是官方的 GBuffer 材质标记
 * 用二进制整数同时记录多个开关，叫做位掩码(bit mask)
 * 如果上述功能全部打开，输出的二进制为 00011111
 * ----------------------------------------------------------
 */

#endif