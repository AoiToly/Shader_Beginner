Shader "Shader Learning/E3_Effects"
{
    // ͨ����ЧShader
    // 1. ��͸��Ч���������ò�ͬ�Ļ�ϵ���ģʽ
    // 2. �ɵ�����ʾ��Ҳ����˫����ʾ
    // 3. ����������
    // 4. ���ֹ���
    // 5. UVŤ��Ч��
    // 6. �ܽ�Ч��

    Properties
    {
        [Header(RenderingMode)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("Src Blend", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("Dst Blend", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", int) = 0
        [Space(25)]

        [Header(Base)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Intensity ("Float", range(-10, 10)) = 1
        _MainUVSpeedX ("MainUVSpeedX", float) = 0
        _MainUVSpeedY ("MainUVSpeedY", float) = 0
        [Space(25)]

        [Header(Mask)]
        [Toggle]_MaskEnabled ("MaskEnabled", int) = 0
        _MaskTex ("MaskTex", 2D) = "white" {}
        _MaskUVSpeedX ("MaskUVSpeedX", float) = 0
        _MaskUVSpeedY ("MaskUVSpeedY", float) = 0
        [Space(25)]

        [Header(Distort)]
        [MaterialToggle(DISTORTENABLED)]_DistortEnabled ("DistortEnabled", int) = 0
        _DistortTex ("DistortTex", 2D) = "white" {}
        _Distort ("Distort", range(0, 1)) = 0
        _DistortUVSpeedX ("DistortUVSpeedX", float) = 0
        _DistortUVSpeedY ("DistortUVSpeedY", float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }

        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cull]

        pass
        {
            ZWrite On
            ColorMask 0
        }

        pass
        {
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // ���ݲ��ʵ�ʹ������������Ƿ�ᱻ����ı���
            #pragma shader_feature _ _MASKENABLED_ON
            #pragma shader_feature _ DISTORTENABLED

            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            half _Intensity;
            float _MainUVSpeedX, _MainUVSpeedY;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float _MaskUVSpeedX, _MaskUVSpeedY;

            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float _Distort;
            float _DistortUVSpeedX, _DistortUVSpeedY;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // ǰ����ͨ����MainTex��uv
                // ������ͨ����MaskTex��uv
                float4 uv : TEXCOORD0;
                // ǰ����ͨ����DistortTex��uv
                float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex) + float2(_MainUVSpeedX, _MainUVSpeedY) * _Time.y;

                #if _MASKENABLED_ON
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex) + float2(_MaskUVSpeedX, _MaskUVSpeedY) * _Time.y;
                #endif
                
                #if DISTORTENABLED
                o.uv2.xy = TRANSFORM_TEX(v.uv, _DistortTex) + float2(_DistortUVSpeedX, _DistortUVSpeedY) * _Time.y;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = _Color * _Intensity;

                float2 uv = i.uv.xy;
                #if DISTORTENABLED
                // distort
                fixed4 distortTex = tex2D(_DistortTex, i.uv2.xy);
                uv = lerp(i.uv.xy, distortTex, _Distort);
                #endif

                c *= tex2D(_MainTex, uv); 

                #if _MASKENABLED_ON
                // mask
                fixed4 maskTex = tex2D(_MaskTex, i.uv.zw);
                c *= maskTex;
                #endif

                return c;
            }
            ENDCG
        }
    }
}
