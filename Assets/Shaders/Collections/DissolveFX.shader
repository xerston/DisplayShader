Shader "Custom/DissolveFX"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color("Color Tint", color) = (1,1,1,1)
		_MainPercent("Main Percent", Range(0, 1)) = 0.5

		_DissolveTex("Dissolve Tex", 2D) = "white" {}
		_DissolveColor("Dissolve Color", color) = (1,1,1,1)
		_DissolveDegree("Dissolve Degree", range(0, 1)) = 0.5
		
		_Edge1Color("Edge1 Color", color) = (1,0,0,1)
		_Edge1Percent("Edge1 Percent", Range(0, 1)) = 0.5

		_Edge2Color("Edge2 Color", color) = (0,0,1,1)
    }
    SubShader
    {
		AlphaToMask On
		//Cull Off

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
			fixed4 _Color;
			fixed _MainPercent;

			sampler2D _DissolveTex;
			fixed4 _DissolveTex_ST;
			fixed4 _DissolveColor;
			fixed _DissolveDegree;
			
			fixed4 _Edge1Color;
			fixed _Edge1Percent;

			fixed4 _Edge2Color;

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
				fixed3 obj_normal : TEXCOORD1;
				fixed3 light_dir : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.xy, _DissolveTex);
				o.obj_normal = v.normal;
				o.light_dir = ObjSpaceLightDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 albedo = tex2D(_MainTex, i.uv.xy) * _Color;
				fixed di_mask = tex2D(_DissolveTex, i.uv.zw).x;
				
				fixed percent = di_mask; //保留正向数据
				//除一下使数据反向，下面进行反向比较
				//例如di_mask的(0.7, 1)会变成(1, 0.7)，若_MainPercent = 0.8，
				//那么主颜色将在percent的(1, 0.9)区间着色
				di_mask = _DissolveDegree / di_mask;
				fixed4 final_color = _Edge2Color;
				//得出0或1再使用lerp选择颜色
				//选择边缘颜色1，将覆盖上层
				fixed edge1_exist = step(di_mask, _Edge1Percent + _MainPercent);
				final_color = lerp(final_color, _Edge1Color, edge1_exist);
				//选择主颜色，将覆盖上层
				fixed main_exist = step(di_mask, _MainPercent);
				final_color = lerp(final_color, albedo, main_exist);
				//正向比较，使用剔除(透明化)
				fixed dissolve_exist = step(percent, _DissolveDegree);
				final_color = lerp(final_color, _DissolveColor, dissolve_exist);
				
				fixed3 obj_normal = normalize(i.obj_normal);
				fixed3 light_dir = normalize(i.light_dir);
				fixed half_lambert = 0.5 * dot(light_dir, obj_normal) + 0.5;
				fixed4 diffuse = final_color * _LightColor0 * half_lambert;
				diffuse.a = final_color.a;

                return fixed4(diffuse);
            }
            ENDCG
        }
    }
}
