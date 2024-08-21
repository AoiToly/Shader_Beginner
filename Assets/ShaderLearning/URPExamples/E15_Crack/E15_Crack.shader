Shader "Shader Learning/URP/E15_Crack"
{
    Properties
    {
        _Color("Color", color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry-1"
        }
        
        // 思路是，先于普通平面渲染
        // 首先用一个pass渲染裂纹内部的细节
        // 再用另一个pass将裂纹拍成面片置于顶部，并设置ColorMask为0用以显示上一个pass中的内容
        // 注意渲染先后顺序，由DrawObjectPass脚本可知，SRPDefaultUnlit先于UniversalForward渲染，渲染顺序与pass在在脚本中的位置无关
        
        Pass
        {
            Tags 
            { 
                "LightMode" = "SRPDefaultUnlit"
            }
            
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            CBUFFER_END
            
            // 顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionOS : TEXCOORD0;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionOS.xyz = v.positionOS;
                return o;
            }

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                half4 c = _Color;
                // anim
                float t = sin(_Time.y * 2) * 0.4 + 0.6;
                c *= t;
                half depth = saturate(abs(i.positionOS.y));
                c *= depth;
                return c;
            }
            ENDHLSL
        }
        
        Pass
        {
            Tags 
            { 
                "LightMode" = "UniversalForward"
            }
            ColorMask 0
            Offset -1, -1
            
            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
        
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // 顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                v.positionOS.y = 0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                return o;
            }

            // 片段着色器
            half4 frag(Varyings i) : SV_Target0
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
