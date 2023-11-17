Shader "Learn/MaskTex2D"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Color Tint", color) = (1,1,1,1)

        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpDegree("Bump Degree", float) = 1.0

        _MaskTex("Mask Texture", 2D) = "white" {}
        _MaskDegree("Mask Degree", Range(0, 1)) = 0.5

        _Specular("Specular", color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 10.0
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

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _Color;

            sampler2D _BumpTex;
            fixed4 _BumpTex_ST;
            fixed _BumpDegree;

            sampler2D _MaskTex;
            fixed4 _MaskTex_ST;
            fixed _MaskDegree;

            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed3 normal : NORMAL;
                fixed4 tangent : TANGENT;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed4 vertex : SV_POSITION;
                fixed4 uv1 : TEXCOORD0;
                fixed2 uv2 : TEXCOORD1;
                fixed4 T2W0 : TEXCOORD2;
                fixed4 T2W1 : TEXCOORD3;
                fixed4 T2W2 : TEXCOORD4;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);

                o.uv1.xy = TRANSFORM_TEX(a.uv.xy, _MainTex);
                o.uv1.zw = TRANSFORM_TEX(a.uv.xy, _BumpTex);
                o.uv2.xy = TRANSFORM_TEX(a.uv.xy, _MaskTex);

                fixed3 world_pos = mul(unity_ObjectToWorld, a.vertex).xyz;
                fixed3 world_normal = UnityObjectToWorldNormal(a.normal);
                fixed3 world_tangent = UnityObjectToWorldDir(a.tangent) * a.tangent.w;
                fixed3 binormal = cross(world_normal, world_tangent);
                o.T2W0 = fixed4(world_tangent.x, binormal.x, world_normal.x, world_pos.x);
                o.T2W1 = fixed4(world_tangent.y, binormal.y, world_normal.y, world_pos.y);
                o.T2W2 = fixed4(world_tangent.z, binormal.z, world_normal.z, world_pos.z);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed4 bump_color = tex2D(_BumpTex, i.uv1.zw);
                fixed3 tangent_normal = UnpackNormal(bump_color);
                tangent_normal.xy *= _BumpDegree;
                tangent_normal.z = sqrt(1 - saturate(dot(tangent_normal.xy, tangent_normal.xy)));
                float3x3 t2w_matrix = float3x3(i.T2W0.xyz, i.T2W1.xyz, i.T2W2.xyz);
                fixed3 world_normal = normalize(mul(t2w_matrix, tangent_normal));

                fixed3 world_pos = fixed3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
                fixed3 view_dir = normalize(UnityWorldSpaceViewDir(world_pos));
                fixed3 light_dir = normalize(UnityWorldSpaceLightDir(world_pos));

                fixed3 albedo = tex2D(_MainTex, i.uv1.xy).xyz * _Color.xyz;
                fixed mask = tex2D(_MaskTex, i.uv2.xy).x * _MaskDegree; //用纹理x值作为遮罩值

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo * mask;
                
                fixed half_lambert = 0.5 * dot(world_normal, light_dir) + 0.5;
                fixed3 diffuse = albedo * _LightColor0.rgb * half_lambert * mask;

                fixed3 deuce_dir = normalize(light_dir + view_dir);
                fixed blinn = pow(max(0, dot(world_normal, deuce_dir)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
