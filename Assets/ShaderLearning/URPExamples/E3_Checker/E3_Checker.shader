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
            #pragma multi_compile_fog

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
                float fogCoord  : TEXCOORD2;
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
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            void frag (Varyings i, out half4 outColor : SV_Target)
            {
                half2 uv = floor(i.uv * 2) / 2;
                
                outColor = frac(uv.x + uv.y) * (i.positionOS.y + _Offset) * _Color;
                outColor.rgb = MixFog(outColor.rgb, i.fogCoord);
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

        pass
        {
            // 这个Pass用于生成shadow map
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ _DISSOLVEENABLED_ON

            #include "UnityCG.cginc"

            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            fixed _Dissolve;

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.uv, _DissolveTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
}
