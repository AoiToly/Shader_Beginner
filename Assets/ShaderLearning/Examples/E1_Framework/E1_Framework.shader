// Shader·��
Shader "Shader Learning/E1_Framework"
{
    // ��������
    Properties
    {
        // �﷨��ʽ
        // [Attribute]_Name ("Display Name", Type) = Default_Value
        [HDR]_Color("Color", color) = (1,1,1,1)
        _Int("Int", int) = 1
        // range������Inspector�������ӻ�����
        [PowerSlider(3)]_Float("Float", range(0,10)) = 1
    }

    // ����Ѱ�ҵ�һ���豸֧�ֵ�SubShader
    SubShader
    {
        // ÿ��һ��pass��Ⱦһ�Σ���pass����ʵ�ָ��ḻ��Ч��
        // passԽ��Խ�ģ�������URP��ֻ֧�ֵ�pass
        pass
        {
            // CG�����
            CGPROGRAM

            // ����include
            // HLSLSupport.cginc������CGPROGRAMʱ�Զ��������ļ������������˺ܶ�Ԥ����������ƽ̨����
            // UnityShaderVariables.cginc������CGPROGRAMʱ�Զ��������ļ������������˺ܶ����õ�ȫ�ֱ���
            // UnityCG.cginc�����ֶ���ӣ����������˺ܶ����õİ���������ṹ
            #include "UnityCG.cginc"

            // ���齫Unity���õ�shader�ӹ�����������Ȼ������Ŀ��

            // ָ�������Ƭ����ɫ��
            #pragma vertex vert
            #pragma fragment frag

            // ��������
            // float/half/fixed
            // Integer
            // sampler2D/samplerCUBE
            // ������������: float3 point = float3(10, 3.8, 1); float4 pos = float4(point, 1);

            // Ӧ�ó���׶�����
            struct appdata
            {
                float4 pos : POSITION;
                float4 color : COLOR;
            };

            // ����Ƭ�δ�������
            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            // Properties�е�������Ҫ������һ��
            fixed4 _Color;

            v2f vert(appdata v)
            { 
                // Ϊ�˷�ֹ����GPU�����ṹ�嶨��ʱ��Ҫ��ʼ��
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.pos);
                return o;
            }

            // SV_TARGETָ�����
            float4 frag(v2f i) : SV_TARGET
            {
                return _Color;
            }

            ENDCG
        }
    }

    // �Զ��������壬ָ���ű�����
    CustomEditor ""
    // �������SubShader����֧�֣�ָ��ʹ�õ�Shader����
    FallBack ""
}
