Shader "Learn/EdgeDetectDepthNormals"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0		//边缘线强度	为0时边缘会叠加在原渲染图像上，为1只显示边缘
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
		_Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)		//x、y分量分别对应法线和深度的检测灵敏度
	}
	SubShader
	{
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;
		
		sampler2D _CameraDepthNormalsTexture; //深度法线纹理
		
		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0; //定义数组为5的纹理坐标数组
		};
		  
		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			o.uv[0] = uv;

			//深度纹理采样坐标差异化处理
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif

			//存储我们需要采样的另外4个纹理坐标
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

			return o;
		}
		
		half CheckSame(half4 center, half4 sample)
		{
			//分别提取两个采样结果得到法线和深度
			half2 centerNormal = center.xy;
			float centerDepth = DecodeFloatRG(center.zw);
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);
			
			//法线差异，不需要解码得到真的法线值，因为我们只需比较差异
			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x; //差值的绝对值，乘以灵敏度
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1; //把差值的每个分量相加再和阙值比较
			//深度差异
			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y; //差值的绝对值，乘以灵敏度
			int isSameDepth = diffDepth < 0.1 * centerDepth; //深度差异小于当前深度的1/10就算差异小
			
			//返回值：1代表差异小，不是边；0代表差异大，是边
			return isSameNormal * isSameDepth ? 1.0 : 0.0; //只要有一个差异大就是边
		}
		
		fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target
		{
			//对4个纹理坐标进行深度+法线采样
			half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);		
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
			
			//使用Roberts算子对比像素差异
			half edge = 1.0;
			edge *= CheckSame(sample1, sample2);
			edge *= CheckSame(sample3, sample4);
			
			//边缘颜色和原图像颜色间选择
			fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
			//边缘颜色和纯色背景间选择
			fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
			//原图像颜色和纯色背景混合，边缘颜色不变
			fixed4 finalColor = lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
			
			return finalColor;
		}
		
		ENDCG
		
		Pass
		{ 
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM      
			
			#pragma vertex vert  
			#pragma fragment fragRobertsCrossDepthAndNormal
			
			ENDCG  
		}
	}
	FallBack Off
}