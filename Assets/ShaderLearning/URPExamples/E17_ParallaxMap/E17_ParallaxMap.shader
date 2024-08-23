Shader "Shader Learning/URP/E17_ParallaxMap"
{
    Properties
    {
        [MainTexture]_MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
        [Normal]_NormalMap("NormalMap", 2D) = "bump" {}
        [KeywordEnum(Default, Limit, Steep, Relief, POM)]_ParallaxType("ParallaxType", int) = 0
        _ParallaxMap("ParallaxMap", 2D) = "white" {}
        _ParallaxStrength("ParallaxStrength", range(0,0.5)) = 0
        _ParallaxAmount("ParallaxAmount", int) = 10
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
            #pragma shader_feature _ _PARALLAXTYPE_DEFAULT _PARALLAXTYPE_LIMIT _PARALLAXTYPE_STEEP _PARALLAXTYPE_RELIEF _PARALLAXTYPE_POM
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            float _ParallaxStrength;
            half _ParallaxAmount;
            CBUFFER_END
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex); 
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_ParallaxMap); SAMPLER(sampler_ParallaxMap);

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half3 normalOS : NORMAL;
                half4 tangentOS : TANGENT;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                half4 normalWS : TEXCOORD1;
                half4 tangentWS : TEXCOORD2;
                half4 bitangentWS : TEXCOORD3;
                float3 positionWS : TEXCOORD4;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS.xyz = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS.xyz = TransformObjectToWorldDir(v.tangentOS.xyz);
                half sign = v.tangentOS.w * GetOddNegativeScale();
                o.bitangentWS.xyz = cross(o.normalWS.xyz, o.tangentWS.xyz) * sign;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;

                float2 offset = 0;
                half3 v = _WorldSpaceCameraPos - i.positionWS;
                // ��vת�����߿ռ���Pt = Wt * Pw -> Pt = Tw^-1 * Pw ->Pt = Tw^T * Pw
                v = mul(float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz), v);
                v = normalize(v);

                // �����Ӳ�ӳ�� T=-V.xy*(H/V.z)�����ܺã�Ч����
                #if _PARALLAXTYPE_DEFAULT
                half parallaxMap = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv).r;
                half h = 1 - parallaxMap;
                offset = -v.xy * h / v.z * _ParallaxStrength;

                // ��ƫ�����޵��Ӳ�ӳ�� T=-V.xy*H
                #elif _PARALLAXTYPE_LIMIT
                half parallaxMap = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv).r;
                half h = 1 - parallaxMap;
                offset = -v.xy * h * _ParallaxStrength;

                // �����Ӳ�ӳ�䣬�ֶβ�����ֱ���ҵ��ӽ�Ŀ����ȵ���ֵ
                #elif _PARALLAXTYPE_STEEP
                half currentDepth = 0;
                half parallaxDepth = 0;
                half deltaDepth = 1/_ParallaxAmount;
                half2 deltaOffset = -v.xy/v.z * _ParallaxStrength;
                // shader�����ѭ����Ҫ������������Ҫ��ȷѭ������
                // ������unroll��ǩ�����޶�����
                // Ҳ������LOD�������
                //[unroll(30)]
                for(int j = 0; j < _ParallaxAmount; j++)
                {
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                    // �����ǰ���������ֵ>���ͼ�е����ֵ���˳�ѭ��
                    if(currentDepth > parallaxDepth) break;
                    currentDepth += deltaDepth;
                    offset = currentDepth * deltaOffset;
                }

                // �����Ӳ�ӳ�䣬�ڶ����Ӳ�ӳ������Ͻ��ж��ֲ��Ҹ���һ����ȷ��ֵ
                #elif _PARALLAXTYPE_RELIEF
                half currentDepth = 0;
                half parallaxDepth = 0;
                half deltaDepth = 1/_ParallaxAmount;
                half2 deltaOffset = -v.xy/v.z * _ParallaxStrength;
                // shader�����ѭ����Ҫ������������Ҫ��ȷѭ������
                // ������unroll��ǩ�����޶�����
                // Ҳ������LOD�������
                //[unroll(30)]
                for(int j = 0; j < _ParallaxAmount; j++)
                {
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                    // �����ǰ���������ֵ>���ͼ�е����ֵ���˳�ѭ��
                    if(currentDepth > parallaxDepth) break;
                    currentDepth += deltaDepth;
                    offset = currentDepth * deltaOffset;
                }
                // ͨ�����ֲ��Ҿ�ȷ�������
                for(int j = 0; j < 5; j++)
                {
                    deltaDepth /= 2;
                    if(currentDepth == parallaxDepth)
                    {
                        break;
                    }
                    else if(currentDepth > parallaxDepth)
                    {
                        currentDepth -= deltaDepth;
                    }
                    else
                    {
                        currentDepth += deltaDepth;
                    }
                    offset = currentDepth * deltaOffset;
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                }

                // �Ӳ��ڱ�ӳ�䣬�ڶ����Ӳ�ӳ��Ļ����ϣ��Խ�����й��㣬���ȱȸ�����Ч�ʸ���
                #elif _PARALLAXTYPE_POM
                half currentDepth = 0;
                half parallaxDepth = 0;
                half preParallaxDepth = 0;
                half deltaDepth = 1/_ParallaxAmount;
                half2 deltaOffset = -v.xy/v.z * _ParallaxStrength;
                // shader�����ѭ����Ҫ������������Ҫ��ȷѭ������
                // ������unroll��ǩ�����޶�����
                // Ҳ������LOD�������
                //[unroll(30)]
                for(int j = 0; j < _ParallaxAmount; j++)
                {
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                    // �����ǰ���������ֵ>���ͼ�е����ֵ���˳�ѭ��
                    if(currentDepth > parallaxDepth) break;
                    preParallaxDepth = parallaxDepth;
                    currentDepth += deltaDepth;
                    offset = currentDepth * deltaOffset;
                }
                half preDepth = currentDepth - deltaDepth;
                half A_C = preDepth - preParallaxDepth;
                half D_B = parallaxDepth - currentDepth;
                half t = A_C/(D_B+A_C);
                half height = lerp(preDepth, currentDepth, t);
                offset = deltaOffset * height;

                #endif


                i.uv += offset;

                half3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv));
                half3 normalWS = mul(normalMap, half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz));

                Light mainLight = GetMainLight();
                half3 l = mainLight.direction;
                half ndotl = max(0.3, dot(l, normalWS));
                c *= ndotl;

                return c;
            }
            ENDHLSL
        }
    }
}
