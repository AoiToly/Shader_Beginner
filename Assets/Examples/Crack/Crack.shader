Shader "Example/Crack"
{
    Properties
    {
        _Color("Color",color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "Queue"="Geometry-2" "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            // ZTest Always
            // Stencil
            // {
                //     Ref 1
                //     Comp Equal
            // }

            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float4 positionOS       : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionOS = v.positionOS;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 c;
                half mask = abs(i.positionOS.y);
                float t = sin(_Time.y)*0.3+0.7;
                c = lerp(0,_Color * t,mask);
                return c;
            }
            ENDHLSL
        }

        Pass
        {
            Tags {"LightMode" = "SRPDefaultUnlit"}
            // Stencil
            // {
                //     Ref 1
                //     Comp Never
                //     Fail Replace
            // }

            ColorMask 0
            
            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                v.positionOS.y = 0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
