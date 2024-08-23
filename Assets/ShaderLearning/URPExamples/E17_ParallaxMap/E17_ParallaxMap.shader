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

            // 顶点着色器的输入（模型的数据信息）
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

            // 顶点着色器
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

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;

                float2 offset = 0;
                half3 v = _WorldSpaceCameraPos - i.positionWS;
                // 将v转到切线空间下Pt = Wt * Pw -> Pt = Tw^-1 * Pw ->Pt = Tw^T * Pw
                v = mul(float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz), v);
                v = normalize(v);

                // 基本视差映射 T=-V.xy*(H/V.z)，性能好，效果差
                #if _PARALLAXTYPE_DEFAULT
                half parallaxMap = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv).r;
                half h = 1 - parallaxMap;
                offset = -v.xy * h / v.z * _ParallaxStrength;

                // 带偏移上限的视差映射 T=-V.xy*H
                #elif _PARALLAXTYPE_LIMIT
                half parallaxMap = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, i.uv).r;
                half h = 1 - parallaxMap;
                offset = -v.xy * h * _ParallaxStrength;

                // 陡峭视差映射，分段采样，直至找到接近目标深度的数值
                #elif _PARALLAXTYPE_STEEP
                half currentDepth = 0;
                half parallaxDepth = 0;
                half deltaDepth = 1/_ParallaxAmount;
                half2 deltaOffset = -v.xy/v.z * _ParallaxStrength;
                // shader中如果循环里要采样纹理，则需要明确循环次数
                // 这里用unroll标签可以限定上限
                // 也可以用LOD采样解决
                //[unroll(30)]
                for(int j = 0; j < _ParallaxAmount; j++)
                {
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                    // 如果当前迭代的深度值>深度图中的深度值则退出循环
                    if(currentDepth > parallaxDepth) break;
                    currentDepth += deltaDepth;
                    offset = currentDepth * deltaOffset;
                }

                // 浮雕视差映射，在陡峭视差映射基础上进行二分查找更进一步精确数值
                #elif _PARALLAXTYPE_RELIEF
                half currentDepth = 0;
                half parallaxDepth = 0;
                half deltaDepth = 1/_ParallaxAmount;
                half2 deltaOffset = -v.xy/v.z * _ParallaxStrength;
                // shader中如果循环里要采样纹理，则需要明确循环次数
                // 这里用unroll标签可以限定上限
                // 也可以用LOD采样解决
                //[unroll(30)]
                for(int j = 0; j < _ParallaxAmount; j++)
                {
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                    // 如果当前迭代的深度值>深度图中的深度值则退出循环
                    if(currentDepth > parallaxDepth) break;
                    currentDepth += deltaDepth;
                    offset = currentDepth * deltaOffset;
                }
                // 通过二分查找精确采样结果
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

                // 视差遮蔽映射，在陡峭视差映射的基础上，对结果进行估算，精度比浮雕差，但效率更高
                #elif _PARALLAXTYPE_POM
                half currentDepth = 0;
                half parallaxDepth = 0;
                half preParallaxDepth = 0;
                half deltaDepth = 1/_ParallaxAmount;
                half2 deltaOffset = -v.xy/v.z * _ParallaxStrength;
                // shader中如果循环里要采样纹理，则需要明确循环次数
                // 这里用unroll标签可以限定上限
                // 也可以用LOD采样解决
                //[unroll(30)]
                for(int j = 0; j < _ParallaxAmount; j++)
                {
                    parallaxDepth = 1 - SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, i.uv + offset, 0).r;
                    // 如果当前迭代的深度值>深度图中的深度值则退出循环
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
