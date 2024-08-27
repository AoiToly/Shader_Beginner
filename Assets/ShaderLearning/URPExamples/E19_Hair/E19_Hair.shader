Shader "Shader Learning/URP/E19_Hair"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color", Color) = (1, 1, 1, 1)

        [Header(Specular)]
        [HDR]_SpecularColor1("Specular Color1", Color) = (1, 1, 1, 1)
        [HDR]_SpecularColor2("Specular Color2", Color) = (1, 1, 1, 1)
        _PrimaryShift("Primary Shift", float) = 0
        _SecondaryShift("Secondary Shift", float) = 0
        _Clip("Clip", range(0, 1)) = 0.5
        _Specular("Specular", float) = 1
        _Exponent("Exponent", float) = 1
        _ShiftTex("Shift Tex", 2D) = "black" {}

        [Header(Fresnel)]
        _Fresnel("Intensity(x) Atten(y)", vector) = (1, 1, 1, 1)
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
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half4 _SpecularColor1;
            half4 _SpecularColor2;
            half _PrimaryShift, _SecondaryShift;
            half _Clip;
            half _Specular;
            half _Exponent;
            half4 _Fresnel;
            CBUFFER_END
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_ShiftTex); SAMPLER(sampler_ShiftTex);

            struct Attributes
            {
                float3 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
            };

            half CalculateSpecular(half3 T, half3 V, half3 L, half exponent)
            {
                // Kajiya-Kay
                // sqrt(1-dot(T,H)^2)^specularity
                half3 H = normalize(L + V);
                half dotTH = dot(T, H);
                half sinTH = sqrt(1 - dotTH * dotTH);
                half dirAtten = smoothstep(-1, 0, dotTH);
                return dirAtten * pow(sinTH, exponent);
            }

            //沿着法线方向调整Tangent方向
            half3 ShiftTangent(half3 T, half3 N, half shift)
            {
                return normalize(T + shift * N);
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                half3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half sign = v.tangentOS.w * GetOddNegativeScale();
                o.bitangentWS.xyz = normalize(cross(o.normalWS, tangentWS) * sign);

                return o;
            }

            half4 frag(Varyings i) : SV_Target0
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                clip(mainTex.r-_Clip);
                half3 mainColor = mainTex.rgb * _Color.rgb;

                // Lambert
                half3 n = i.normalWS;
                Light mainLight = GetMainLight();
                half3 l = mainLight.direction;
                half3 lambert = mainColor * max(0.2, dot(n, l));

                half3 v = normalize(_WorldSpaceCameraPos - i.positionWS);

                // Shift
                float shift = SAMPLE_TEXTURE2D(_ShiftTex, sampler_ShiftTex, i.uv).r - 0.5;
                half3 t1 = ShiftTangent(i.bitangentWS, n, shift + _PrimaryShift);
                half3 t2 = ShiftTangent(i.bitangentWS, n, shift + _SecondaryShift);

                half3 specular1 = CalculateSpecular(t1, v, l, _Exponent) * _SpecularColor1.rgb;
                half3 specular2 = CalculateSpecular(t2, v, l, _Exponent) * _SpecularColor2.rgb;

                // fresnel
                half dotnv = dot(n, v);
                half fresnel = _Fresnel.x * pow(1 - saturate(dotnv), _Fresnel.y);

                half4 c = 0;
                c.rgb = lambert + specular1 * _Specular + specular2 * _Specular + fresnel;

                return c;
            }
            ENDHLSL
        }
    }
}
