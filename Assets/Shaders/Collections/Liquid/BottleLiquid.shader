Shader "Custom/BottleLiquid"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_Tint("Tint", Color) = (1,1,1,1)

        _FillAmount("Fill Amount", Range(-10,10)) = 0.0
		_WobbleX("WobbleX", Range(-1,1)) = 0.0
		_WobbleZ("WobbleZ", Range(-1,1)) = 0.0

        _TopColor("Top Color", Color) = (1,1,1,1)

		_FoamColor("Foam Line Color", Color) = (1,1,1,1)
        _FoamWidth("Foam Line Width", Range(0,0.1)) = 0.0

		_RimColor("Rim Color", Color) = (1,1,1,1)
	    _RimPower("Rim Power", Range(0,10)) = 0.0
    }

    SubShader
    {
        Tags {"Queue"="Geometry"  "DisableBatching" = "True" }
		
        Pass
        {
			Zwrite On
			Cull Off // we want the front and back faces
			AlphaToMask On // transparency

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
 
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 viewDir : TEXCOORD1;
				float3 normal : TEXCOORD2;
				float fillEdge : TEXCOORD3;
			};
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Tint;

			float _FillAmount, _WobbleX, _WobbleZ;

			fixed4 _TopColor;

			fixed4 _FoamColor;
			fixed _FoamWidth;

			float4 _RimColor;
			float _RimPower;
           
			float4 RotateAroundYInDegrees (float3 worldPos)
			{
				float alpha = 2 * UNITY_PI;
				float sina, cosa;
				sincos(alpha, sina, cosa);
				float2x2 m = float2x2(cosa, sina, -sina, cosa);
				return float4(worldPos.yz , mul(m, worldPos.xz)).xzyw ;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				// get world position of the vertex
				float3 worldPos = mul (unity_ObjectToWorld, v.vertex.xyz);
				// rotate it around XY
				float3 worldPosX= RotateAroundYInDegrees(worldPos);
				// rotate around XZ
				float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);
				// combine rotations with worldPos, based on sine wave from script
				float3 worldPosAdjusted = worldPos + (worldPosX  * _WobbleX) + (worldPosZ * _WobbleZ);
				// how high up the liquid is
				o.fillEdge =  worldPosAdjusted.y + _FillAmount;

				o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
				o.normal = v.normal;
				return o;
			}
			
			fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Tint;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				// rim light
				float dotProduct = 1 - pow(dot(i.normal, i.viewDir), _RimPower);
				float4 RimResult = smoothstep(0.5, 1.0, dotProduct);
				RimResult *= _RimColor;

				// foam edge
				float4 foam = ( step(i.fillEdge, 0.5) - step(i.fillEdge, (0.5 - _FoamWidth)));
				float4 foamColored = foam * (_FoamColor * 0.9);

				// rest of the liquid
				float4 result = step(i.fillEdge, 0.5) - foam;
				float4 resultColored = result * col;

				// both together, with the texture
				float4 finalResult = resultColored + foamColored;
				finalResult.rgb += RimResult;

				// color of backfaces/ top
				float4 topColor = _TopColor * (foam + result);
				//VFACE returns positive for front facing, negative for backfacing
				return facing > 0 ? finalResult: topColor;
			}

			ENDCG
        }
    }
}