// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Test02"
{
	Properties
	{
		_MainTexture("Main Texture",2D) = "white"{}
		_OverlayTexture("Overlay Texture",2D) = "black"{}
		_Direction("Coverage Direction",Vector) = (0,1,0)
		_OverlayIntensity("Coverage Intensity",Range(0,1)) = 1

		_Color("Color",Color) = (1,1,1,1)
		_AnimationSpeed("Animation Speed", Range(0,3)) = 0
		_OffsetSize("Offset Size", Range(0, 10)) = 0
	}

	SubShader
	{
		pass 
		{
			CGPROGRAM

			#pragma vertex vertexFunc
			#pragma fragment fragmentFunc

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv_Main : TEXCOORD0;
				float2 uv_Overlay : TEXCOORD1;
			};

			fixed4 _VertexOffset;
			fixed4 _Color;

			sampler2D _MainTexture;
			float4 _MainTexture_ST;
			sampler2D _OverlayTexture;
			float4 _OverlayTexture_ST;

			float _AnimationSpeed;
			float _OffsetSize;

			v2f vertexFunc(appdata_full IN)
			{
				v2f OUT;

				IN.vertex.y += sin(_Time.y * _AnimationSpeed + IN.vertex.y * _OffsetSize);
				OUT.position = UnityObjectToClipPos(IN.vertex);
				OUT.uv_Main = TRANSFORM_TEX(IN.texcoord,_MainTexture);
				OUT.uv_Overlay = TRANSFORM_TEX(IN.texcoord, _OverlayTexture);
				OUT.normal = mul(unity_ObjectToWorld, IN.normal);
				return OUT;
			}

			float3 _Direction;
			fixed _OverlayIntensity;

			fixed4 fragmentFunc(v2f IN) : COLOR
			{
				fixed dir = dot(normalize(IN.normal),_Direction);

				if (dir < 1 - _OverlayIntensity)
				{
					dir = 0;
				}
				fixed4 tex1 = tex2D(_MainTexture, IN.uv_Main);
				fixed4 tex2 = tex2D(_OverlayTexture, IN.uv_Overlay);

				return lerp(tex1,tex2,dir) * _Color;
			}
			ENDCG
		}
	}
}
	
