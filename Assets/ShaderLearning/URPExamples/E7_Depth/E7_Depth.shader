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

            // 声明深度图及其采样器
            #define REQUIRE_DEPTH_TEXTURE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);   // 纹理的定义，如果是编译到GLES2.0平台，则相当于_MainTex；否则就相当于sampler2D
            SAMPLER(sampler_MainTex);   // 采样器定义，如果是编译到GLES2.0平台，则相当于空；否则就相当于SamplerState sampler_MainTex
            half4 _Color;
            CBUFFER_END
            float4 _MainTex_ST;

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

            sampler2D _CameraDepthTexture;

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.uv = v.uv;

                return o;
            }

            // 片段着色器
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
