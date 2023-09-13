using UnityEditor;
using UnityEngine;

//该脚本主要是针对控件切换的处理
namespace Scarecrow
{
    //切换按钮 控制显示
    public class Toggle_SwitchDrawer : MaterialPropertyDrawer
    {
        //该Toggle是否勾选
        private bool _enbale = true;
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;

        public override void Apply(MaterialProperty prop)
        {
            base.Apply(prop);

            //初始化关键字,并设置列表
            if (prop.type == MaterialProperty.PropType.Float)
            {
                _enbale = (int)prop.floatValue == 0 ? false : true;
                SetToggleKeyword(prop, _enbale);
                SetToggleSwitch(prop, _enbale);
            }
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            //检查
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            if (_simpleShaderGUI == null)
            {
                GUILayout.Label(prop.displayName + " :   Please use SimpleShaderGUI in your shader");
                return;
            }
            if (prop.type != MaterialProperty.PropType.Float)
            {
                GUILayout.Label(prop.displayName + " :   Property must be of type float");
                return;
            }


            EditorGUI.showMixedValue = prop.hasMixedValue;
            EditorGUI.BeginChangeCheck();
            _enbale = EditorGUI.Toggle(position, label, (int)prop.floatValue == 0 ? false : true);
            if (EditorGUI.EndChangeCheck())
            {
                prop.floatValue = _enbale ? 1 : 0;
                SetToggleKeyword(prop, _enbale);
            }
            EditorGUI.showMixedValue = false;

            if (!prop.hasMixedValue)
                SetToggleKeyword(prop, _enbale);
            SetToggleSwitch(prop, _enbale);
        }

        //设置Toggle 关键字
        private void SetToggleKeyword(MaterialProperty pro, bool enable)
        {
            //设置Keyword
            string keyword = pro.name.ToUpperInvariant() + "_ON";
            foreach (Material m in pro.targets)
            {
                if (enable)
                    m.EnableKeyword(keyword);
                else
                    m.DisableKeyword(keyword);
            }
        }

        //设置switch列表
        private void SetToggleSwitch(MaterialProperty pro, bool enable)
        {
            if (_simpleShaderGUI == null)
                return;

            if (enable)
            {
                if (!_simpleShaderGUI.SwitchList.Contains(pro.name))
                    _simpleShaderGUI.SwitchList.Add(pro.name);
            }
            else
            {
                _simpleShaderGUI.SwitchList.Remove(pro.name);
            }
        }
    }
    //菜单按钮控制显示
    public class Enum_SwitchDrawer : MaterialPropertyDrawer
    {
        //菜单栏列表
        private string[] _enumList = new string[0];
        //菜单栏数值
        private int[] _enumValue = new int[0];
        //当前选择的选项
        private int _optionIndex;
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;

        public Enum_SwitchDrawer(params string[] enumList)
        {
            _enumList = enumList;
            _enumValue = new int[_enumList.Length];
            for (int i = 0; i < _enumValue.Length; i++)
                _enumValue[i] = i;
        }

        public override void Apply(MaterialProperty prop)
        {
            base.Apply(prop);

            //初始化关键字,并设置列表
            if (prop.type == MaterialProperty.PropType.Float)
            {
                ApplyEnumData(prop);
                SetEnumKeyword(prop);
                SetEnumSwitch(prop);
            }
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            //检查
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            if (_simpleShaderGUI == null)
            {
                GUILayout.Label(prop.displayName + " :   Please use SimpleShaderGUI in your shader");
                return;
            }
            if (prop.type != MaterialProperty.PropType.Float)
            {
                GUILayout.Label(prop.displayName + " :   Property must be of type float");
                return;
            }

            ApplyEnumData(prop);

            EditorGUI.showMixedValue = prop.hasMixedValue;
            EditorGUI.BeginChangeCheck();
            _optionIndex = EditorGUI.IntPopup(position, label, _optionIndex, _enumList, _enumValue);
            if (EditorGUI.EndChangeCheck())
            {
                prop.floatValue = _optionIndex;
                SetEnumKeyword(prop);
            }
            EditorGUI.showMixedValue = false;

            if (!prop.hasMixedValue)
                SetEnumKeyword(prop);
            SetEnumSwitch(prop);
        }


        //初始化枚举数据
        private void ApplyEnumData(MaterialProperty prop)
        {
            int index = (int)prop.floatValue;
            index = Mathf.Clamp(index, 0, _enumList.Length - 1);
            // prop.floatValue = index;
            _optionIndex = index;
        }

        //设置菜单栏的关键字
        private void SetEnumKeyword(MaterialProperty pro)
        {
            //设置Keyword
            foreach (Material m in pro.targets)
            {
                foreach (string options in _enumList)
                {
                    string keyword = (pro.name + "_" + options).ToUpperInvariant();
                    if (options == _enumList[_optionIndex])
                        m.EnableKeyword(keyword);
                    else
                        m.DisableKeyword(keyword);
                }
            }
        }

        //设置switch列表
        private void SetEnumSwitch(MaterialProperty pro)
        {
            if (_simpleShaderGUI == null)
                return;

            foreach (string options in _enumList)
            {
                if (options == _enumList[_optionIndex])
                {
                    if (!_simpleShaderGUI.SwitchList.Contains(options))
                        _simpleShaderGUI.SwitchList.Add(options);
                }
                else
                {
                    _simpleShaderGUI.SwitchList.Remove(options);
                }
            }

        }
    }

    //控件显示控制
    public class SwitchDrawer : MaterialPropertyDrawer
    {
        //该控件会在以下选项中显示
        private string[] _showList = new string[0];
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;

        //填写任意数量的选项，当其中一个选项被选中时，该控件会被渲染
        public SwitchDrawer() { }
        public SwitchDrawer(params string[] showList)
        {
            _showList = showList;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return -1.5f;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            //检查
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            if (_simpleShaderGUI == null)
            {
                GUILayout.Label(prop.displayName + " :   Please use SimpleShaderGUI in your shader");
                return;
            }

            if (_simpleShaderGUI.GetShowState(_showList))
            {
                editor.DefaultShaderProperty(prop, label);
            }
        }
    }
}