using UnityEngine;
using Tools.TimerEvent.DoAnim;

public class EdgeDetectDepthNormals : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;
    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f; //0->1 原图像->边缘

    public Color edgeColor = Color.black; //线的颜色

    public Color backgroundColor = Color.white; //背景颜色

    public float sampleDistance = 1.0f; //控制深度法线纹理采样时，使用的采样距离。

    public float sensitivityDepth = 1.0f; //深度值检测边缘灵敏度

    public float sensitivityNormals = 1.0f; //法线值检测边缘灵敏度

    private SequenceAnim anim;
    private void OnEnable()
    {
        anim = ObjectDo.GetSequence().AddInterval(0.2f)
            .AddAnim(ObjectDo.DoFloat(0f, 0.7f, 2f, (value) => { edgesOnly = value; })
                    .SetLoop(0, LoopType.Bound));
        anim.Start();
        
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals; //获取深度法线纹理
    }

    [ImageEffectOpaque] //不透明物渲染完成后执行
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}

