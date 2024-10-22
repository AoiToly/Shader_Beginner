Shader "Shader Learning/Builtin/E11_PBR"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal]_NormalTex ("Normal", 2D) = "bump" {}
        _MetallicTex ("Metallic(R) Smoothness(G) AO(B)", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _AO ("AO", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        

        // ---- forward rendering base pass:
        Pass {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "../CGIncludes/MyPhysicalBasedRendering.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            sampler2D _MetallicTex;
            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
            float _AO;
            
            struct appdata 
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float4 texcoord3 : TEXCOORD3;
                fixed4 color : COLOR;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0; // _MainTex
                float3 worldPos : TEXCOORD1;
                #if UNITY_SHOULD_SAMPLE_SH
                    half3 sh : TEXCOORD2; // SH
                #endif
                float3 tSpace0:TEXCOORD3;
                float3 tSpace1:TEXCOORD4;
                float3 tSpace2:TEXCOORD5;
                UNITY_FOG_COORDS(6)
                UNITY_SHADOW_COORDS(7)
            };

            // vertex shader
            v2f vert (appdata v) 
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                // 将模型本地空间转换到齐次裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 对_MainTex纹理进行UV变换
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                // 世界空间下的顶点坐标
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 世界空间下的顶点法线
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
                //     fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //     fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                //     fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                // #endif
                // #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED) && !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
                //     o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                //     o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                //     o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                // #endif
                o.worldPos.xyz = worldPos;

                half3 worldTangent = UnityObjectToWorldDir(v.tangent);
                // v.tangent.w:DCC软件中顶点UV值中的V值翻转情况.
                // unity_WorldTransformParams.w:模型缩放是否有奇数负值. 
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float3(worldTangent.x,worldBinormal.x,worldNormal.x);
                o.tSpace1 = float3(worldTangent.y,worldBinormal.y,worldNormal.y);
                o.tSpace2 = float3(worldTangent.z,worldBinormal.z,worldNormal.z);

                // SH/ambient and vertex lights
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    o.sh = 0;
                    // Approximated illumination from non-important point lights
                    #ifdef VERTEXLIGHT_ON
                        o.sh += Shade4PointLights (
                        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                        unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                        unity_4LightAtten0, worldPos, worldNormal);
                    #endif
                    o.sh = ShadeSHPerVertex (worldNormal, o.sh);
                #endif

                UNITY_TRANSFER_LIGHTING(o,v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
                UNITY_TRANSFER_FOG(o,o.pos); // pass fog coordinates to pixel shader
                return o;
            }

            // fragment shader
            fixed4 frag (v2f i) : SV_Target 
            {
                UNITY_EXTRACT_FOG(i);
                float3 worldPos = i.worldPos.xyz;
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                SurfaceOutputStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
                fixed4 mainTex = tex2D(_MainTex, i.uv);
                o.Albedo = mainTex.rgb * _Color;
                o.Emission = 0;
                
                fixed4 metallicTex = tex2D(_MetallicTex, i.uv);
                o.Metallic = metallicTex * _Metallic;
                o.Smoothness = metallicTex.g * _Glossiness;
                o.Occlusion = metallicTex.b * _AO;
                o.Alpha = 1;
                half3 normalTex = UnpackNormalWithScale(tex2D(_NormalTex,i.uv),1);
                o.Normal = half3(dot(i.tSpace0,normalTex),dot(i.tSpace1,normalTex),dot(i.tSpace2,normalTex));

                // compute lighting & shadowing factor
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos)

                // Setup lighting environment
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = _WorldSpaceLightPos0.xyz;

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = worldViewDir;
                giInput.atten = atten;
                giInput.lightmapUV = 0.0;
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    giInput.ambient = i.sh;
                #else
                    giInput.ambient.rgb = 0.0;
                #endif
                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;
                #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
                    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
                #endif
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
                    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
                    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
                    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
                    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif
                LightingStandard_GI1(o, giInput, gi);

                // PBS的核心计算
                fixed4 c = LightingStandard1 (o, worldViewDir, gi);

                // 雾效
                UNITY_APPLY_FOG(_unity_fogCoord, c); // apply fog

                return c;
            }

            ENDCG

        }
    }
}
