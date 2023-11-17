using UnityEngine;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial = null;

    public Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }
    
    [Range(0, 4)]
    public int iterations = 3; //高斯模糊迭代次数

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f; //模糊范围
    
    [Range(1, 8)]
    public int downSample = 2; //降采样倍数

    //// 版本1.没有优化的实现
    //void OnRenderImage(RenderTexture src, RenderTexture dest)
    //{
    //    if (material != null)
    //    {
    //        int rtW = src.width;
    //        int rtH = src.height;
    //        RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);

    //        // Render the vertical pass
    //        Graphics.Blit(src, buffer, material, 0);
    //        // Render the horizontal pass
    //        Graphics.Blit(buffer, dest, material, 1);

    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(src, dest);
    //    }
    //}

    //// 版本2.利用缩放对图像进行降采样，从而减少需要处理的像素个数，提升性能
    //void OnRenderImage(RenderTexture src, RenderTexture dest)
    //{
    //    if (material != null)
    //    {
    //        int rtW = src.width / downSample;
    //        int rtH = src.height / downSample;
    //        RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
    //        //采样精度增加，避免下面的Blit采样由于纹理缩小出现锯齿的情况
    //        buffer.filterMode = FilterMode.Bilinear;

    //        // Render the vertical pass
    //        Graphics.Blit(src, buffer, material, 0);
    //        // Render the horizontal pass
    //        Graphics.Blit(buffer, dest, material, 1);

    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(src, dest);
    //    }
    //}

    // 版本3.除了降采样还能设置高斯模糊的迭代次数
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            //设置降采样后的大小
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0); //获取临时渲染纹理
            //采样精度增加，避免下面的Blit采样由于纹理缩小出现锯齿的情况
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(src, buffer0); //降采样

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                //纵向高斯滤波
                Graphics.Blit(buffer0, buffer1, material, 0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                //横向高斯滤波
                Graphics.Blit(buffer0, buffer1, material, 1);

                // 空出buffer1为下一次循环准备
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            Graphics.Blit(buffer0, dest);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}