using UnityEngine;

[ExecuteInEditMode]
public class DynamicReflection : MonoBehaviour
{
    public GameObject obj;
    private Camera cam;
    private Material mat;
    private void Start()
    {
        cam = GetComponent<Camera>();
        if (obj != null)
        {
            mat = obj.GetComponent<Renderer>().sharedMaterial;
        }
    }

    private int pixelSize = 512;
    private void Update()
    {
        if (mat != null)
        {
            //创建渲染纹理，纹理大小决定精细程度，当然越精细性能越差
            RenderTexture cubemap = new RenderTexture(pixelSize, pixelSize, 16);
            cubemap.dimension = UnityEngine.Rendering.TextureDimension.Cube; //设置为Cube模式
            mat.SetTexture("_Cubemap", cubemap);
            cam.RenderToCubemap(cubemap); //更新立方体纹理
        }
    }
}