// ���Լ���ʵ��
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

        // �ڵ�ͼƬ��͸��: Blend One One
        // ͸��ͨ��ͼƬ��͸����
        // ����һ��Blend SrcAlpha OneMinusSrcAlpha
        // ����������͸��ͨ��������ɫ��������Blend One One
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
            TEXTURE2D(_MainTex);   // ����Ķ��壬����Ǳ��뵽GLES2.0ƽ̨�����൱��_MainTex��������൱��sampler2D
            SAMPLER(sampler_Repeat_Bilinear);
            half4 _SequenceParams;
            int _IsContinous;
            CBUFFER_END

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xy��ʾͼƬTexUV��zw��ʾw��z�е���ͼƬ
                float4 uv : TEXCOORD0;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);

                // ����֡�������ŵ��ڼ�֡��
                half progress = _SequenceParams.z * _Time.y;
                // �������
                #if _ISCONTINOUS_ON
                    half2 startPoint = half2(fmod(progress, _SequenceParams.x), _SequenceParams.y -1 - floor(progress / _SequenceParams.x));
                #else
                    half2 startPoint = half2(floor(fmod(progress, _SequenceParams.x)), _SequenceParams.y - 1 - floor(progress / _SequenceParams.x));
                #endif

                o.uv = float4(v.uv, startPoint);
                
                return o;
            }

            // Ƭ����ɫ��
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                // ÿһ����ͼ�ĳ��Ϳ�
                half2 grid = half2(1/_SequenceParams.x, 1/_SequenceParams.y);
                // ��x��yԽ��ʱ�����Ĵ���
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

        // �ڵ�ͼƬ��͸��: Blend One One
        // ͸��ͨ��ͼƬ��͸����
        // ����һ��Blend SrcAlpha OneMinusSrcAlpha
        // ����������͸��ͨ��������ɫ��������Blend One One
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

            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // xy��ʾͼƬTexUV��zw��ʾw��z�е���ͼƬ
                float4 uv : TEXCOORD0;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = UnityObjectToClipPos(v.positionOS);

                // ����֡�������ŵ��ڼ�֡��
                half progress = _SequenceParams.z * _Time.y;
                // �������
                #if _ISCONTINOUS_ON
                    half2 startPoint = half2(fmod(progress, _SequenceParams.x), _SequenceParams.y -1 - floor(progress / _SequenceParams.x));
                #else
                    half2 startPoint = half2(floor(fmod(progress, _SequenceParams.x)), _SequenceParams.y -1 - floor(progress / _SequenceParams.x));
                #endif

                o.uv = float4(v.uv, startPoint);
                
                return o;
            }

            // Ƭ����ɫ��
            void frag(Varyings i, out fixed4 outColor : SV_Target0)
            {
                // ÿһ����ͼ�ĳ��Ϳ�
                half2 grid = half2(1/_SequenceParams.x, 1/_SequenceParams.y);
                // ��x��yԽ��ʱ�����Ĵ���
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
