Shader "Shader Learning/URP/E3_Checker"
{
    Properties
    {
        _Repeat("Repeat", float) = 5
        _Color("Color", Color) = (1, 1, 1, 1)
        _Offset("Offset", float) = 0.6
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque" 
        }

        Cull front
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionOS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Repeat;
            half4 _Color;
            half _Offset;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv * _Repeat;
                o.positionOS = v.positionOS.xyz;
                return o;
            }

            void frag (Varyings i, out half4 outColor : SV_Target)
            {
                half2 uv = floor(i.uv * 2) / 2;
                
                outColor = frac(uv.x + uv.y) * (i.positionOS.y + _Offset) * _Color;
            }
            ENDHLSL
        }
    }

    // Builtin
    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque" 
        }

        Cull front
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionOS : TEXCOORD1;
            };

            half _Repeat;
            half4 _Color;
            half _Offset;

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = UnityObjectToClipPos(v.positionOS.xyz);
                o.uv = v.uv * _Repeat;
                o.positionOS = v.positionOS.xyz;
                return o;
            }

            void frag (Varyings i, out half4 outColor : SV_Target)
            {
                half2 uv = floor(i.uv * 2) / 2;
                
                outColor = frac(uv.x + uv.y) * (i.positionOS.y + _Offset) * _Color;
            }
            ENDCG
        }
    }
}
