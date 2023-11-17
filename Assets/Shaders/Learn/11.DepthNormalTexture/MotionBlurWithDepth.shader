Shader "Learn/MotionBlurWithDepth"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture; //深度纹理
		float4x4 _CurrentViewProjectionInverseMatrix; //当前帧的VP矩阵的逆矩阵
		float4x4 _PreviousViewProjectionMatrix; //上一帧的VP矩阵
		half _BlurSize;
		
		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
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
					 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target
		{
			// 对深度纹理进行采样，得到深度值
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 构建像素的NDC坐标H，同理得到NDC的xy分量，范围均为[-1,1]
			//屏幕纹理的uv和屏幕位置是一致的
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			//从NDC转换到世界空间(获得当前帧像素的世界位置)
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			float4 worldPos = D / D.w; //齐次除法
			
			float4 currentPos = H;
			//从世界空间转换到NDC(获得上一帧像素的NDC位置)
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			previousPos /= previousPos.w; //齐次除法
			
			//前一帧和当前帧在屏幕空间下的位置差，得到当前像素的速度
			//想象相机下移时，前一帧的位置相当于上移，那么运动方向向下
			//等同于float2 velocity = (currentPos.xy * 0.5 + 0.5) - (previousPos.xy * 0.5 + 0.5);
			float2 velocity = (currentPos.xy - previousPos.xy) * 0.5;
			
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			//当前像素向运动方向混合颜色
			uv += velocity * _BlurSize;
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}
		
		ENDCG
		
		Pass
		{      
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM  
			
			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
	}
	FallBack Off
}