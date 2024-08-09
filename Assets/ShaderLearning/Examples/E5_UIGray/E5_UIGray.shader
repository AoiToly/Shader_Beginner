Shader "Shader Learning/E5_UIGray"
{
	Properties
	{
		// PerRenderDataʹ��������Inspector����ϲ��ɼ�
		// ʹ�ø����Կ���ͨ��MaterialPropertyBlock�����޸ģ������ڴ�ռ�ã�����Ч��
		[PerRenderData] _MainTex ("MainTex", 2D) = "white" {}
		_Stencil ("Stencil", int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comp", int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Op", int) = 0
		_StencilReadMask ("Stencil Read Mask", int) = 255
		_StencilWriteMask ("Stencil Write Mask", int) = 255
		_ColorMask ("Color Mask", Float) = 15
		[Toggle]_GrayEnabled ("Gray Enabled", int) = 0
	}

	SubShader
	{
		Tags { "Queue" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha

		// ģ�����
		Stencil
		{
			Ref [_Stencil]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
			Comp [_StencilComp]
			Pass [_StencilOp]
			//Fail [_Fail]
			//ZFail [_ZFail]
		}

		ColorMask [_ColorMask]
		
		pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ UNITY_UI_CLIP_RECT
			#pragma multi_compile _ _GRAYENABLED_ON
			
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _ClipRect;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				// ֱ�ӻ�ȡUIͼƬ�е�Color����
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
				float4 vertex : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.color = v.color;
				o.vertex = v.vertex;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed4 c = i.color ;
				fixed4 mainTex = tex2D(_MainTex, i.uv);
				c *= mainTex;

				#if UNITY_UI_CLIP_RECT
				c *= UnityGet2DClipping(i.vertex, _ClipRect);
				#endif
				
				#if _GRAYENABLED_ON
				// ����һ������ȷ�ĵ�ͨ��ȡɫ
				// c.rgb = c.r;

				// ��������ȥɫ��ʽdot(rgb,fixed3(0.22,0.707,0.071))
				// c.rgb = c.r * 0.22 + c.g * 0.707 + c.b * 0.071;

				// �����������ú���
				c.rgb = Luminance(c);
				#endif

				return c;
			}

			ENDCG
		}
	}
}