Shader "Shader Learning/Builtin/E10_TextureTutorial"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(Repeat, Clamp)]_WrapMode ("Wrap Mode", int) = 0
        [IntRange]_Mipmap ("Mipmap", Range(0, 12)) = 0

        [Normal]_NormalTex ("NormalTex", 2D) = "bump" {}

        _CubeMap ("CubeMap", Cube) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _WRAPMODE_REPEAT _WRAPMODE_CLAMP

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                half3 worldNormal : TEXCOORD3;
                // 3个float3向量组合成的切线转置矩阵
                float3 tSpace0 : TEXCOORD4;
                float3 tSpace1 : TEXCOORD5;
                float3 tSpace2 : TEXCOORD6;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalTex;

            half _Mipmap;

            samplerCUBE _CubeMap;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.localPos = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 本地空间切线转世界空间
                half3 worldTangent = UnityObjectToWorldDir(v.tangent);
                // 确定副切线的方向
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                // 叉积计算副切线
                half3 worldBinormal = cross(o.worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float3(worldTangent.x, worldBinormal.x, o.worldNormal.x);
                o.tSpace1 = float3(worldTangent.y, worldBinormal.y, o.worldNormal.y);
                o.tSpace2 = float3(worldTangent.z, worldBinormal.z, o.worldNormal.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // WrapMode
                #if _WRAPMODE_REPEAT
                    i.uv = frac(i.uv);
                #elif _WRAPMODE_CLAMP
                    i.uv = clamp(i.uv, 0, 1);
                #endif

                // Mipmap
                float4 uvMipmap = float4(i.uv, 0, _Mipmap);
                fixed4 c = tex2Dlod(_MainTex, uvMipmap);

                // 计算物体的法线纹理
                // 世界空间下的法线的计算公式
                // n_w = M^T * n_t
                // 即切线变换矩阵的转置矩阵乘以切线空间下的法线
                // 切线变换矩阵可以将世界空间下的切线转换为切线空间下的切线
                fixed3 normalTex = UnpackNormalWithScale(tex2D(_NormalTex, i.uv), 1);
                half3 worldNormal = half3(dot(i.tSpace0, normalTex), dot(i.tSpace1, normalTex), dot(i.tSpace2, normalTex));
                // lambert max(0, dot(N,L))
                fixed3 N1 = normalize(worldNormal);
                fixed3 L = _WorldSpaceLightPos0.xyz;
                return max(0, dot(N1, L));
                return fixed4(normalTex, 1);

                // Cube
                // V,N,R
                // fixed3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // fixed3 N = normalize(i.worldNormal);
                // fixed3 R = reflect(-V, N);
                // fixed4 cubemap = texCUBE(_CubeMap, R);
                // return cubemap;

                // 计算天空盒反射的颜色
                //half3 worldView = normalize (UnityWorldSpaceViewDir (i.worldPos));
                //half3 R = reflect (-worldView, N);
                //half4 cubemap = UNITY_SAMPLE_TEXCUBE (unity_SpecCube0, R);
                //half3 skyColor = DecodeHDR (cubemap, unity_SpecCube0_HDR);
            }
            ENDCG
        }
    }
}
