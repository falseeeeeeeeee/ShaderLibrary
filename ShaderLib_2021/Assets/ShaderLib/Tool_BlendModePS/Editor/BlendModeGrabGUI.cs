using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class BlendModeGrabGUI : ShaderGUI
{
    // OnGuI 接收的两个参数
    MaterialEditor materialEditor;       //当前材质面板
    MaterialProperty[] materialProperty; //当前shader的properties
    Material targetMat;                  //绘制对象材质球

    //private Material mat;

    #region 混合枚举
    enum BlendModeCategory
    {
        一般_Normal = 0,
        变暗_Darken = 1,
        变亮_Lighten = 2,
        对比_Contrast = 3,
        反转_Inversion = 4,
        合成_Component = 5,
    }

    enum NormalBlendMode
    {
        正常_Normal = 0,
        透明混合_Alphablend = 1,
    }
    enum DarkenBlendMode
    {
        变暗_Darken = 2,
        正片叠底_Multiply = 3,
        颜色加深_ColorBurn = 4,
        线性加深_LinearBurn = 5,
        深色_DarkerColor = 6,
    }

    enum LightenBlendMode
    {
        变亮_Lighten = 7,
        滤色_Screen = 8,
        颜色减淡_ColorDodge = 9,
        线性减淡_LinearDodge = 10,
        浅色_LighterColor = 11,
    }

    enum ContrastBlendMode
    {
        叠加_Overlay = 12,
        柔光_SoftLight = 13,
        强光_HardLight = 14,
        亮光_VividLight = 15,
        线性光_LinearLight = 16,
        点光_PinLight = 17,
        实色混合_HardMix = 18,
    }

    enum InversionBlendMode
    {
        差值_Difference = 19,
        排除_Exclusion = 20,
        减去_Subtract = 21,
        划分_Divide = 22,
    }

    enum ComponentBlendMode
    {
        色相_Hue = 23,
        饱和度_Saturation = 24,
        颜色_Color = 25,
        明度_Luminosity = 26,
    }

    enum BlendModeChoose
    {
        正常_Normal,
        透明混合_Alphablend,
        变暗_Darken,
        正片叠底_Multiply,
        颜色加深_ColorBurn,
        线性加深_LinearBurn,
        深色_DarkerColor,
        变亮_Lighten,
        滤色_Screen,
        颜色减淡_ColorDodge,
        线性减淡_LinearDodge,
        浅色_LighterColor,
        叠加_Overlay,
        柔光_SoftLight,
        强光_HardLight,
        亮光_VividLight,
        线性光_LinearLight,
        点光_PinLight,
        实色混合_HardMix,
        差值_Difference,
        排除_Exclusion,
        减去_Subtract,
        划分_Divide,
        色相_Hue,
        饱和度_Saturation,
        颜色_Color,
        明度_Luminosity
    }

    #endregion

    #region 属性声明

    string[] MateritalChoosenames = System.Enum.GetNames(typeof(BlendModeChoose));
    string[] NormalModeChoosenames = System.Enum.GetNames(typeof(NormalBlendMode));
    string[] DarkenModeChoosenames = System.Enum.GetNames(typeof(DarkenBlendMode));
    string[] LightenModeChoosenames = System.Enum.GetNames(typeof(LightenBlendMode));
    string[] ContrastModeChoosenames = System.Enum.GetNames(typeof(ContrastBlendMode));
    string[] InversionModeChoosenames = System.Enum.GetNames(typeof(InversionBlendMode));
    string[] ComponentModeChoosenames = System.Enum.GetNames(typeof(ComponentBlendMode));
    string[] BlendCategoryChoosenames = System.Enum.GetNames(typeof(BlendModeCategory));

    private float choice = 0f;

    #endregion

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.materialEditor = materialEditor;               // 当前编辑器
        this.materialProperty = properties;                 // 用到的变量
        this.targetMat = materialEditor.target as Material; // 当前材质球

        #region Shader属性

        MaterialProperty _BaseColor = FindProperty("_BaseColor", properties);
        MaterialProperty _BaseMap = FindProperty("_BaseMap", properties);
        MaterialProperty _MixColor = FindProperty("_MixColor", properties);
        MaterialProperty _MixMap = FindProperty("_MixMap", properties);

        MaterialProperty ModeID = FindProperty("_ModeID", properties);
        MaterialProperty ModeChooseProps = FindProperty("_IDChoose", properties);
        MaterialProperty CategoryChooseProps = FindProperty("_BlendCategoryChoose", properties);

        MaterialProperty _StyleChoose = FindProperty("_StyleChoose", materialProperty);
        MaterialProperty _EnableCameraTex = FindProperty("_EnableCameraTex", materialProperty);

        GUIContent StyleChoose = new GUIContent("单双列显示模式切换");
        GUIContent EnableCameraTex = new GUIContent("是否使用相机背景");

        #endregion

        #region 列表枚举
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        EditorGUILayout.Space(10);

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = _StyleChoose.hasMixedValue;
        EditorGUI.showMixedValue = false;

        var _STYLECHOOSE_ON = EditorGUILayout.Toggle(StyleChoose, _StyleChoose.floatValue == 1);
        if (EditorGUI.EndChangeCheck()) _StyleChoose.floatValue = _STYLECHOOSE_ON ? 1 : 0;  

        //打开开关之后的效果
        if (_StyleChoose.floatValue == 1)
        {
            ModeChooseProps.floatValue = EditorGUILayout.Popup("选择类型", (int)ModeChooseProps.floatValue, MateritalChoosenames);
            choice = ModeChooseProps.floatValue;
        }
        else
        {
            
            //选择混合范畴
            CategoryChooseProps.floatValue = EditorGUILayout.Popup("选择类型", (int)CategoryChooseProps.floatValue, BlendCategoryChoosenames);

            EditorGUI.indentLevel++;
            //选择范畴后选择具体混合模式
            switch (CategoryChooseProps.floatValue)
            {
                case (float)BlendModeCategory.一般_Normal:
                    ModeChooseProps.floatValue = EditorGUILayout.Popup("NormalBlendMode", (int)ModeChooseProps.floatValue, NormalModeChoosenames);
                    choice = ModeChooseProps.floatValue;
                    break;
                case (float)BlendModeCategory.变暗_Darken:
                    ModeChooseProps.floatValue = EditorGUILayout.Popup("DarkenBlendMode", (int)ModeChooseProps.floatValue, DarkenModeChoosenames);
                    choice = ModeChooseProps.floatValue;
                    choice += 2; 
                    break;
                case (float)BlendModeCategory.变亮_Lighten:
                    ModeChooseProps.floatValue = EditorGUILayout.Popup("LightenBlendMode", (int)ModeChooseProps.floatValue, LightenModeChoosenames);
                    choice = ModeChooseProps.floatValue;
                    choice += 7;
                    break;
                case (float)BlendModeCategory.对比_Contrast:
                    ModeChooseProps.floatValue = EditorGUILayout.Popup("ContrastBlendMode", (int)ModeChooseProps.floatValue, ContrastModeChoosenames);
                    choice = ModeChooseProps.floatValue;
                    choice += 12;
                    break;
                case (float)BlendModeCategory.反转_Inversion:
                    ModeChooseProps.floatValue = EditorGUILayout.Popup("InversionBlendMode", (int)ModeChooseProps.floatValue, InversionModeChoosenames);
                    choice = ModeChooseProps.floatValue;
                    choice += 19;
                    break;
                case (float)BlendModeCategory.合成_Component:
                    ModeChooseProps.floatValue = EditorGUILayout.Popup("ComponentBlendMode", (int)ModeChooseProps.floatValue, ComponentModeChoosenames);
                    choice = ModeChooseProps.floatValue;
                    choice += 23;
                    break;
            }

            EditorGUI.indentLevel--;
        }
        #endregion

        switch (choice)
        {
            case 0:
                ModeID.floatValue = 0;
                break;
            case 1:
                ModeID.floatValue = 1;
                break;
            case 2:
                ModeID.floatValue = 2;
                break;
            case 3:
                ModeID.floatValue = 3;
                break;
            case 4:
                ModeID.floatValue = 4;
                break;
            case 5:
                ModeID.floatValue = 5;
                break;
            case 6:
                ModeID.floatValue = 6;
                break;
            case 7:
                ModeID.floatValue = 7;
                break;
            case 8:
                ModeID.floatValue = 8;
                break;
            case 9:
                ModeID.floatValue = 9;
                break;
            case 10:
                ModeID.floatValue = 10;
                break;
            case 11:
                ModeID.floatValue = 11;
                break;
            case 12:
                ModeID.floatValue = 12;
                break;
            case 13:
                ModeID.floatValue = 13;
                break;
            case 14:
                ModeID.floatValue = 14;
                break;
            case 15:
                ModeID.floatValue = 15;
                break;
            case 16:
                ModeID.floatValue = 16;
                break;
            case 17:
                ModeID.floatValue = 17;
                break;
            case 18:
                ModeID.floatValue = 18;
                break;
            case 19:
                ModeID.floatValue = 19;
                break;
            case 20:
                ModeID.floatValue = 20;
                break;
            case 21:
                ModeID.floatValue = 21;
                break;
            case 22:
                ModeID.floatValue = 22;
                break;
            case 23:
                ModeID.floatValue = 23;
                break;
            case 24:
                ModeID.floatValue = 24;
                break;
            case 25:
                ModeID.floatValue = 25;
                break;
            case 26:
                ModeID.floatValue = 26;
                break;
        }

        EditorGUILayout.Space(10);
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(30);

        #region 颜色图片GUI
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        EditorGUILayout.Space(10);
        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = _EnableCameraTex.hasMixedValue;
        EditorGUI.showMixedValue = false;

        var _ENABLECAMERATEX_ON = EditorGUILayout.Toggle(EnableCameraTex, _EnableCameraTex.floatValue == 1);
        if (EditorGUI.EndChangeCheck()) _EnableCameraTex.floatValue = _ENABLECAMERATEX_ON ? 1 : 0;

        //打开开关之后的效果
        if (_EnableCameraTex.floatValue == 1)
        {
            targetMat.EnableKeyword("_ENABLECAMERATEX_ON");
            EditorGUI.indentLevel++;
            GUILayout.Label("正在使用相机背景");
            EditorGUI.indentLevel--;
        }
        else
        {
            targetMat.DisableKeyword("_ENABLECAMERATEX_ON");
            materialEditor.ColorProperty(_BaseColor, "背景颜色");
            materialEditor.TextureProperty(_BaseMap, "背景贴图");
        }

        materialEditor.ColorProperty(_MixColor, "混合颜色");
        materialEditor.TextureProperty(_MixMap, "混合贴图");

        EditorGUILayout.Space(10);
        EditorGUILayout.EndVertical();

        // Render Queue
        EditorGUILayout.Space(20);

        materialEditor.RenderQueueField();
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
        #endregion
    }
}