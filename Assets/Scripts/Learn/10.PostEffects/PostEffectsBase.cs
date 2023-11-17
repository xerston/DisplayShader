using UnityEngine;
[ExecuteInEditMode] //编辑模式可用
[RequireComponent(typeof(Camera))] //绑定在相机上using UnityEngine;
public class PostEffectsBase : MonoBehaviour
{
    protected void CheckResources()
    {
        bool isSupported = CheckSupport();

        if (isSupported == false)
        {
            NotSupported();
        }
    }

    protected bool CheckSupport()
    {
        //判断支持的方法已被弃用
        //if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        //{
        //    Debug.LogWarning("This platform does not support image effects or render textures.");
        //    return false;
        //}
        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    protected void Start()
    {
        CheckResources();
    }

    //需要一个Shader生成材质以供处理源渲染纹理
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (shader == null)
        {
            return null;
        }

        if (shader.isSupported && material && material.shader == shader)
            return material;

        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
                return material;
            else
                return null;
        }
    }
}