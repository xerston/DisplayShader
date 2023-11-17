Shader "Learn/AlphaTestShadow"
{
    //AlphaTest等于裁剪
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Color Tint", color) = (1,1,1,1)

        _Cutoff("Alpha Cut", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "true" }

        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _Color;

            fixed _Cutoff;

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
				TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainTexColor = tex2D(_MainTex, i.uv.xy);
                clip(mainTexColor.a - _Cutoff); //裁剪操作将在片元着色器之后执行
                fixed3 albedo = mainTexColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed lambert = max(0, dot(worldNormal, lightDir));
                fixed3 diffuse = albedo * _LightColor0.rgb * lambert;

				UNITY_LIGHT_ATTENUATION(atten, i , i.worldPos);
                return fixed4(ambient + diffuse * atten, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Transparent/Cutout/VertexLit"
}
