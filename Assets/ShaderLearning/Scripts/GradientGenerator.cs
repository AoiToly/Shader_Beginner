using UnityEngine;

public class GradientGenerator : MonoBehaviour
{
    // Gradient是内置的渐变条
    public Gradient Gradient;
    public Texture2D RampTexture;
    public string PropertyName;

    private void Start()
    {

    }

    void OnValidate()
    {
        //创建一家纹理图
        RampTexture = new Texture2D(128, 1);
        RampTexture.wrapMode = TextureWrapMode.Clamp;
        RampTexture.filterMode = FilterMode.Bilinear;

        int count = RampTexture.width * RampTexture.height;
        //为纹理图声明相对应相除数量的颜色数组
        Color[] cols = new Color[count];
        for (int i = 0; i < count; i++)
        {
            cols[i] = Gradient.Evaluate((float)i / (count - 1));
        }

        //把颜色应用到纹理上
        RampTexture.SetPixels(cols);
        RampTexture.Apply();

        //全局赋值
        if (!string.IsNullOrEmpty(PropertyName))
        {
            Shader.SetGlobalTexture(PropertyName, RampTexture);
        }
    }
}
