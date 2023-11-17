Shader "Learn/LightShadowUpdate"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
			#include "AutoLight.cginc"
			//Base Pass的必要声明
			#pragma multi_compile_fwdbase

            fixed4 _Diffuse;
            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
				SHADOW_COORDS(2)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal, (fixed3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_SHADOW(o);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed lambert = max(0, dot(worldNormal, worldLight));
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * lambert;

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

				//blinn-phong经验公式计算
				fixed3 halfDir = normalize(worldLight + viewDir);
				fixed3 blinn_phong = pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn_phong;

				UNITY_LIGHT_ATTENUATION(atten, i ,i.worldPos);
                fixed3 color = ambient + (diffuse + specular) * atten;
                return fixed4(color, 1.0);
            }

            ENDCG
        }

		Pass
		{
			Tags{"LightMode" = "ForwardAdd"}

			//ForwardAdd需要混合模式，否则直接覆盖Forwbase的结果
			Blend One One
			
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
			//unity_WorldToLight、_LightTexture都来自AutoLight.cginc
            #include "AutoLight.cginc"
			//Additional Pass的必要声明
			//#pragma multi_compile_fwdadd
			#pragma multi_compile_fwdadd_fullshadows

            fixed4 _Diffuse;
            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
				SHADOW_COORDS(2)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal, (fixed3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_SHADOW(o);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

				//判断当前处理的是否为平行光
				#ifdef USING_DIRECTIONAL_LIGHT
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				#else
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				#endif

                fixed lambert = max(0, dot(worldNormal, worldLight));
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * lambert;

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

				//blinn-phong经验公式计算
				fixed3 halfDir = normalize(worldLight + viewDir);
				fixed3 blinn_phong = pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn_phong;
				
				////点光源
				//#if defined (POINT)
				////转换成光源空间坐标
				//float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				////使用lightCoord长度平方从衰减纹理中取得衰减值
				////UNITY_ATTEN_CHANNEL是衰减值所在的纹理通道，或是a或是r，取决于目标平台
				//fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).xx).UNITY_ATTEN_CHANNEL;
				////聚光灯(没看懂，以后再解析)
				//#elif defined (SPOT)
				//float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				//fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w;
				//atten = atten * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).xx).UNITY_ATTEN_CHANNEL;
				////平行光
				//#else
				//fixed atten = 1.0; //平行光衰减函数为常数1
				//#endif
				
				UNITY_LIGHT_ATTENUATION(atten, i ,i.worldPos);
                fixed3 color = (diffuse + specular) * atten;
                return fixed4(color, 1.0);
            }

            ENDCG
		}
    }

    FallBack "Specular"
}
