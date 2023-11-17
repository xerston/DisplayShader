using UnityEngine;

public class FogWithDepth : PostEffectsBase
{
    public Shader fogShader;
    private Material fogMaterial = null;

    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    //需要获取摄像机的相关参数，所以用两个变量存储摄像机的Camera组件和Transform组件
    private Camera myCamera;
    public Camera MyCamera
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

    private Transform myCameraTransform;
    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = MyCamera.transform;
            }

            return myCameraTransform;
        }
    }

    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;    //控制雾的浓度
    public Color fogColor = Color.white;    //控制雾的颜色
    public float fogStart = 0.0f;    //控制雾的起始高度
    public float fogEnd = 2.0f;    //控制雾的终止高度
    
    void OnEnable()
    {
        MyCamera.depthTextureMode |= DepthTextureMode.Depth; //获取摄像机的深度纹理
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            float FOV = MyCamera.fieldOfView; //相机垂直方向的视野角度
            float Near = MyCamera.nearClipPlane; //近裁剪面距离
            float aspect = MyCamera.aspect; //相机视口宽高比

            float halfHeight = Near * Mathf.Tan(FOV * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;
            Vector3 toTop = cameraTransform.up * halfHeight;

            //相机到近裁剪面左上的向量
            Vector3 TL = cameraTransform.forward * Near + toTop - toRight;
            float scale = TL.magnitude / Near; //将锥形边/中线的比值作为长度，4个向量的长度相同，因此只算一次
            TL.Normalize();
            TL *= scale;

            //相机到近裁剪面右上的向量
            Vector3 TR = cameraTransform.forward * Near + toRight + toTop;
            TR.Normalize();
            TR *= scale;

            //相机到近裁剪面左下的向量
            Vector3 BL = cameraTransform.forward * Near - toTop - toRight;
            BL.Normalize();
            BL *= scale;

            //相机到近裁剪面右下的向量
            Vector3 BR = cameraTransform.forward * Near + toRight - toTop;
            BR.Normalize();
            BR *= scale;

            frustumCorners.SetRow(0, BL);
            frustumCorners.SetRow(1, BR);
            frustumCorners.SetRow(2, TR);
            frustumCorners.SetRow(3, TL);

            material.SetMatrix("_FrustumCornersRay", frustumCorners);

            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}