Shader "Learn/ScrollBG"
{
    Properties
    {
        _MainTex ("Base Layer", 2D) = "white" { }// 第一张图片
        _DetailTex ("2nd Layer", 2D) = "white" { }// 第二张图片
        _ScrollX ("Base Layer Scroll Speed", Float) = 0.2 // 第一张图片滚动速度
        _Scroll2X ("2nd Layer Scroll Speed", Float) = 0.5 // 第二张图片滚动速度
        _Multiplier ("Layer Multiplier", Float) = 1 // 亮度
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

        pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            struct a2v
            {
                float4 vertex: POSITION;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 uv: TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                // 水平方向对纹理坐标进行偏移
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

                return o;
            }

            fixed4 frag(v2f i): SV_TARGET
            {
                fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);

                fixed4 color = lerp(firstLayer, secondLayer, secondLayer.a); //混合两层图片
                color.rgb *= _Multiplier; //亮度

                return color;
            }
            
            ENDCG

        }
    }

    FallBack "VertexLit"
}