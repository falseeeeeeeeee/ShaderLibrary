using System.Collections.Generic;
using System.Linq;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomPostProcessRenderPass : ScriptableRenderPass
{
    //构造方法中接收这个Render Pass的Profiler标识与后处理组件列表，以每个组件的名称作为它们渲染时的Profiler标识。

    List<CustomVolumeComponent> volumeComponents; // 所有自定义后处理组件
    List<int> activeComponents; //当前可用的组件下标

    string profilerTag; //Profiler标识

    //围绕CPU和GPU分析采样器的包装器。在ProfilingScope中使用它来分析一段代码。
    List<ProfilingSampler> profilingSamplers; // 每个组件对应的ProfilingSampler

    RenderTargetHandle source; //源图像
    RenderTargetHandle destination; //目标图像
    RenderTargetHandle tempRT0; //临时RT
    RenderTargetHandle tempRT1; //临时RT
    private ScriptableRenderPass _scriptableRenderPassImplementation; //执行

    /// <param name="profilerTag">Profiler标识</param>
    /// <param name="volumeComponents">属于该RendererPass的后处理组件</param>
    public CustomPostProcessRenderPass(string profilerTag, List<CustomVolumeComponent> volumeComponents)
    {
        this.profilerTag = profilerTag; //Profiler标识
        this.volumeComponents = volumeComponents; //属于该RendererPass的后处理组件
        activeComponents = new List<int>(volumeComponents.Count); //当前可用的组件下标
        profilingSamplers = volumeComponents.Select(c => new ProfilingSampler(c.ToString())).ToList();

        tempRT0.Init("_TemporaryRenderTexture0");
        tempRT1.Init("_TemporaryRenderTexture1");
    }

    /// <summary>
    /// 设置后处理组件
    /// </summary>
    /// <returns>是否存在有效组件</returns>
    public bool SetupComponents()
    {
        activeComponents.Clear();
        for (int i = 0; i < volumeComponents.Count; i++)
        {
            volumeComponents[i].Setup();
            if (volumeComponents[i].IsActive())
            {
                activeComponents.Add(i);
            }
        }

        return activeComponents.Count != 0;
    }

    /// <summary>
    /// 设置渲染源和渲染目标
    /// </summary>
    public void Setup(RenderTargetHandle source, RenderTargetHandle destination)
    {
        this.source = source;
        this.destination = destination;
    }

    // 你可以在这里实现渲染逻辑。
    // 使用<c>ScriptableRenderContext</c>来执行绘图命令或Command Buffer
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // 你不需要手动调用ScriptableRenderContext.submit，渲染管线会在特定位置调用它。
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        //通过Profiler标识获取一个新的命令缓冲区，并为它分配一个名称。
        //命名命令缓冲区将为缓冲区执行隐式地添加分析生成器。
        var cmd = CommandBufferPool.Get(profilerTag);
        context.ExecuteCommandBuffer(cmd); //调度自定义图形命令缓冲区的执行（指定要执行的命令缓冲区）
        cmd.Clear(); //清除缓冲区中的所有命令

        // 获取Descriptor描述符号
        var descriptor = renderingData.cameraData.cameraTargetDescriptor;
        descriptor.msaaSamples = 1; //RenderTexture的多采样抗锯齿级别。
        descriptor.depthBufferBits = 0; //渲染纹理深度缓冲的精度以比特位为单位(支持0,16,24/32)。
        // descriptor.width = descriptor.width / 2;
        // descriptor.height = descriptor.height / 2;

        // 初始化临时RT
        RenderTargetIdentifier buff0, buff1; //标识一个渲染CommandBuffer的RenderTexture
        bool rt1Used = false; //是否使用rt1
        cmd.GetTemporaryRT(tempRT0.id, descriptor); //获得临时RT0
        buff0 = tempRT0.id; //buff0

        // 如果destination没有初始化，则需要获取RT，主要是destinaton为_AfterPostProcessTexture的情况
        if (destination != RenderTargetHandle.CameraTarget && !destination.HasInternalRenderTargetId())
        {
            cmd.GetTemporaryRT(destination.id, descriptor); //获得临时RT
        }

        // 执行每个组件的Render方法
        // 如果只有一个组件，则直接source -> buff0
        if (activeComponents.Count == 1)
        {
            int index = activeComponents[0]; //组件数
            using (new ProfilingScope(cmd, profilingSamplers[index])) //分析范围（cmd，采样器）
            {
                volumeComponents[index].Render(cmd, ref renderingData, source.Identifier(), buff0); //渲染到buff0
            }
        }
        else
        {
            // 如果有多个组件，则在两个RT上左右横跳
            cmd.GetTemporaryRT(tempRT1.id, descriptor); //获得临时RT1
            buff1 = tempRT1.id; //buff1
            rt1Used = true; //使用rt1
            Blit(cmd, source.Identifier(), buff0); //先渲染到buff0
            for (int i = 0; i < activeComponents.Count; i++) //遍历组件数
            {
                int index = activeComponents[i]; //组件数
                var component = volumeComponents[index]; //组件
                using (new ProfilingScope(cmd, profilingSamplers[index])) //分析范围（cmd，采样器）
                {
                    component.Render(cmd, ref renderingData, buff0, buff1); //从buff0渲染到buff1
                }

                CoreUtils.Swap(ref buff0, ref buff1); //交换，buff0→buff1，buff1→buff0
            }
        }

        Blit(cmd, buff0, destination.Identifier()); //最后blit到destination最终

        cmd.ReleaseTemporaryRT(tempRT0.id); //释放RT0

        if (rt1Used) //如果使用rt1
            cmd.ReleaseTemporaryRT(tempRT1.id); //释放RT1

        context.ExecuteCommandBuffer(cmd); //执行命令缓冲区
        CommandBufferPool.Release(cmd); //释放命令缓冲池
    }
}