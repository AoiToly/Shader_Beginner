Shader "Shader Learning/E9_Fog"
{
    Properties
    {

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // ��Ч����һ���ֶ�����
                //float fogFactor : TEXCOORD0;
                // ��Ч�����������淽��
                // �൱��������Ч����ʱ����һ��float���͵ı���fogCoord
                //UNITY_FOG_COORDS(1)
                // ��Ч������������v2f���ж���worldPosʱ�����԰�worldPos.w����������Ϊ��Чֵ
                float4 worldPos : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o)
                o.pos = UnityObjectToClipPos(v.vertex);
                // ��Ч����һ���ֶ�����
                //float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

                //float z = length(_WorldSpaceCameraPos - worldPos);
                //#if defined(FOG_LINEAR)
                //    // (end - z) / (end - start) = z * (-1/(end - start)) + (end/(end-start))
                //    o.fogFactor = z * unity_FogParams.z + unity_FogParams.w;
                //#elif defined(FOG_EXP)
                //    // exp2(-density * z) 
                //    o.fogFactor = exp2(-unity_FogParams.y * z);
                //#elif defined(FOG_EXP2)
                //    // exp2(-(density*z)^2)
                //    float density = unity_FogParams.x * z;
                //    o.fogFactor = exp2(-density * density);
                //#endif

                // ��Ч�����������淽��
                //UNITY_TRANSFER_FOG(o, o.pos);

                // ��Ч������������v2f���ж���worldPosʱ�����԰�worldPos.w����������Ϊ��Чֵ
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG_COMBINED_WITH_WORLD_POS(o, o.pos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = 1;
                // ��Ч����һ���ֶ�����
                //#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
                //    c = lerp(unity_FogColor, c, i.fogFactor);
                //#endif

                // ��Ч�����������淽��
                //UNITY_APPLY_FOG(i.fogCoord, c);

                // ��Ч������������v2f���ж���worldPosʱ�����԰�worldPos.w����������Ϊ��Чֵ
                UNITY_EXTRACT_FOG_FROM_WORLD_POS(i);
                UNITY_APPLY_FOG(_unity_fogCoord, c);

                return c;
            }
            ENDCG
        }
    }
}
