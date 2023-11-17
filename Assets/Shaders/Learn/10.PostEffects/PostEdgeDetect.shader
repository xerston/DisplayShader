Shader "Learn/PostEdgeDetect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgesOnly ("EdgesOnly",Float) = 1.0
        _EdgeColor ("EdgeColor",Color) = (0,0,0,1)
        _BackgroundColor ("BackgroundColor",Color) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            ZTest Always //渲染所有像素。这在功能上等同于 AlphaTest Off。
            Cull Off
            ZWrite Off //关闭深度写入    

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv[9] : TEXCOORD0; //对应Sobel边缘检测算子(此处使用了九个插值器)
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize; //_MainTex 的纹素( 1/纹理宽，1/纹理高，纹理宽，纹理高)
            fixed _EdgesOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;



            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv = v.uv;
            
                //将uv的每个1格都扩展至9格
                //在顶点着色器里利用插值器以减小计算量节约性能
                //计算卷积核每个格子对应的uv坐标
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1); //计算像素左下的uv坐标
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);  //计算像素下的uv坐标
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);  //计算像素右下的uv坐标
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);  //计算像素左的uv坐标
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0); //计算像素的uv坐标
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0); //计算像素右的uv坐标
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);  //计算像素左上的uv坐标
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1); //计算像素上的uv坐标
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1); //计算像素右上的uv坐标

                return o;
            }

            //计算灰度值
            fixed luminance(fixed4 color)
            {
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            half Sobel(v2f i)
            {
                //此处的Sobel算子是经过反转之后的，所以可以直接用于梯度计算
                const half Gx[9] =
                {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                const half Gy[9] =
                {
                    -1, -2, -1,
                    0, 0, 0,
                    1, 2, 1
                };

                half texColor;
                half edgeX = 0; //横向梯度值 （如果左右两侧灰度变化比较大，那计算得到的梯度值的绝对值就越大，为负则表明左侧颜色深，为正则表明右侧颜色比较深；反之同理） 
                half edgeY = 0; //纵向梯度值 （如果上下两边灰度变化比较大，那计算得到的梯度值的绝对值就越大，为负则表明上边颜色深，为正则表明下边颜色比较深；反之同理）
                for (int it = 0; it < 9; it++)
                {
                    texColor = luminance(tex2D(_MainTex, i.uv[it])); //获取灰度值
                    edgeX += texColor * Gx[it];
                    edgeY += texColor * Gy[it];
                }
                
                //梯度值越大，edge越小，则需要在在边缘颜色属性中取占比更多的值
                half edge = 1 - abs(edgeX) - abs(edgeY);
                return edge; 
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //return luminance(tex2D(_MainTex, i.uv[4])); //测试灰度值
                half edge = Sobel(i);
                //return edge; //测试梯度值

                //edge越小，说明在边缘，则需要在在边缘颜色属性中取占比更多的值；反之取纹理本身的颜色。以此来得到纹理和边缘颜色的混合颜色。
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                return lerp(withEdgeColor, onlyEdgeColor, _EdgesOnly);
            }
            ENDCG
        }
    }
}