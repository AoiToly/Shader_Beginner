using UnityEngine;

[ExecuteInEditMode]
public class E14_PostProcessing : MonoBehaviour
{
    public Shader PPShader;
    [Range(0, 1)]public float Value;

    private Material m_PPMaterial;
    public Material PPMaterial
    {
        get
        {
            if (m_PPMaterial == null)
            {
                if(PPShader == null || !PPShader.isSupported)
                {
                    Debug.LogError("戳啦！");
                    return null;
                }
                m_PPMaterial = new Material(PPShader);
            }
            return m_PPMaterial;
        }
    }


    // 该脚本必须挂在相机上
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        PPMaterial.SetFloat("_Value", Value);
        Graphics.Blit(source, destination, PPMaterial);
    }
}
