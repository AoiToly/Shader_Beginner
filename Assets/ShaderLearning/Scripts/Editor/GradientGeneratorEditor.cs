using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(GradientGenerator))]
public class GradientGeneratorEditor : Editor
{
    private GradientGenerator m_GradientGenerator;

    private void OnEnable()
    {
        m_GradientGenerator = target as GradientGenerator;
    }

    public override void OnInspectorGUI()
    {
        base.DrawDefaultInspector();
        if (GUILayout.Button("��������"))
        {
            string path = EditorUtility.SaveFilePanelInProject("�洢����", "", m_GradientGenerator.PropertyName, "png");
            System.IO.File.WriteAllBytes(path, m_GradientGenerator.RampTexture.EncodeToPNG());
            AssetDatabase.Refresh();

        }
    }
}
