Shader "Shader Learning/E14_GPUInstancing"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // ����ʵ�����ı���
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                // ����instanceID
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // ����instanceID
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #ifdef UNITY_INSTANCING_ENABLED
                // ���������Ĵ���
                // �˴�prop���������⣬��֤Start��Endͳһ����
                UNITY_INSTANCING_BUFFER_START(prop)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _BaseColor)
                UNITY_INSTANCING_BUFFER_END(prop)
            #else
                fixed4 _BaseColor;
            #endif

            v2f vert (appdata v)
            {
                // ��ʼ��InstanceID����֤��һ��������������������ȷ
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                // ��InstanceID����Ƭ����ɫ��
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ��ʼ��InstanceID����֤��һ��������������������ȷ
                UNITY_SETUP_INSTANCE_ID(i);
                // ��ȡ�����Ĵ����е�����ֵ
                fixed4 c = UNITY_ACCESS_INSTANCED_PROP(prop, _BaseColor);
                return c;
            }
            ENDCG
        }
    }
}
