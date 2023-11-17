Shader "Learn/RefractionSpecular"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _RefractColor ("Refraction Color", Color) = (1,1,1,1)
        _RefractAmount ("Refraction Amount", Range(0,1)) = 1.0
        _RefractRatio ("Refraction Ratio", Range(0.1,1)) = 0.5
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}
		
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldViewRefractDir : TEXCOORD3;
				//SHADOW_COORDS(4) //不需要接收阴影时直接注释
            };

            samplerCUBE _Cubemap;
            fixed4 _Color;
            fixed4 _RefractColor;
            float _RefractAmount;
            float _RefractRatio;
			
            fixed4 _Specular;
            fixed _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                //因为只需要反射视角的方向变量采样，所以无需再进行归一化
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                
                /*
                  refract(I,N,eta)  计算折射向量，I 为入射光线，N 为法向量，eta 为折射系数；
                其中 I 和 N 必须被归一化，如果 I 和 N 之间的夹角太大，则返回（0，0，0），也就是没有折射光线；I 是指向顶点的；(函数只对三元向量有效)
                */
                //计算视角得折射方向（即折射进视角得光线反向), 入射光线需要指向顶点，故取反
                o.worldViewRefractDir = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);
                
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 diffuse = _LightColor0.rgb * _Color * saturate(dot(worldLightDir, worldNormal));

                // 根据视角得折射方向对 Cubemap 采样
                fixed4 cubeMapColor = texCUBE(_Cubemap, i.worldViewRefractDir);
                //Cubemap 采样颜色 和 定义的反射颜色混合
                fixed3 refracttionColor = cubeMapColor.rgb * _RefractColor.rgb;

				//blinn-phong经验公式计算
				fixed3 halfDir = normalize(worldLightDir + worldViewDir);
				fixed3 blinn_phong = pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * blinn_phong;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 col = ambient + (lerp(diffuse, refracttionColor, _RefractAmount) + specular) * atten;
                
                return fixed4(col, 1.0);
            }
            ENDCG
        }
    }
    //FallBack "Diffuse" //不需要投射阴影时直接注释
}