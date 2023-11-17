Shader "Learn/VertexDiffuse"
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
                float3 color : COLOR;
            };

            v2f vert(appdata a)
            {
                v2f o;
                //o.vertex = mul(UNITY_MATRIX_MVP, a.vertex);
                o.vertex = UnityObjectToClipPos(a.vertex);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 world_normal = normalize(mul(a.normal, (fixed3x3)unity_WorldToObject));
                fixed3 world_light = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(world_normal, world_light));

                o.color = ambient + diffuse;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}
