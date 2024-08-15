using UnityEngine;
using UnityEditor;

public class E11_CustomMaterialGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);

        // float
        // ��ȡĿ������
        MaterialProperty floatProp = FindProperty("_Float", properties);
        // ����
        materialEditor.FloatProperty(floatProp, "Float_cs");

        // ������
        MaterialProperty sliderProp = FindProperty("_Slider", properties);
        materialEditor.RangeProperty(sliderProp, "Slider_cs");

        // ��ά����
        MaterialProperty vectorProp = FindProperty("_Vector", properties);
        // ����һ
        materialEditor.VectorProperty(vectorProp, "Vector_cs");
        // ������
        int vectorPropX = (int)vectorProp.vectorValue.x;
        vectorPropX = EditorGUILayout.IntField("Int_X", vectorPropX);
        // ������
        int vectorPropY = (int)vectorProp.vectorValue.y;
        vectorPropY = EditorGUILayout.IntSlider("IntSlider_Y", vectorPropY, 0, 10);
        // ��Χ������
        float vectorPropZ = vectorProp.vectorValue.z;
        float vectorPropW = vectorProp.vectorValue.w;
        EditorGUILayout.MinMaxSlider("MinMaxSlider_ZW", ref vectorPropZ, ref vectorPropW, 0, 10);

        vectorProp.vectorValue = new Vector4(vectorPropX, vectorPropY, vectorPropZ, vectorPropW);

        // ��ɫ
        MaterialProperty colorProp = FindProperty("_Color", properties);
        materialEditor.ColorProperty(colorProp, "Color_cs");

        // ����
        MaterialProperty textureProp = FindProperty("_MainTex", properties);
        materialEditor.TextureProperty(textureProp, "Texture_cs");
    }
}
