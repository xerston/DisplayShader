Shader "Learn/AlphaBlendShadow"
{
    //AlphaBlend等于透明混合
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Color Tint", color) = (1,1,1,1)
        
        _AlphaCut("AlphaCut", Range(0, 1)) = 0.5
        _AlphaDegree("AlphaDegree", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "true" }

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _Color;
            
            fixed _AlphaCut;
            fixed _AlphaDegree;

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed3 normal : NORMAL;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed4 pos : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainTexColor = tex2D(_MainTex, i.uv.xy);
                clip(mainTexColor.a - _AlphaCut);
                fixed3 albedo = mainTexColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed halfLambert = 0.5 * dot(worldNormal, lightDir) + 0.5;
                fixed3 diffuse = albedo * _LightColor0.rgb * halfLambert;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                return fixed4(ambient + diffuse * atten, _AlphaDegree);
            }

            ENDCG
        }
    }
    //FallBack "Transparent/VertexLit"
    FallBack "VertexLit"
}
