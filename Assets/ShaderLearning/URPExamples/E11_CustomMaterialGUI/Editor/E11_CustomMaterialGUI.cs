using UnityEngine;
using UnityEditor;

public class E11_CustomMaterialGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);

        // float
        // 获取目标属性
        MaterialProperty floatProp = FindProperty("_Float", properties);
        // 绘制
        materialEditor.FloatProperty(floatProp, "Float_cs");

        // 滑动条
        MaterialProperty sliderProp = FindProperty("_Slider", properties);
        materialEditor.RangeProperty(sliderProp, "Slider_cs");

        // 四维向量
        MaterialProperty vectorProp = FindProperty("_Vector", properties);
        // 方案一
        materialEditor.VectorProperty(vectorProp, "Vector_cs");
        // 方案二
        int vectorPropX = (int)vectorProp.vectorValue.x;
        vectorPropX = EditorGUILayout.IntField("Int_X", vectorPropX);
        // 滑动条
        int vectorPropY = (int)vectorProp.vectorValue.y;
        vectorPropY = EditorGUILayout.IntSlider("IntSlider_Y", vectorPropY, 0, 10);
        // 范围滑动条
        float vectorPropZ = vectorProp.vectorValue.z;
        float vectorPropW = vectorProp.vectorValue.w;
        EditorGUILayout.MinMaxSlider("MinMaxSlider_ZW", ref vectorPropZ, ref vectorPropW, 0, 10);

        vectorProp.vectorValue = new Vector4(vectorPropX, vectorPropY, vectorPropZ, vectorPropW);

        // 颜色
        MaterialProperty colorProp = FindProperty("_Color", properties);
        materialEditor.ColorProperty(colorProp, "Color_cs");

        // 纹理
        MaterialProperty textureProp = FindProperty("_MainTex", properties);
        materialEditor.TextureProperty(textureProp, "Texture_cs");
    }
}
