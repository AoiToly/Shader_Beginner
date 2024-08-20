Shader "Shader Learning/URP/E13_Water"
{
    Properties
    {
        [Header(Common)]
        _Water01("Direction(XY) Speed(Z) Distort(W)",vector) = (1,1,0.1,0.05)
        _Water02("Atten(X) Lightness(Y) Caustic(Z)",vector) = (1,1,3,0)
        _Water03("Specular: Distort(X) Intensity(Y) Smoothness(Z)",vector) = (0.8,5,8,0)
        _Water04("FoamRange(X) FoamNoise(Y)",vector) = (5,2.8,0,0)
        _SpecularColor("Specular Color",color) = (1,1,1,1)
        _FoamColor("FoamColor",color) = (1,1,1,1)

        [Header(Texture)]
        _NormalTex("NormalTex",2D) = "white"{}
        _ReflectionTex("ReflectionTex",Cube) = "white"{}
        _CausticTex("CausticTex",2D) = "white"{}
        _FoamTex("FoamTex", 2D) = "white" {}
        _RampTexture("Ramp Tex", 2D) = "white" {}
    }

    // URP
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        ZWrite off
        Pass
        {
            //Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
        
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            // �������ͼ���������
            #define REQUIRE_DEPTH_TEXTURE
            #define REQUIRE_OPAQUE_TEXTURE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _Water01,_Water02,_Water03,_Water04;
            float4 _NormalTex_ST;
            half4 _SpecularColor;
            float4 _FoamTex_ST;
            half4 _FoamColor;
            float4 _CausticTex_ST;
            CBUFFER_END
            TEXTURE2D (_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURECUBE (_ReflectionTex);SAMPLER(sampler_ReflectionTex);
            TEXTURE2D (_CausticTex);SAMPLER(sampler_CausticTex);
            TEXTURE2D (_FoamTex);SAMPLER(sampler_FoamTex);

            TEXTURE2D (_RampTexture);SAMPLER(sampler_RampTexture);  //ˮ����ɫ����ͼ

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float4 uv               : TEXCOORD0;    // xyΪfoam��uv��zw��ʾˮ��ƫ��
                float4 normalUV         : TEXCOORD1;
                float fogCoord          : TEXCOORD2;
                float3 positionVS       : TEXCOORD3;
                float3 positionWS       : TEXCOORD4;
                float3 normalWS         : TEXCOORD5;
            };

            // ������ɫ��
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS = TransformWorldToView(o.positionWS);
                o.positionCS = TransformWViewToHClip(o.positionVS);
                o.uv.zw = _Water01.xy * _Time.y * _Water01.z;
                o.uv.xy = o.positionWS.xz * _FoamTex_ST.xy + o.uv.zw;
                o.normalUV.xy = TRANSFORM_TEX(v.uv, _NormalTex) + o.uv.zw;
                o.normalUV.zw = TRANSFORM_TEX(v.uv, _NormalTex) + o.uv.zw * float2(-1.07, 1.07);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            // Ƭ����ɫ��
            half4 frag(Varyings i) : SV_Target0
            {
                /// ����Ԥ����
                float distortValue = _Water01.w;
                float atten = _Water02.x;
                float lightness = _Water02.y;
                float causticIntensity = _Water02.z;
                float specularDistort = _Water03.x;
                float specularIntensity = _Water03.y;
                float specularSmoothness = _Water03.z;
                float foamRange = _Water04.x;
                float foamNoise = _Water04.y;
                float2 speed = i.uv.zw;
                
                /// ��Ļ�ռ�UV
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;

                /// ˮ�����
                // ʹ������ռ���ˮ���ˮ�׵�Zֵ�����ˮ�����
                // �������ͼ���ˮ��Zֵ
                half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                half depthGround = LinearEyeDepth(depthTex, _ZBufferParams);
                // ˮ��Zֵ
                // ע�⣬����ռ�����������ϵ��Zֵ��Ҫȡ��
                half depthWaterSurface = -i.positionVS.z;
                // ����ˮ�����
                half depthWater = depthGround - depthWaterSurface;
                depthWater = max(0, depthWater);
                // ˥��������ˮ��
                depthWater *= atten;

                /// ����
                // ����UV������ʹ�����˶�����ͬ���Բ���ˮ�沨�����Ե�Ч��
                half4 normalTex01 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.xy);
                half4 normalTex02 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.zw);
                half4 normalTex = normalTex01 * normalTex02;
                // ���㷨��Ť��
                half3 normal = normalTex.xyz * distortValue;

                /// ˮ�µ�Ť����ͨ��OpaqueTexture���
                // ���ݷ��ߵ�Ť�������µ�UV
                half2 distortUV = screenUV + normal.xy;
                // ����Ť��������ͼ���������ͼ�����ж�Ť�����ͼ����λ��ˮ�»���ˮ��
                half depthDistortTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, distortUV).r;
                half depthDistortGround = LinearEyeDepth(depthDistortTex, _ZBufferParams);
                half depthDistortWater = depthDistortGround - depthWaterSurface;
                // �޳�ˮ�����ϲ��ֵ�Ť��
                int isUnderWater = depthDistortWater > 0;
                distortUV = !isUnderWater * screenUV + isUnderWater * distortUV;
                half4 distort = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortUV);

                /// ˮ�Ľ�ɢ
                // ʵ��ԭ������������ͬ����ͼƬ����ˮ�׼���
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * depthDistortGround / depthWaterSurface;
                depthVS.z = depthDistortGround;
                float3 depthWS = mul(unity_CameraToWorld, depthVS).xyz;
                // ��������ͬ����������uv������ɢ��ͼ����ʵ�����������Ч��
                float2 causticUV01 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.2 + speed;
                float2 causticUV02 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.1 + speed * float2(-1.07, 1.43);
                half4 causticTex01 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV01);
                half4 causticTex02 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV02);
                // ��ͼ��ϣ���ӱ��min���
                half4 caustic = min(causticTex01, causticTex02);
                caustic *= causticIntensity;

                /// ˮ�ĸ߹�
                // Specular = SpecularColor * Ks * pow(max(0,dot(N,H)), Shininess)
                half3 N = normalize(lerp(i.normalWS, normalTex.xyz, specularDistort));
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                half3 H = normalize(L + V);
                half4 specular = _SpecularColor * specularIntensity * pow(saturate(dot(N, H)), specularSmoothness);

                /// ˮ�ķ���
                // ����+������
                N = normal;
                half3 reflectionUV = reflect(-V, N);
                half4 reflectionTex = SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, reflectionUV);
                half fresnel = pow(1 - saturate(dot(i.normalWS, V)), 3);
                half4 reflection = reflectionTex * fresnel;

                /// ˮ����ĭ
                // ������ȼ�����ĭ������λ��
                half foamWidth = foamRange * depthWater;
                half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.xy).r;
                foamTex = pow(abs(foamTex), foamNoise);
                // ������ͼ���бȽϣ�����ĭ��Χ�޶���foamRange֮��
                half foamMask = step(foamWidth, foamTex);
                half4 foam = foamMask * _FoamColor;
                
                // ˮ����ɫ
                // �������ɫ�����õ���depthWater
                // ���ʹ��depthDistortWater����Ч�������
                // ����ΪŤ�������⣬���ֲ�����������ǳ����أ�����Ŀǰ��û�뵽ʲô�ܺõķ��������
                half4 rampTex01 = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(depthWater, 1));
                half4 rampTex02 = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(depthWater, 0));

                half4 c = half4(0, 0, 0, 1);
                c += rampTex01 * lightness + specular * reflection + foam + (distort + caustic * lightness) * rampTex02;
                return c;
            }
            ENDHLSL
        }
    }
}
