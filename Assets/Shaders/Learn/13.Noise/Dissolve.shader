Shader "Learn/Dissolve"
{
	Properties
	{
		_BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0 //消融程度
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1 //燃烧效果的线宽
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {} //法线纹理
        _BumpDegree("Bump Degree", Float) = 1.0 //凹凸程度
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1) //火焰边缘颜色1
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1) //火焰边缘颜色2
		_NoiseMap("Noise Map", 2D) = "white"{} //噪声纹理
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			Cull Off //正反面都被渲染
			
			CGPROGRAM
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			fixed _BurnAmount;
			fixed _LineWidth;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpDegree;
			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;
			sampler2D _NoiseMap;
			float4 _NoiseMap_ST;
			
			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvNoiseMap : TEXCOORD2;
				float3 tangentLightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)
			};
			
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvNoiseMap = TRANSFORM_TEX(v.texcoord, _NoiseMap);
				
				TANGENT_SPACE_ROTATION;
  				o.tangentLightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
  				
  				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  				
  				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 noise = tex2D(_NoiseMap, i.uvNoiseMap).rgb;
				
				clip(noise.r - _BurnAmount);
				
				float3 tangentLightDir = normalize(i.tangentLightDir);
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));
                tangentNormal.xy *= _BumpDegree; //凹凸程度
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy))); //计算变化后的z值
				
				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//燃烧线宽内，在两个颜色间渐变
				fixed t = 1 - smoothstep(0, _LineWidth, noise.r - _BurnAmount);
				fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
				burnColor = pow(burnColor, 5); //颜色降暗，接近烧焦颜色
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.01, _BurnAmount));
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
		
		//阴影计算，简单的Alpha测试阴影
		Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_shadowcaster
			
			#include "UnityCG.cginc"
			
			fixed _BurnAmount;
			sampler2D _NoiseMap;
			float4 _NoiseMap_ST;
			
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uvNoiseMap : TEXCOORD1;
			};
			
			v2f vert(appdata_base v) {
				v2f o;
				
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				
				o.uvNoiseMap = TRANSFORM_TEX(v.texcoord, _NoiseMap);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_NoiseMap, i.uvNoiseMap).rgb;
				
				clip(burn.r - _BurnAmount);
				
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}