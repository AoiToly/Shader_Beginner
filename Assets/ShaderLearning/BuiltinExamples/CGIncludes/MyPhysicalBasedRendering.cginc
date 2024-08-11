#ifndef MYPHYSICALBASEDRENDERING_CGINCLUDE
    #define MYPHYSICALBASEDRENDERING_CGINCLUDE
    
    inline float SmithJointGGXVisibilityTerm1 (float NdotL, float NdotV, float roughness)
    {
        #if 0
            // Original formulation:
            //  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
            //  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
            //  G           = 1 / (1 + lambda_v + lambda_l);

            // Reorder code to be more optimal
            half a          = roughness;
            half a2         = a * a;

            half lambdaV    = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
            half lambdaL    = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

            // Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
            return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
                                                        // therefore epsilon is smaller than can be represented by half
        #else
            // ���湫ʽ�Ľ���ʵ�֣���ƽ��������ѧ�ϲ�̫��ȷ����Ч���ȽϽӽ�
            // Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
            float a = roughness;
            float lambdaV = NdotL * (NdotV * (1 - a) + a);
            float lambdaL = NdotV * (NdotL * (1 - a) + a);

            #if defined(SHADER_API_SWITCH)
                return 0.5f / (lambdaV + lambdaL + UNITY_HALF_MIN);
            #else
                return 0.5f / (lambdaV + lambdaL + 1e-5f);
            #endif

        #endif
    }

    inline float GGXTerm1 (float NdotH, float roughness)
    {
        float a2 = roughness * roughness;
        float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
        // +1e-7��Ϊ�˷�ֹ����Ϊ0
        return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
                                                // therefore epsilon is smaller than what can be represented by half
    }

    inline half3 FresnelTerm1 (half3 F0, half cosA)
    {
        half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
        return F0 + (1-F0) * t;
    }

    // GI�о��淴���Fresnel����
    // F0 = ���������巨�߼н�Ϊ0�����
    // F90 = ���������巨�߼н�Ϊ90�����
    inline half3 FresnelLerp1 (half3 F0, half3 F90, half cosA)
    {
        half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
        return lerp (F0, F90, t);
    }
    
    half4 BRDF1_Unity_PBS1 (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
        float3 normal, float3 viewDir,
        UnityLight light, UnityIndirect gi)
    {
        // ���ԵĴֲڶ� = 1 - smoothness
        float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
        // ��������������ߺ����߷���֮�͵Ĺ�һ������
        float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);

        // ���������ߵĵ���ڿɼ������ϲ�Ӧ�ó��ָ�ֵ���������п��ܷ�����ͶӰ�뷨��ӳ��ʱ������ͨ��ĳЩ��ʽ�����������ǻ���������ָ������
        // �����������abs����ֵ����ʽ��ͬ�����Թ���ֻ����ȷ�Ի���һЩ
        // NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
        // In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
        // but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
        // Following define allow to control this. Set it to 0 if ALU is critical on your platform.
        // This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
        // Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
        #define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

        #if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
            // The amount we shift the normal toward the view vector is defined by the dot product.
            half shiftAmount = dot(normal, viewDir);
            normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
            // A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
            //normal = normalize(normal);

            float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
        #else
            half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
        #endif
            
        // ���ַ���ĵ������
        float nl = saturate(dot(normal, light.dir));
        float nh = saturate(dot(normal, halfDir));

        half lv = saturate(dot(light.dir, viewDir));
        half lh = saturate(dot(light.dir, halfDir));

        // Diffuse term
        // ����������������Ӧ�ó���PI���������������㲢û����ô��
        // 1. �����ᵼ����ɫ�Ⱦɵ���ɫ����
        // 2. ��������������������Ϊ����Ҫ�ĵƹ���SHʱ������г���PI�Ĳ���
        // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
        // BUT 1) that will make shader look significantly darker than Legacy ones
        // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
        half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

        // Specular term
        // ����һ��ѧ���ϵĴֲڶ�
        float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
        // ���ڼ���߹��ģ��
        // GGXģ��ӵ�бȽϺõ�Ч��
        #if UNITY_BRDF_GGX
            // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
            roughness = max(roughness, 0.002);
            float V = SmithJointGGXVisibilityTerm1 (nl, nv, roughness);
            float D = GGXTerm1 (nh, roughness);
        #else
            // Legacy
            half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
            half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
        #endif

        // �������PI��ԭ���ǣ�����������ΪһЩԭ��û�г���PI��Ϊ�˱�֤Ч��һ�£����淴����Ҫ����PI
        float specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

        // �������GAMMA�ռ�Ļ�
        #   ifdef UNITY_COLORSPACE_GAMMA
                specularTerm = sqrt(max(1e-4h, specularTerm));
        #   endif

        // ��ֹ���Ϊ������������������
        // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
        specularTerm = max(0, specularTerm * nl);
        // �����ϵľ���߹⿪��
        #if defined(_SPECULARHIGHLIGHTS_OFF)
            specularTerm = 0.0;
        #endif

        // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
        half surfaceReduction;
        #   ifdef UNITY_COLORSPACE_GAMMA
                surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
        #   else
                surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
        #   endif

        // To provide true Lambert lighting, we need to be able to kill specular completely.
        // ��metallic=1������AlbedoΪ����ɫʱ����Ӧ���н�������
        specularTerm *= any(specColor) ? 1.0 : 0.0;

        half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
        // ������
        half3 diffuse = diffColor * (gi.diffuse + light.color * diffuseTerm);
        // ���淴��DFG/4coslcosv
        // DG = specularTerm
        // F = FresnelTerm
        half3 specular = specularTerm * light.color * FresnelTerm1 (specColor, lh);
        // IBL (Image Based Lighting) ����ͼ��Ĺ��գ�������Ӱ�죩
        // surfaceReducation = ˥��
        // gi.specular = ��ӹ��еľ��淴��
        // FresnelLerp = ���淴���ڲ�ͬ�Ƕ��µĹ��ɣ�F0-F90��
        half3 ibl = surfaceReduction * gi.specular * FresnelLerp1 (specColor, grazingTerm, nv);
        half3 color = diffuse + specular + ibl;
        return half4(color, 1);
    }
    
    // Default BRDF to use:
    // TierSetting������
    // StandardShaderQuality = low (UNITY_PBS_USE_BRDF3)
    // StandardShaderQuality = Medium (UNITY_PBS_USE_BRDF2)
    // StandardShaderQuality = high (UNITY_PBS_USE_BRDF1)
    #if !defined (UNITY_BRDF_PBS1) // allow to explicitly override BRDF in custom shader
        // still add safe net for low shader models, otherwise we might end up with shaders failing to compile
        #if SHADER_TARGET < 30 || defined(SHADER_TARGET_SURFACE_ANALYSIS) // only need "something" for surface shader analysis pass; pick the cheap one
            #define UNITY_BRDF_PBS1 BRDF3_Unity_PBS  // Ч������BRDF
        #elif defined(UNITY_PBS_USE_BRDF3)
            #define UNITY_BRDF_PBS1 BRDF3_Unity_PBS
        #elif defined(UNITY_PBS_USE_BRDF2)
            #define UNITY_BRDF_PBS1 BRDF2_Unity_PBS
        #elif defined(UNITY_PBS_USE_BRDF1)
            #define UNITY_BRDF_PBS1 BRDF1_Unity_PBS1
        #else
            #error something broke in auto-choosing BRDF
        #endif
    #endif

    inline half OneMinusReflectivityFromMetallic1(half metallic)
    {
        // We'll need oneMinusReflectivity, so
        //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
        // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
        //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
        //                  = alpha - metallic * alpha
        half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
        return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
    }

    inline half3 DiffuseAndSpecularFromMetallic1 (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
    {
        // ���㷴����ɫ
        // ��metallic = 0ʱ���ǽ�����������unity_ColorSpaceDielectricSpec.rgb
        // unity_ColorSpaceDielectricSpec��ʾ��Ե���ͨ�÷�����ɫ����ʿ���׼����0.04��ʾ
        // ��metallic = 1ʱ���������������屾�����ɫ��ʾ����albedo
        specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
        // ����1-�߹ⷴ���ʣ������䷴���ʣ�
        oneMinusReflectivity = OneMinusReflectivityFromMetallic1(metallic);
        return albedo * oneMinusReflectivity;
    }

    // s = �������������Ϣ
    // viewDir = ���߷���
    // gi = ȫ�ֹ��գ�GI������+GI���淴�䣩
    inline half4 LightingStandard1 (SurfaceOutputStandard s, float3 viewDir, UnityGI gi)
    {
        s.Normal = normalize(s.Normal);

        half oneMinusReflectivity;
        half3 specColor;
        s.Albedo = DiffuseAndSpecularFromMetallic1 (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

        // shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
        // this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
        // ������͸��ģʽ���е�Alpha��ؼ���
        half outputAlpha;
        s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

        // �����BRDF
        // s.Albedo = �������Ļ�����ɫ
        // specColor = ���淴����ɫ
        // oneMinueReflectivity = ��������
        // s.Smoothness = �������Ĺ⻬��
        // s.Normal = �������ķ���
        // viewDir = ���߷���
        // gi.light = ֱ�ӹ���Ϣ
        // gi.indirect = ��ӹ���Ϣ
        half4 c = UNITY_BRDF_PBS1 (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
        c.a = outputAlpha;
        return c;
    }

    // ���������ǻ�����
    // ���ܵ�����ֲڶȵ�Ӱ��
    // ���õ�˼·Ϊ��������Դֲڶȣ����ֵ�ͷ�����ͼ��mipmap����
    // ����Խ�ֲڣ��ͻ���ü���Խ�ߵ�mipmapģ��ֲ�Ч��
    half3 Unity_GlossyEnvironment1 (UNITY_ARGS_TEXCUBE(tex), half4 hdr, Unity_GlossyEnvironmentData glossIn)
    {
        // �������Դֲڶ�
        half perceptualRoughness = glossIn.roughness /* perceptualRoughness */ ;

        // TODO: CAUTION: remap from Morten may work only with offline convolution, see impact with runtime convolution!
        // For now disabled
        #if 0
            float m = PerceptualRoughnessToRoughness(perceptualRoughness); // m is the real roughness parameter
            const float fEps = 1.192092896e-07F;        // smallest such that 1.0+FLT_EPSILON != 1.0  (+1e-4h is NOT good here. is visibly very wrong)
            float n =  (2.0/max(fEps, m*m))-2.0;        // remap to spec power. See eq. 21 in --> https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf

            n /= 4;                                     // remap from n_dot_h formulatino to n_dot_r. See section "Pre-convolved Cube Maps vs Path Tracers" --> https://s3.amazonaws.com/docs.knaldtech.com/knald/1.0.0/lys_power_drops.html

            perceptualRoughness = pow( 2/(n+2), 0.25);      // remap back to square root of real roughness (0.25 include both the sqrt root of the conversion and sqrt for going from roughness to perceptualRoughness)
        #else
            // MM: came up with a surprisingly close approximation to what the #if 0'ed out code above does.
            // r = r * (1.7 - 0.7 * r)
            // �ֲڶȺ�mipmap�ȼ��������Թ�ϵ��������������ʽ����
            perceptualRoughness = perceptualRoughness*(1.7 - 0.7*perceptualRoughness);
        #endif

        // mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
        // UNITY_SPECCUBE_LOD_STEPS = 6����ʾmip��߼���Ϊ6
        half mip = perceptualRoughnessToMipmapLevel(perceptualRoughness);
        half3 R = glossIn.reflUVW;
        half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, R, mip);

        return DecodeHDR(rgbm, hdr);
    }

    // GI���������
    inline UnityGI UnityGlobalIllumination1 (UnityGIInput data, half occlusion, half3 normalWorld)
    {
        return UnityGI_Base(data, occlusion, normalWorld);
    }

    
    // GI�߹ⷴ�����
    inline half3 UnityGI_IndirectSpecular1(UnityGIInput data, half occlusion, Unity_GlossyEnvironmentData glossIn)
    {
        // �������صı���specular
        half3 specular;

        // �������̽��ΪBoxProjectionģʽ
        #ifdef UNITY_SPECCUBE_BOX_PROJECTION
            // we will tweak reflUVW in glossIn directly (as we pass it to Unity_GlossyEnvironment twice for probe0 and probe1), so keep original to pass into BoxProjectedCubemapDirection
            half3 originalReflUVW = glossIn.reflUVW;
            glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
        #endif

        // �����ѡ��Standard��������еĽ��÷��书�ܵĻ�
        #ifdef _GLOSSYREFLECTIONS_OFF
            specular = unity_IndirectSpecColor.rgb;
        #else
            half3 env0 = Unity_GlossyEnvironment1 (UNITY_PASS_TEXCUBE(unity_SpecCube0), data.probeHDR[0], glossIn);
            // ��������˷���̽��Ļ�ϵĻ�
            #ifdef UNITY_SPECCUBE_BLENDING
                const float kBlendFactor = 0.99999;
                float blendLerp = data.boxMin[0].w;
                UNITY_BRANCH
                if (blendLerp < kBlendFactor)
                {
                    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                        glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
                    #endif

                    half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), data.probeHDR[1], glossIn);
                    specular = lerp(env1, env0, blendLerp);
                }
                else
                {
                    specular = env0;
                }
            #else
                specular = env0;
            #endif
        #endif

        return specular * occlusion;
    }

    inline UnityGI UnityGlobalIllumination1 (UnityGIInput data, half occlusion, half3 normalWorld, Unity_GlossyEnvironmentData glossIn)
    {
        // ����������
        UnityGI o_gi = UnityGI_Base(data, occlusion, normalWorld);
        // ����߹ⷴ��
        o_gi.indirect.specular = UnityGI_IndirectSpecular1(data, occlusion, glossIn);
        return o_gi;
    }
    
    float SmoothnessToPerceptualRoughness1(float smoothness)
    {
        return (1 - smoothness);
    }

    Unity_GlossyEnvironmentData UnityGlossyEnvironmentSetup1(half Smoothness, half3 worldViewDir, half3 Normal, half3 fresnel0)
    {
        Unity_GlossyEnvironmentData g;

        g.roughness /* perceptualRoughness */   = SmoothnessToPerceptualRoughness1(Smoothness);
        // ������Ĳ�������
        g.reflUVW   = reflect(-worldViewDir, Normal);

        return g;
    }

    // PBR����ģ��GI����
    inline void LightingStandard_GI1 (SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
    {
        // ������ӳ���ȾPass�Ļ����ҿ������ӳ���Ⱦ����̽��Ļ�
        #if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
            gi = UnityGlobalIllumination1(data, s.Occlusion, s.Normal);
        #else
            // Unity_GlossyEnvironmentData��ʾGI�еķ�������
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup1(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
            gi = UnityGlobalIllumination1(data, s.Occlusion, s.Normal, g);
        #endif
    }

#endif