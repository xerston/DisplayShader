Shader "Custom/TextureChange"
{
    Properties
    {
        _FirstTex ("First Texture", 2D) = "white" {}
        _SecondTex ("Second Texture", 2D) = "white" {}
		_Color("Color Tint", color) = (1,1,1,1)
		_ChangeDegree("Change Degree", Range(0, 1)) = 0.5
		
		[HDR]_Emission("Emission", Color) = (0,0,0)
		_EmissionDegree("Emission Degree", Range(0, 2)) = 0.5
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
			
			sampler2D _FirstTex;
			fixed4 _FirstTex_ST;
			sampler2D _SecondTex;
			fixed4 _SecondTex_ST;
			fixed4 _Color;
			fixed _ChangeDegree;

			fixed3 _Emission;
			fixed _EmissionDegree;
			
            struct appdata
            {
                float4 vertex : POSITION;
				fixed3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
			
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
				fixed3 world_normal : TEXCOORD1;
				fixed3 world_pos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _FirstTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.xy, _FirstTex);
				o.world_normal = UnityObjectToWorldNormal(v.normal);
				o.world_pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed3 first_color = tex2D(_FirstTex, i.uv.xy).rgb * _ChangeDegree;
				fixed3 second_color = tex2D(_SecondTex, i.uv.zw).rgb * (1 - _ChangeDegree);
				fixed3 albedo = (first_color + second_color) * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				fixed3 world_normal = normalize(i.world_normal);
				fixed3 light_dir = normalize(UnityWorldSpaceLightDir(i.world_pos));
				fixed3 half_lambert = 0.5 * dot(light_dir, world_normal) + 0.5;
				fixed3 diffuse = albedo * _LightColor0.rgb * half_lambert;

				//自发光
				fixed3 emission = albedo * _Emission.rgb * _EmissionDegree;

				return fixed4(ambient + diffuse + emission, 1.0);
            }
            ENDCG
        }
    }
	FallBack "Diffuse"
}
