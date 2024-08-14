// 我自己的实现
Shader "Shader Learning/URP/Sequence1"
{
    Properties
    {
        [NoScaleOffset]_MainTex("Main Tex", 2D) = "white" {}
        _SequenceParams("XNum(x) YNum(y), Speed(z)", vector) = (1, 1, 1, 0)
        [Toggle]_IsContinous("IsContinous", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor", int) = 0
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        // 黑底图片做透明: Blend One One
        // 透明通道图片做透明：
        // 方案一：Blend SrcAlpha OneMinusSrcAlpha
        // 方案二：将透明通道乘以颜色，并设置Blend One One
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
            half4 _SequenceParams;
            int _IsContinous;
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
                // xy表示图片TexUV，zw表示w行z列的子图片
                float4 uv : TEXCOORD0;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);

                // 序列帧动画播放到第几帧了
                half progress = _SequenceParams.z * _Time.y;
                // 采样起点
                #if _ISCONTINOUS_ON
                    half2 startPoint = half2(fmod(progress, _SequenceParams.x), _SequenceParams.y -1 - floor(progress / _SequenceParams.x));
                #else
                    half2 startPoint = half2(floor(fmod(progress, _SequenceParams.x)), _SequenceParams.y - 1 - floor(progress / _SequenceParams.x));
                #endif

                o.uv = float4(v.uv, startPoint);
                
                return o;
            }

            // 片段着色器
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                // 每一张子图的长和宽
                half2 grid = half2(1/_SequenceParams.x, 1/_SequenceParams.y);
                // 当x、y越界时所做的处理
                half overflowX = step(_SequenceParams.x, i.uv.z + i.uv.x);
                half x = i.uv.z + i.uv.x - overflowX * _SequenceParams.x;
                half overflowY = step(_SequenceParams.y, i.uv.w + i.uv.y + overflowX);
                half y = i.uv.w + i.uv.y - overflowX + overflowY * _SequenceParams.y;
                half2 uv = half2(x * grid.x, y * grid.y);

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_Repeat_Bilinear, uv);
                outColor = mainTex;
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

        // 黑底图片做透明: Blend One One
        // 透明通道图片做透明：
        // 方案一：Blend SrcAlpha OneMinusSrcAlpha
        // 方案二：将透明通道乘以颜色，并设置Blend One One
        Blend [_SrcFactor][_DstFactor]

        Pass
        {
            CGPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _ISCONTINOUS_ON
        
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            half4 _SequenceParams;
            int _IsContinous;

            // 顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xy表示图片TexUV，zw表示w行z列的子图片
                float4 uv : TEXCOORD0;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = UnityObjectToClipPos(v.positionOS);

                // 序列帧动画播放到第几帧了
                half progress = _SequenceParams.z * _Time.y;
                // 采样起点
                #if _ISCONTINOUS_ON
                    half2 startPoint = half2(fmod(progress, _SequenceParams.x), _SequenceParams.y -1 - floor(progress / _SequenceParams.x));
                #else
                    half2 startPoint = half2(floor(fmod(progress, _SequenceParams.x)), _SequenceParams.y -1 - floor(progress / _SequenceParams.x));
                #endif

                o.uv = float4(v.uv, startPoint);
                
                return o;
            }

            // 片段着色器
            void frag(Varyings i, out fixed4 outColor : SV_Target0)
            {
                // 每一张子图的长和宽
                half2 grid = half2(1/_SequenceParams.x, 1/_SequenceParams.y);
                // 当x、y越界时所做的处理
                half overflowX = step(_SequenceParams.x, i.uv.z + i.uv.x);
                half x = i.uv.z + i.uv.x - overflowX * _SequenceParams.x;
                half overflowY = step(_SequenceParams.y, i.uv.w + i.uv.y + overflowX);
                half y = i.uv.w + i.uv.y - overflowX + overflowY * _SequenceParams.y;
                half2 uv = half2(x * grid.x, y * grid.y);

                fixed4 mainTex = tex2D(_MainTex, uv);
                outColor = mainTex;
            }
            ENDCG
        }
    }

    FallBack "Hidden/Shader Graph/FallbackError"
}
