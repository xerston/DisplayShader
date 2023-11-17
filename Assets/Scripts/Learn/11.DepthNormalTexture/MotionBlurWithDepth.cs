using UnityEngine;
using System.Collections;

public class MotionBlurWithDepth : PostEffectsBase
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
    
    private Camera myCamera;
    public Camera MyCamera //获取相机
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    [Range(0.0f, 1.0f)]
    public float blurSize = 0.5f; //模糊融合范围

    private Matrix4x4 previousViewProjectionMatrix; //上一帧的VP矩阵

    void OnEnable()
    {
        MyCamera.depthTextureMode |= DepthTextureMode.Depth; //获取摄像机的深度纹理
        previousViewProjectionMatrix = MyCamera.projectionMatrix * MyCamera.worldToCameraMatrix;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_BlurSize", blurSize);

            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
            //计算当前帧的VP矩阵,C#中矩阵*矩阵 等同于 Shader中mul(矩阵, 矩阵)
            Matrix4x4 currentViewProjectionMatrix = MyCamera.projectionMatrix * MyCamera.worldToCameraMatrix;
            //当前帧的VP矩阵的逆矩阵
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
            //传递VP矩阵给下一帧使用
            previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}