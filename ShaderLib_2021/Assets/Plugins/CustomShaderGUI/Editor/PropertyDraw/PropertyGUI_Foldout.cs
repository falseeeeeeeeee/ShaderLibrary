using UnityEditor;
using UnityEngine;



//该脚本主要是对折叠页的处理
namespace Scarecrow
{
    //折叠页样式
    public enum FoldoutStyle
    {
        Big = 1,
        Median = 2,
        Small = 3
    }

    //折叠页绘制
    //思路来源于word中的标题，可以设置1级，2级标题进行层层嵌套
    public class FoldoutDrawer : MaterialPropertyDrawer
    {
        //折叠页等级
        private int _foldoutLevel = 1;
        //折叠页自身缩进大小
        private float _foldoutIndent = 15;
        //折叠页状态, true展开, false折叠
        private bool _foldoutOpen = true;
        //折叠页样式
        private FoldoutStyle _foldoutStyle = FoldoutStyle.Big;
        //是否绘制折叠页复选框
        private bool _foldoutToggleDraw = false;
        //折叠页内容是否可以被编辑
        private bool _foldoutEditor = true;
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;
        //材质属性
        private MaterialProperty _property;
        //该控件会在以下选项中显示
        private string[] _showList = new string[0];
        //是否总是显示
        private bool _isAlwaysShow = true;


        //foldoutLevel      折叠页等级，折叠页最低等级为1级(默认1级折叠页)
        //foldoutStyle      折叠页外观样式(默认第一种)，目前有3种 1 大折叠页样式， 2 中折叠页样式, 3 小折叠页样式
        //foldoutToggleDraw 折叠页 复选框是否绘制， 0 不绘制 , 1绘制 
        //foldoutOpen       折叠页初始展开状态，    0 折叠， 1展开
        //showList          填写任意数量的选项，当其中一个选项被选中时，该控件会被渲染
        public FoldoutDrawer() : this(1) { }
        public FoldoutDrawer(float foldoutLevel) : this(foldoutLevel, 1) { }
        public FoldoutDrawer(float foldoutLevel, float foldoutStyle) : this(foldoutLevel, foldoutStyle, 0) { }
        public FoldoutDrawer(float foldoutLevel, float foldoutStyle, float foldoutToggleDraw) : this(foldoutLevel, foldoutStyle, foldoutToggleDraw, 1) { }
        public FoldoutDrawer(float foldoutLevel, float foldoutStyle, float foldoutToggleDraw, float foldoutOpen, params string[] showList)
        {
            int level = (int)foldoutLevel;
            int style = (int)foldoutStyle;
            int toggleDraw = (int)foldoutToggleDraw;
            int open = (int)foldoutOpen;

            //设置折叠页等级
            _foldoutLevel = level < 1 ? 1 : level;

            //设置折叠页样式
            switch (style)
            {
                case 2: _foldoutStyle = FoldoutStyle.Median; break;
                case 3: _foldoutStyle = FoldoutStyle.Small; toggleDraw = 0; break;//如果样式是 小折叠页，则不进行复选框的绘制
                default: _foldoutStyle = FoldoutStyle.Big; break;
            }

            //是否绘制复选框
            _foldoutToggleDraw = toggleDraw == 0 ? false : true;

            //折叠页默认展开状态
            _foldoutOpen = open == 0 ? false : true;

            //设置显示列表
            _showList = showList;
            _isAlwaysShow = showList == null || showList.Length == 0;
        }
        public override void Apply(MaterialProperty prop)
        {
            base.Apply(prop);
            //设置初始KeyWorld
            if (prop.type == MaterialProperty.PropType.Float)
            {
                bool foldoutEditor = prop.floatValue != 0 ? true : false;
                SetFoldoutEditorKeyword(prop, foldoutEditor);
            }
        }

        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return -2;
        }
        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            //折叠页检查
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
            if (!SimpleShaderGUI.IsFoldout(prop))
            {
                GUILayout.Label(prop.displayName + " :   Please add " + SimpleShaderGUI.FoldoutSign + " after displayName");
                return;
            }


            //如果该折叠页属于上个折叠页的内容，并且上个折叠页是折叠状态，则该折叠页不显示
            if (_foldoutLevel > _simpleShaderGUI.FoldoutLevel && !_simpleShaderGUI.FoldoutOpen)
                return;

            //检查该折叠页是否要被绘制，
            if (!(_isAlwaysShow || _simpleShaderGUI.GetShowState(_showList)))
            {
                _simpleShaderGUI.SetFoldout(_foldoutLevel, _simpleShaderGUI.FoldoutLevel_Editor, false, _simpleShaderGUI.FoldoutEditor);
                return;
            }

