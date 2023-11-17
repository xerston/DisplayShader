Shader "Custom/4LayerLiquid"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_Layer1Color("Layer1 Color", Color) = (1,1,1,1)
        _Layer1Amount("Layer1 Amount", Range(-1,1.1)) = 0.0

		_Layer2Color("Layer2 Color", Color) = (1,1,1,1)
        _Layer2Amount("Layer2 Amount", Range(-1,1.1)) = 0.0

		_Layer3Color("Layer3 Color", Color) = (1,1,1,1)
        _Layer3Amount("Layer3 Amount", Range(-1,1.1)) = 0.0

		_Layer4Color("Layer4 Color", Color) = (1,1,1,1)
        _Layer4Amount("Layer4 Amount", Range(-1,1.1)) = 0.0

        _TopColor("Top Color", Color) = (1,1,1,1)

		_RimColor("Rim Color", Color) = (1,1,1,1)
	    _RimPower("Rim Power", Range(0,10)) = 0.0
    }

    SubShader
    {
        Tags {"Queue"="Geometry"  "DisableBatching" = "True" }
		
        Pass
        {
			Zwrite On
			Cull Off //关闭剔除，需优化
			AlphaToMask On //启用透明，目标颜色alpha才会生效

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Layer1Color;
			float _Layer1Amount;

			fixed4 _Layer2Color;
			fixed _Layer2Amount;

			fixed4 _Layer3Color;
			fixed _Layer3Amount;

			fixed4 _Layer4Color;
			fixed _Layer4Amount;

			fixed4 _TopColor;

			float4 _RimColor;
			float _RimPower;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 world_pos : TEXCOORD1;
				float3 obj_normal : TEXCOORD2;
				float3 view_dir : TEXCOORD3;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				float3 world_pos = mul(unity_ObjectToWorld, v.vertex.xyz);
				
				o.world_pos = world_pos;
				o.obj_normal = v.normal;
				o.view_dir = ObjSpaceViewDir(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, i.uv) * _Layer1Color;

				//边缘高光
				fixed3 obj_normal = normalize(i.obj_normal);
				fixed3 view_dir = normalize(i.view_dir);
				fixed re_view_blinn = 1 - pow(dot(obj_normal, view_dir), _RimPower);
				re_view_blinn = smoothstep(0.5, 1.0, re_view_blinn); //re_view_blinn为0->0.5时不要高光
				//re_view_blinn = saturate((re_view_blinn - 0.5) / (1.0 - 0.5));
				fixed3 rim_result = _RimColor.rgb * re_view_blinn;

				fixed4 final_color = fixed4(0,0,0,0);
				//Layer4
				fixed layer4_exist = step(i.world_pos.y, _Layer4Amount);
				final_color = lerp(final_color, _Layer4Color, layer4_exist);

				//Layer3
				fixed layer3_exist = step(i.world_pos.y, _Layer3Amount);
				final_color = lerp(final_color, _Layer3Color, layer3_exist);

				//Layer2
				fixed layer2_exist = step(i.world_pos.y, _Layer2Amount);
				final_color = lerp(final_color, _Layer2Color, layer2_exist);

				//Layer1
				fixed layer1_exist = step(i.world_pos.y, _Layer1Amount);
				final_color = lerp(final_color, _Layer1Color, layer1_exist);

				//合成颜色
				final_color.rgb += rim_result;

				//有泡沫或者主液体的背面都加上顶部颜色，使得看起来顶部有颜色，实际上是中空的
				fixed4 top_color = _TopColor * saturate(layer1_exist + layer2_exist + layer3_exist + layer4_exist);

				//VFACE为正表示正面，为负表示背面
				return facing > 0 ? final_color: top_color;
			}

			ENDCG
        }
    }

	FallBack "Specular"
}