Shader "Shader Learning/URP/E2_Ghost"
{
    Properties
    {
        _FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
        _Fresnel("Fade(x) Intensity(y) Top(z) YOffset(w)", vector) = (3, 1, 0.5, 0)
        _AnimationX("AnimX Repeat(x) Intensity(y) Speed(z) Offset(w)", vector) = (2,0.2,1,0.5)
        _AnimationZ("AnimZ Repeat(x) Intensity(y) Speed(z) Offset(w)", vector) = (2,0.2,1,0)
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        Blend One One
        ZWrite off
        
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

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float4 positionOS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
            half3 _FresnelColor;
            half4 _Fresnel;
            half4 _AnimationX;
            half4 _AnimationZ;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                // ���鶯������
                v.positionOS.x += sin(_Time.y * _AnimationX.z + v.positionOS.y * _AnimationX.x + _AnimationX.w) * _AnimationX.y;
                v.positionOS.z += sin(_Time.y * _AnimationZ.z + v.positionOS.y * _AnimationZ.x + _AnimationZ.w) * _AnimationZ.y;
                
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionOS = v.positionOS;
                return o;
            }

            void frag (Varyings i, out half4 outColor : SV_Target)
            {
                // ������������䣬����Lambert
                // �ȼ���max(0, dot(N, V))
                // ����TransformObjectToWorldNormal�Ѿ���һ����
                // ���Ӷ��㵽Ƭ����ɫ���Ĺ����л��в�ֵ�������²��ֶ���δ��һ��
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                half dotNV = 1 - saturate(dot(N, V));
                half4 fresnel = pow(dotNV, _Fresnel.x) * _Fresnel.y * half4(_FresnelColor, 1);
                
                // �������������µ�͸��������
                half mask = saturate(i.positionOS.y + i.positionOS.z - _Fresnel.w);
                
                outColor = lerp(fresnel, half4(_FresnelColor, 1), _Fresnel.z) * mask;
                
            }
            ENDHLSL
        }
    }

    // Builtin
    SubShader
    {
        Tags 
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        Blend One One
        ZWrite off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float4 positionOS : TEXCOORD2;
            };

            half3 _FresnelColor;
            half4 _Fresnel;
            half4 _AnimationX;
            half4 _AnimationZ;

            Varyings vert (Attributes v)
            {
                // ���鶯��ʵ��
                v.positionOS.x += sin(_Time.y * _AnimationX.z + v.positionOS.y * _AnimationX.x + _AnimationX.w) * _AnimationX.y;
                v.positionOS.z += sin(_Time.y * _AnimationZ.z + v.positionOS.y * _AnimationZ.x + _AnimationZ.w) * _AnimationZ.y;
                
                Varyings o = (Varyings)0;
                o.positionCS = UnityObjectToClipPos(v.positionOS.xyz);
                o.normalWS = UnityObjectToWorldNormal(v.normalOS);
                o.positionWS = mul(unity_ObjectToWorld, v.positionOS.xyz);
                o.positionOS = v.positionOS;
                return o;
            }

            fixed4 frag (Varyings i) : SV_Target
            {
                // ������������䣬����Lambert
                // �ȼ���max(0, dot(N, V))
                // ����TransformObjectToWorldNormal�Ѿ���һ����
                // ���Ӷ��㵽Ƭ����ɫ���Ĺ����л��в�ֵ�������²��ֶ���δ��һ��
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                half dotNV = 1 - saturate(dot(N, V));
                half4 fresnel = pow(dotNV, _Fresnel.x) * _Fresnel.y * half4(_FresnelColor, 1);
                
                // �������������µ�͸��������
                half mask = saturate(i.positionOS.y + i.positionOS.z - _Fresnel.w);
                
                fixed4 c = lerp(fresnel, half4(_FresnelColor, 1), _Fresnel.z) * mask;
                return c;
                
            }
            ENDCG
        }
    }
}
