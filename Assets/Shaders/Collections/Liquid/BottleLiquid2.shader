Shader "Custom/BottleLiquid2"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color Tint", Color) = (1,1,1,1)

        _FillAmount("Fill Amount", Range(-1,1.1)) = 0.0

        _TopColor("Top Color", Color) = (1,1,1,1)

		_FoamColor("Foam Line Color", Color) = (1,1,1,1)
        _FoamWidth("Foam Line Width", Range(0,0.1)) = 0.0

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
			fixed4 _Color;

			float _FillAmount, _WobbleX, _WobbleZ;

			fixed4 _TopColor;

			fixed4 _FoamColor;
			fixed _FoamWidth;

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
				UNITY_FOG_COORDS(1)
				float3 world_pos : TEXCOORD1;
				float3 obj_normal : TEXCOORD2;
				float3 view_dir : TEXCOORD3;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				float3 world_pos = mul(unity_ObjectToWorld, v.vertex.xyz);
				
				o.world_pos = world_pos;
				o.obj_normal = v.normal;
				o.view_dir = ObjSpaceViewDir(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;
				//启用雾效果
				UNITY_APPLY_FOG(i.fogCoord, albedo);

				//边缘高光
				fixed3 obj_normal = normalize(i.obj_normal);
				fixed3 view_dir = normalize(i.view_dir);
				fixed re_view_blinn = 1 - pow(dot(obj_normal, view_dir), _RimPower);
				re_view_blinn = smoothstep(0.5, 1.0, re_view_blinn); //re_view_blinn为0->0.5时不要高光
				//re_view_blinn = saturate((re_view_blinn - 0.5) / (1.0 - 0.5));
				fixed3 rim_result = _RimColor.rgb * re_view_blinn;

				//主液体
				fixed main_exist = step(i.world_pos.y, _FillAmount - _FoamWidth);
				fixed4 main_colored = albedo * main_exist;

				//泡沫
				fixed foam_exist = step(i.world_pos.y, _FillAmount) - main_exist;
				fixed4 foam_colored = _FoamColor * foam_exist;

				//合成颜色
				fixed4 final_result = main_colored + foam_colored;
				final_result.rgb += rim_result;

				//有泡沫或者主液体的背面都加上顶部颜色，使得看起来顶部有颜色，实际上是中空的
				fixed4 top_color = _TopColor * (foam_exist + main_exist);

				//VFACE为正表示正面，为负表示背面
				return facing > 0 ? final_result: top_color;
			}

			ENDCG
        }
    }

	FallBack "Specular"
}