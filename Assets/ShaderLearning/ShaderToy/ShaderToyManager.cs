using UnityEngine;

[ExecuteInEditMode]
public class ShaderToyManager : MonoBehaviour
{
    public Shader PPShader;

    private Material m_PPMaterial;
    public Material PPMaterial
    {
        get
        {
            if (m_PPMaterial == null)
            {
                if(PPShader == null || !PPShader.isSupported)
                {
                    Debug.LogError("������");
                    return null;
                }
                m_PPMaterial = new Material(PPShader);
            }
            return m_PPMaterial;
        }
    }


    // �ýű�������������
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, PPMaterial);
    }
}
