Shader "Custom/4LayerGradientLiquid2"
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

		_ChangeRange("Change Range", Range(0,1)) = 0.1

        _TopColor("Top Color", Color) = (1,1,1,1)

		_RimColor("Rim Color", Color) = (1,1,1,1)
	    _RimPower("Rim Power", Range(0,10)) = 0.0

		_AlphaPower("Alpha Power", Range(0.8, 256)) = 20.0
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
			#include "UnityCG.cginc"

			float _Layer1Amount;
			fixed _Layer2Amount;
			fixed _Layer3Amount;
			fixed _Layer4Amount;
			fixed4 _TopColor;

			struct appdata
			{
				float4 vertex : POSITION;
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
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed liquid_h = i.world_pos.y * 0.5 + 0.5;
				fixed threshold = _Layer1Amount + _Layer2Amount + _Layer3Amount + _Layer4Amount;
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
			#include "UnityCG.cginc"

			fixed4 _Layer1Color;
			float _Layer1Amount;

			fixed4 _Layer2Color;
			fixed _Layer2Amount;

			fixed4 _Layer3Color;
			fixed _Layer3Amount;

			fixed4 _Layer4Color;
			fixed _Layer4Amount;

			fixed _ChangeRange;

			float4 _RimColor;
			float _RimPower;

			float _AlphaPower;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 world_pos : TEXCOORD1;
				float3 obj_normal : TEXCOORD2;
				float3 view_dir : TEXCOORD3;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				float3 world_pos = mul(unity_ObjectToWorld, v.vertex.xyz);
				
				o.world_pos = world_pos;
				o.obj_normal = v.normal;
				o.view_dir = ObjSpaceViewDir(v.vertex);
				return o;
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
				
				fixed4 final_color = fixed4(0,0,0,0);
				fixed4 mix_color;
				fixed threshold;
				fixed percent;
				fixed layer_exist;
				fixed front_exist = 0;
				fixed liquid_h = i.world_pos.y * 0.5 + 0.5;

				//Layer3-4
				threshold = _Layer1Amount + _Layer2Amount + _Layer3Amount + _Layer4Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				percent = (liquid_h - (_Layer1Amount + _Layer2Amount + _Layer3Amount)) / _Layer4Amount;
				percent = saturate(percent / _ChangeRange);
				mix_color = lerp(_Layer3Color, _Layer4Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer2-3
				threshold = _Layer1Amount + _Layer2Amount + _Layer3Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				percent = (liquid_h - (_Layer1Amount + _Layer2Amount)) / _Layer3Amount;
				percent = saturate(percent / _ChangeRange);
				mix_color = lerp(_Layer2Color, _Layer3Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer1-2
				threshold = _Layer1Amount + _Layer2Amount;
				layer_exist = step(liquid_h, threshold);
				front_exist += layer_exist;

				percent = (liquid_h - _Layer1Amount) / _Layer2Amount;
				percent = saturate(percent / _ChangeRange);
				mix_color = lerp(_Layer1Color, _Layer2Color, percent);
				final_color = lerp(final_color, mix_color, layer_exist);

				//Layer1
				layer_exist = step(liquid_h, _Layer1Amount);
				front_exist += layer_exist;
				final_color = lerp(final_color, _Layer1Color, layer_exist);

				//合成颜色
				final_color.rgb += rim_result;
				final_color.a = (1 - pow(dot(obj_normal, view_dir), _AlphaPower)) * saturate(front_exist);

				return final_color;
			}

			ENDCG
        }
    }

	FallBack "Specular"
}