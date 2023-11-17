Shader "Learn/FragSpecular"
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
			//Base Pass的必要声明
			#pragma multi_compile_fwdbase

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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);
                o.worldNormal = normalize(mul(a.normal, (fixed3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, a.vertex).xyz;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed halfLambert = 0.5 * dot(worldNormal, worldLight) + 0.5;
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * halfLambert;

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

				////phong经验公式计算
                //fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
                //fixed phong = pow(max(0, dot(reflectDir, viewDir)), _Gloss);
                //fixed3 specular = _Specular.rgb * _LightColor0.rgb * phong;

				////blinn经验公式计算
                //fixed3 deuceDir = normalize(viewDir + worldLight);
                //fixed blinn = pow(max(0, dot(deuceDir, worldNormal)), _Gloss);
                //fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

				//blinn-phong经验公式计算
				fixed3 halfDir = normalize(worldLight + viewDir);
				fixed3 blinn_phong = pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn_phong;

                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
