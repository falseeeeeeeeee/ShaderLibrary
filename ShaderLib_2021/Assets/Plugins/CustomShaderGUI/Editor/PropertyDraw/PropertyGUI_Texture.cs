using UnityEditor;
using UnityEngine;

//该脚本用于纹理的绘制
namespace Scarecrow
{
    public class TexDrawer : MaterialPropertyDrawer
    {
        //额外属性名字
        private string _addProName;
        //该控件会在以下选项中显示
        private string[] _showList = new string[0];
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;
        //是否总是显示
        private bool _isAlwaysShow = true;


        //addProName    要在纹理后面绘制属性的名字
        //填写任意数量的选项，当其中一个选项被选中时，该控件会被渲染
        public TexDrawer() : this("") { }
        public TexDrawer(string addProName, params string[] showList)
        {
            _addProName = addProName;
            _showList = showList;
            _isAlwaysShow = showList == null || showList.Length == 0;
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            if (_simpleShaderGUI == null)
                return base.GetPropertyHeight(prop, label, editor);
            //检查属性是否要被绘制
            if (!(_isAlwaysShow || _simpleShaderGUI.GetShowState(_showList)))
                return -2f;

            //是否绘制额外属性
            MaterialProperty addPro = _simpleShaderGUI.FindProperty(_addProName);
            if (addPro != null)
                return -1.5f;
            else
                return base.GetPropertyHeight(prop, label, editor);
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            //检查
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            if (_simpleShaderGUI == null)
            {
                GUILayout.Label(prop.displayName + " :   Please use SimpleShaderGUI in your shader");
                return;
            }
            if (prop.type != MaterialProperty.PropType.Texture)
            {
                GUILayout.Label(prop.displayName + " :   Property must be of type texture");
                return;
            }

            //检查属性是否要被绘制
            if (!(_isAlwaysShow || _simpleShaderGUI.GetShowState(_showList)))
                return;

            //获取额外属性
            MaterialProperty addPro = _simpleShaderGUI.FindProperty(_addProName);
            if (addPro != null)
            {
                float labelWidth = EditorGUIUtility.labelWidth;
                EditorGUIUtility.labelWidth = labelWidth + 2f;//对齐
                //在颜色纹理后绘制额外属性
                editor.TexturePropertySingleLine(label, prop, addPro);
                EditorGUIUtility.labelWidth = labelWidth;
            }
            else
            {
                //绘制单行纹理
                editor.TexturePropertyMiniThumbnail(position, prop, label.text, "");
            }

            //在纹理后面绘制纹理缩放控件
            if (prop.flags != MaterialProperty.PropFlags.NoScaleOffset)
            {
                EditorGUI.indentLevel++;
                EditorGUI.showMixedValue = prop.hasMixedValue;
                editor.TextureScaleOffsetProperty(prop);
                EditorGUI.showMixedValue = false;
                EditorGUI.indentLevel--;
            }
        }
    }
}
