using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;

    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 0.9f)]//为了防止拖尾效果完全替代前帧的渲染结果，所以把值控制在0到0.9范围内
    public float blurAmount = 0.5f; //模糊程度

    private RenderTexture accumulationTexture;//定义一个RenderTexture类型的变量，保存之前图像叠加的结果

    //在该脚本不运行时，即调用OnDiable时，立即销毁accumulationTexture，这是因为希望在下一次开始应用运动模糊时重新叠加图像
    private void OnDisable()
    {
        DestroyImmediate(accumulationTexture);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            //若accumationTexture为空或与当前分辨率不相等时重新创建一个accumationTexture
            if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
            {
                //立即销毁
                DestroyImmediate(accumulationTexture);
                //创建一个符合大小的渲染纹理
                accumulationTexture = new RenderTexture(src.width, src.height, 0);
                //HideAndDontSave：保留对象到新场景，与DontSave类似，但不会显示在Hierarchy面板中
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(src, accumulationTexture); //使用当前的帧图像初始化accumulationTexture
            }

            //调用MarkRestoreExpected来表明需要进行一个渲染纹理的恢复操作
            accumulationTexture.MarkRestoreExpected();

            //每次调用OnRenderImage时都需要把当前帧图像和accumulationTexture纹理混合
            //accumulationTexture纹理不需要提前清空，因为她保存了我们之前的混合结果。

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);//将参数传给材质

            Graphics.Blit(src, accumulationTexture, material);//把当前屏幕图像src叠加到accumulationTexture中
            Graphics.Blit(accumulationTexture, dest);//把结果显示到屏幕上
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }

}