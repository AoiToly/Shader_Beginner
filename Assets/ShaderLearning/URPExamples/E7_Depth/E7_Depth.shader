Shader "Shader Learning/URP/E7_Depth"
{
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
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag

            // �������ͼ���������
            #define REQUIRE_DEPTH_TEXTURE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);   // ����Ķ��壬����Ǳ��뵽GLES2.0ƽ̨�����൱��_MainTex��������൱��sampler2D
            SAMPLER(sampler_MainTex);   // ���������壬����Ǳ��뵽GLES2.0ƽ̨�����൱�ڿգ�������൱��SamplerState sampler_MainTex
            half4 _Color;
            CBUFFER_END
            float4 _MainTex_ST;

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            // Ƭ����ɫ��
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;
                
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                half depth = Linear01Depth(depthMap, _ZBufferParams).x;
                //half depth = LinearEyeDepth(depthMap.x, _ZBufferParams).x;

                outColor = depth;
            }
            ENDHLSL
        }
    }

    // Builtin
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        Pass
        {
            CGPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "UnityCG.cginc"
            
            
            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _CameraDepthTexture;

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.uv = v.uv;

                return o;
            }

            // Ƭ����ɫ��
            void frag(Varyings i, out fixed4 outColor : SV_Target)
            {
                float2 uv = i.positionCS.xy / _ScreenParams.xy;
                fixed depthMap = frac(tex2D(_CameraDepthTexture, uv));
                fixed depth = Linear01Depth(depthMap);
                //fixed depth = LinearEyeDepth(depthMap);
                outColor = depth;
            }
            ENDCG
        }
    }

    FallBack "Hidden/Shader Graph/FallbackError"
}
