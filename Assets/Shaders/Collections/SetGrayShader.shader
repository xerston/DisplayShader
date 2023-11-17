Shader "Custom/SetGrayShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color Tint", color) = (1,1,1,1)

        _GrayDegree("Gray Degree", Range(0, 1)) = 0.2

        _Specular("Specular", color) = (1,1,1,1)
        _Gloss("Gloss", Range(5, 256)) = 20.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 obj_normal : TEXCOORD1;
                fixed3 light_dir : TEXCOORD2;
                fixed3 view_dir : TEXCOORD3;
            };

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _Color;

            fixed _GrayDegree;

            fixed4 _Specular;
            fixed _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.obj_normal = v.normal;
                o.light_dir = ObjSpaceLightDir(v.vertex);
                o.view_dir = ObjSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed gray = albedo.r + albedo.g + albedo.b; //三色合一能够置灰
                albedo = lerp(albedo, fixed3(gray,gray,gray), _GrayDegree);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                fixed3 obj_normal = normalize(i.obj_normal);
                fixed3 light_dir = normalize(i.light_dir);
                fixed half_lambert = 0.5 * dot(obj_normal, light_dir) + 0.5;
                fixed3 diffuse = albedo * _LightColor0.rgb * half_lambert;

                fixed3 view_dir = normalize(i.view_dir);
                fixed3 deuce_dir = normalize(view_dir + light_dir);
                fixed blinn = pow(saturate(dot(deuce_dir, obj_normal)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                return float4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }
}
