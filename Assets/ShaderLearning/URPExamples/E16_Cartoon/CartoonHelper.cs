using UnityEngine;

public class CartoonHelper : MonoBehaviour
{
    public int StencilRef = 1;

    private void Start()
    {
        Renderer[] renderers = GetComponentsInChildren<Renderer>();
        foreach (Renderer renderer in renderers)
        {
            Material[] materials = renderer.materials;
            foreach (Material material in materials)
            {
                material.SetInt("_StencilRef", StencilRef);
            }
        }
    }
}