            //折叠页复选框状态， 非0勾选, 0 不勾选
            _foldoutEditor = prop.floatValue != 0 ? true : false;
            _property = prop;

            //绘制折叠页
            FoldoutGUIDraw();

            //计算该折叠页属性实际的禁用状态
            int actual_foldoutEditorLevel = _simpleShaderGUI.FoldoutLevel_Editor;
            bool actual_foldoutEditor = _simpleShaderGUI.FoldoutEditor;

            //如果记录的折叠页是启用，该折叠页是禁用，则记录该折叠页等级和状态
            bool state1 = _simpleShaderGUI.FoldoutEditor && !_foldoutEditor;
            //如果记录的折叠页是禁用，该折叠页是启用，并且该折叠页不属于记录的折叠页中，则记录该折叠页等级和状态
            bool state2 = !_simpleShaderGUI.FoldoutEditor && _foldoutEditor && _foldoutLevel <= _simpleShaderGUI.FoldoutLevel_Editor;
            if (state1 || state2)
            {
                actual_foldoutEditorLevel = _foldoutLevel;
                actual_foldoutEditor = _foldoutEditor;
            }
            //设置折叠页
            _simpleShaderGUI.SetFoldout(_foldoutLevel, actual_foldoutEditorLevel, _foldoutOpen, actual_foldoutEditor);

