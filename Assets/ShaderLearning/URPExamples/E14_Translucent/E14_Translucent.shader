Shader "Shader Learning/URP/E14_Translucent"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
        _Specular("Specular", float) = 1
        _Shininess("Shininess", float) = 1

        [Header(Translucent)]
        _ThicknessMap("Thickness Map", 2D) = "white" {}
        _Thickness("Thickness", range(0, 1)) = 0.5
        _NormalDistortion("Normal Distortion", range(0, 1)) = 0.5
        _Atten("Atten", float) = 0
        _Strength("Strength", float) = 1
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
            #pragma multi_compile_fog
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _Specular;
            half _Shininess;
            half _NormalDistortion;
            half _Atten;
            half _Strength;
            half _Thickness;
            CBUFFER_END
            TEXTURE2D(_MainTex);   // 纹理的定义，如果是编译到GLES2.0平台，则相当于_MainTex；否则就相当于sampler2D
            SAMPLER(sampler_MainTex);   // 采样器定义，如果是编译到GLES2.0平台，则相当于空；否则就相当于SamplerState sampler_MainTex
            TEXTURE2D(_ThicknessMap);
            SAMPLER(sampler_ThicknessMap);

            // 顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fogCoord  : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                return o;
            }

            half3 LightingTranslucent(float3 viewWS, float3 normalWS, float3 lightWS, half3 lightColor, half thickness)
            {
                // 透射
                // dot(-H, V)
                half3 L = lightWS;
                half3 V = viewWS;
                half3 N = normalWS;
                half3 H = L + N * _NormalDistortion;
                half LdotV = dot(-H, V);
                half3 I = pow(saturate(LdotV), _Atten) * _Strength * lightColor * thickness;
                return I;
            }

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c *= _Color;

                // Diffuse = Ambient + Kd * LightColor * max(0,dot(N,L))
                Light light = GetMainLight();
                half3 lightColor = light.color;
                half3 L = light.direction;
                half3 N = i.normalWS;
                half3 V = normalize(_WorldSpaceCameraPos - i.positionWS).xyz;
                half Kd = 1;
                // 最小值调整为0.3使得暗部没有那么暗
                half4 diffuse = half4(Kd * lightColor * max(0.3, dot(N, L)), 1);
                c *= diffuse;

                // Specular = SpecularColor * Ks * pow(max(0,dot(N,H)), Shininess)
                half Ks = _Specular;
                half3 H = normalize(L + V);
                half4 specular = Ks * pow(max(0, dot(N, H)), _Shininess);
                c += specular;

                half thicknessMap = 1 - SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap, i.uv).r;
                half thickness = lerp(1, thicknessMap, _Thickness);

                // 主灯透射
                half3 I = LightingTranslucent(i.positionWS, N, L, lightColor, thickness);
                c.rgb += I;

                // 额外光的透射支持
                #if defined(_ADDITIONAL_LIGHTS)
                uint pixelLightCount = GetAdditionalLightsCount();
                
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    // 额外灯Lambert
                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    c.rgb += LightingLambert(light.color, light.direction, i.normalWS) * saturate(light.distanceAttenuation);
                    // 额外灯透射
                    c.rgb += LightingTranslucent(V, N, light.direction, light.color, thickness) * light.distanceAttenuation;
                LIGHT_LOOP_END
                #endif

                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }
}
