Shader "Learn/Mirror"
{
    Properties
    {
        _MainTex ("实时渲染纹理", 2D) = "white" {}
    }

    SubShader
    {
        Tags {"Queue"="Geometry" "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;

            struct a2v{
                float4 vertex:POSITION;
                float3 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                o.uv.x = 1-o.uv.x; //模拟镜子左右翻转
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                return tex2D(_MainTex,i.uv);
            }

            ENDCG
        }
    }
    Fallback off
}