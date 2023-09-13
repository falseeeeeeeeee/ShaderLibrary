using UnityEditor;
using UnityEngine;
using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace Scarecrow
{
    public class SimpleShaderGUI : ShaderGUI
    {
        //折叠页缩进等级
        public const int FoldoutIndent = 1;
        //折叠页标记，在折叠页属性 显示名字后面务必添加他，他将用来标识该属性为折叠页。其他属性务必不要添加
        public const string FoldoutSign = "_Foldout";


        //当前折叠等级，他将用来描述PropertyGUI绘制在那级折叠页中
        public int FoldoutLevel { get { return _foldoutLevel; } }
        //折叠页编辑等级
        public int FoldoutLevel_Editor { get { return _foldoutLevel_Editor; } }
        //折叠页状态, true展开, false折叠
        public bool FoldoutOpen { get { return _foldoutOpen; } }
        //折叠页中的属性是否可以被编辑
        public bool FoldoutEditor { get { return _foldoutEditor; } }

        //面板切换列表
        public List<string> SwitchList = new List<string>();



        //当前折叠等级，他将用来描述PropertyGUI绘制在那级折叠页中
        private int _foldoutLevel = 0;
        //折叠页编辑等级
        private int _foldoutLevel_Editor = 0;
        //折叠页状态, true展开, false折叠
        private bool _foldoutOpen = true;
        //折叠页中的属性是否可以被编辑
        private bool _foldoutEditor = true;
        //绘制的所有材质属性
        private MaterialProperty[] _allProperties;


        //混合模式的两个选项
        private MaterialProperty _SrcBlend;
        private MaterialProperty _DstBlend;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            InitializationData();//初始化数据
            _allProperties = properties;

            //绘制两个切换按钮
            _SrcBlend = FindProperty("_SrcBlend");
            _DstBlend = FindProperty("_DstBlend");
            TransparentSwitchButtonDraw();

            //依次绘制所有属性
            for (int i = 0; i < properties.Length; i++)
            {
                //如果该属性不是折叠页，则考虑是否禁用
                if (!IsFoldout(properties[i]))
                    EditorGUI.BeginDisabledGroup(!_foldoutEditor);

                //如果折叠页为展开状态，或该属性是折叠页则进行属性绘制
                if (_foldoutOpen || IsFoldout(properties[i]))
                {
                    if (properties[i].flags != MaterialProperty.PropFlags.HideInInspector)
                        materialEditor.ShaderProperty(properties[i], properties[i].displayName);
                }

                if (!IsFoldout(properties[i]))
                    EditorGUI.EndDisabledGroup();
            }

            //如果折叠页为展开状态，或该属性是折叠页则进行属性绘制
            if (_foldoutOpen)
            {
                EditorGUI.BeginDisabledGroup(!_foldoutEditor);
                //GPU实例化
                materialEditor.EnableInstancingField();
                materialEditor.EmissionEnabledProperty();

                //双面全局光照UI
                materialEditor.DoubleSidedGIField();
                //绘制调节队列的控件
                materialEditor.RenderQueueField();
                EditorGUI.EndDisabledGroup();
            }
        }


        //折叠页设置，
        //foldoutLevel  折叠页等级
        //foldoutState  折叠页展开状态， true展开  false折叠
        //foldoutEditor 折叠页中的属性是否可以编辑
        public void SetFoldout(int foldoutLevel, int foldoutLevel_Editor, bool foldoutState, bool foldoutEditor = true)
        {
            EditorGUI.indentLevel += (foldoutLevel - _foldoutLevel) * FoldoutIndent;
            _foldoutLevel = foldoutLevel;
            _foldoutLevel_Editor = foldoutLevel_Editor;
            _foldoutOpen = foldoutState;
            _foldoutEditor = foldoutEditor;
        }
        //判断是否显示该控件, 只有包含在SwitchList中才会显示
        public bool GetShowState(string[] showList)
        {
            foreach (string show in showList)
            {
                if (SwitchList.Contains(show))
                    return true;
            }

            return false;
        }

        //查找一个属性
        public MaterialProperty FindProperty(string name)
        {
            return ShaderGUI.FindProperty(name, _allProperties, false);
        }


        //判断该属性是否是折叠页
        public static bool IsFoldout(MaterialProperty property)
        {
            //通过正则表达式 匹配属性显示名字的末尾， 从而判断该属性是否是折叠页
            string pattern = FoldoutSign + @"\s*$";
            return Regex.IsMatch(property.displayName, pattern);
        }

        //获取折叠页显示名字，这将displayName通过正则表达式将_Foldout标记移除
        public static string GetFoldoutDisplayName(MaterialProperty property)
        {
            string pattern = FoldoutSign + @"\s*$";
            Regex reg = new Regex(pattern);
            return reg.Replace(property.displayName, "");
        }


        //初始化数据
        private void InitializationData()
        {
            _foldoutLevel = 0;
            _foldoutLevel_Editor = 0;
            _foldoutOpen = true;
            _foldoutEditor = true;
            EditorGUI.indentLevel = 0;
            SwitchList.Clear();
        }

        //绘制两个按钮(不透和半透)
        private void TransparentSwitchButtonDraw()
        {
            //没有找到属性直接返回
            if (_SrcBlend == null || _DstBlend == null)
                return;
            if (_SrcBlend.type != MaterialProperty.PropType.Float || _DstBlend.type != MaterialProperty.PropType.Float)
                return;

            //绘制两个切换Button
            EditorGUILayout.BeginHorizontal();

            if (GUILayout.Button("设置为不透明"))
            {
                _SrcBlend.floatValue = 1;
                _DstBlend.floatValue = 0;
                foreach (Material m in _SrcBlend.targets)
                {
                    m.renderQueue = 2000;
                }
            }

            if (GUILayout.Button("设置为不透明裁切"))
            {
                _SrcBlend.floatValue = 1;
                _DstBlend.floatValue = 0;
                foreach (Material m in _SrcBlend.targets)
                {
                    m.renderQueue = 2450;
                }
            }

            if (GUILayout.Button("设置为半透明"))
            {
                _SrcBlend.floatValue = 5;
                _DstBlend.floatValue = 10;
                foreach (Material m in _SrcBlend.targets)
                {
                    m.renderQueue = 3000;
                }
            }

            EditorGUILayout.EndHorizontal();
        }
    }
}
