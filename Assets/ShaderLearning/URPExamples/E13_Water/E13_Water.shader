Shader "Shader Learning/URP/E13_Water"
{
    Properties
    {
        _WaterColor01("Water Color01(RGB)", Color) = (1, 1, 1, 1)
        _WaterColor02("Water Color02(RGB)", Color) = (1, 1, 1, 1)

        _Speed("Speed", range(0, 2)) = 1

        [Header(Foam)]
        _FoamTex("Foam Tex", 2D) = "white" {}
        _FoamColor("Foam Color", color) = (1, 1, 1, 1)
        _FoamRange("Foam Range", range(0, 50)) = 1
        _FoamNoise("Foam Noise", range(0, 1)) = 1
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
            half4 _WaterColor01;
            half4 _WaterColor02;

            half _Speed;

            float4 _FoamTex_ST;
            half4 _FoamColor;
            half _FoamRange;
            half _FoamNoise;
            CBUFFER_END
            TEXTURE2D(_FoamTex);
            SAMPLER(sampler_FoamTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xyΪfoam��uv
                float4 uv : TEXCOORD0;
                float fogCoord  : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS = TransformWorldToView(o.positionWS);
                o.positionCS = TransformWViewToHClip(o.positionVS);
                o.uv.xy = o.positionWS.xz * _FoamTex_ST.xy + _Time.y * _Speed;
                o.uv += _Time.y * _Speed;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c;
                
                // ��Ļ�ռ�UV
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;

                // ˮ�����
                // ʹ������ռ���ˮ���ˮ�׵�Zֵ�����ˮ�����
                // �������ͼ���ˮ��Zֵ
                half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                half depthGround = LinearEyeDepth(depthTex, _ZBufferParams);
                // ˮ��Zֵ
                // ע�⣬����ռ�����������ϵ��Zֵ��Ҫȡ��
                half depthWaterSurface = -i.positionVS.z;
                // ����ˮ�����
                half depthWater = depthGround - depthWaterSurface;
                
                // ˮ����ɫ
                half4 waterColor = lerp(_WaterColor01, _WaterColor02, depthWater);

                // ˮ�ĸ߹�


                // ˮ�ķ���


                // ˮ�Ľ�ɢ


                // ˮ�µ�Ť��


                // ˮ����ĭ
                half foamRange = _FoamRange * depthWater;
                half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.xy).r;
                foamTex = pow(foamTex, _FoamNoise);
                // ������ͼ���бȽϣ�����ĭ��Χ�޶���foamRange֮��
                half foamMask = step(foamRange, foamTex);
                half4 foam = foamMask * _FoamColor;
                
                c = foam + waterColor;
                return c;
            }
            ENDHLSL
        }
    }
}
