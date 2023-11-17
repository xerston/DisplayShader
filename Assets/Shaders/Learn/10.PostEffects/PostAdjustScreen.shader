Shader "Learn/PostAdjustScreen"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness ("Brightness", Float) = 1
        _Saturation ("Saturation", Float) = 1
        _Contrast ("Contrast", Float) = 1
    }
    SubShader
    {
        Pass
        {
            ZTest Always  //渲染所有像素。这在功能上等同于 AlphaTest Off。
            Cull Off    
            ZWrite Off  //关闭深度写入
            
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
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Brightness;
            float _Saturation;
            float _Contrast;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 tex = tex2D(_MainTex, i.uv);

                //调整亮度
                fixed3 finalColor = tex.rgb * _Brightness;
                //调整饱和度
                fixed luminance = 0.2125 * tex.r + 0.7154 * tex.g + 0.0721 * tex.b; //对颜色的每个分量的值乘上一个特定的系数并相加
                fixed3 luminanceColor = fixed3(luminance,luminance,luminance); //得到一个饱和度为0的颜色值
                finalColor = lerp(luminanceColor,finalColor,_Saturation);
                //调整对比度
                fixed3 avgColor = fixed3(0.5,0.5,0.5); //得到对比度为0的颜色值
                finalColor = lerp(avgColor, finalColor, _Contrast);
                
                return fixed4(finalColor, tex.a);
            }
            ENDCG
        }
    }
}