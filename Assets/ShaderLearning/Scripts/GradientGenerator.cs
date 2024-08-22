using UnityEngine;

public class GradientGenerator : MonoBehaviour
{
    // Gradient�����õĽ�����
    public Gradient Gradient;
    public Texture2D RampTexture;
    public string PropertyName;

    private void Start()
    {

    }

    void OnValidate()
    {
        //����һ������ͼ
        RampTexture = new Texture2D(128, 1);
        RampTexture.wrapMode = TextureWrapMode.Clamp;
        RampTexture.filterMode = FilterMode.Bilinear;

        int count = RampTexture.width * RampTexture.height;
        //Ϊ����ͼ�������Ӧ�����������ɫ����
        Color[] cols = new Color[count];
        for (int i = 0; i < count; i++)
        {
            cols[i] = Gradient.Evaluate((float)i / (count - 1));
        }

        //����ɫӦ�õ�������
        RampTexture.SetPixels(cols);
        RampTexture.Apply();

        //ȫ�ָ�ֵ
        if (!string.IsNullOrEmpty(PropertyName))
        {
            Shader.SetGlobalTexture(PropertyName, RampTexture);
        }
    }
}
