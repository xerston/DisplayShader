Shader "Custom/OneLayerLiquid"
{
    Properties
    {
		_LayerTex("Layer Tex", 2D) = "white" {}
        _LayerAmount("Layer Amount", Range(0,1)) = 0.0
		
		_AppendTex("Append Tex", 2D) = "white" {}
		[Toggle(SWITCH_APPEND)] _Append("Append?", float) = 0

		_RimColor("Rim Color", Color) = (1,1,1,1)
	    _RimPower("Rim Power", Range(0,10)) = 0.0

		_AlphaPower("Alpha Power", Range(0, 10)) = 5.0
		
		_WobbleX("WobbleX", Range(-1, 1)) = 0.0
		_WobbleZ("WobbleZ", Range(-1, 1)) = 0.0
    }

    SubShader
    {
        Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "true" }
		
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile __ SWITCH_APPEND
			#include "UnityCG.cginc"
			
			sampler2D _LayerTex;
			float _LayerAmount;

			fixed _WobbleX;
			fixed _WobbleZ;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				fixed3 world_pos : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.world_pos = mul(unity_ObjectToWorld, v.vertex.xyz);
				#ifdef SWITCH_APPEND
				o.world_pos.xyz = v.uv.xyx * 2 - 1;
				#endif
				return o;
			}
			
			fixed GetWobbleY(fixed3 world_pos)
			{
				return (world_pos.x * _WobbleX + world_pos.z * _WobbleZ) * 0.5;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				fixed liquid_h = i.world_pos.y;
				fixed wobble_y = GetWobbleY(i.world_pos);
				fixed threshold = _LayerAmount + wobble_y;
				fixed back_exist = step(liquid_h, threshold);
				fixed4 final_color = tex2D(_LayerTex, fixed2(i.world_pos.x, threshold));
				final_color.rgb = lerp(final_color.rgb, fixed3(1,1,1), 0.15);
				return final_color * back_exist;
			}

			ENDCG
        }
		
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile __ SWITCH_APPEND
			#include "UnityCG.cginc"
			
			sampler2D _LayerTex;
			float _LayerAmount;

			float4 _RimColor;
			float _RimPower;

			float _AlphaPower;

			sampler2D _AppendTex;
			float4 _AppendTex_ST;

			fixed _WobbleX;
			fixed _WobbleZ;

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
				o.uv = TRANSFORM_TEX(v.uv, _AppendTex);

				float3 world_pos = mul(unity_ObjectToWorld, v.vertex.xyz);
				o.world_pos = world_pos;
				#ifdef SWITCH_APPEND
				o.world_pos.xyz = v.uv.xyx * 2 - 1;
				#endif

				o.obj_normal = v.normal;
				o.view_dir = ObjSpaceViewDir(v.vertex);
				return o;
			}

			fixed GetWobbleY(fixed3 world_pos)
			{
				return (world_pos.x * _WobbleX + world_pos.z * _WobbleZ) * 0.5;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				//边缘高光
				fixed3 obj_normal = normalize(i.obj_normal);
				fixed3 view_dir = normalize(i.view_dir);
				fixed re_view_blinn = 1 - pow(dot(obj_normal, view_dir), _RimPower);
				re_view_blinn = smoothstep(0.5, 1.0, re_view_blinn); //re_view_blinn为0->0.5时不要高光
				//re_view_blinn = saturate((re_view_blinn - 0.5) / (1.0 - 0.5));
				fixed3 rim_result = _RimColor.rgb * re_view_blinn;
				
				//液体
				fixed liquid_h = i.world_pos.y;
				fixed wobble_y = GetWobbleY(i.world_pos);
				fixed threshold = _LayerAmount + wobble_y;
				fixed front_exist = step(liquid_h, threshold);
				fixed4 final_color = tex2D(_LayerTex, fixed2(i.world_pos.x, liquid_h));

				//合成颜色
				#ifdef SWITCH_APPEND
				//fixed4 tex_color = tex2D(_AppendTex, i.uv);
				//fixed tex_not_exist = step(tex_color.a, 0.4);
				//final_color = lerp(tex_color, final_color, tex_not_exist);
				final_color = lerp(final_color, tex2D(_AppendTex, i.uv), 0.05);
				#endif

				final_color.rgb += rim_result;
				#ifdef SWITCH_APPEND
				final_color.a = 0.8;
				#else
				final_color.a = saturate(1 - pow(dot(obj_normal, view_dir), _AlphaPower)) + 0.5;
				#endif
				final_color.a *= saturate(front_exist);

				return final_color;
			}

			ENDCG
        }
    }

	FallBack "Specular"
}