            //当更改属性名时，unity不会调用Apply函数进行初始化(只会调用构造函数), 这里每次渲染时都来设置关键字,这或许是unity的bug?...因为在官方的[Toggle]也会出现这种问题(当修改属性名时不会初始化构造函数)
            //即便如此，OnGUI函数只有在绘制时才会被调用，所以如果该属性不会被绘制时(被折叠或不显示)，同时在shader里修改他的名字,同样不会设置关键字，一般不会有这种操作
            if (!_property.hasMixedValue)
                SetFoldoutEditorKeyword(_property, _foldoutEditor);
        }

        //折叠页绘制
        private void FoldoutGUIDraw()
        {
            switch (_foldoutStyle)
            {
                case FoldoutStyle.Big: FoldoutGUIDraw_Shuriken(30, 3); break;
                case FoldoutStyle.Median: FoldoutGUIDraw_Shuriken(25, 2); break;
                case FoldoutStyle.Small: FoldoutGUIDraw_Small(); break;
            }
        }

        //折叠页绘制 大中折叠页 , 返回折叠页复选框状态
        private void FoldoutGUIDraw_Shuriken(float height, int fontSize)
        {
            //如果记录的折叠页是禁用，并且该折叠页属于他，则禁用该折叠页
            if (_foldoutLevel > _simpleShaderGUI.FoldoutLevel_Editor && !_simpleShaderGUI.FoldoutEditor)
                EditorGUI.BeginDisabledGroup(true);

            GUIStyle style = new GUIStyle("ShurikenModuleTitle");//获取折叠页背景样式
            style.border = new RectOffset(15, 7, 4, 4);
            style.font = EditorStyles.boldLabel.font;
            style.fontStyle = EditorStyles.boldLabel.fontStyle;
            style.fontSize = EditorStyles.boldLabel.fontSize + fontSize;
            style.fixedHeight = height;
            style.contentOffset = new Vector2(20f, -1);//折叠页文本偏移
            if (_foldoutToggleDraw)
                style.contentOffset += new Vector2(18f, 0); //如果绘制复选框，文本向后偏移

            Rect rect = GUILayoutUtility.GetRect(0, height, style);
            rect.xMin += (_foldoutLevel - 1) * _foldoutIndent;
            GUI.Box(rect, SimpleShaderGUI.GetFoldoutDisplayName(_property), style);//绘制折叠页外观

            Rect triangleRect = new Rect(rect.x + 4, rect.y + rect.height / 2 - 7, 14f, 14f);//创建三角形外观矩形
            Event e = Event.current;
            //绘制折叠三角形外观
            if (e.type == EventType.Repaint)
                EditorStyles.foldout.Draw(triangleRect, false, false, _foldoutOpen, false);

            //复选框绘制
            Rect toggleRect = new Rect(triangleRect.x + 16, triangleRect.y - 1, 14f, 14f);//创建复选框矩形
            if (_foldoutToggleDraw)
            {
                EditorGUI.BeginChangeCheck();
                if (_property.hasMixedValue)
                    _foldoutEditor = GUI.Toggle(toggleRect, false, "", new GUIStyle("ToggleMixed"));
                else
                    _foldoutEditor = GUI.Toggle(toggleRect, _foldoutEditor, "");
                if (EditorGUI.EndChangeCheck())
                {
                    _property.floatValue = _foldoutEditor ? 1 : 0;
                    //设置关键字
                    SetFoldoutEditorKeyword(_property, _foldoutEditor);
                }
            }

            EditorGUI.EndDisabledGroup();

            //鼠标点击事件处理
            if (e.type == EventType.MouseDown)//在折叠页内点击，进行切换
            {
                //当在折叠框内点击时，切换折叠状态
                if (rect.Contains(e.mousePosition) && !(_foldoutToggleDraw && toggleRect.Contains(e.mousePosition)))
                {
                    _foldoutOpen = !_foldoutOpen;
                    e.Use();//标记该事件已被使用
                }
            }
        }

        //绘制小的折叠页
        private void FoldoutGUIDraw_Small()
        {
            //如果记录的折叠页是禁用，并且该折叠页属于他，则禁用该折叠页
            if (_foldoutLevel > _simpleShaderGUI.FoldoutLevel_Editor && !_simpleShaderGUI.FoldoutEditor)
                EditorGUI.BeginDisabledGroup(true);

            Rect rect = GUILayoutUtility.GetRect(0, 25, EditorStyles.foldout);
            rect.xMin += (_foldoutLevel - 1) * _foldoutIndent;
            Event e = Event.current;
            if (e.type == EventType.Repaint)
                EditorStyles.foldout.Draw(rect, SimpleShaderGUI.GetFoldoutDisplayName(_property), false, false, _foldoutOpen, false);

            EditorGUI.EndDisabledGroup();

            //鼠标点击事件处理
            if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
            {
                _foldoutOpen = !_foldoutOpen;
                e.Use();
            }
        }

        //设置折叠页编辑 关键字
        private void SetFoldoutEditorKeyword(MaterialProperty pro, bool foldoutEditor)
        {
            //设置正常关键字
            string keyword = pro.name.ToUpperInvariant() + "_ON";
            foreach (Material m in pro.targets)
            {
                if (foldoutEditor)
                    m.EnableKeyword(keyword);
                else
                    m.DisableKeyword(keyword);
            }
        }
    }

    //跳出折叠页，可以使下面的属性跳出到任意等级折叠页
    //原理是和绘制折叠页一样，但是他不会进行绘制，而会更改SimpleShaderGUI.FoldoutLevel来达到跳出折叠页的目的
    public class Foldout_Out : MaterialPropertyDrawer
    {
        //退出到哪个等级中，如果退出到1级，他将和1级折叠页并起
        private int _foldoutLevel = 1;
        //绘制折叠页的ShaderGUI
        private SimpleShaderGUI _simpleShaderGUI;

        //默认跳出等级为1
        public Foldout_Out() : this(1) { }
        public Foldout_Out(float foldoutLevel)
        {
            int level = (int)foldoutLevel - 1;
            _foldoutLevel = level < 0 ? 0 : level;
        }


        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return -2;
        }
        public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
        {
            //折叠页检查
            _simpleShaderGUI = editor.customShaderGUI as SimpleShaderGUI;
            if (_simpleShaderGUI == null)
            {
                GUILayout.Label(prop.displayName + " :   Please use SimpleShaderGUI in your shader");
                return;
            }
            if (!SimpleShaderGUI.IsFoldout(prop))
            {
                GUILayout.Label(prop.displayName + " :   Please add " + SimpleShaderGUI.FoldoutSign + " after displayName");
                return;
            }
            //如果该折叠页属于上个折叠页的内容，并且上个折叠页是折叠状态，则该折叠页不显示
            if (_foldoutLevel >= _simpleShaderGUI.FoldoutLevel && !_simpleShaderGUI.FoldoutOpen)
                return;

            //计算该折叠页属性实际的禁用状态
            int actual_foldoutEditorLevel = _simpleShaderGUI.FoldoutLevel_Editor;
            bool actual_foldoutEditor = _simpleShaderGUI.FoldoutEditor;

            //如果记录的折叠页是禁用，该折叠页是启用，并且该折叠页不属于记录的折叠页中，则记录该折叠页等级和状态
            bool state2 = !_simpleShaderGUI.FoldoutEditor && _foldoutLevel < _simpleShaderGUI.FoldoutLevel_Editor;
            if (state2)
            {
                actual_foldoutEditorLevel = _foldoutLevel;
                actual_foldoutEditor = true;
            }
            //设置折叠页
            _simpleShaderGUI.SetFoldout(_foldoutLevel, actual_foldoutEditorLevel, true, actual_foldoutEditor);
        }
    }
}
