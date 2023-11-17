Shader "Custom/GrayShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GrayDegree("Gray Degree", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GrayDegree;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float gray_color = col.x * _GrayDegree + col.y * _GrayDegree + col.z * _GrayDegree;

                //三个分量相同时，颜色的取值就是灰度图颜色
                return float4(gray_color,gray_color,gray_color,1.0);
            }
            ENDCG
        }
    }
}
