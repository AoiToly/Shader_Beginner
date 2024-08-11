using UnityEngine;

[ExecuteInEditMode]
public class ShaderLOD : MonoBehaviour
{
    public enum Quality
    {
        High, Medium, Low
    }

    public Quality quality = Quality.High;

    private void Update()
    {
        switch (quality)
        {
            case Quality.High:
                Shader.globalMaximumLOD = 600;
                break;
            case Quality.Medium:
                Shader.globalMaximumLOD = 400;
                break;
            case Quality.Low:
                Shader.globalMaximumLOD = 200;
                break;
            default:
                Shader.globalMaximumLOD = 200;
                break;
        }
    }
}
