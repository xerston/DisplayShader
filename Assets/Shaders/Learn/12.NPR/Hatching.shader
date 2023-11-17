// 素描风格效果
Shader "Learn/Hatching"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _TileFactor ("Tile Factor", Range(0, 10)) = 1 // 纹理的平铺系数，越大则素描线条越密
        _Outline ("Outline", Range(0, 1)) = 0.1 // 描边宽度
		// 6张素描纹理
        _Hatch0 ("Hatch 0", 2D) = "white" { }
        _Hatch1 ("Hatch 1", 2D) = "white" { }
        _Hatch2 ("Hatch 2", 2D) = "white" { }
        _Hatch3 ("Hatch 3", 2D) = "white" { }
        _Hatch4 ("Hatch 4", 2D) = "white" { }
        _Hatch5 ("Hatch 5", 2D) = "white" { }
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

        UsePass "Learn/ToonShading/OUTLINE" //使用描边

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"

            fixed4 _Color;
            float _TileFactor;
            sampler2D _Hatch0;
            sampler2D _Hatch1;
            sampler2D _Hatch2;
            sampler2D _Hatch3;
            sampler2D _Hatch4;
            sampler2D _Hatch5;

            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float4 texcoord: TEXCOORD0;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                fixed3 hatchWeights0: TEXCOORD1; // 存储6张纹理的权重
                fixed3 hatchWeights1: TEXCOORD2; // 存储6张纹理的权重
                float3 worldPos: TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v)
            {
                v2f o;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uv = v.texcoord.xy * _TileFactor;
                
                fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed lambert = max(0, dot(worldLightDir, worldNormal));
                
                o.hatchWeights0 = fixed3(0, 0, 0);
                o.hatchWeights1 = fixed3(0, 0, 0);

                //  将漫反射系数diff缩放到[O, 7] 范围
                // 们把[O, 7] 区间均匀划分为7个子区间 ，通过判断 hatchFactor 所处的子区间来计算对应的纹理混合权重。
                float hatchFactor = lambert * 7;
                if (hatchFactor > 6) //最亮
                {
                    // 纯白色，什么也不做
                }
                else if (hatchFactor > 5)
                {
                    o.hatchWeights0.x = hatchFactor - 5; //取小数部分为权重
					//相邻权重是纯白色的权重，片元着色器会计算
                }
                else if (hatchFactor > 4)
                {
                    o.hatchWeights0.x = hatchFactor - 4; //取小数部分为权重
                    o.hatchWeights0.y = 1 - o.hatchWeights0.x; //计算相邻权重
                }
                else if (hatchFactor > 3)
                {
                    o.hatchWeights0.y = hatchFactor - 3; //取小数部分为权重
                    o.hatchWeights0.z = 1 - o.hatchWeights0.y; //计算相邻权重
                }
                else if (hatchFactor > 2)
                {
                    o.hatchWeights0.z = hatchFactor - 2; //取小数部分为权重
                    o.hatchWeights1.x = 1 - o.hatchWeights0.z; //计算相邻权重
                }
                else if (hatchFactor > 1)
                {
                    o.hatchWeights1.x = hatchFactor - 1; //取小数部分为权重
                    o.hatchWeights1.y = 1 - o.hatchWeights1.x; //计算相邻权重
                }
                else //最暗
                {
                    o.hatchWeights1.y = hatchFactor; //取小数部分为权重
                    o.hatchWeights1.z = 1 - o.hatchWeights1.y; //计算相邻权重
                }

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i): SV_TARGET
            {
                //采样素描纹理，并和它们对应的权重值相乘得到每张纹理的采样颜色
                fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchWeights1.z;

                //获取混合权重的纯白色
                fixed4 whiteColor = fixed4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z -
                i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);

				//混合纯白与素描色
                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;

                // 计算阴影值和光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(hatchColor.rgb * _Color.rgb * atten, 1);
            }

            ENDCG

        }
    }
    FallBack "Diffuse"
}