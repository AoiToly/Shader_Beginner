Shader "Shader Learning/URP/E13_Water"
{
    Properties
    {
        _Water01("Direction(xy) Speed(z) Distort(w)", vector) = (1, 1, 0.1, 0.05)
        _Water02("Atten(x)", vector) = (1, 1, 1, 1)
        _Water03("Specular:Distort(x) Intensity(y) Smoothness(z)", vector) = (0.8, 5, 8, 0)
        _WaterColor01("Water Color01(RGB)", Color) = (1, 1, 1, 1)
        _WaterColor02("Water Color02(RGB)", Color) = (1, 1, 1, 1)
        _NormalTex("Normal Tex", 2D) = "white" {}

        [Header(Foam)]
        _FoamTex("Foam Tex", 2D) = "white" {}
        _FoamColor("Foam Color", color) = (1, 1, 1, 1)
        _FoamRange("Foam Range", range(0, 50)) = 1
        _FoamNoise("Foam Noise", range(0, 1)) = 1

        [Header(Specular)]
        _SpecularColor("Specular Color", color) = (1, 1, 1, 1)
        _Specular("Specular", float) = 5
        _Smoothness("Smoothness", float) = 8

        [Header(Reflection)]
        [NoScaleOffset]_ReflectionTex("Reflection Tex", cube) = "white" {}

        // 焦散
        [Header(Caustic)]
        _CausticTex("CausticTex", 2D) = "white" {}
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        ZWrite off
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            // 声明深度图及其采样器
            #define REQUIRE_DEPTH_TEXTURE
            #define REQUIRE_OPAQUE_TEXTURE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Water01, _Water02, _Water03;
            half4 _WaterColor01;
            half4 _WaterColor02;

            float4 _FoamTex_ST;
            half4 _FoamColor;
            half _FoamRange;
            half _FoamNoise;

            float4 _NormalTex_ST;

            half4 _SpecularColor;
            half _Specular;
            half _Smoothness;

            float4 _CausticTex_ST;
            CBUFFER_END
            TEXTURE2D(_FoamTex); SAMPLER(sampler_FoamTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);
            TEXTURECUBE(_ReflectionTex); SAMPLER(sampler_ReflectionTex);
            TEXTURE2D(_CausticTex); SAMPLER(sampler_CausticTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xy为foam的uv，zw表示水流偏移
                float4 uv : TEXCOORD0;
                // 法线uv
                float4 normalUV : TEXCOORD1;
                float fogCoord  : TEXCOORD2;
                float3 positionVS : TEXCOORD3;
                float3 positionWS : TEXCOORD4;
                float3 normalWS : TEXCOORD5;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS = TransformWorldToView(o.positionWS);
                o.positionCS = TransformWViewToHClip(o.positionVS);
                o.uv.zw = _Water01.xy * _Time.y * _Water01.z;
                o.uv.xy = o.positionWS.xz * _FoamTex_ST.xy + o.uv.zw;
                o.normalUV.xy = TRANSFORM_TEX(v.uv, _NormalTex) + o.uv.zw;
                o.normalUV.zw = TRANSFORM_TEX(v.uv, _NormalTex) + o.uv.zw * float2(-1.07, 1.07);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                half distortValue = _Water01.w;
                half speed = i.uv.zw;
                half atten = _Water02.x;
                float specularDistort = _Water03.x;
                float specularIntensity = _Water03.y;
                float specularSmoothness = _Water03.z;
                
                half4 c;
                
                // 屏幕空间UV
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;

                // 水的深度
                // 使用相机空间下水面和水底的Z值差计算水的深度
                // 利用深度图获得水底Z值
                half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                half depthGround = LinearEyeDepth(depthTex, _ZBufferParams);
                // 水面Z值
                // 注意，相机空间是右手坐标系，Z值需要取反
                half depthWaterSurface = -i.positionVS.z;
                // 计算水的深度
                half depthWater = depthGround - depthWaterSurface;
                depthWater *= atten;
                
                // 水的颜色
                half4 waterColor = lerp(_WaterColor01, _WaterColor02, depthWater);

                // 法线
                half4 normal01 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.xy);
                half4 normal02 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.zw);
                half4 normalTex = normal01 * normal02;
                half3 normal = normalTex.xyz * distortValue;

                // 水下的扭曲
                half2 distortUV = screenUV + normal;
                half depthDistortTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, distortUV).r;
                half depthDistortGround = LinearEyeDepth(depthDistortTex, _ZBufferParams);
                half depthDistortWater = depthDistortGround - depthWaterSurface;
                float2 opaqueUV = distortUV;
                if(depthDistortWater < 0)
                {
                    opaqueUV = screenUV;
                }
                half4 distort = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, opaqueUV);

                // 水的焦散
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * depthDistortGround / depthWaterSurface;
                depthVS.z = depthDistortGround;
                float3 depthWS = mul(unity_CameraToWorld, depthVS).xyz;
                float2 causticUV01 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.2 + speed;
                float2 causticUV02 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.1 + speed * float2(-1.07, 1.43);
                half4 causticTex01 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV01);
                half4 causticTex02 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV02);
                half4 caustic = min(causticTex01, causticTex02);

                // 水的高光
                // Specular = SpecularColor * Ks * pow(max(0,dot(N,H)), Shininess)
                half3 N = lerp(i.normalWS, normalTex.xyz, specularDistort);
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                half3 H = normalize(L + V);
                half NdotH = dot(N, H);
                half4 specular = _SpecularColor * specularIntensity * pow(saturate(dot(N, H)), specularSmoothness);
                specular.a = 1;
                //return specular;

                // 水的反射
                N = normal;
                half3 reflectionUV = reflect(-V, N);
                half4 reflectionTex = SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, reflectionUV);
                half fresnel = pow(1 - saturate(dot(i.normalWS, V)), 3);
                half4 reflection = reflectionTex * fresnel;

                // 水的泡沫
                half foamRange = _FoamRange * depthWater;
                half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.xy).r;
                foamTex = pow(abs(foamTex), _FoamNoise);
                // 将两张图进行比较，将泡沫范围限定在foamRange之内
                half foamMask = step(foamRange, foamTex);
                half4 foam = foamMask * _FoamColor;
                

                c = waterColor * distort + foam + specular * reflection + caustic;

                c.a = 0.8;

                return c;
            }
            ENDHLSL
        }
    }
}
