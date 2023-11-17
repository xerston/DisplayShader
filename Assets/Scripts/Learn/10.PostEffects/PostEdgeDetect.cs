using UnityEngine;

public class PostEdgeDetect : PostEffectsBase
{
    public Shader EdgeDetectionShader;

    [Range(0.0f, 1.0f)]
    public float EdgesOnly = 0.0f;  //边缘线强度
    public Color EdgeColor = Color.black;  //描边颜色
    public Color BackgroundColor = Color.white;  //背景颜色

    private Material _EdgeDetectionMaterial;

    public Material material
    {
        get
        {
            _EdgeDetectionMaterial = CheckShaderAndCreateMaterial(EdgeDetectionShader, _EdgeDetectionMaterial);
            return _EdgeDetectionMaterial;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgesOnly", EdgesOnly);
            material.SetColor("_EdgeColor", EdgeColor);
            material.SetColor("_BackgroundColor", BackgroundColor);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}