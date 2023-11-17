Shader "Custom/GradientColor"
{
    Properties
    {
        _StartColor("Start Color", color) = (1,1,1,1)
        _EndColor("End Color", color) = (1,1,1,1)
        _Center("Center", Range(-1, 1)) = 0
        _ChangeRange("Change Range", Range(0, 1)) = 1.0

        _Specular("Specular", color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 20.0
    }
    SubShader
    {
        Tags{ "Queue" = "Geometry" }
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed3 module_pos : TEXCOORD0;
                fixed3 world_pos : TEXCOORD1;
                fixed3 world_normal : TEXCOORD2;
            };

            v2f vert (appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);
                o.module_pos = a.vertex;
                o.world_pos = mul(unity_ObjectToWorld, a.vertex).xyz;
                o.world_normal = UnityObjectToWorldNormal(a.normal);
                return o;
            }

            fixed4 _StartColor;
            fixed4 _EndColor;
            fixed _Center;
            fixed _ChangeRange;

            fixed4 _Specular;
            fixed _Gloss;

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed3 module_pos = mul(unity_WorldToObject, i.world_pos).xyz; ?为何转换回来会有问题

                fixed d = i.module_pos.y - _Center;
                fixed sign = d / abs(d);
                fixed percent = d / (sign * _ChangeRange);
                percent = sign * saturate(percent); //范围在(-1, 1)
                percent = percent * 0.5 + 0.5; //范围在(0, 1)

                fixed3 albedo = lerp(_StartColor, _EndColor, percent).rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                
                fixed3 world_normal = normalize(i.world_normal);
                fixed3 view_dir = normalize(UnityWorldSpaceViewDir(i.world_pos));
                fixed3 light_dir = normalize(UnityWorldSpaceLightDir(i.world_pos));

                fixed half_lambert = 0.5 * dot(light_dir, world_normal) + 0.5;
                fixed3 diffuse = albedo * _LightColor0.rgb * half_lambert;

                //fixed3 deuce_dir = normalize(view_dir +  light_dir);
                //fixed blinn = pow(max(0, dot(deuce_dir, world_normal)), _Gloss);
                //fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                return fixed4(ambient + diffuse/* + specular*/, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
