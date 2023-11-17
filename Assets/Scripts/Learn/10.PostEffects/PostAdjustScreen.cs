using UnityEngine;

public class PostAdjustScreen : PostEffectsBase
{
    public Shader AdjustShader;

    //亮度
    [Range(0.0f, 3.0f)]
    public float Brightness = 1.0f;
    //饱和度
    [Range(0.0f, 3.0f)]
    public float Saturation = 1.0f;
    //对比度
    [Range(0.0f, 3.0f)]
    public float Contrast = 1.0f;

    private Material _BriSatConMaterial;

    public Material material
    {
        get
        {
            _BriSatConMaterial = CheckShaderAndCreateMaterial(AdjustShader, _BriSatConMaterial);
            return _BriSatConMaterial;
        }
    }

    [ImageEffectOpaque] //在不透明物体渲染完成后调用
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_Brightness", Brightness);
            material.SetFloat("_Saturation", Saturation);
            material.SetFloat("_Contrast", Contrast);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}