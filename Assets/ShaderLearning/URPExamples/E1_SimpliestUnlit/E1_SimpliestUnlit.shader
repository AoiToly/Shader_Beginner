// 由默认Unlit Shader Graph精简而来
Shader "Shader Learning/URP/E1_SimpliestUnlit"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
    }
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
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            TEXTURE2D(_MainTex);   // 纹理的定义，如果是编译到GLES2.0平台，则相当于_MainTex；否则就相当于sampler2D
            float4 _MainTex_ST;
            SAMPLER(sampler_MainTex);   // 采样器定义，如果是编译到GLES2.0平台，则相当于空；否则就相当于SamplerState sampler_MainTex
            CBUFFER_END

            // 顶点着色器的输入（模型的数据信息）
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

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            // 片段着色器
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                outColor = mainTex * _Color;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}