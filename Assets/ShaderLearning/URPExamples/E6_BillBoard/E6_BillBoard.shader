// ������shader����֤��Ƭʼ�ճ������
Shader "Shader Learning/URP/E6_BillBoard"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
        [Enum(BillBoard,1,VerticalBillBoard,0)]_BillBoardType("BillBoardType", int) = 0
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }
        Pass
        {
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);   // ����Ķ��壬����Ǳ��뵽GLES2.0ƽ̨�����൱��_MainTex��������൱��sampler2D
            float4 _MainTex_ST;
            SAMPLER(sampler_MainTex);   // ���������壬����Ǳ��뵽GLES2.0ƽ̨�����൱�ڿգ�������൱��SamplerState sampler_MainTex
            half4 _Color;
            int _BillBoardType;
            CBUFFER_END

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ˼·�������������������ϵ�Ļ��������󣬽�����Ա��ؿռ��еĵ����Եõ����

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                // ��ñ��ؿռ������λ��
                // ע�⣬�����������泯������������x���y��Ӧ�ú������xy�᷽��һ�£����������ֶ���z�᷽��Ϊ���ָ������
                // ��ˣ��˴���viewDir��Ҫȡ�෴��
                float3 viewDir = -mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos, 1)).xyz;
                // �����ת������ϵ�Ļ�����
                viewDir.y *= _BillBoardType;
                float3 z = normalize(viewDir);
                float3 y = float3(0, 1, 0);
                float3 x = normalize(cross(y, z));
                y = normalize(cross(z, x));

                float3x3 M = float3x3(
                    x.x, y.x, z.x,
                    x.y, y.y, z.y,
                    x.z, y.z, z.z);
                float3 targetPos = mul(M, v.positionOS);

                o.positionCS = TransformObjectToHClip(targetPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            // Ƭ����ɫ��
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                outColor = mainTex * _Color;
            }
            ENDHLSL
        }
    }

    // Builtin
    SubShader
    {
        Tags 
        {
            "RenderType" = "Opaque"
        }
        Pass
        {
            CGPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            int _BillBoardType;
            
            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                // ��ñ��ؿռ������λ��
                // ע�⣬�����������泯������������x���y��Ӧ�ú������xy�᷽��һ�£����������ֶ���z�᷽��Ϊ���ָ������
                // ��ˣ��˴���viewDir��Ҫȡ�෴��
                float3 viewDir = -mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
                // �����ת������ϵ�Ļ�����
                viewDir.y *= _BillBoardType;
                float3 z = normalize(viewDir);
                float3 y = float3(0, 1, 0);
                float3 x = normalize(cross(y, z));
                y = normalize(cross(z, x));

                float3x3 M = float3x3(
                    x.x, y.x, z.x,
                    x.y, y.y, z.y,
                    x.z, y.z, z.z);
                float3 targetPos = mul(M, v.positionOS);

                o.positionCS = UnityObjectToClipPos(targetPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            // Ƭ����ɫ��
            void frag(Varyings i, out fixed4 outColor : SV_Target)
            {
                half4 mainTex = tex2D(_MainTex, i.uv);

                outColor = mainTex * _Color;
            }
            ENDCG
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
