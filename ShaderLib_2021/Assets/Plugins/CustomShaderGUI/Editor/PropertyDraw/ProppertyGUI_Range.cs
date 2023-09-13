using UnityEditor;
using UnityEngine;

namespace Scarecrow
{
    public class RangeDrawer : MaterialPropertyDrawer
    {
        //该控件会在以下选项中显示
        private string[] _showList = new string[0];
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;
        //是否总是显示
        private bool _isAlwaysShow = true;

        public RangeDrawer()
        {
            _isAlwaysShow = true;
        }
        public RangeDrawer(params string[] showList)
        {
            _showList = showList;
            _isAlwaysShow = showList == null || showList.Length == 0;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            //检查属性是否要被绘制
            if (!(_isAlwaysShow || _simpleShaderGUI.GetShowState(_showList)))
                return -2f;

            return base.GetPropertyHeight(prop, label, editor);
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
            if (prop.type != MaterialProperty.PropType.Vector)
            {
                GUILayout.Label(prop.displayName + " :   Property must be of type vector");
                return;
            }

            //检查属性是否要被绘制
            if (!(_isAlwaysShow || _simpleShaderGUI.GetShowState(_showList)))
                return;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;

            Vector4 value = prop.vectorValue;
            //修正范围
            if (value.z == value.w)
                value += new Vector4(0, 0, 0, 0.1f);
            if (value.z > value.w)
            {
                float tem = value.z;
                value.z = value.w;
                value.w = value.z;
            }
            if (value.x > value.y)
            {
                float tem = value.x;
                value.x = value.y;
                value.y = value.x;
            }
            value.x = Mathf.Max(value.x, value.z);
            value.y = Mathf.Min(value.y, value.w);


            //滑动条
            Rect rangeRect = new Rect(position)
            {
                width = position.width - 110
            };

            //绘制最小属性
            Rect minRect = new Rect(position)
            {
                x = position.xMax - 105f,
                width = 50,
            };
            //绘制最大属性
            Rect maxRect = new Rect(position)
            {
                x = position.xMax - 50f,
                width = 50,
            };


            EditorGUI.MinMaxSlider(rangeRect, label, ref value.x, ref value.y, value.z, value.w);
            //绘制后面字符框，还原缩进等级
            int indentLevel = EditorGUI.indentLevel;
            EditorGUI.indentLevel = 0;
            value.x = EditorGUI.FloatField(minRect, value.x);
            value.y = EditorGUI.FloatField(maxRect,value.y);
            EditorGUI.indentLevel = indentLevel;

            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                prop.vectorValue = value;
            }
        }
    }
}