Shader "Learn/Billboard"
{
    Properties
    {
        _MainTex ("_Main Tex", 2D) = "white" {}
        _Color ("_Color Tint", Color) = (1,1,1,1)
        _VecticalBillborading ("Vertical Restraints",Range(0,1)) = 1 //用于调整是固定法线方向，还是固定向上的方向，即垂直约束
    }
    SubShader
    {
		//使用透明混合
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnorePrjectot" = "True" "DisableBatching" = "True" }

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off //关闭剔除功能，保证背面也能显示
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };
 
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VecticalBillborading;
 
            v2f vert (a2v v)
            {
                v2f o;
                float3 center = float3(0,0,0); //使用模型空间的原点作为锚点
                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)); //模型空间下的相机的位置
                float3 normalDir = viewer - center;
                //当_VecticalBillborading为1时，意味着法线方向一直朝向相机。
                //当_VecticalBillborading为0时，意味着法线方向的Y轴为0，即分布在XZ的平面上。
                normalDir.y = normalDir.y * _VecticalBillborading;
                normalDir = normalize(normalDir);
                //如果normalDir是(0,1,0),那我们需要矫正upDir为前方向防止他们平行
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1) : float3(0,1,0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));

				//按照计算好的正交基，旋转顶点
                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
                o.pos = UnityObjectToClipPos(float4(localPos,1));
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }
 
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex,i.uv);
                c.rgb *= _Color.rgb;
                return c;
            }
            ENDCG
        }
    }
 
    Fallback "Transparent/VertexLit"
}