Shader "Shader Learning/E4_HeatDistort03"
{
    Properties
    {
        _DistortTex ("DistortTex", 2D) = "white" {}
        _Distort ("SpeedX(X) SpeedY(Y) Distort(Z)", vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" }

        // 抓取屏幕截图
        // 输入名字之后就可以避免多个引用此shader的物体的重复屏幕抓取
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
                float4 pos : SV_POSITION;
                float4 screenUV : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DistortTex) + _Distort.xy * _Time.y;
                o.screenUV = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 screenUV = i.pos.xy / _ScreenParams.xy;
                fixed4 distortTex = tex2D(_DistortTex, i.uv);
                fixed2 uv = lerp(screenUV, distortTex, _Distort.z);
                fixed4 grabTex = tex2D(_GrabTex, uv);
                return grabTex;
            }
            ENDCG
        }
    }
}