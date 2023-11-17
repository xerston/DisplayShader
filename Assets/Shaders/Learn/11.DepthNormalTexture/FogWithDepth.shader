Shader "Learn/FogWithDepth"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		float4x4 _FrustumCornersRay;
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture; //深度纹理
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
		
		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;    //存储插值后的像素向量
		};
		
		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			//平台差异化处理
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
			
			//后处理的平面只有4个顶点，按照位置选择对应向量
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

			//平台差异化处理
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index; //输入图像是翻转的，那么输出图像也得是翻转的
			#endif
			
			//输出向量进行插值
			o.interpolatedRay = _FrustumCornersRay[index];
				 	 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target
		{
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth)); //计算线性深度值
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz; //计算像素的世界位置

			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); //世界空间位置越高，雾效越少
			fogDensity = saturate(fogDensity * _FogDensity); //整体雾效浓度
			////限制最高浓度为0.5
			//fogDensity = fogDensity * 0.5;
			
			//显示雾效
			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		
		ENDCG
		
		Pass {
			ZTest Always Cull Off ZWrite Off
			     	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}