using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class TexGenerator : MonoBehaviour
{
    public Material material = null;

    #region Material properties
    private int m_textureWidth = 512;
    public int textureWidth
    {
        get
        {
            return m_textureWidth;
        }
        set
        {
            m_textureWidth = value;
            _UpdateMaterial();
        }
    }
    
    private Color m_backgroundColor = Color.white;
    public Color backgroundColor
    {
        get
        {
            return m_backgroundColor;
        }
        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }
    
    private Color m_circleColor = Color.yellow;
    public Color circleColor
    {
        get
        {
            return m_circleColor;
        }
        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }
    
    private float m_blurFactor = 5.0f;
    public float blurFactor
    {
        get
        {
            return m_blurFactor;
        }
        set
        {
            m_blurFactor = value;
            _UpdateMaterial();
        }
    }
    #endregion

    private Texture2D m_generatedTexture = null;
    
    private void Start()
    {
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if (renderer == null)
            {
                Debug.LogWarning("Cannot find a renderer.");
                return;
            }

            material = renderer.sharedMaterial;
        }

        _UpdateMaterial();
    }

    private void _UpdateMaterial()
    {
        if (material != null)
        {
            m_generatedTexture = _GenerateProceduralTexture();
            material.SetTexture("_MainTex", m_generatedTexture);
        }
    }

    private Color _MixColor(Color color0, Color color1, float mixFactor)
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }

    private Texture2D _GenerateProceduralTexture()
    {
        //    初始化一张二维纹理
        Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

        // 圆与圆的间距
        float circleInterval = textureWidth / 4.0f;
        // 圆半径
        float radius = textureWidth / 10.0f;
        //  模糊系数
        float edgeBlur = 1.0f / blurFactor;

        for (int w = 0; w < textureWidth; w++)
        {
            for (int h = 0; h < textureWidth; h++)
            {
                // 使用背景颜色进行初始化
                Color pixel = backgroundColor;

                // 依次画9个圆
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        // 当前圆的圆心位置
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

                        //当前像素与圆心的距离再减半径，dist为负则代表在圆内
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;

                        // 模糊圆的边界
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

                        // 与之前得到的颜色进行混合
                        pixel = _MixColor(pixel, color, color.a);
                    }
                }

                proceduralTexture.SetPixel(w, h, pixel);
            }
        }

        proceduralTexture.Apply();

        return proceduralTexture;
    }
}