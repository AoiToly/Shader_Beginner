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
            // 声明实例化的变体
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                // 声明instanceID
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 声明instanceID
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #ifdef UNITY_INSTANCING_ENABLED
                // 声明常量寄存器
                // 此处prop命名可随意，保证Start和End统一即可
                UNITY_INSTANCING_BUFFER_START(prop)
                UNITY_DEFINE_INSTANCED_PROP(fixed4, _BaseColor)
                UNITY_INSTANCING_BUFFER_END(prop)
            #else
                fixed4 _BaseColor;
            #endif

            v2f vert (appdata v)
            {
                // 初始化InstanceID，保证这一批里的所有物体的数据正确
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                // 将InstanceID传给片段着色器
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 初始化InstanceID，保证这一批里的所有物体的数据正确
                UNITY_SETUP_INSTANCE_ID(i);
                // 获取常量寄存器中的属性值
                fixed4 c = UNITY_ACCESS_INSTANCED_PROP(prop, _BaseColor);
                return c;
            }
            ENDCG
        }
    }
}
