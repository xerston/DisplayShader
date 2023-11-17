Shader "Learn/Tex2D"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color Tint", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            fixed4 _MainTex_ST; //代表_Albedo的缩放和偏移，即外部可调节的4个值
            fixed4 _Color;
            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 world_normal : TEXCOORD0;
                float3 world_pos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);
                o.world_normal = UnityObjectToWorldNormal(a.normal);
                o.world_pos = mul(unity_ObjectToWorld, a.vertex).xyz;

                //o.uv = a.uv.xy * _MainTex_TS.xy + _MainTex_TS.zw; 与下句等价
                o.uv = TRANSFORM_TEX(a.uv, _MainTex);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo.rgb;

                fixed3 world_normal = normalize(i.world_normal);
                fixed3 light_dir = normalize(UnityWorldSpaceLightDir(i.world_pos));
                fixed half_lambert = 0.5 * dot(world_normal, light_dir) + 0.5;
                fixed3 diffuse = albedo.rgb * _LightColor0.rgb * half_lambert;
                //fixed lambert = max(0, dot(world_normal, light_dir));
                //fixed3 diffuse = albedo.rgb * _LightColor0.rgb * lambert;

                fixed3 view_dir = normalize(UnityWorldSpaceViewDir(i.world_pos));
                fixed3 deuce_dir = normalize(view_dir + light_dir);
                fixed blinn = pow(max(0, dot(deuce_dir, world_normal)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
