Shader "taecg/Common/Checker"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull Mode",int)=0
        _Color("Color",Color) = (1,1,1,1)
        _Repeat("Repeat",float) = 5
    }

    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType"="Opaque" 
        }
        Cull [_Cull]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog   //FOG_LINEAR FOG_EXP FOG_EXP2

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertexCS : SV_POSITION;
                float3 vertexOS:TEXCOORD1;
                float fogCoord  : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Repeat;
            half4 _Color;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertexOS = v.vertexOS;
                o.vertexCS = TransformObjectToHClip(v.vertexOS);
                o.uv = v.uv * _Repeat;
                o.fogCoord = ComputeFogFactor(o.vertexCS.z);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 c;
                float2 uv = floor(i.uv*2)*0.5;
                float checker = frac(uv.x+uv.y)*2;

                half mask = i.vertexOS.y+0.53;
                c = checker * mask;
                c *= _Color;

                c.rgb = MixFog(c, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull [_Cull]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertexCS : SV_POSITION;
                float3 vertexOS : TEXCOORD1;
            };

            half _Repeat;
            half4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertexOS = v.vertexOS;
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.uv = v.uv * _Repeat;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 c;
                float2 uv = floor(i.uv*2)*0.5;
                float checker = frac(uv.x+uv.y)*2;

                half mask = i.vertexOS.y+0.53;
                c = checker * mask;
                c *= _Color;
                return c;
            }
            ENDCG
        }
    }

    Fallback "Diffuse"
}
