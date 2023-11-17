Shader "Learn/SequenceAnim"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_RowAmount("RowAmount",float) = 4
		_ColumnAmount("ColumnAmount",float) = 4
		_Speed("Speed",Range(1,100)) = 30
    }
    SubShader
    {
		//帧序列图像通常是透明纹理，使用透明混合
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjection"="True" }
        LOD 100

        Pass
        {
	        ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _RowAmount;
            float _ColumnAmount;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float time = floor(_Time.y * _Speed);//通过_Speed控制时间的快慢，如果_Speed为30则意味着1/30秒变化一帧
				float row = floor(time / _RowAmount);//表示当前时间应该跑到第几行了
				float column = time - row * _RowAmount;//表示当前时间应该跑到第几列了
				half2 uv = i.uv + half2(column, -row);//往右走列数增加，往下走行数减少，最好在unity中自己测试一下
				uv.x /= _RowAmount;//将原本采样UV的x缩小_RowAmount倍
				uv.y /= _ColumnAmount;//将原本采样UV的y缩小_ColumnAmount倍
                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            ENDCG
        }
    }
}