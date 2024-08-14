// 公告牌shader，保证面片始终朝向相机
Shader "Shader Learning/URP/E6_BillBoard"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        [HDR]_Color("Color(RGB)", Color) = (1, 1, 1, 1)
        [Enum(BillBoard,1,VerticalBillBoard,0)]_BillBoardType("BillBoardType", int) = 0
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }
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
            
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);   // 纹理的定义，如果是编译到GLES2.0平台，则相当于_MainTex；否则就相当于sampler2D
            float4 _MainTex_ST;
            SAMPLER(sampler_MainTex);   // 采样器定义，如果是编译到GLES2.0平台，则相当于空；否则就相当于SamplerState sampler_MainTex
            half4 _Color;
            int _BillBoardType;
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

            // 思路：计算面向相机的坐标系的基向量矩阵，将其乘以本地空间中的点便可以得到结果

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                // 获得本地空间下相机位置
                // 注意，由于物体正面朝向相机，因此其x轴和y轴应该和相机的xy轴方向一致，而根据左手定则，z轴方向为相机指向物体
                // 因此，此处的viewDir需要取相反数
                float3 viewDir = -mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos, 1)).xyz;
                // 获得旋转后坐标系的基向量
                viewDir.y *= _BillBoardType;
                float3 z = normalize(viewDir);
                float3 y = float3(0, 1, 0);
                float3 x = normalize(cross(y, z));
                y = normalize(cross(z, x));

                float3x3 M = float3x3(
                    x.x, y.x, z.x,
                    x.y, y.y, z.y,
                    x.z, y.z, z.z);
                float3 targetPos = mul(M, v.positionOS);

                o.positionCS = TransformObjectToHClip(targetPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            // 片段着色器
            void frag(Varyings i, out half4 outColor : SV_Target0)
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                outColor = mainTex * _Color;
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
        
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            int _BillBoardType;
            
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

                // 获得本地空间下相机位置
                // 注意，由于物体正面朝向相机，因此其x轴和y轴应该和相机的xy轴方向一致，而根据左手定则，z轴方向为相机指向物体
                // 因此，此处的viewDir需要取相反数
                float3 viewDir = -mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
                // 获得旋转后坐标系的基向量
                viewDir.y *= _BillBoardType;
                float3 z = normalize(viewDir);
                float3 y = float3(0, 1, 0);
                float3 x = normalize(cross(y, z));
                y = normalize(cross(z, x));

                float3x3 M = float3x3(
                    x.x, y.x, z.x,
                    x.y, y.y, z.y,
                    x.z, y.z, z.z);
                float3 targetPos = mul(M, v.positionOS);

                o.positionCS = UnityObjectToClipPos(targetPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            // 片段着色器
            void frag(Varyings i, out fixed4 outColor : SV_Target)
            {
                half4 mainTex = tex2D(_MainTex, i.uv);

                outColor = mainTex * _Color;
            }
            ENDCG
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}
