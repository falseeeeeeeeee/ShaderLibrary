using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.SocialPlatforms.GameCenter;

public class UniversalParticleTransparentGUI : ShaderGUI
{
    // 卷展栏UI风格
    public GUIStyle style = new GUIStyle();
    static bool Foldout(bool display, string title)
    {
        var style = new GUIStyle("ShurikenModuleTitle");
        style.font = new GUIStyle(EditorStyles.boldLabel).font;
        style.border = new RectOffset(15, 7, 4, 4);
        style.fixedHeight = 22;     // 灰条条
        style.contentOffset = new Vector2(20, -2f);
        style.fontSize = 13;
        style.fontStyle = FontStyle.Bold;
        //style.normal.textColor = new Color(0.5f, 0.5f, 0.5f);

        var rect = GUILayoutUtility.GetRect(16f, 25, style);
        GUI.Box(rect, title, style);

        var e = Event.current;

        var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
        if (e.type == EventType.Repaint)
        {
            EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
        }

        if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
        {
            display = !display;
            e.Use();
        }

        return display;
    }
    
    #region [卷展栏模块开关]
    static bool _Custom_Foldout = false;
    static bool _Main_Foldout = true;
    static bool _Add1_Foldout = true;
    static bool _Mask_Foldout = true;
    static bool _Dissolve_Foldout = true;    
    static bool _Distort_Foldout = true;
    static bool _Fresnel_Foldout = true;
    static bool _Vertex_Foldout = true;
    static bool _Render_Foldout = true;
    #endregion

    #region [属性声明]
    Material material;
    MaterialEditor materialEditor;
    //MaterialProperty[] materialProperty;
    
    MaterialProperty MainColor = null;
    MaterialProperty MainTex = null;
    MaterialProperty MainTexUVS = null;
    MaterialProperty CylinderFace = null;
    MaterialProperty CylinderCenter = null;
    MaterialProperty MainTexAR = null;
    MaterialProperty MainTexUSpeed = null;
    MaterialProperty MainTexVSpeed = null;
    MaterialProperty CustomMainTex = null;
    MaterialProperty MainTexMulVertexColor = null;
    
    MaterialProperty FAddTex1 = null;
    MaterialProperty AddColor1 = null;
    MaterialProperty AddTex1 = null;
    MaterialProperty AddTex1UVCenter = null;
    MaterialProperty AddTex1UVRotation = null;
    MaterialProperty AddTex1Power = null;
    MaterialProperty AddTex1Intensity = null;
    MaterialProperty AddTex1UVStyle = null;
    MaterialProperty AddTex1BlendStyle = null;
    MaterialProperty Add1Saturation = null;
    MaterialProperty Add1Brightness = null;
    MaterialProperty AddTex1RSpeed = null;
    MaterialProperty AddTex1USpeed = null;
    MaterialProperty AddTex1VSpeed = null;
    MaterialProperty CustomAddTex1 = null;
    MaterialProperty AddTex1MulVertexColor = null;
    
    MaterialProperty FMaskTex = null;
    MaterialProperty MaskTex = null;
    MaterialProperty MaskTexReverse = null;
    MaterialProperty MaskTexUVS = null;
    MaterialProperty MaskTexAR = null;
    MaterialProperty MaskTexUSpeed = null;
    MaterialProperty MaskTexVSpeed = null;    
    
    MaterialProperty FDissolveTex = null;
    MaterialProperty DissolveColor = null;
    MaterialProperty DissolveTex = null;
    MaterialProperty DissolveTexPower = null;
    MaterialProperty DissolveTexIntensity = null;
    MaterialProperty DissolveTexUVS = null;
    MaterialProperty DissolveTexAR = null;
    MaterialProperty DissolveTexUSpeed = null;
    MaterialProperty DissolveTexVSpeed = null;
    MaterialProperty CustomDissolveTex = null;
    MaterialProperty DissolveIntensity = null;
    MaterialProperty DissolveTexSoft = null;
    MaterialProperty DissolveSoft = null;
    MaterialProperty DissolveWide = null;
    MaterialProperty DissolveWideUseColor = null;
    MaterialProperty DissolveWideSaturation = null;
    
    MaterialProperty FDistortTex = null;
    MaterialProperty DistortTex = null;
    MaterialProperty DistortTexAR = null;
    MaterialProperty DistortTexUSpeed = null;
    MaterialProperty DistortTexVSpeed = null;
    MaterialProperty CustomDistortTex = null;
    MaterialProperty DistortIntensity = null;
    MaterialProperty DistortMainTex = null;
    MaterialProperty DistortMaskTex = null;
    MaterialProperty DistortDissolveTex = null;    
    
    MaterialProperty FFresnel = null;
    MaterialProperty FresnelBlendStyle = null;
    MaterialProperty FresnelAlphaBlendStyle = null;
    MaterialProperty FresnelMulVertexColor = null;
    MaterialProperty FresnelHard = null;
    MaterialProperty FresnelReverse = null;
    MaterialProperty FresnelColor = null;
    MaterialProperty FresnelScale = null;
    MaterialProperty FresnelPower = null;
    
    MaterialProperty FVertexOffsetTex = null;
    MaterialProperty VertexOffsetTex = null;
    MaterialProperty VertexOffsetTexUSpeed = null;
    MaterialProperty VertexOffsetTexVSpeed = null;
    MaterialProperty VertexOffsetXYZSpeed = null;
    MaterialProperty CustomVertexOffsetTex = null;
    MaterialProperty VertexOffsetStrength = null;
    
