Shader "Shader Learning/URP/E9_EnergyShield"
{
    Properties
    {
        [Header(Base)]
        _MainTex("Main Tex", 2D) = "white" {}
        _FresnelColor("Fresnel Color", color) = (1, 1, 1, 1)
        [PowerSlider(3)]_FresnelIntensity("Fresnel Intensity", range(0, 15)) = 1
        [Space(25)]

        [Header(Highlight)]
        _HighlightColor("Highlight Color", color) = (1, 1, 1, 1)
        _HighlightFade("Highlight Fade", float) = 3
        [Space(25)]

        [Header(Distort Flow)]
        _FlowTiling("Flow Tiling", float) = 8
        _FlowSpeed("Flow Speed", float) = 1
        _Distort("Distort", range(0, 1)) = 0.4
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
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            
            #define REQUIRE_DEPTH_TEXTURE
            #define REQUIRE_OPAQUE_TEXTURE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _HighlightColor;
            float _HighlightFade;
            half4 _FresnelColor;
            float _FresnelIntensity;
            float _FlowTiling;
            float _FlowSpeed;
            half _Distort;
            CBUFFER_END
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xy�����MainTex��uv��zw����������uv
                float4 uv : TEXCOORD0;
                float3 positionVS : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 positionWS = TransformObjectToWorld(v.positionOS);
                float3 positionVS = TransformWorldToView(positionWS);

                o.positionCS = TransformWViewToHClip(positionVS);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv;
                o.positionVS = positionVS;
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.positionWS = positionWS;

                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c;

                // ��͸����ʱ��Խ�ӽ��Ӵ�����ɫԽǿ��Ч��
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                // ���ͼ�ڹ۲�ռ��µ�zֵ
                half depthTex = LinearEyeDepth(depthMap, _ZBufferParams);
                // ģ���ڹ۲�ռ��µ�zֵ�����ڹ۲�ռ�����������ϵ������zֵȡ��
                half depth = -i.positionVS.z;
                // ����߹������������ͼzֵ��ģ��zֵ�Ĳ�ֵ
                half4 highlight = depthTex - depth;
                highlight *= _HighlightFade;
                highlight = saturate((1 - highlight) * _HighlightColor);
                c = highlight;

                // fresnel
                // pow(max(0, dot(N, V)), Intensity)
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float NdotV = 1 - saturate(dot(N, V));
                float4 fresnel = pow(abs(NdotV), _FresnelIntensity) * _FresnelColor;
                c += fresnel;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                c += mainTex * _FresnelColor * 0.03;

                // Ť������Ч��
                half4 mainTex01 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, half2(i.uv.x, i.uv.y + _Time.y * _FlowSpeed));
                float2 distortUV = lerp(screenUV, mainTex01.rg, _Distort);
                half4 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortUV);
                half4 distort = half4(opaqueTex.rgb, 1);
                half flowMask = frac(i.uv.w * _FlowTiling + _Time.y * _FlowSpeed);
                distort *= flowMask;
                c += distort;

                return c;
            }
            ENDHLSL
        }
    }

    // Builtin
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        ZWrite off
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass { "_GrabTex" }

        Pass
        {
            CGPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            sampler2D _GrabTex;
            half4 _HighlightColor;
            float _HighlightFade;
            half4 _FresnelColor;
            float _FresnelIntensity;
            float _FlowTiling;
            float _FlowSpeed;
            half _Distort;

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xy�����MainTex��uv��zw����������uv
                float4 uv : TEXCOORD0;
                float3 positionVS : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 positionWS = mul(unity_ObjectToWorld, v.positionOS);
                float3 positionVS = UnityObjectToViewPos(v.positionOS);

                o.positionCS = mul(UNITY_MATRIX_P, float4(positionVS, 1));
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv;
                o.positionVS = positionVS;
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                o.positionWS = positionWS;

                return o;
            }

            // Ƭ����ɫ��
            fixed4 frag(Varyings i) : SV_Target0
            {
                half4 c;

                // ��͸����ʱ��Խ�ӽ��Ӵ�����ɫԽǿ��Ч��
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;
                half4 depthMap = tex2D(_CameraDepthTexture, screenUV);
                // ���ͼ�ڹ۲�ռ��µ�zֵ
                half depthTex = LinearEyeDepth(depthMap.x);
                // ģ���ڹ۲�ռ��µ�zֵ�����ڹ۲�ռ�����������ϵ������zֵȡ��
                half depth = -i.positionVS.z;
                // ����߹������������ͼzֵ��ģ��zֵ�Ĳ�ֵ
                half4 highlight = depthTex - depth;
                highlight *= _HighlightFade;
                highlight = saturate((1 - highlight) * _HighlightColor);
                c = highlight;

                // fresnel
                // pow(max(0, dot(N, V)), Intensity)
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float NdotV = 1 - saturate(dot(N, V));
                float4 fresnel = pow(abs(NdotV), _FresnelIntensity) * _FresnelColor;
                c += fresnel;

                half4 mainTex = tex2D(_MainTex, i.uv.xy);
                c += mainTex * _FresnelColor * 0.03;

                // Ť������Ч��
                half4 mainTex01 = tex2D(_MainTex, half2(i.uv.x, i.uv.y + _Time.y * _FlowSpeed));
                float2 distortUV = lerp(screenUV, mainTex01.rr, _Distort);
                half4 opaqueTex = tex2D(_GrabTex, distortUV);
                half4 distort = half4(opaqueTex.rgb, 1);
                half flowMask = frac(i.uv.w * _FlowTiling + _Time.y * _FlowSpeed);
                distort *= flowMask;
                c += distort;

                return c;
            }
            ENDCG
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
