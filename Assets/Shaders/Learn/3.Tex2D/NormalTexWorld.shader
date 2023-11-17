Shader "Learn/NormalTexWorld"
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
                float4 T2W0 : TEXCOORD1;
                float4 T2W1 : TEXCOORD2;
                float4 T2W2 : TEXCOORD3;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);
                o.uv.xy = TRANSFORM_TEX(a.uv.xy, _MainTex); //主纹理的采样坐标
                o.uv.zw = TRANSFORM_TEX(a.uv.xy, _BumpTex); //法线纹理的采样坐标

                fixed3 worldPos = mul(unity_ObjectToWorld, a.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(a.normal); //世界空间法线(已归一化)
                fixed3 worldTangent = UnityObjectToWorldDir(a.tangent); //世界空间切线(已归一化)
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * a.tangent.w; //世界空间副切线
                //切线空间的坐标轴顺序不能放错
                o.T2W0 = fixed4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.T2W1 = fixed4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.T2W2 = fixed4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 worldPos = fixed3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos)); //光照方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos)); //观察方向
                
                fixed4 bumpColor = tex2D(_BumpTex, i.uv.zw); //采样法线纹理
                //fixed3 tangentNormal = bumpColor.xy * 2 - 1;
                fixed3 tangentNormal = UnpackNormal(bumpColor);
                tangentNormal.xy *= _BumpDegree; //凹凸程度
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy))); //计算变化后的z值
                
				//这三个向量可以组成标准正交基，因此T2W_matrix是正交矩阵，不需要使用逆转置
                float3x3 T2W_matrix = float3x3(i.T2W0.xyz, i.T2W1.xyz, i.T2W2.xyz); //切线空间转世界空间矩阵(3行构建矩阵)
                fixed3 worldNormal = normalize(half3(mul(T2W_matrix, tangentNormal))); //转换到世界空间
                
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                //fixed half_lambert = 0.5 * dot(worldNormal, lightDir) + 0.5;
                //fixed3 diffuse = albedo.rgb * _LightColor0.rgb * half_lambert;
                fixed lambert = max(0, dot(worldNormal, lightDir));
                fixed3 diffuse = albedo.rgb * _LightColor0.rgb * lambert;
                
                fixed3 deuceDir = normalize(viewDir + lightDir);
                fixed blinn = pow(max(0, dot(deuceDir, worldNormal)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn;

                fixed3 color = ambient + diffuse + specular;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
