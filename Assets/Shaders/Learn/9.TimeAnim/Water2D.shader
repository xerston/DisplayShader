Shader "Learn/Water2D"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _Magnitude("Distortion Magnitude", Float) = 1 //波动幅度
        _Frequency("Distortion Frequency", Float) = 1 //波动频率
        _InvWaveLength("Distortion Inverse Wave Length", Float) = 1 //波长的倒数，该值越大波长越小
        _Speed("Speed", Float) = 0.5
    }
    SubShader
    {
		//使用透明混合
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True"}
 
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
 
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
 
            #include "UnityCG.cginc" 
 
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;
 
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
 
            v2f vert(a2v v) 
            {
                v2f o;

                float4 offset;
                offset.yzw = float3(0.0, 0.0, 0.0);
				//模型顶点的xyz之和共同决定sin值结果(波形)，最后加上_Frequency * _Time.y使波形随时间移动
                offset.x = sin((v.vertex.x + v.vertex.y + v.vertex.z) * _InvWaveLength + _Frequency * _Time.y);
				offset.x *= _Magnitude; //倍乘波动幅度
                o.pos = UnityObjectToClipPos(v.vertex + offset);

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv += float2(0.0, _Time.y * _Speed); //使纹理采样y值按时间偏移

                return o;
            }
 
            fixed4 frag(v2f i) : SV_Target 
            {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;
 
                return c;
            }
 
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}