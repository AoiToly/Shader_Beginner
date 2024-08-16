using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEngine;

public class E11_CustomMaterialGUI : ShaderGUI
{
    bool m_IsFolded = false;
    bool m_IsColorEnabled = false;
    AnimBool m_FoldAnim = new(false);
    enum EBlendMode
    {
        Additive,
        Alpha
    }
    EBlendMode m_BlendMode = EBlendMode.Additive;


    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // base.OnGUI(materialEditor, properties);

        MaterialProperty saveProp = FindProperty("_Save", properties);
        Vector4 saveVec = saveProp.vectorValue;

        // 枚举（Blend）
        MaterialProperty srcBlendProp = FindProperty("_SrcBlend", properties);
        MaterialProperty dstBlendProp = FindProperty("_DstBlend", properties);
        m_BlendMode = (EBlendMode)saveVec.y;
        m_BlendMode = (EBlendMode)EditorGUILayout.EnumPopup("混合模式", m_BlendMode);
        switch(m_BlendMode)
        {
            case EBlendMode.Additive:
                srcBlendProp.floatValue = (float)UnityEngine.Rendering.BlendMode.One;
                dstBlendProp.floatValue = (float)UnityEngine.Rendering.BlendMode.One;
                break;
            case EBlendMode.Alpha:
                srcBlendProp.floatValue = (float)UnityEngine.Rendering.BlendMode.SrcAlpha;
                dstBlendProp.floatValue = (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                break;
        }
        saveVec.y = (float)m_BlendMode;


        // 折叠
        m_IsFolded = saveProp.vectorValue.x == 1;
        saveVec.x = EditorGUILayout.Foldout(m_IsFolded, "折叠组控制") ? 1 : 0;

        m_FoldAnim.target = m_IsFolded;
        if (EditorGUILayout.BeginFadeGroup(m_FoldAnim.faded))
        {
            // Header
            EditorGUILayout.LabelField("浮点值", EditorStyles.boldLabel);
            // float
            // 获取目标属性
            MaterialProperty floatProp = FindProperty("_Float", properties);
            // 绘制
            materialEditor.FloatProperty(floatProp, "Float_cs");
            if (floatProp.floatValue > 1 || floatProp.floatValue < 0)
            {
                EditorGUILayout.HelpBox("越界", MessageType.Error);
            }
            // 滑动条
            MaterialProperty sliderProp = FindProperty("_Slider", properties);
            materialEditor.RangeProperty(sliderProp, "Slider_cs");

            // 空行
            EditorGUILayout.Space(30);
        }
        EditorGUILayout.EndFadeGroup();

        // 边框
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
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
        EditorGUILayout.EndVertical();

        m_IsColorEnabled = (materialEditor.target as Material).IsKeywordEnabled("_COLORENABLED_ON");
        m_IsColorEnabled = EditorGUILayout.BeginToggleGroup("开启颜色", m_IsColorEnabled);
        if (m_IsColorEnabled)
        {
            (materialEditor.target as Material).EnableKeyword("_COLORENABLED_ON");
        }
        else
        {
            (materialEditor.target as Material).DisableKeyword("_COLORENABLED_ON");
        }
        // 颜色
        MaterialProperty colorProp = FindProperty("_Color", properties);
        materialEditor.ColorProperty(colorProp, "Color_cs");
        EditorGUILayout.EndToggleGroup();

        // 纹理
        MaterialProperty textureProp = FindProperty("_MainTex", properties);
        materialEditor.TextureProperty(textureProp, "Texture_cs");

        // 存储Editor状态
        saveProp.vectorValue = saveVec;

        EditorGUILayout.Space(30);

        // 默认额外参数
        // 渲染排序
        materialEditor.RenderQueueField();
        // GPUInstancing
        materialEditor.EnableInstancingField();
        // GI
        materialEditor.DoubleSidedGIField();
    }
}
