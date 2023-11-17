Shader "Learn/ToonShading" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Ramp ("Ramp Texture", 2D) = "white" {} //渐变纹理
		_Outline ("Outline", Range(0, 1)) = 0.1 //轮廓线宽度
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1) //轮廓线颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1) //高光颜色
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01 //高光范围系数
	}
    SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass {
			NAME "OUTLINE"
			
			Cull Front //只渲染背面
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			float _Outline;
			fixed4 _OutlineColor;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			}; 
			
			struct v2f {
			    float4 pos : SV_POSITION;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				float3 viewPos = UnityObjectToViewPos(v.vertex); //位置转换到观察空间
				float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); //法线转换到观察空间
				viewNormal.z = -0.5; //将观察空间法线的z值固定
				viewPos = viewPos + float4(normalize(viewNormal), 0) * _Outline; //按法线方向移动扩展
				o.pos = mul(UNITY_MATRIX_P, float4(viewPos, 1.0)); //转换到裁剪空间
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				return float4(_OutlineColor.rgb, 1);               
			}
			
			ENDCG
		}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Back

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Ramp;
			fixed4 _Specular;
			fixed _SpecularScale;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos( v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal  = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
				
				fixed4 c = tex2D (_MainTex, i.uv);
				fixed3 albedo = c.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				halfLambert *= atten;
				fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(halfLambert, halfLambert)).rgb;
				
				fixed spec = dot(worldNormal, worldHalfDir);
				fixed w = fwidth(spec) * 2.0; //获得一个像素级别的较小值
				spec = lerp(0, 1, smoothstep(-w, w, spec - (1 - _SpecularScale))); //_SpecularScale越大，高光范围越大
				fixed3 specular = _Specular.rgb * spec * step(0.0001, _SpecularScale);
				
				return fixed4(ambient + diffuse + specular * atten, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}