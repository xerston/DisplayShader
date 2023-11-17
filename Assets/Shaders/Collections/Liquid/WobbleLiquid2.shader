Shader "Custom/WobbleLiquid2"
{
    Properties
    {
		_Layer1Color("Layer1 Color", Color) = (1,1,1,1)
        _Layer1Amount("Layer1 Amount", Range(0,1)) = 0.0

		_Layer2Color("Layer2 Color", Color) = (1,1,1,1)
        _Layer2Amount("Layer2 Amount", Range(0,1)) = 0.0

		_Layer3Color("Layer3 Color", Color) = (1,1,1,1)
        _Layer3Amount("Layer3 Amount", Range(0,1)) = 0.0

		_Layer4Color("Layer4 Color", Color) = (1,1,1,1)
        _Layer4Amount("Layer4 Amount", Range(0,1)) = 0.0

		_Layer5Color("Layer5 Color", Color) = (1,1,1,1)
        _Layer5Amount("Layer5 Amount", Range(0,1)) = 0.0

		_GradientRange("Gradient Range", Range(0,1)) = 0.1

        _TopColor("Top Color", Color) = (1,1,1,1)

		_RimColor("Rim Color", Color) = (1,1,1,1)
	    _RimPower("Rim Power", Range(0,10)) = 0.0

		_AlphaPower("Alpha Power", Range(0, 10)) = 5.0
		
		_AppendTex("Append Tex", 2D) = "white" {}
		[Toggle(SWITCH_APPEND)] _Append("Append?", float) = 0

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

			float _Layer1Amount;
			fixed _Layer2Amount;
			fixed _Layer3Amount;
			fixed _Layer4Amount;
			fixed _Layer5Amount;
			fixed4 _TopColor;

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
				o.world_pos.xyz = v.uv.xyx * 2 - 1; //注意转换
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
				fixed threshold = _Layer1Amount + _Layer2Amount + _Layer3Amount + _Layer4Amount + _Layer5Amount + wobble_y;
				fixed back_exist = step(liquid_h, threshold);
				return _TopColor * back_exist;
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

			fixed4 _Layer1Color;
			float _Layer1Amount;

			fixed4 _Layer2Color;
			fixed _Layer2Amount;

			fixed4 _Layer3Color;
			fixed _Layer3Amount;

			fixed4 _Layer4Color;
			fixed _Layer4Amount;

			fixed4 _Layer5Color;
			fixed _Layer5Amount;

			fixed _GradientRange;

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
				o.world_pos.xyz = v.uv.xyx * 2 - 1; //注意转换
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
				fixed wobble_y = GetWobbleY(i.world_pos);

				//边缘高光
				fixed3 obj_normal = normalize(i.obj_normal);
				fixed3 view_dir = normalize(i.view_dir);
				fixed re_view_blinn = 1 - pow(dot(obj_normal, view_dir), _RimPower);
				re_view_blinn = smoothstep(0.5, 1.0, re_view_blinn); //re_view_blinn为0->0.5时不要高光
				//re_view_blinn = saturate((re_view_blinn - 0.5) / (1.0 - 0.5));
				fixed3 rim_result = _RimColor.rgb * re_view_blinn;
				
				fixed4 final_color = fixed4(0,0,0,0);
				fixed4 mix_color;
				fixed percent;
				fixed layer_exist;
				fixed front_exist = 0;
				fixed liquid_h = i.world_pos.y;
				
				fixed threshold = _Layer1Amount + _Layer2Amount + _Layer3Amount + _Layer4Amount + _Layer5Amount + wobble_y;
				fixed grad_base = _Layer1Amount + _Layer2Amount + _Layer3Amount + _Layer4Amount + wobble_y;
				
				//Layer4-5
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				grad_base -= 0;
				percent = (liquid_h - grad_base) / _Layer5Amount;
				percent = saturate(percent / _GradientRange);
				mix_color = lerp(_Layer4Color, _Layer5Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer3-4
				threshold -= _Layer5Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				grad_base -= _Layer4Amount;
				percent = (liquid_h - grad_base) / _Layer4Amount;
				percent = saturate(percent / _GradientRange);
				mix_color = lerp(_Layer3Color, _Layer4Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer2-3
				threshold -= _Layer4Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				grad_base -= _Layer3Amount;
				percent = (liquid_h - grad_base) / _Layer3Amount;
				percent = saturate(percent / _GradientRange);
				mix_color = lerp(_Layer2Color, _Layer3Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer1-2
				threshold -= _Layer3Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;
				
				grad_base -= _Layer2Amount;
				percent = (liquid_h - grad_base) / _Layer2Amount;
				percent = saturate(percent / _GradientRange);
				mix_color = lerp(_Layer1Color, _Layer2Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer1
				threshold -= _Layer2Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				final_color = lerp(final_color, _Layer1Color, layer_exist);

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