Shader "Shader Learning/URP/E10_DepthDecal"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
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
        Blend One One

        Pass
        {
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            // �������ͼ���������
            #define REQUIRE_DEPTH_TEXTURE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            CBUFFER_END
            TEXTURE2D(_MainTex);   // ����Ķ��壬����Ǳ��뵽GLES2.0ƽ̨�����൱��_MainTex��������൱��sampler2D
            SAMPLER(sampler_MainTex);   // ���������壬����Ǳ��뵽GLES2.0ƽ̨�����൱�ڿգ�������൱��SamplerState sampler_MainTex

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionOS : TEXCOORD1;
                float4 positionVS : TEXCOORD2;
                float fogCoord  : TEXCOORD3;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.positionOS = v.positionOS;
                o.positionVS = float4(TransformWorldToView(TransformObjectToWorld(v.positionOS.xyz)), 1);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                // ˼·��
                // ͨ�����ͼ����������ڵĹ۲�ռ��е�Zֵ
                // ͨ����ǰ��Ⱦ����Ƭ��������ڹ۲�ռ��µ�����
                // ͨ����������������ͼ�е����ص�XYZ����
                // �ٽ�������ת����Ƭģ�͵ı��ؿռ䣬��XY����UV�������������

                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;                
                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                half depth = LinearEyeDepth(depthMap.x, _ZBufferParams).x;

                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * depth / -i.positionVS.z;
                depthVS.z = depth;

                float3 depthWS = mul(unity_CameraToWorld, depthVS).xyz;
                float3 depthOS = mul(unity_WorldToObject, float4(depthWS, 1)).xyz;
                float2 uv = depthOS.xz + 0.5;
                
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

                // ���Blend One One����Ч��Ϸ���
                c.rgb *= saturate(lerp(1, 0, i.fogCoord));
                //c.rgb = MixFog(c.rgb, i.fogCoord);

                return c * _Color;
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
        Blend One One

        Pass
        {
            CGPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
        
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            sampler2D _CameraDepthTexture;
            
            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionOS : TEXCOORD1;
                float4 positionVS : TEXCOORD2;
                float fogCoord : TEXCOORD3;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                

                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.positionOS = v.positionOS;
                o.positionVS = mul(UNITY_MATRIX_MV, v.positionOS);
                UNITY_TRANSFER_FOG(o, o.positionVS);
                return o;
            }

            // Ƭ����ɫ��
            fixed4 frag(Varyings i) : SV_Target
            {
                
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;      
                fixed depthMap = frac(tex2D(_CameraDepthTexture, screenUV));          
                half depth = LinearEyeDepth(depthMap.x).x;

                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * depth / -i.positionVS.z;
                depthVS.z = depth;

                float3 depthWS = mul(unity_CameraToWorld, depthVS);
                float3 depthOS = mul(unity_WorldToObject, float4(depthWS, 1));
                float2 uv = depthOS.xz + 0.5;
                
                half4 c = tex2D(_MainTex, uv);

                // ���Blend One One����Ч��Ϸ���
                c.rgb *= saturate(lerp(1, 0, i.fogCoord));
                //UNITY_APPLY_FOG(i.fogCoord, c);

                return c * _Color;
            }
            ENDCG
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
