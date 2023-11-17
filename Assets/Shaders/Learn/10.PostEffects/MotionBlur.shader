Shader "Learn/MotionBlur"
{
	Properties
	{
		_MainTex ("Base(RGB)", 2D) = "white" {}
		_BlurAmount("Blur Amount" , Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D  _MainTex;
		fixed _BlurAmount;

		struct v2f
		{
			float4 pos:SV_POSITION;
			half2 uv:TEXCOORD0;
		};

		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			return o;
		}

		//定义两个片元着色器，为了保护A通道不受到混合的影响
		//渲染RGB通道
		fixed4 fragRGB(v2f i) : SV_Target
		{
			//对图像进行采样，把A通道的值设置为_BlurAmount,以便在后面混合时可以使用它的透明通道进行混合
			return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount); 
		}
		//渲染A通道
		half4 fragA(v2f i) : SV_Target
		{
			return tex2D(_MainTex, i.uv);
		}
		ENDCG

		ZTest Always Cull Off ZWrite Off

		//之所以把把A通道和RGB通道分开，是因为在更新RGB时我们需要设置它的A通道的来混合图像，但又不希望A通道的值写入渲染纹理中

		//用来更新渲染RGB通道
		Pass
		{
			//混合 A (1-A) 这里是混合的关键
			Blend SrcAlpha OneMinusSrcAlpha
			//颜色遮罩 RGB
			ColorMask RGB

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragRGB
			ENDCG 
		}

		//用来更新渲染A通道
		Pass
		{
			//混合 1 0
			Blend One Zero
			//颜色遮罩 A
			ColorMask A

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragA
			ENDCG
		}
	}
	Fallback Off
}