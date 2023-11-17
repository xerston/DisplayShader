Shader "Learn/AlphaBlend"
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
                fixed4 vertex : SV_POSITION;
                fixed2 uv : TEXCOORD0;
                fixed3 world_normal : TEXCOORD1;
                fixed3 world_pos : TEXCOORD2;
            };

            v2f vert (appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);

                o.uv.xy = TRANSFORM_TEX(a.uv.xy, _MainTex);

                o.world_normal = UnityObjectToWorldNormal(a.normal);

                o.world_pos = mul(unity_ObjectToWorld, a.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 main_tex_color = tex2D(_MainTex, i.uv.xy);
                clip(main_tex_color.r - _AlphaCut);
                fixed3 albedo = main_tex_color.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                fixed3 world_normal = normalize(i.world_normal);
                fixed3 light_dir = normalize(UnityWorldSpaceLightDir(i.world_pos));
                fixed half_lambert = 0.5 * dot(world_normal, light_dir) + 0.5;
                fixed3 diffuse = albedo * _LightColor0.rgb * half_lambert;

                return fixed4(ambient + diffuse, _AlphaDegree);
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
