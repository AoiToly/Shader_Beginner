Shader "Shader Learning/URP/E3_Checker"
{
    Properties
    {
        _Repeat("Repeat", float) = 5
        _Color("Color", Color) = (1, 1, 1, 1)
        _Offset("Offset", float) = 0.6
        [Toggle]_Shadow("Shadow", float) = 0
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
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _SHADOW_ON
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionOS   : TEXCOORD1;
                float fogCoord      : TEXCOORD2;
                float3 positionWS   : TEXCOORD3;

                float4 shadowCoord  : TEXCOORD4;
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
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    #if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
                        o.shadowCoord = ComputeScreenPos(o.positionCS);
                    #else
                        o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                    #endif
                #endif
                return o;
            }

            void frag (Varyings i, out half4 outColor : SV_Target)
            {
                half2 uv = floor(i.uv * 2) / 2;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    i.shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    i.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    i.shadowCoord = float4(0, 0, 0, 0);
                #endif

                Light mainLight = GetMainLight(i.shadowCoord);
                
            #if _SHADOW_ON
                outColor = frac(uv.x + uv.y) * (i.positionOS.y + _Offset) * _Color * mainLight.shadowAttenuation;
            #else
                outColor = frac(uv.x + uv.y) * (i.positionOS.y + _Offset) * _Color;
            #endif
                outColor.rgb = MixFog(outColor.rgb, i.fogCoord);
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
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
            #include "AutoLight.cginc"

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
                UNITY_SHADOW_COORDS(2)
                float3 positionWS : TEXCOORD3;
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
                TRANSFER_SHADOW(o);
                o.positionWS = mul(unity_ObjectToWorld, v.positionOS);
                return o;
            }

            void frag (Varyings i, out half4 outColor : SV_Target)
            {
                half2 uv = floor(i.uv * 2) / 2;
                half4 chessColor = frac(uv.x + uv.y) * (i.positionOS.y + _Offset) * _Color;
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.positionWS);

                outColor = chessColor * atten;
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
