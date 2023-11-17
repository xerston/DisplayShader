Shader "Learn/FragDiffuse"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 world_normal : TEXCOORD0;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);
                o.world_normal = normalize(mul(a.normal, (fixed3x3)unity_WorldToObject));

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.zyx;

                fixed3 world_normal = normalize(i.world_normal);
                fixed3 world_light = normalize(_WorldSpaceLightPos0.xyz);
                //fixed lambert = max(0, dot(world_normal, world_light));
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * lambert;
                fixed half_lambert = 0.5 * dot(world_normal, world_light) + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * half_lambert;

                fixed3 color = ambient + diffuse;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}
