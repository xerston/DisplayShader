Shader "Custom/XRay/XRayMask"
{
    Properties
    {
    }
    SubShader
    {
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry-1" }
        Pass
        {
			ColorMask 0
			Stencil
			{
				Ref 1
				Comp Always
				Pass Replace
			}
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata a)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(a.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return fixed4(1, 1, 1, 1);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}
