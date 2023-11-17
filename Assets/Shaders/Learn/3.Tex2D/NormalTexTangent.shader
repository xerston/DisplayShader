Shader "Learn/NormalTexTangent"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {} //主纹理
        _Color("Color Tint", Color) = (1,1,1,1)

        _BumpTex("Normal Map", 2D) = "bump" {} //法线纹理
        _BumpDegree("Bump Degree", Float) = 1.0 //凹凸程度

        _Specular("Specular", Color) = (1,1,1,1) //高光颜色
        _Gloss("Gloss", Range(8.0, 256)) = 20.0 //高光程度
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

            sampler2D _MainTex;
            fixed4 _MainTex_ST; //代表_Albedo的缩放和偏移，即外部可调节的4个值
            fixed4 _Color;
            
            sampler2D _BumpTex;
            fixed4 _BumpTex_ST;
            fixed _BumpDegree;

            fixed4 _Specular;
            fixed _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; //顶点法线
                float4 tangent : TANGENT; //顶点切线
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex); //主纹理的采样坐标
                o.uv.zw = TRANSFORM_TEX(v.uv.xy, _BumpTex); //法线纹理的采样坐标

                //float3 objectBinormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w; //模型空间副切线
				//float3x3 rotation = float3x3(v.tangent.xyz, objectBinormal, v.normal);
				TANGENT_SPACE_ROTATION; //内置函数实现上面两行代码，获取转换矩阵rotation

				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir); //光照方向
                fixed3 tangentViewDir = normalize(i.viewDir); //观察方向
                
                fixed4 bumpColor = tex2D(_BumpTex, i.uv.zw); //采样法线纹理
                //fixed3 tangentNormal = bumpColor.xy * 2 - 1;
                fixed3 tangentNormal = UnpackNormal(bumpColor);
                tangentNormal.xy *= _BumpDegree; //凹凸程度
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy))); //计算变化后的z值
                
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                //fixed half_lambert = 0.5 * dot(tangentNormal, tangentLightDir) + 0.5;
                //fixed3 diffuse = albedo.rgb * _LightColor0.rgb * half_lambert;
                fixed lambert = max(0, dot(tangentNormal, tangentLightDir));
                fixed3 diffuse = albedo.rgb * _LightColor0.rgb * lambert;
                
                fixed3 deuceDir = normalize(tangentViewDir + tangentLightDir);
                fixed blinn = pow(max(0, dot(deuceDir, tangentNormal)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
