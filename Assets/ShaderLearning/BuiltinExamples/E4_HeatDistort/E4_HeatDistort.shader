Shader "Shader Learning/Builtin/E4_HeatDistort"
{
    // ��Ť��Ч��
    Properties
    {
        _DistortTex ("DistortTex", 2D) = "white" {}
        _Distort ("SpeedX(X) SpeedY(Y) Distort(Z)", vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" }

        // ץȡ��Ļ��ͼ
        // ��������֮��Ϳ��Ա��������ô�shader��������ظ���Ļץȡ
        GrabPass { "_GrabTex" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _GrabTex;
            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float4 _Distort;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v, out float4 pos : SV_POSITION)
            {
                v2f o = (v2f)0;
                pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DistortTex) + _Distort.xy * _Time.y;
                return o;
            }

            // ��������õ���ǰ���ص���Ļ����
            fixed4 frag (v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target
            {
                // ����uvֵ
                fixed2 screenUV = screenPos.xy / _ScreenParams.xy;
                
                fixed4 distortTex = tex2D(_DistortTex, i.uv);
                float2 uv = lerp(screenUV, distortTex, _Distort.z);

                fixed4 grabTex = tex2D(_GrabTex, uv);

                return grabTex;
            }
            ENDCG
        }
    }
}