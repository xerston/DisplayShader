Shader "Learn/TwoSideAlphaBlend"
{
    //双面透明混合
    //Cull Back剔除背面(默认)，Front剔除正面，Off关掉剔除，慎重关掉剔除，这样会使渲染图元成倍增加，除非特殊需求，不要关闭剔除。
    //不可以关掉剔除，由于透明混合关闭了深度写入，无深度信息，
    //如果双面同时渲染，无法保证同一个物体的正面和背面图元的渲染顺序，这样可能得到错误的半透效果
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

            Cull Front
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
        
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            Cull Back
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
                clip(main_tex_color.x - _AlphaCut);
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
