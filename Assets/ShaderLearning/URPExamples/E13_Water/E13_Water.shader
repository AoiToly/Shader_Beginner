Shader "Shader Learning/URP/E13_Water"
{
    Properties
    {
        [Header(Common)]
        _Water01("Direction(XY) Speed(Z) Distort(W)",vector) = (1,1,0.1,0.05)
        _Water02("Atten(X) Lightness(Y) Caustic(Z)",vector) = (1,1,3,0)
        _Water03("Specular: Distort(X) Intensity(Y) Smoothness(Z)",vector) = (0.8,5,8,0)
        _Water04("FoamRange(X) FoamNoise(Y)",vector) = (5,2.8,0,0)
        _SpecularColor("Specular Color",color) = (1,1,1,1)
        _FoamColor("FoamColor",color) = (1,1,1,1)

        [Header(Texture)]
        _NormalTex("NormalTex",2D) = "white"{}
        _ReflectionTex("ReflectionTex",Cube) = "white"{}
        _CausticTex("CausticTex",2D) = "white"{}
        _FoamTex("FoamTex", 2D) = "white" {}
        _RampTexture("Ramp Tex", 2D) = "white" {}
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
            //Blend SrcAlpha OneMinusSrcAlpha

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
            float4 _Water01,_Water02,_Water03,_Water04;
            float4 _NormalTex_ST;
            half4 _SpecularColor;
            float4 _FoamTex_ST;
            half4 _FoamColor;
            float4 _CausticTex_ST;
            CBUFFER_END
            TEXTURE2D (_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURECUBE (_ReflectionTex);SAMPLER(sampler_ReflectionTex);
            TEXTURE2D (_CausticTex);SAMPLER(sampler_CausticTex);
            TEXTURE2D (_FoamTex);SAMPLER(sampler_FoamTex);

            TEXTURE2D (_RampTexture);SAMPLER(sampler_RampTexture);  //水的颜色渐变图

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float4 uv               : TEXCOORD0;    // xy为foam的uv，zw表示水流偏移
                float4 normalUV         : TEXCOORD1;
                float fogCoord          : TEXCOORD2;
                float3 positionVS       : TEXCOORD3;
                float3 positionWS       : TEXCOORD4;
                float3 normalWS         : TEXCOORD5;
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
                /// 参数预定义
                float distortValue = _Water01.w;
                float atten = _Water02.x;
                float lightness = _Water02.y;
                float causticIntensity = _Water02.z;
                float specularDistort = _Water03.x;
                float specularIntensity = _Water03.y;
                float specularSmoothness = _Water03.z;
                float foamRange = _Water04.x;
                float foamNoise = _Water04.y;
                float2 speed = i.uv.zw;
                
                /// 屏幕空间UV
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;

                /// 水的深度
                // 使用相机空间下水面和水底的Z值差计算水的深度
                // 利用深度图获得水底Z值
                half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                half depthGround = LinearEyeDepth(depthTex, _ZBufferParams);
                // 水面Z值
                // 注意，相机空间是右手坐标系，Z值需要取反
                half depthWaterSurface = -i.positionVS.z;
                // 计算水的深度
                half depthWater = depthGround - depthWaterSurface;
                depthWater = max(0, depthWater);
                // 衰减，控制水深
                depthWater *= atten;

                /// 法线
                // 两次UV采样，使法线运动方向不同，以产生水面波光粼粼的效果
                half4 normalTex01 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.xy);
                half4 normalTex02 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.zw);
                half4 normalTex = normalTex01 * normalTex02;
                // 计算法线扭曲
                half3 normal = normalTex.xyz * distortValue;

                /// 水下的扭曲，通过OpaqueTexture获得
                // 根据法线的扭曲计算新的UV
                half2 distortUV = screenUV + normal.xy;
                // 采样扭曲后的深度图，这张深度图用于判断扭曲后的图案是位于水下还是水上
                half depthDistortTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, distortUV).r;
                half depthDistortGround = LinearEyeDepth(depthDistortTex, _ZBufferParams);
                half depthDistortWater = depthDistortGround - depthWaterSurface;
                // 剔除水面以上部分的扭曲
                int isUnderWater = depthDistortWater > 0;
                distortUV = !isUnderWater * screenUV + isUnderWater * distortUV;
                half4 distort = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortUV);

                /// 水的焦散
                // 实现原理和深度贴画相同，将图片贴于水底即可
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * depthDistortGround / depthWaterSurface;
                depthVS.z = depthDistortGround;
                float3 depthWS = mul(unity_CameraToWorld, depthVS).xyz;
                // 用两个不同方向流动的uv采样焦散贴图，以实现随机流动的效果
                float2 causticUV01 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.2 + speed;
                float2 causticUV02 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.1 + speed * float2(-1.07, 1.43);
                half4 causticTex01 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV01);
                half4 causticTex02 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV02);
                // 贴图混合，新颖的min混合
                half4 caustic = min(causticTex01, causticTex02);
                caustic *= causticIntensity;

                /// 水的高光
                // Specular = SpecularColor * Ks * pow(max(0,dot(N,H)), Shininess)
                half3 N = normalize(lerp(i.normalWS, normalTex.xyz, specularDistort));
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                half3 H = normalize(L + V);
                half4 specular = _SpecularColor * specularIntensity * pow(saturate(dot(N, H)), specularSmoothness);

                /// 水的反射
                // 反射+菲涅尔
                N = normal;
                half3 reflectionUV = reflect(-V, N);
                half4 reflectionTex = SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, reflectionUV);
                half fresnel = pow(1 - saturate(dot(i.normalWS, V)), 3);
                half4 reflection = reflectionTex * fresnel;

                /// 水的泡沫
                // 根据深度计算泡沫产生的位置
                half foamWidth = foamRange * depthWater;
                half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.xy).r;
                foamTex = pow(abs(foamTex), foamNoise);
                // 将两张图进行比较，将泡沫范围限定在foamRange之内
                half foamMask = step(foamWidth, foamTex);
                half4 foam = foamMask * _FoamColor;
                
                // 水的颜色
                // 这里的颜色采样用的是depthWater
                // 如果使用depthDistortWater采样效果会更真
                // 但因为扭曲的问题，这种采样方法穿帮非常严重，并且目前我没想到什么很好的方法来解决
                half4 rampTex01 = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(depthWater, 1));
                half4 rampTex02 = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(depthWater, 0));

                half4 c = half4(0, 0, 0, 1);
                c += rampTex01 * lightness + specular * reflection + foam + (distort + caustic * lightness) * rampTex02;
                return c;
            }
            ENDHLSL
        }
    }
}
