Shader "Learn/Reflection"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _ReflectColor ("Reflection Color", Color) = (1,1,1,1)
        _ReflectAmount ("Reflect Amount", Range(0,1)) = 1.0
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}
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
                float3 worldViewReflectDir : TEXCOORD3;
				//SHADOW_COORDS(4) //不需要接收阴影时直接注释
            };

            samplerCUBE _Cubemap;
            fixed4 _Color;
            fixed4 _ReflectColor;
            float _ReflectAmount;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                //计算视角得反射方向（即反射进视角得光线反向）reflect需要指向顶点则需要视角取反
                o.worldViewReflectDir = reflect(-o.worldViewDir, o.worldNormal);
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

                // 根据视角得反射方向对 Cubemap 采样
                fixed4 cubeMapColor = texCUBE(_Cubemap, i.worldViewReflectDir);
                //Cubemap 采样颜色 和 定义的反射颜色混合
                fixed3 reflectionColor = cubeMapColor.rgb * _ReflectColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 col = ambient + lerp(diffuse, reflectionColor, _ReflectAmount) * atten;
                
                return fixed4(col, 1.0);
            }
            ENDCG
        }
    }
    //FallBack "Diffuse" //不需要投射阴影时直接注释
}