    MaterialProperty BlendMode = null;
    MaterialProperty BlendOp = null;
    MaterialProperty SrcBlend = null;
    MaterialProperty DstBlend = null;
    
    MaterialProperty CullMode = null;
    MaterialProperty ColorMask = null;
    MaterialProperty ZWriteMode = null;
    MaterialProperty ZTestMode = null;
    MaterialProperty StencilToggle = null;
    MaterialProperty Stencil = null;
    MaterialProperty StencilComp = null;
    MaterialProperty StencilWriteMask = null;
    MaterialProperty StencilReadMask = null;
    MaterialProperty StencilPass = null;
    MaterialProperty StencilFail = null;
    MaterialProperty StencilZFail = null;
    
    MaterialProperty AlphaGamma = null;
    MaterialProperty CustomAlphaGamma = null;
    MaterialProperty AlphaCut = null;
    MaterialProperty Cutoff = null;
    MaterialProperty PreMulAlpha = null;
    MaterialProperty SoftParticles = null;
    MaterialProperty SoftFade = null;
    MaterialProperty Transparent = null;
    #endregion

    #region [属性对应变量名]
    public void FindProperties(MaterialProperty[] properties)
    {
        MainTex = FindProperty("_MainTex", properties);
        MainColor = FindProperty("_MainColor", properties);
        MainTexUVS = FindProperty("_MainTexUVS", properties);
        CylinderFace = FindProperty("_CylinderFace", properties);
        CylinderCenter = FindProperty("_CylinderCenter", properties);
        MainTexAR = FindProperty("_MainTexAR", properties);
        MainTexUSpeed = FindProperty("_MainTexUSpeed", properties);
        MainTexVSpeed = FindProperty("_MainTexVSpeed", properties);
        CustomMainTex = FindProperty("_CustomMainTex", properties);
        MainTexMulVertexColor = FindProperty("_MainTexMulVertexColor", properties);
        
        FAddTex1 = FindProperty("_FAddTex1", properties);
        AddColor1 = FindProperty("_AddColor1", properties);;
        AddTex1 = FindProperty("_AddTex1", properties);;
        AddTex1UVCenter = FindProperty("_AddTex1UVCenter", properties);;
        AddTex1UVRotation = FindProperty("_AddTex1UVRotation", properties);;
        AddTex1Power = FindProperty("_AddTex1Power", properties);;
        AddTex1Intensity = FindProperty("_AddTex1Intensity", properties);;
        AddTex1UVStyle = FindProperty("_AddTex1UVS", properties);;
        AddTex1BlendStyle = FindProperty("_AddTex1BlendStyle", properties);;
        Add1Saturation = FindProperty("_Add1Saturation", properties);;
        Add1Brightness = FindProperty("_Add1Brightness", properties);;
        AddTex1RSpeed = FindProperty("_AddTex1RSpeed", properties);;
        AddTex1USpeed = FindProperty("_AddTex1USpeed", properties);;
        AddTex1VSpeed = FindProperty("_AddTex1VSpeed", properties);;
        CustomAddTex1 = FindProperty("_CustomAddTex1", properties);;
        AddTex1MulVertexColor = FindProperty("_AddTex1MulVertexColor", properties);;

        FMaskTex = FindProperty("_FMaskTex", properties);
        MaskTex = FindProperty("_MaskTex", properties);
        MaskTexReverse = FindProperty("_MaskTexReverse", properties);
        MaskTexUVS = FindProperty("_MaskTexUVS", properties);
        MaskTexAR = FindProperty("_MaskTexAR", properties);
        MaskTexUSpeed = FindProperty("_MaskTexUSpeed", properties);
        MaskTexVSpeed = FindProperty("_MaskTexVSpeed", properties);
        
        FDissolveTex = FindProperty("_FDissolveTex", properties);
        DissolveColor = FindProperty("_DissolveColor", properties);
        DissolveTex = FindProperty("_DissolveTex", properties);
        DissolveTexPower = FindProperty("_DissolveTexPower", properties);
        DissolveTexIntensity = FindProperty("_DissolveTexIntensity", properties);
        DissolveTexUVS = FindProperty("_DissolveTexUVS", properties);
        DissolveTexAR = FindProperty("_DissolveTexAR", properties);
        DissolveTexUSpeed = FindProperty("_DissolveTexUSpeed", properties);
        DissolveTexVSpeed = FindProperty("_DissolveTexVSpeed", properties);
        CustomDissolveTex = FindProperty("_CustomDissolveTex", properties);
        DissolveIntensity = FindProperty("_DissolveIntensity", properties);
        DissolveTexSoft = FindProperty("_DissolveTexSoft", properties);
        DissolveSoft = FindProperty("_DissolveSoft", properties);
        DissolveWide = FindProperty("_DissolveWide", properties);
        DissolveWideUseColor = FindProperty("_DissolveWideUseColor", properties);
        DissolveWideSaturation = FindProperty("_DissolveWideSaturation", properties);

        FDistortTex = FindProperty("_FDistortTex", properties); 
        DistortTex = FindProperty("_DistortTex", properties);
        DistortTexAR = FindProperty("_DistortTexAR", properties);
        DistortTexUSpeed = FindProperty("_DistortTexUSpeed", properties);
        DistortTexVSpeed = FindProperty("_DistortTexVSpeed", properties);
        CustomDistortTex = FindProperty("_CustomDistortTex", properties);
        DistortIntensity = FindProperty("_DistortIntensity", properties);
        DistortMainTex = FindProperty("_DistortMainTex", properties);
        DistortMaskTex = FindProperty("_DistortMaskTex", properties);
        DistortDissolveTex = FindProperty("_DistortDissolveTex", properties);    

        FFresnel = FindProperty("_FFresnel", properties);
        FresnelBlendStyle = FindProperty("_FresnelBlendStyle", properties);
        FresnelAlphaBlendStyle = FindProperty("_FresnelAlphaBlendStyle", properties);
        FresnelMulVertexColor = FindProperty("_FresnelMulVertexColor", properties);
        FresnelHard = FindProperty("_FresnelHard", properties);
        FresnelReverse = FindProperty("_FresnelReverse", properties);
        FresnelColor = FindProperty("_FresnelColor", properties);
        FresnelScale = FindProperty("_FresnelScale", properties);
        FresnelPower = FindProperty("_FresnelPower", properties);        
        
        FVertexOffsetTex = FindProperty("_FVertexOffsetTex", properties);
        VertexOffsetTex = FindProperty("_VertexOffsetTex", properties);
        VertexOffsetTexUSpeed = FindProperty("_VertexOffsetTexUSpeed", properties);
        VertexOffsetTexVSpeed = FindProperty("_VertexOffsetTexVSpeed", properties);
        VertexOffsetXYZSpeed = FindProperty("_VertexOffsetXYZSpeed", properties);
        CustomVertexOffsetTex = FindProperty("_CustomVertexOffsetTex", properties);
        VertexOffsetStrength = FindProperty("_VertexOffsetStrength", properties);

        BlendMode = FindProperty("_BlendMode", properties);
        BlendOp = FindProperty("_BlendOp", properties);
        SrcBlend = FindProperty("_SrcBlend", properties);
        DstBlend = FindProperty("_DstBlend", properties);
        CullMode = FindProperty("_CullMode", properties);
        ColorMask = FindProperty("_ColorMask", properties);
        ZWriteMode = FindProperty("_ZWriteMode", properties);
        ZTestMode = FindProperty("_ZTestMode", properties);
        
        StencilToggle = FindProperty("_StencilToggle", properties);
        Stencil = FindProperty("_Stencil", properties);
        StencilComp = FindProperty("_StencilComp", properties);
        StencilWriteMask = FindProperty("_StencilWriteMask", properties);
        StencilReadMask = FindProperty("_StencilReadMask", properties);
        StencilPass = FindProperty("_StencilPass", properties);
        StencilFail = FindProperty("_StencilFail", properties);
        StencilZFail = FindProperty("_StencilZFail", properties);
        
        AlphaGamma = FindProperty("_AlphaGamma", properties);
        CustomAlphaGamma = FindProperty("_CustomAlphaGamma", properties);
        AlphaCut = FindProperty("_AlphaCut", properties);
        Cutoff = FindProperty("_Cutoff", properties);
        PreMulAlpha = FindProperty("_PreMulAlpha", properties);
        SoftParticles = FindProperty("_SoftParticles", properties);
        SoftFade = FindProperty("_SoftFade", properties);
        Transparent = FindProperty("_Transparent", properties);
    }
    

