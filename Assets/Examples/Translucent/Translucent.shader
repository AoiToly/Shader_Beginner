Shader "taecg/URP/Translucent"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _Specular("Specular",float) = 1
        _Shininess("Shininess",float) = 1
        [Header(Translucent)]
        _ThicknessMap("ThicknessMap",2D) = "white"{}
        _Thickness("Thickness",range(0,1)) = 0.5
        _NormalDistortion("Normal Distortion",range(0,1)) = 0.5
        _Attenuation("Attenuation",float) = 0
        _Strength("Strength",float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS         : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float fogCoord          : TEXCOORD1;
                float3 normalWS         : TEXCOORD2;
                float3 viewWS           : TEXCOORD3;
                float3 positionWS       : TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            half _Specular,_Shininess;
            half _NormalDistortion,_Attenuation,_Strength,_Thickness;
            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D (_ThicknessMap);SAMPLER(sampler_ThicknessMap);
            // #define smp _linear_clampU_mirrorV
            // SAMPLER(smp);

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewWS = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                return o;
            }

            //透射
            half3 LightingTranslucent(float3 lightDir,float3 viewDir,half3 normalWS,half3 color,half thickness)
            {
                half3 L = lightDir;
                half3 V = viewDir;
                half3 N = normalWS;
                half3 H = L + N * _NormalDistortion;
                half _LdotV = dot(-H,V);
                half3 I = pow(saturate(_LdotV),_Attenuation) * _Strength;
                I *= thickness;
                I *= color;
                return I;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 c;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;

                //漫反射
                //Specular = Ks * pow(max(0,dot(N,H)), Shininess)
                float3 N = normalize(i.normalWS);
                Light mainLight = GetMainLight();
                float3 L = mainLight.direction;
                float3 V = i.viewWS;
                float3 H = normalize(L + V);
                half NdotH = saturate(dot(N,H));
                half specular = _Specular * pow(NdotH,_Shininess);
                half diffuse = max(0.3,dot(N,L));
                c *= diffuse;
                c += specular;

                half thicknessMap = 1-SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap, i.uv).r;
                half thickness = lerp(1,thicknessMap,_Thickness);
                c.rgb += LightingTranslucent(L,i.viewWS,N,mainLight.color,thickness);

                //额外光的透射支持
                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light light = GetAdditionalLight(lightIndex, i.positionWS);
                        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                        c.rgb += LightingTranslucent(light.direction,i.viewWS,N,light.color,thickness) * attenuatedLightColor;
                    }
                #endif

                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }
}
