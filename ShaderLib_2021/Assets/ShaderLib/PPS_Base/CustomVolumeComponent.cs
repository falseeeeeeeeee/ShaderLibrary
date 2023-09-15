using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//后处理组件基类
public abstract class CustomVolumeComponent : VolumeComponent, IPostProcessComponent, IDisposable
{
    //后处理插入位置
    public enum  CustomPostProcessInjectionPoint
    {
        AfterOpaqueAndSky,
        BeforePostProcess,
        AfterPostProcess
    }
    
    //在同一个插入点可能会存在多个后处理组件，所以还需要一个排序编号来确定谁先谁后：
    //在InjectionPoint中的渲染顺序
    public virtual int OrderInPass => 0;

    //插入位置
    public virtual CustomPostProcessInjectionPoint InjectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;
    
    //初始化，将在RenderPass加入队列时调用
    public abstract void Setup();
    
    //执行渲染
    //定义一个初始化方法与渲染方法，在渲染方法中，将CommandBuffer、RenderingData、渲染源、目标 传入
    public abstract void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination);

    #region IPostProcessComponent
    
    //返回当前组件是否激活状态
    public abstract bool IsActive();
    public virtual bool IsTileCompatible() => false;

    #endregion
    
    //IDisposable接口的方法，由于渲染可能需要临时生成材质，在这里将它们释放

    #region IDisposable

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }
    
    //释放资源
    public virtual void Dispose(bool disposing)
    {
    }

    #endregion
    
}