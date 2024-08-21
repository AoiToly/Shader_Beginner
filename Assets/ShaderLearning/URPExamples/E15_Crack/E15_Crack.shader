Shader "Shader Learning/URP/E15_Crack"
{
    Properties
    {
        _Color("Color", color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry-1"
        }
        
        // ˼·�ǣ�������ͨƽ����Ⱦ
        // ������һ��pass��Ⱦ�����ڲ���ϸ��
        // ������һ��pass�������ĳ���Ƭ���ڶ�����������ColorMaskΪ0������ʾ��һ��pass�е�����
        // ע����Ⱦ�Ⱥ�˳����DrawObjectPass�ű���֪��SRPDefaultUnlit����UniversalForward��Ⱦ����Ⱦ˳����pass���ڽű��е�λ���޹�
        
        Pass
        {
            Tags 
            { 
                "LightMode" = "SRPDefaultUnlit"
            }
            
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            CBUFFER_END
            
            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionOS : TEXCOORD0;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionOS.xyz = v.positionOS;
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = _Color;
                // anim
                float t = sin(_Time.y * 2) * 0.4 + 0.6;
                c *= t;
                half depth = saturate(abs(i.positionOS.y));
                c *= depth;
                return c;
            }
            ENDHLSL
        }
        
        Pass
        {
            Tags 
            { 
                "LightMode" = "UniversalForward"
            }
            ColorMask 0
            Offset -1, -1
            
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                v.positionOS.y = 0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
