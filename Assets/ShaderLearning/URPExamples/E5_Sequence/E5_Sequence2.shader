Shader "Shader Learning/URP/Sequence2"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _SequenceParams("XNum(x) YNum(y), Speed(z)", vector) = (1, 1, 1, 0)
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor", int) = 0
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }
        Blend [_SrcFactor][_DstFactor]
        Pass
        {
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _ISCONTINOUS_ON
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);   // 纹理的定义，如果是编译到GLES2.0平台，则相当于_MainTex；否则就相当于sampler2D
            SAMPLER(sampler_Repeat_Bilinear);
            float4 _MainTex_ST;
            half4 _SequenceParams;
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

                o.uv = float2(v.uv.x/_SequenceParams.x, v.uv.y/_SequenceParams.y + 1/_SequenceParams.y*(_SequenceParams.y-1));
                o.uv.x += frac(floor(_Time.y*_SequenceParams.z)/_SequenceParams.x);
                o.uv.y -= frac(floor(_Time.y*_SequenceParams.z/_SequenceParams.x)/_SequenceParams.y);
                return o;
            }

            // 片段着色器
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_Repeat_Bilinear, i.uv);
                outColor = mainTex;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
