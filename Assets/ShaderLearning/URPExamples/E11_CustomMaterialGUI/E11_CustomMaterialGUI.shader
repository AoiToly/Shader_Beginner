Shader "Shader Learning/URP/E11_CustomMaterialGUI"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
        _Float("Float", float) = 0
        _Slider("Slider", range(0, 1)) = 0
        _Vector("Vector", vector) = (0, 0, 0, 0)

        _SrcBlend("SrcBlend", float) = 0
        _DstBlend("DstBlend", float) = 0

        // ���أ�shader�㷨�����ã������ڴ洢Editor״̬
        _Save("Save", vector) = (0, 0, 0, 0)
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Blend [_SrcBlend][_DstBlend]

        Pass
        {
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _COLORENABLED_ON
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            float _Float;
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
                float fogCoord  : TEXCOORD1;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c.rgb = MixFog(c.rgb, i.fogCoord);
                #if _COLORENABLED_ON
                    return c * _Color;
                #else
                    return c;
                #endif
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
            #pragma multi_compile_fog
        
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            
            // ������ɫ�������루ģ�͵�������Ϣ��
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
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

                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            // Ƭ����ɫ��
            fixed4 frag(Varyings i) : SV_Target
            {
                half4 c = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c * _Color;
            }
            ENDCG
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
    CustomEditor "E11_CustomMaterialGUI"
}
