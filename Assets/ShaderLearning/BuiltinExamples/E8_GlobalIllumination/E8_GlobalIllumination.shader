Shader "Shader Learning/Builtin/E8_GlobalIllumination"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "../CGIncludes/MyGlobalIllumination.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                
                // 当Baked GI或者Realtime GI开启时则进行定义
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    float4 texcoord1:TEXCOORD1;
                #endif
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                float4 texcoord1 : TEXCOORD1;
                #endif
                half3 worldNormal : NORMAL;
                #ifndef LIGHTMAP_ON
                    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                        half3 sh : TEXCOORD2;
                    #endif
                #endif
                UNITY_LIGHTING_COORDS(3,4)
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                // Baked GI的Tiling和Offset
                #if defined(LIGHTMAP_ON)
                    o.texcoord1.xy = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                // Realtime GI的Tiling和Offset
                #if defined(DYNAMICLIGHTMAP_ON)
                    o.texcoord1.zw = v.texcoord1 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 同时定义灯光衰减以及实时阴影采样所需的插值器
                UNITY_TRANSFER_LIGHTING(o, v.texcoord2.xy);
                // 光照探针sh
                // SH/ambient and vertex lights
                #ifndef LIGHTMAP_ON  // 当此对象没有开启静态烘焙时
                    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                        o.sh = 0;
                        // Approximated illumination from non-important point lights
                        // 近似模拟非重要级别的点光在逐顶点上的光照效果
                        #ifdef VERTEXLIGHT_ON
                            o.sh += Shade4PointLights (
                                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                                unity_4LightAtten0, o.worldPos, o.worldNormal);
                        #endif
                        o.sh = ShadeSHPerVertex (o.worldNormal, o.sh);
                    #endif
                #endif // !LIGHTMAP_ON
                return o;
            }

            // 这部分的详细内容可以查看Unity内置的Shader来查询如何去实现
            fixed4 frag (v2f i) : SV_Target
            {
                // 1. 灯光的衰减效果
                // 2. 实时阴影的采样
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                SurfaceOutput o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutput, o);
                o.Normal = i.worldNormal;
                o.Albedo = 1;

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.light.color = _LightColor0;
                gi.light.dir = _WorldSpaceLightPos0;
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = i.worldPos;
                giInput.worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                giInput.atten = atten;
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    giInput.ambient = i.sh;
                #else
                    giInput.ambient.rgb = 0.0;
                #endif
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    giInput.lightmapUV = i.texcoord1;
                #endif

                LightingLambert_GI1(o, giInput, gi);

                fixed4 c = LightingLambert1(o, gi);

                return c;
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

            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }

        // 此pass用于在烘焙时计算光照的间接光反弹，在正常渲染时不会使用此pass
        pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"
            #include "UnityMetaPass.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uvMain : TEXCOORD0;
                float2 uvIllum : TEXCOORD1;
            #ifdef EDITOR_VISUALIZATION
                float2 vizUV : TEXCOORD2;
                float4 lightCoord : TEXCOORD3;
            #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 _MainTex_ST;
            float4 _Illum_ST;

            v2f vert (appdata_full v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
                o.uvMain = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvIllum = TRANSFORM_TEX(v.texcoord, _Illum);
                #ifdef EDITOR_VISUALIZATION
                    o.vizUV = 0;
                    o.lightCoord = 0;
                    if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
                        o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
                    else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
                    {
                        o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                        o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
                    }
                #endif
                return o;
            }

            sampler2D _MainTex;
            sampler2D _Illum;
            fixed4 _Color;
            fixed _Emission;

            half4 frag (v2f i) : SV_Target
            {
                UnityMetaInput metaIN;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);

                fixed4 tex = tex2D(_MainTex, i.uvMain);
                fixed4 c = tex * _Color;
                metaIN.Albedo = c.rgb;
                metaIN.Emission = c.rgb * tex2D(_Illum, i.uvIllum).a;
                #if defined(EDITOR_VISUALIZATION)
                    metaIN.VizUV = i.vizUV;
                    metaIN.LightCoord = i.lightCoord;
                #endif

                return UnityMetaFragment(metaIN);
            }
            ENDCG
        }
    }
    
    // 这个Editor可以修改物体GI的模式
    // 由于默认是None，所以需要调出来作修改
    CustomEditor "LegacyIlluminShaderGUI"
}
