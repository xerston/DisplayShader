Shader "Learn/FresnelReflection"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _FresnelScale ("Fresnel Scale", Range(0,1)) = 1.0
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}
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
            };

            samplerCUBE _Cubemap;
            fixed4 _Color;
            float _FresnelScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                //因为只需要反射视角的方向变量采样，所以无需再进行归一化
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                
                //计算视角得反射方向（即反射进视角得光线反向), 入射光线需要指向顶点，故取反
                o.worldViewRefractDir = reflect(-o.worldViewDir,o.worldNormal);
                
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 根据视角得折射方向对 Cubemap 采样
                fixed4 cubeMapColor = texCUBE(_Cubemap, i.worldViewRefractDir);
                //Cubemap 采样颜色
                fixed3 reflectLightColor = cubeMapColor.rgb;

                //计算菲涅尔反射系数
                fixed3 fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal),5);
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldLightDir, worldNormal));
                fixed3 color = ambient + lerp(diffuse, reflectLightColor, saturate(fresnel)) * atten;
                
                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
}