    #endregion

    #region [自定义枚举]
    enum EnumBlendMode
    {
        AlphaBlend,
        PremultiplyAlphaBlend,
        Additive,
        AdditiveBlend,
        SoftAdditive,
        Multiply,
        DoubleMultiply,
        Custom
    }
    enum EnumCullMode
    {
        Off,
        Front,
        Back
    }
    #endregion

    // 绘制顺序
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        FindProperties(properties); //拿到属性
        this.materialEditor = materialEditor;
        this.material = materialEditor.target as Material;

        //TopFoldout();

        CustomFoldoutShow();
        
        MainFoldoutShow();
        Add1FoldoutShow();
        MaskFoldoutShow();
        DissolveFoldoutShow();
        DistortFoldoutShow();
        FresnelFoldoutShow();
        VertexFoldoutShow();

        RenderFoldoutShow();
    }

    #region [自定义模块]
    // 顶部文字
    void TopFoldout()
    {
        var topStyle = new GUIStyle("ShurikenModuleTitle");
        topStyle.fixedHeight = 60;     // 灰条条
        topStyle.alignment = TextAnchor.MiddleCenter;
        topStyle.fontSize = 25;
        topStyle.fontStyle = FontStyle.Bold;
        GUILayout.Box(new GUIContent("特效通用透明材质（Tansparent）    "), topStyle,new []{GUILayout.Height(60), GUILayout.ExpandWidth(true)});
    }
    
    // 自定义
    void CustomFoldoutShow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Custom_Foldout = Foldout(_Custom_Foldout, "自定义模块");

        if (_Custom_Foldout)
        {
            EditorGUI.indentLevel++;
            
            materialEditor.ShaderProperty(FAddTex1, "额外的贴图1（Add1）模块");
            GUILayout.Space(5);                
            materialEditor.ShaderProperty(FMaskTex, "遮罩（Mask）模块");
            GUILayout.Space(5);            
            materialEditor.ShaderProperty(FDissolveTex, "溶解（Dissolve）模块");
            GUILayout.Space(5);            
            materialEditor.ShaderProperty(FDistortTex, "UV扭曲（Distort）模块");
            GUILayout.Space(5);            
            materialEditor.ShaderProperty(FFresnel, "菲涅尔（Fresnel）模块");
            GUILayout.Space(5);            
            materialEditor.ShaderProperty(FVertexOffsetTex, "顶点偏移（VertexOffset）模块");
            GUILayout.Space(5);
            
            
            // Tips
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            style.fontSize = 12;
            style.normal.textColor = new Color(0.5f, 0.5f, 0.5f);
            style.wordWrap = true;
            GUILayout.Space(5); GUILayout.Label("用什么开什么，不用的模块要记得关闭，不然会有性能问题，没有用到还都开着是会变成猪的", style);
            GUILayout.Space(5); GUILayout.Label("有Bug，或者觉得哪不好用，或者要加什么功能记得反馈哦", style);
            GUILayout.Space(5);
            EditorGUILayout.EndVertical();
            

            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }    
    
    // 主贴图设置
    void MainFoldoutShow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Main_Foldout = Foldout(_Main_Foldout, "基本贴图");

        if (_Main_Foldout)
        {
            EditorGUI.indentLevel++;

            materialEditor.TexturePropertySingleLine(new GUIContent("主贴图（MainTex）"), MainTex, MainColor);
            GUILayout.Space(5);

            //if (MainTex.textureValue != null ) 
            { 
                using (new EditorGUI.IndentLevelScope())
                {
                    EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                    materialEditor.TextureScaleOffsetProperty(MainTex);
                    materialEditor.ShaderProperty(MainTexUVS, new GUIContent("UV模式","正常，极坐标，圆柱体"));
                    if (material.GetFloat("_MainTexUVS") == 2) 
                    {                    
                        EditorGUI.indentLevel += 1;
                        materialEditor.ShaderProperty(CylinderFace, "圆柱体面朝向（Face）");
                        materialEditor.ShaderProperty(CylinderCenter, "圆柱体中心（Center）");
                        EditorGUI.indentLevel -= 1;
                    }
                    materialEditor.ShaderProperty(MainTexAR, new GUIContent("R通道为透明通道","没有Alaha通道还想让黑白图透明就勾上"));
                    GUILayout.Space(3);
                    EditorGUILayout.EndVertical();
                    GUILayout.Space(3);
                }

                materialEditor.ShaderProperty(MainTexUSpeed, "U 方向流动");
                materialEditor.ShaderProperty(MainTexVSpeed, "V 方向流动");
                materialEditor.ShaderProperty(CustomMainTex, new GUIContent("粒子自定义数据（UV偏移）","使用粒子的Custom1.xy控制主贴图额外的UV偏移（使用先添加uv2，再添加Custom1.xyzw，再添加Custom2.xyzw）"));
                materialEditor.ShaderProperty(MainTexMulVertexColor, new GUIContent("使用粒子颜色（VertexColor）","粒子颜色与主贴图颜色相乘（含Alpha）"));
                GUILayout.Space(5);
            }
            
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }
    
    // 额外的贴图1
    void Add1FoldoutShow()
    {
        bool bFAddTex1 = material.GetFloat("_FAddTex1") == 1;
        SetKeyword(material, "_FADDTEX1_ON", bFAddTex1);
        if (bFAddTex1) 
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            _Add1_Foldout = Foldout(_Add1_Foldout, "额外的贴图1（AddTex1），如：扫光");

            if (_Add1_Foldout)
            {
                EditorGUI.indentLevel++;
        
                materialEditor.TexturePropertySingleLine(new GUIContent("额外贴图1（AddTex1）"), AddTex1, AddColor1);
                GUILayout.Space(5);

                if (AddTex1.textureValue != null)
                {
                    using (new EditorGUI.IndentLevelScope())
                    {
                        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                        GUILayout.Space(3);
                        materialEditor.TextureScaleOffsetProperty(AddTex1);
                        materialEditor.ShaderProperty(AddTex1UVRotation, "UV旋转角度（Center）");
                        materialEditor.ShaderProperty(AddTex1UVCenter, "UV旋转中心（Center）");
                        materialEditor.ShaderProperty(AddTex1Power, "额外贴图1锐度（Power）");
                        materialEditor.ShaderProperty(AddTex1Intensity, "额外贴图1亮度（Multiply）");
                        materialEditor.ShaderProperty(AddTex1UVStyle, new GUIContent("UV模式","正常，极坐标，圆柱体"));
                        if (material.GetFloat("_AddTex1UVS") == 2) 
                        {                    
                            EditorGUI.indentLevel += 1;
                            materialEditor.ShaderProperty(CylinderFace, "圆柱体面朝向（Face）");
                            materialEditor.ShaderProperty(CylinderCenter, "圆柱体中心（Center）");
                            EditorGUI.indentLevel -= 1;
                        }
                        GUILayout.Space(3);
                        EditorGUILayout.EndVertical();
                        GUILayout.Space(3);
                    }

                    materialEditor.ShaderProperty(AddTex1RSpeed, "UV 旋转速度");
                    materialEditor.ShaderProperty(AddTex1USpeed, "U 方向流动");
                    materialEditor.ShaderProperty(AddTex1VSpeed, "V 方向流动");
                    materialEditor.ShaderProperty(AddTex1BlendStyle, "额外贴图1与主贴图混合模式");
                    materialEditor.ShaderProperty(Add1Saturation, "额外贴图1饱和度（Saturatio）");
                    materialEditor.ShaderProperty(Add1Brightness, "额外贴图1亮度（Multiply）");
                    materialEditor.ShaderProperty(CustomAddTex1, new GUIContent("粒子自定义数据（UV偏移）","使用粒子的Custom2.zw控制UV方向的偏移（使用先添加uv2，再添加Custom1.xyzw，再添加Custom2.xyzw）"));
                    materialEditor.ShaderProperty(AddTex1MulVertexColor, new GUIContent("使用粒子颜色（VertexColor）","粒子颜色与主贴图颜色相乘（无Alpha）"));

                    GUILayout.Space(5);
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }
    }    
    
    // 遮罩图
    void MaskFoldoutShow()
    {
        bool bFMaskTex = material.GetFloat("_FMaskTex") == 1;
        SetKeyword(material, "_FMASKTEX_ON", bFMaskTex);
        if (bFMaskTex) 
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            _Mask_Foldout = Foldout(_Mask_Foldout, "遮罩（Mask）");

            if (_Mask_Foldout)
            {
                EditorGUI.indentLevel++;
        
                materialEditor.TexturePropertySingleLine(new GUIContent("遮罩贴图（MaskTex）"), MaskTex);
                GUILayout.Space(5);

                if (MaskTex.textureValue != null)
                {
                    using (new EditorGUI.IndentLevelScope())
                    {
                        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                        GUILayout.Space(3);
                        materialEditor.TextureScaleOffsetProperty(MaskTex);
                        materialEditor.ShaderProperty(MaskTexUVS, new GUIContent("UV模式","正常，极坐标，圆柱体"));
                        if (material.GetFloat("_MaskTexUVS") == 2) 
                        {                    
                            EditorGUI.indentLevel += 1;
                            materialEditor.ShaderProperty(CylinderFace, "圆柱体面朝向（Face）");
                            materialEditor.ShaderProperty(CylinderCenter, "圆柱体中心（Center）");
                            EditorGUI.indentLevel -= 1;
                        }
                        materialEditor.ShaderProperty(MaskTexReverse, "遮罩贴图反转（Reverse）");
                        materialEditor.ShaderProperty(MaskTexAR, new GUIContent("R通道为遮罩通道","这个建议用黑白图，用R通道做遮罩，要是非得偷懒用张RGBA的我也没有办法"));
                        GUILayout.Space(3);
                        EditorGUILayout.EndVertical();
                        GUILayout.Space(3);
                    }

                    materialEditor.ShaderProperty(MaskTexUSpeed, "U 方向流动");
                    materialEditor.ShaderProperty(MaskTexVSpeed, "V 方向流动");
                    GUILayout.Space(5);
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }
    }    
    
    // 溶解图
    void DissolveFoldoutShow()
    {
        bool bFDissolveTex = material.GetFloat("_FDissolveTex") == 1;
        SetKeyword(material, "_FDISSOLVETEX_ON", bFDissolveTex);
        if (bFDissolveTex) 
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            _Dissolve_Foldout = Foldout(_Dissolve_Foldout, "溶解（Dissolve）");

            if (_Dissolve_Foldout)
            {
                EditorGUI.indentLevel++;
        
                materialEditor.TexturePropertySingleLine(new GUIContent("溶解贴图（DissolveTex）"), DissolveTex, DissolveColor);
                GUILayout.Space(5);

                if (DissolveTex.textureValue != null)
                {
                    using (new EditorGUI.IndentLevelScope())
                    {
                        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                        GUILayout.Space(3);
                        materialEditor.TextureScaleOffsetProperty(DissolveTex);
                        materialEditor.ShaderProperty(DissolveTexPower, "溶解贴图锐度（Power）");
                        materialEditor.ShaderProperty(DissolveTexIntensity, "溶解贴图亮度（Multiply）");
                        materialEditor.ShaderProperty(DissolveTexUVS, new GUIContent("UV模式","正常，极坐标，圆柱体"));
                        if (material.GetFloat("_DissolveTexUVS") == 2) 
                        {                    
                            EditorGUI.indentLevel += 1;
                            materialEditor.ShaderProperty(CylinderFace, "圆柱体面朝向（Face）");
                            materialEditor.ShaderProperty(CylinderCenter, "圆柱体中心（Center）");
                            EditorGUI.indentLevel -= 1;
                        }
                        materialEditor.ShaderProperty(DissolveTexAR, "R通道为遮罩通道");
                        GUILayout.Space(3);
                        EditorGUILayout.EndVertical();
                        GUILayout.Space(3);
                    }

                    materialEditor.ShaderProperty(DissolveTexUSpeed, "U 方向流动");
                    materialEditor.ShaderProperty(DissolveTexVSpeed, "V 方向流动");
                    GUILayout.Space(5);

                    materialEditor.ShaderProperty(CustomDissolveTex, new GUIContent("粒子自定义数据（溶解程度）","使用粒子的Custom1.z控制溶解程度（使用先添加uv2，再添加Custom1.xyzw，再添加Custom2.xyzw）"));
                    if (material.GetFloat("_CustomDissolveTex") == 0) 
                    {
                        materialEditor.ShaderProperty(DissolveIntensity, "溶解程度（Intensity）");
                    }
                    
                    GUILayout.Space(5);
                    materialEditor.ShaderProperty(DissolveTexSoft, "使用软溶解");
                    if (material.GetFloat("_DissolveTexSoft") == 1) 
                    {
                        materialEditor.ShaderProperty(DissolveSoft, "软化程度（Soft）");
                    }
                    else
                    {
                        materialEditor.ShaderProperty(DissolveWide, "溶解宽度（Wide）");
                    }
                    GUILayout.Space(5);
                    
                    materialEditor.ShaderProperty(DissolveWideUseColor, "溶解宽度使用源颜色");
                    if (material.GetFloat("_DissolveWideUseColor") == 1) 
                    {
                        materialEditor.ShaderProperty(DissolveWideSaturation, "溶解宽度源颜色饱和度");
                    }
                    GUILayout.Space(5);

                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }
    }
    
    // 扭曲图
    void DistortFoldoutShow()
    {
        bool bFDistortTex = material.GetFloat("_FDistortTex") == 1;
        SetKeyword(material, "_FDISTORTTEX_ON", bFDistortTex);
        if (bFDistortTex) 
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            _Distort_Foldout = Foldout(_Distort_Foldout, "UV扭曲（Distort）");

            if (_Distort_Foldout)
            {
                EditorGUI.indentLevel++;
        
                materialEditor.TexturePropertySingleLine(new GUIContent("扭曲图（DistortTex）"), DistortTex);
                GUILayout.Space(5);

                if (DistortTex.textureValue != null)
                {
                    using (new EditorGUI.IndentLevelScope())
                    {
                        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                        GUILayout.Space(3);
                        materialEditor.TextureScaleOffsetProperty(DistortTex);
                        materialEditor.ShaderProperty(DistortTexAR, new GUIContent("R通道为扭曲通道","这个建议用黑白图，用R通道做扭曲，要是非得偷懒用张RGBA的我也没有办法"));
                        GUILayout.Space(3);
                        EditorGUILayout.EndVertical();
                        GUILayout.Space(3);
                    }

                    materialEditor.ShaderProperty(DistortTexUSpeed, "U 方向流动");
                    materialEditor.ShaderProperty(DistortTexVSpeed, "V 方向流动");
                    GUILayout.Space(3);
                    
                    materialEditor.ShaderProperty(CustomDistortTex, new GUIContent("粒子自定义数据（扭曲程度）","使用粒子的Custom1.w控制扭曲程度（使用先添加uv2，再添加Custom1.xyzw，再添加Custom2.xyzw）"));
                    if (material.GetFloat("_CustomDistortTex") == 0)
                    {
                        materialEditor.ShaderProperty(DistortIntensity, "扭曲程度（Intensity）");
                    }    
                    GUILayout.Space(5);
                    
                    using (new EditorGUI.IndentLevelScope())
                    {
                        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                        GUILayout.Space(3);
                        materialEditor.ShaderProperty(DistortMainTex, "影响主贴图（MainTex）");
                        if (material.GetFloat("_FMaskTex") == 1)
                        {
                            materialEditor.ShaderProperty(DistortMaskTex, "影响遮罩贴图（MaskTex）");
                        }                        
                        if (material.GetFloat("_FDissolveTex") == 1)
                        {
                            materialEditor.ShaderProperty(DistortDissolveTex, "影响溶解贴图（DissolveTex）");
                        }
                        GUILayout.Space(3);
                        EditorGUILayout.EndVertical();
                        GUILayout.Space(5);
                    }
                    
                    GUILayout.Space(5);
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }
    }
    
    // 菲涅尔
    void FresnelFoldoutShow()
    {
        bool bFFresnel = material.GetFloat("_FFresnel") == 1;
        SetKeyword(material, "_FFRESNEL_ON", bFFresnel);
        if (bFFresnel) 
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            _Fresnel_Foldout = Foldout(_Fresnel_Foldout, "菲涅尔（Fresnel）");

            if (_Fresnel_Foldout)
            {
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(FresnelBlendStyle, new GUIContent("菲涅尔颜色混合方式","菲涅尔颜色与主贴图的颜色混合方式，Normal是互不影响lerp的混合方式，Multiply是菲涅尔颜色与主贴图正片叠底，Add就是与主贴图叠加，None就是没有菲涅尔颜色（配合Alpha用）"));
                materialEditor.ShaderProperty(FresnelAlphaBlendStyle, new GUIContent("菲涅尔透明度混合方式","菲涅尔与Alpha混合方式，Normal是直接使用菲涅尔当Alpha值，Reverse是反相，None是不使用菲涅尔与Alpha相乘直接输出Alpha"));
                GUILayout.Space(5);

                materialEditor.ShaderProperty(FresnelMulVertexColor, new GUIContent("使用粒子颜色（VertexColor）","粒子颜色与菲涅尔颜色相乘"));
                materialEditor.ShaderProperty(FresnelHard, "使用硬菲涅尔（Step）");
                materialEditor.ShaderProperty(FresnelReverse, "反向菲涅尔（1-）");
                GUILayout.Space(5);

                materialEditor.ShaderProperty(FresnelColor, "菲涅尔颜色（Color）");
                materialEditor.ShaderProperty(FresnelScale, "菲涅尔强度（Scale）");
                materialEditor.ShaderProperty(FresnelPower, "菲涅尔锐化（Power）");
                GUILayout.Space(5);
                
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }
    }
    
    // 顶点偏移
    void VertexFoldoutShow()
    {
        bool bFVertexOffsetTex = material.GetFloat("_FVertexOffsetTex") == 1;
        SetKeyword(material, "_FVERTEXOFFSETTEX_ON", bFVertexOffsetTex);
        if (bFVertexOffsetTex) 
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            _Vertex_Foldout = Foldout(_Vertex_Foldout, "顶点偏移（VertexOffset）");

            if (_Vertex_Foldout)
            {
                EditorGUI.indentLevel++;
        
                materialEditor.TexturePropertySingleLine(new GUIContent("顶点偏移图（VertexOffsetTex）"), VertexOffsetTex);
                GUILayout.Space(5);

                if (VertexOffsetTex.textureValue != null)
                {
                    using (new EditorGUI.IndentLevelScope())
                    {
                        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                        GUILayout.Space(3);
                        materialEditor.TextureScaleOffsetProperty(VertexOffsetTex);
                        GUILayout.Space(3);
                        EditorGUILayout.EndVertical();
                        GUILayout.Space(3);
                    }

                    materialEditor.ShaderProperty(VertexOffsetTexUSpeed, "U 方向流动");
                    materialEditor.ShaderProperty(VertexOffsetTexVSpeed, "V 方向流动");
                    GUILayout.Space(5);
                }
                
                materialEditor.ShaderProperty(CustomVertexOffsetTex, new GUIContent("粒子自定义数据（顶点偏移强度）","使用粒子的Custom2.x控制溶解程度（使用先添加uv2，再添加Custom1.xyzw，再添加Custom2.xyzw）"));
                if (material.GetFloat("_CustomVertexOffsetTex") == 0) 
                {
                    materialEditor.ShaderProperty(VertexOffsetStrength, "顶点偏移强度（Strength）");
                }
                GUILayout.Space(5);
                
                materialEditor.ShaderProperty(VertexOffsetXYZSpeed, new GUIContent("顶点整体平移（XYZ为方向，W为波动范围）","是个顶点动画的Sin波"));
                GUILayout.Space(5);
                
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }
    }
    
    // 渲染设置
    void RenderFoldoutShow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        _Render_Foldout = Foldout(_Render_Foldout, "全局设置");

        if (_Render_Foldout)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            GUILayout.Space(5);

            // 混合模式
            string[] blendeModeNames = System.Enum.GetNames(typeof(EnumBlendMode));
            BlendMode.floatValue = EditorGUILayout.Popup("混合模式（Blend Mode）", (int) BlendMode.floatValue, blendeModeNames);
            int value = (int) BlendMode.floatValue;
            switch (value)
            {
                case 0:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    break;
                case 1:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    break;
                case 2:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    break;
                case 3:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.One);
                    break;
                case 4:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusDstColor);
                    material.SetInt("_Dstend", (int) UnityEngine.Rendering.BlendMode.One);
                    break;
                case 5:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.DstColor);
                    material.SetInt("_Dstend", (int) UnityEngine.Rendering.BlendMode.Zero);
                    break;
                case 6:
                    material.SetInt("_BlendOp", (int) UnityEngine.Rendering.BlendOp.Add);
                    material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.DstColor);
                    material.SetInt("_Dstend", (int) UnityEngine.Rendering.BlendMode.SrcColor);
                    break;
                case 7:
                    break;
            }

            if (value == 7)
            {
                EditorGUI.indentLevel += 1;
                materialEditor.ShaderProperty(BlendOp, "混合操作符（BlendOp）");
                materialEditor.ShaderProperty(SrcBlend, "源因子（SrcBlend）");
                materialEditor.ShaderProperty(DstBlend, "目标因子（DstBlend）");
                EditorGUI.indentLevel -= 1;
            }
            GUILayout.Space(3);

            // 剔除模式
            string[] cullModeNames = System.Enum.GetNames(typeof(EnumCullMode));
            CullMode.floatValue =
                EditorGUILayout.Popup("剔除模式（Cull Mode）", (int) CullMode.floatValue, cullModeNames);
            GUILayout.Space(3);

            // 深度写入
            materialEditor.ShaderProperty(ColorMask, "颜色遮罩（Color Mask）");
            GUILayout.Space(5);
            EditorGUILayout.EndVertical();

            // 深度测试 & 深度写入 & 模板测试
            {
                GUILayout.Space(5);
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                GUILayout.Space(5);

                // 深度写入
                materialEditor.ShaderProperty(ZWriteMode, "深度写入（ZWrite Mode）");
                GUILayout.Space(3);

                // 深度写入
                materialEditor.ShaderProperty(ZTestMode,
                    new GUIContent("深度测试（ZWrite Test）", "把特效显示再最前面选Alway，默认LessEqual"));
                GUILayout.Space(3);

                // 模板测试
                materialEditor.ShaderProperty(StencilToggle, "模板测试（Stencil）");
                if (material.GetFloat("_StencilToggle") == 1)
                {
                    EditorGUI.indentLevel += 1;
                    EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                    materialEditor.ShaderProperty(Stencil, new GUIContent("Stencil ID", "当前材质的的参考值，默认0"));
                    materialEditor.ShaderProperty(StencilWriteMask,
                        new GUIContent("Stencil Write Mask", "GPU 在执行模板测试时使用此值作为遮罩， 默认255"));
                    materialEditor.ShaderProperty(StencilReadMask,
                        new GUIContent("Stencil Read Mask", "GPU 在写入模板缓冲区时使用此值作为遮罩， 默认255"));
                    materialEditor.ShaderProperty(StencilComp,
                        new GUIContent("Stencil Comparison", "GPU 为所有像素的模板测试执行的操作，默认Always"));
                    materialEditor.ShaderProperty(StencilPass,
                        new GUIContent("Stencil Pass", "当像素通过模板测试和深度测试时，GPU 对模板缓冲区执行的操作，默认Keep"));
                    materialEditor.ShaderProperty(StencilFail,
                        new GUIContent("Stencil Fail", "当像素未能通过模板测试时，GPU 对模板缓冲区执行的操作，默认Keep"));
                    materialEditor.ShaderProperty(StencilZFail,
                        new GUIContent("Stencil ZFail", "当像素通过模板测试，但是未能通过深度测试时，GPU 对模板缓冲区执行的操作，默认Keep"));
                    EditorGUILayout.EndVertical();
                    GUILayout.Space(5);
                    EditorGUI.indentLevel -= 1;
                }
                else
                {
                    material.SetInt("_Stencil", (int) 0);
                    material.SetInt("_StencilReadMask", (int) 255);
                    material.SetInt("_StencilWriteMask", (int) 255);
                    material.SetInt("_StencilComp", (int) 8);
                    material.SetInt("_StencilPass", (int) 0);
                    material.SetInt("_StencilFail", (int) 0);
                    material.SetInt("_StencilZFail", (int) 0);
                }
                
                GUILayout.Space(5);
                EditorGUILayout.EndVertical();
            }
            
            // 透明度相关
            {
                GUILayout.Space(5);
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                GUILayout.Space(5);
                
                // 预乘Alpha
                materialEditor.ShaderProperty(PreMulAlpha, new GUIContent("透明度预乘（PreMulAlpha）", "把RGB通道和A通道再相乘一次"));
                GUILayout.Space(3);

                // AlphaCut
                materialEditor.ShaderProperty(AlphaGamma, new GUIContent("透明度伽马矫正（AlphaGamma）", "Unity中贴图的Alpha通道无论勾不勾选sRGB都是线性的，与Photoshop中的半透明是不一样的，勾选后即可相同，线性值为1.0，伽马值为2.2"));
                if (material.GetFloat("_AlphaGamma") == 1)
                {
                    EditorGUI.indentLevel += 1;
                    materialEditor.ShaderProperty(CustomAlphaGamma, new GUIContent("自定义伽马值（Power）", "Alpha的指数乘方，线性>伽马=pow(a,2.2)，伽马>线性=pow(a,(1/2.2)"));
                    EditorGUI.indentLevel -= 1;
                }
                GUILayout.Space(3);
                
                // AlphaCut
                materialEditor.ShaderProperty(AlphaCut, "透明度裁剪（AlphaCut）");
                if (material.GetFloat("_AlphaCut") == 1)
                {
                    EditorGUI.indentLevel += 1;
                    //materialEditor.ShaderProperty(Cutoff, Cutoff.displayName);
                    materialEditor.ShaderProperty(Cutoff, "裁剪阈值（Cutoff）");
                    EditorGUI.indentLevel -= 1;
                }
                GUILayout.Space(3);

                // 软粒子
                materialEditor.ShaderProperty(SoftParticles, "软粒子（SoftParticle）");
                if (material.GetFloat("_SoftParticles") == 1)
                {
                    EditorGUI.indentLevel += 1;
                    materialEditor.ShaderProperty(SoftFade, "褪色（Fade）");
                    EditorGUI.indentLevel -= 1;
                }
                GUILayout.Space(3);
                
                // 全局透明度
                materialEditor.ShaderProperty(Transparent, "全局透明度（Alpha）");                

                GUILayout.Space(5);
                EditorGUILayout.EndVertical();
            }
            
            // 检索所有属性
            GUILayout.Space(5);     
            GUI_Common(material);

            EditorGUI.indentLevel--;
        }
        
        EditorGUILayout.EndVertical();
    }
    #endregion

    #region [自定义通用方法]
    // 设置宏方法
    static void SetKeyword(Material material, string keyword, bool state)
    {
        if (state)
            material.EnableKeyword(keyword);
        else
            material.DisableKeyword(keyword);
    }
    
    // 检索默认编辑器属性（渲染队列，GPU合批，双面GUI）
    void GUI_Common(Material material)
    {
        EditorGUI.BeginChangeCheck();
        {
            MaterialProperty[] props = { };
            base.OnGUI(materialEditor, props);
        }
        //materialEditor.RenderQueueField();
        //materialEditor.EnableInstancingField();
        //materialEditor.DoubleSidedGIField();
    }
    #endregion

    #region [更新备注]
    /*
    修改日期：20220713，增加软粒子
    修改日期：20220718，增加三种UV选择
    修改日期：20220726，增加溶解描边饱和度、额外的贴图作扫光
    */
    #endregion
}
