Shader "Custom/Checker"
{
    Properties
    {
        _CheckerScale("Checker Scale", Range(1, 10)) = 5.0
    }
    SubShader
    {
        Pass
        {
            Tags{ "LightingMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed4 vertex : SV_POSITION;
                fixed2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed _CheckerScale;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.uv * _CheckerScale;
                uv = floor(uv) * 0.5;
                float color = frac(uv.x + uv.y) * 2;
                return color;
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}
