Shader "Learn/Glass" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}    //材质纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}    //法线纹理
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}    //模拟反射的环境纹理
		_Distortion ("Distortion", Range(0, 100)) = 10    //控制模拟折射时图像的扭曲程度
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0    //控制折射程度，0=只包含反射，1=只包含折射
	}
	SubShader {
		//设置渲染队列为Transparent，确保所有不透明物体渲染完成后抓取屏幕
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		//在该物体渲染前抓取屏幕图像，保存到名为_RefractionTex的渲染纹理中
		GrabPass { "_RefractionTex" }
		
		Pass {
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex; //GrabPass中定义的渲染纹理
			float4 _RefractionTex_TexelSize; //纹理的纹素大小，例如一个256x512的纹理的纹素大小为(1/256, 1/512)
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
			    float4 TtoW1 : TEXCOORD3;
			    float4 TtoW2 : TEXCOORD4;
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.scrPos = ComputeGrabScreenPos(o.pos); //计算屏幕空间下的坐标，并保留裁剪空间的zw
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //乘tangent.w选择切线方向
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
                //解压获取法线(切线空间)
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				
				/*使用offset对屏幕图像的采样坐标进行偏移，
				  其中bump.xy * _RefractionTex_TexelSize.xy作为一个偏移单位，_Distortion作为偏移Scale，
				  这种偏移模拟类似折射的效果，偏移越大背后的物体形变越大*/
				float2 offset = _Distortion * bump.xy * _RefractionTex_TexelSize.xy;
				//i.scrPos.xy需要透视除法得到真正的屏幕采样坐标(见ComputeGrabScreenPos定义)
				/*亲测i.scrPos.z/i.scrPos.w的值范围是[0, 1]，该值在观察空间下近裁剪面处为1，远裁剪面处为0
				  正常来说i.scrPos.z / i.scrPos.w的值范围应该是[-1, 1]，这里先留个疑问
				  也就是说物体离相机越近，扭曲程度就越大*/
				i.scrPos.xy = (offset * i.scrPos.z + i.scrPos.xy) / i.scrPos.w;

				//屏幕颜色采样
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy).rgb;
				
				//法线从切线空间转换到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				
				//反射和折射混合
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}