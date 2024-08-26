Shader "Shader Learning/URP/E16_Cartoon"
{
    Properties
    {
        [Header(base)]
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", color) = (1, 1, 1, 1)
        _LightIntensity("Light Intensity", float) = 1

        [Header(Outline)]
        _OutlineColor("Outline Color", color) = (1, 1, 1, 1)
        _OutlineWidth("Outline Width", range(0, 1)) = 0.1
        _StencilRef("Stencil Ref", int) = 1
        _UniformWidth("Uniform Width", range(0, 1)) = 0.5

        [Header(Color)]
        [IntRange]_Step("Step", range(1, 5)) = 2
        _ShadowMap("Shadow Map", 2D) = "black" {}
        _ShadowRampMap("Shadow Ramp Map", 2D) = "white" {}
        _ShadowMask("Shadow Mask", 2D) = "white" {}

        [Header(Specular)]
        _Specular("Intensity(x) atten(y) �߹��Ử(z) �߹�͸����(w)", vector) = (1, 1, 0, 1)
        _SpecularMask("Specular Mask", 2D) = "white" {}

        [Header(Fresnel)]
        _Fresnel("Intensity(x) atten(y) �Ử(z)", vector) = (1, 1, 0, 0)
        _FresnelColor("Fresnel Color", color) = (1,1,1,1)
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
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil
            {
                Ref [_StencilRef]
                Comp Always
                Pass replace
            }

            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            float _LightIntensity;
            half _Step;
            half4 _Specular;
            half4 _FresnelColor;
            half4 _Fresnel;
            CBUFFER_END
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_ShadowRampMap); SAMPLER(sampler_ShadowRampMap);
            TEXTURE2D(_ShadowMap);
            TEXTURE2D(_ShadowMask);
            TEXTURE2D(_SpecularMask); SAMPLER(sampler_SpecularMask);

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float fogCoord      : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 positionWS   : TEXCOORD3;
                float4 shadowCoord  : TEXCOORD4;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    #if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
                        o.shadowCoord = ComputeScreenPos(o.positionCS);
                    #else
                        o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                    #endif
                #endif
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                // ����������Ӱ
                // ��������ϸ�ڹ��࣬�ڿ�ͨ��Ⱦ�е���Ӱ������ǳ�ͻأ
                // �����Ҫ��DCC����У��������ķ��߽��е���
                // ���ȣ�����������Ҫ���м򻯣���ͷ�����ĵ�ΪԲ�ģ���ÿ�����������һ�����ߣ�ʹ�÷��߷����Ϊ�򵥾���
                // Ȼ����Ϊ���߷���Ҳ���ܹ��ڼ�ʹ����û���κ�ϸ�ڣ�������Ҫһ����ֵ�ܵ��������ڼ򻯰��ԭ��֮��ı���
                // ���⣬���ĵ��λ��Ҳ���Խ��е�������γ��ԣ����ҵ���Ϊ����Ľ��
                
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c *= _Color;

                // ��Ӱ
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    i.shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    i.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    i.shadowCoord = float4(0, 0, 0, 0);
                #endif
                // Lambert
                Light mainLight = GetMainLight(i.shadowCoord);

                half3 l = mainLight.direction;
                half3 lightColor = mainLight.color;
                half3 n = i.normalWS;
                half3 v = normalize(_WorldSpaceCameraPos - i.positionWS);
                half ndotl = dot(n, l);
                half3 lambert = lightColor * _LightIntensity;

                // ����ɫ��
                // ���Ӳ��������
                half level;
                {
                    half lambertDarkSide = ndotl;
                    half shadowAttenuation = mainLight.shadowAttenuation;
                    // �����е���Ӱ���޷��ܵ�����Ӱ�죬��Ҫʹ�ö�����ͼ��
                    // ����Χ����Ϊ0.5-1����֤����û����ô��
                    half shadowMask = SAMPLE_TEXTURE2D(_ShadowMask, sampler_MainTex, i.uv).a *0.5 + 0.5;
                    half shadowUV = min(min(lambertDarkSide, shadowAttenuation), shadowMask);

                    // ����һ���㷨ʵ��
                    // level = max(0.3, ceil(ndotl * _Step)/_Step);

                    // ��������������Ӱ��ͼ
                    half shadowRampMap = SAMPLE_TEXTURE2D(_ShadowRampMap, sampler_ShadowRampMap, half2(shadowUV, 0)).r;
                    level = max(0.3, shadowRampMap);
                }
                
                // ������Ӱ��ɫ
                half4 shadowMap = SAMPLE_TEXTURE2D(_ShadowMap, sampler_MainTex, i.uv);
                half4 shadow = lerp(shadowMap, 1, level);

                // specular
                half4 specular; 
                {
                    half3 h = normalize(l + v);
                    half ndoth = dot(n, h);
                    specular = pow(max(0, ndoth), _Specular.y) * _Specular.x;
                    // Ӳ�ߴ���
                    specular = smoothstep(0.5, 0.5 + _Specular.z, specular);
                    half specularMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, i.uv).r;
                    specular *= specularMask * _Specular.w;
                }

                // �ⷢ��fresnel
                half4 fresnel;
                {
                    half ndotv = 1 - saturate(dot(n, v));
                    fresnel = _Fresnel.x * pow(ndotv, _Fresnel.y);
                    fresnel = _FresnelColor * smoothstep(0.5, 0.5 + _Fresnel.z, fresnel);
                }

                c.rgb *= lambert * shadow.xyz;
                c += specular;
                c += fresnel;
                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "LightMode" = "CartoonOutline"
            }

            Stencil
            {
                Ref [_StencilRef]
                Comp NotEqual
            }

            Cull front
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            // ������������������
            // ��Ҫ��DCC����н�����ƽ�������������д洢

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                // rgbͨ���������ɫ��aͨ������ߴ�ϸ
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half4 color : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            half _OutlineWidth;
            half4 _OutlineColor;
            half _UniformWidth;
            CBUFFER_END
            TEXTURE2D(_ShadowMap); SAMPLER(sampler_ShadowMap);

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 positionOS = v.positionOS;
                float3 positionWS = TransformObjectToWorld(positionOS);
                float distance = length(_WorldSpaceCameraPos - positionWS);
                distance = lerp(1, distance, _UniformWidth);

                float3 width = normalize(v.normalOS) * _OutlineWidth * distance * 0.01;
                width *= v.color.a;
                positionOS += width;
                o.positionCS = TransformObjectToHClip(positionOS);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                // �����ɫ����һ��������Ӱ��ͼ�е���ɫ
                //half4 shadowMap = SAMPLE_TEXTURE2D(_ShadowMap, sampler_ShadowMap, i.uv);
                //return shadowMap * _OutlineColor;
                
                // �����ɫ�������������ֻ棬����ɫ��Ϣ�浽����ɫ��
                return i.color * _OutlineColor;
            }

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

    }
}
