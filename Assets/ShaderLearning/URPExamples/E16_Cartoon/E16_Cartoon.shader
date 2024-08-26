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
        _Specular("Intensity(x) atten(y) 高光柔滑(z) 高光透明度(w)", vector) = (1, 1, 0, 1)
        _SpecularMask("Specular Mask", 2D) = "white" {}

        [Header(Fresnel)]
        _Fresnel("Intensity(x) atten(y) 柔滑(z)", vector) = (1, 1, 0, 0)
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

            // 顶点着色器的输入（模型的数据信息）
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

            // 顶点着色器
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

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                // 关于脸部阴影
                // 由于脸部细节过多，在卡通渲染中的阴影往往会非常突兀
                // 因此需要在DCC软件中，将脸部的法线进行调整
                // 首先，脸部法线需要进行简化，以头部中心点为圆心，向每个顶点射出归一化法线，使得法线方向更为简单均匀
                // 然后，因为法线方向也不能过于简单使脸部没有任何细节，所以需要一个插值能调整法线在简化版和原版之间的比例
                // 另外，中心点的位置也可以进行调整，多次尝试，以找到较为合理的结果
                
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c *= _Color;

                // 阴影
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

                // 明暗色阶
                // 多阶硬边明暗面
                half level;
                {
                    half lambertDarkSide = ndotl;
                    half shadowAttenuation = mainLight.shadowAttenuation;
                    // 纹理中的阴影（无法受到光照影响，需要使用额外贴图）
                    // 将范围调整为0.5-1，保证暗面没有那么暗
                    half shadowMask = SAMPLE_TEXTURE2D(_ShadowMask, sampler_MainTex, i.uv).a *0.5 + 0.5;
                    half shadowUV = min(min(lambertDarkSide, shadowAttenuation), shadowMask);

                    // 方案一，算法实现
                    // level = max(0.3, ceil(ndotl * _Step)/_Step);

                    // 方案二，采样阴影贴图
                    half shadowRampMap = SAMPLE_TEXTURE2D(_ShadowRampMap, sampler_ShadowRampMap, half2(shadowUV, 0)).r;
                    level = max(0.3, shadowRampMap);
                }
                
                // 采样阴影颜色
                half4 shadowMap = SAMPLE_TEXTURE2D(_ShadowMap, sampler_MainTex, i.uv);
                half4 shadow = lerp(shadowMap, 1, level);

                // specular
                half4 specular; 
                {
                    half3 h = normalize(l + v);
                    half ndoth = dot(n, h);
                    specular = pow(max(0, ndoth), _Specular.y) * _Specular.x;
                    // 硬边处理
                    specular = smoothstep(0.5, 0.5 + _Specular.z, specular);
                    half specularMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, i.uv).r;
                    specular *= specularMask * _Specular.w;
                }

                // 外发光fresnel
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

            // 关于外轮廓断裂问题
            // 需要在DCC软件中将法线平均化后导入切线中存储

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                // rgb通道存描边颜色，a通道存描边粗细
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
                // 描边颜色方案一，采用阴影贴图中的颜色
                //half4 shadowMap = SAMPLE_TEXTURE2D(_ShadowMap, sampler_ShadowMap, i.uv);
                //return shadowMap * _OutlineColor;
                
                // 描边颜色方案二，美术手绘，将颜色信息存到顶点色中
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
