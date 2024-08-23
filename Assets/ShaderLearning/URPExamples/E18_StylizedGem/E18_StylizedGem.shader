Shader "Shader Learning/URP/E18_StylizedGem"
{
    Properties
    {
        [Header(Specular)]
        _SpecularColor("Specular Color", color) = (1, 1, 1, 1)
        _Specular("Intensity(x) Atten(y)", vector) = (1, 1, 1, 1)

        [Header(Rim)]
        _RimColorInner("Rim Color Inner", color) = (1, 1, 1, 1)
        _RimColorOuter("Rim Color Outer", color) = (1, 1, 1, 1)
        _Rim("Intensity(x) Atten(y)", vector) = (1, 2, 0, 0)

        [Header(Reflect)]
        _Reflect("Reflect", range(0, 1)) = 0.1
        _ReflectColorOffset("Reflect Color Offset", range(0, 0.2)) = 0.015

        [Header(Noise)]
        [Toggle]_NoiseEnabled("NoiseEnabled", int) = 0
        _NoiseMap("Noise Map", 2D) = "white" {}
        _Noise("Intensity(x) Atten(y) Parallax(z)", vector) = (1, 2, 0, 0)
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
        Pass
        {
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ _NOISEENABLED_ON
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _SpecularColor;
            half4 _Specular;
            half4 _RimColorInner;
            half4 _RimColorOuter;
            half4 _Rim;
            half _Reflect;
            half _ReflectColorOffset;
            half4 _NoiseMap_ST;
            half4 _Noise;
            CBUFFER_END
            TEXTURE2D(_NoiseMap); SAMPLER(sampler_NoiseMap);
            TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                half4 tangentWS     :TEXCOORD3;
                half4 bitangentWS   :TEXCOORD4;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseMap);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.tangentWS.xyz = TransformObjectToWorldDir(v.tangentOS.xyz);
                half sign = v.tangentOS.w * GetOddNegativeScale();
                o.bitangentWS.xyz = cross(o.normalWS, o.tangentWS.xyz) * sign;

                return o;
            }

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = 1;
                
                half3 v = normalize(_WorldSpaceCameraPos - i.positionWS);
                Light mainLight = GetMainLight();
                half3 l = mainLight.direction;
                half3 h = normalize(l + v);
                half3 n = i.normalWS;
                
                // Blinn-Phong
                // Specular = SpecularColor * Ks * pow(max(0,dot(N,H)), Shininess)
                half ks = _Specular.x;
                half shininess = _Specular.y;
                half3 specular = _SpecularColor.rgb * ks * pow(max(0, dot(n, h)), shininess);

                // Rim(fresnel)
                // ndotv
                half fresnel = 1 - saturate(dot(n, v));
                half rimIntensity = _Rim.x;
                half rimAtten = _Rim.y;
                half rim = pow(max(0, fresnel), rimAtten);
                half3 rimColor = rimIntensity * lerp(_RimColorInner, _RimColorOuter, rim).rgb;
                
                // 折射
                half2 screenUV = GetNormalizedScreenSpaceUV(i.positionCS.xy);
                half2 reflectUV = lerp(screenUV, fresnel, _Reflect);
                //half3 reflect = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, reflectUV).rgb;
                half3 reflect;
                // 颜色分离
                reflect.r = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, reflectUV).r;
                reflect.gb = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, reflectUV + _ReflectColorOffset).gb;

                // 亮闪闪的效果
                #if _NOISEENABLED_ON
                    // 利用视差映射使效果更具有体积感
                    half vTS = normalize(mul(float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz), v)).r;
                    // 用fresnel代替视差映射贴图
                    half parallaxMap = fresnel;
                    half parallax = _Noise.z;
                    float2 offset = -v.xy * parallaxMap * parallax;
                    half4 noiseMap = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, i.uv + offset);
                    // 转换到世界空间下
                    half3 noiseWS = mul(noiseMap.xyz,half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz));
                    half3 noiseNormal = n + noiseWS.rgb;
                    half noiseNdotV = max(0, dot(noiseNormal, v));
                    half noiseIntensity = _Noise.x;
                    half noiseAtten = _Noise.y;
                    half3 noise = noiseIntensity * pow(noiseNdotV, noiseAtten);

                #else
                    half3 noise = 0;
                #endif

                c.rgb = specular + rimColor + reflect + noise;

                return c;
            }
            ENDHLSL
        }
    }
}
