Shader "Learn/RampTex2D"
{
    Properties
    {
        _RampTex("Texture", 2D) = "white" {}
        _Color("Color Tint", Color) = (1,1,1,1)

        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpDegree("Bump Degree", Float) = 1.0

        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20.0
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

            sampler2D _RampTex;
            fixed4 _RampTex_ST; //代表_MainTex的缩放和偏移，即外部可调节的4个值
            fixed4 _Color;
            
            sampler2D _BumpTex;
            fixed4 _BumpTex_ST;
            fixed _BumpDegree;

            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 T2W0 : TEXCOORD1;
                float4 T2W1 : TEXCOORD2;
                float4 T2W2 : TEXCOORD3;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);

                o.uv.xy = TRANSFORM_TEX(a.uv.xy, _RampTex);
                o.uv.zw = TRANSFORM_TEX(a.uv.xy, _BumpTex);

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
                fixed4 bump_color = tex2D(_BumpTex, i.uv.zw);
                fixed3 tangent_normal = UnpackNormal(bump_color);
                tangent_normal.xy *= _BumpDegree;
                tangent_normal.z = sqrt(1 - saturate(dot(tangent_normal.xy, tangent_normal.xy)));

                fixed3 world_pos = fixed3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
                fixed3 view_dir = normalize(UnityWorldSpaceViewDir(world_pos));
                fixed3 light_dir = normalize(UnityWorldSpaceLightDir(world_pos));

                float3x3 t2w_matrix = float3x3(i.T2W0.xyz, i.T2W1.xyz, i.T2W2.xyz);
                fixed3 world_normal = normalize(mul(t2w_matrix, tangent_normal));
                fixed half_lambert = 0.5 * dot(world_normal, light_dir) + 0.5;
                fixed3 ramp_color = tex2D(_RampTex, fixed2(0, half_lambert)).rgb * _Color.rgb; //按渐变纹理y轴变化

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 diffuse = ramp_color * _LightColor0.rgb;

                fixed3 deuce_dir = normalize(view_dir + light_dir);
                fixed blinn = pow(max(0, dot(deuce_dir, world_normal)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
