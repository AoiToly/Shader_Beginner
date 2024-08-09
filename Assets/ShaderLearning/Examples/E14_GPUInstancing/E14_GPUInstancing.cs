using UnityEngine;

public class E14_GPUInstancing : MonoBehaviour
{
    public GameObject Prefab;
    public int Count = 100;
    public float Range = 10;

    private void Start()
    {
        // 必须通过材质属性块修改材质属性才能激活GPUInstancing
        MaterialPropertyBlock prop = new MaterialPropertyBlock();
        for (int i = 0; i < Count; i++)
        {
            Vector2 xz = Random.insideUnitSphere * Range;
            Vector3 pos = new Vector3(xz.x, 0, xz.y);
            GameObject obj = GameObject.Instantiate(Prefab, pos, Quaternion.identity);
            Color color = Random.ColorHSV();
            prop.SetColor("_BaseColor", color);
            obj.GetComponent<Renderer>().SetPropertyBlock(prop);
        }
    }
}
