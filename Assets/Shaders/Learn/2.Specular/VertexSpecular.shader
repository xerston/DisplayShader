Shader "Learn/VertexSpecular"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
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
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 color : COLOR;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 world_normal = normalize(mul(a.normal, (fixed3x3)unity_WorldToObject));
                fixed3 world_light = normalize(_WorldSpaceLightPos0.xyz);
                fixed half_lambert = 0.5 * dot(world_normal, world_light) + 0.5;
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * half_lambert;

                fixed3 reflect_dir = normalize(reflect(-world_light, world_normal));
                fixed3 view_dir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, a.vertex));
                fixed phong = pow(max(0, dot(reflect_dir, view_dir)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * phong;

                o.color = ambient + diffuse + specular;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
