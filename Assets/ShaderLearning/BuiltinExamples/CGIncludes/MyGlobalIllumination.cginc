#ifndef MYGLOBALILLUMINATION_CGINCLUDE
#define MYGLOBALILLUMINATION_CGINCLUDE

// Lambert����ģ��
inline fixed4 UnityLambertLight1 (SurfaceOutput s, UnityLight light)
{
    fixed diff = max (0, dot (s.Normal, light.dir));

    fixed4 c;
    c.rgb = s.Albedo * light.color * diff;
    c.a = s.Alpha;
    return c;
}

// ֱ�ӹ���+��ӹ���
inline fixed4 LightingLambert1 (SurfaceOutput s, UnityGI gi)
{
    fixed4 c;
    c = UnityLambertLight1 (s, gi.light);

    // �����Baked GI������Realtime GI������£��ᱻ����
    #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
        c.rgb += s.Albedo * gi.indirect.diffuse;
    #endif

    return c;
}

// GI��������
inline UnityGI UnityGI_Base1(UnityGIInput data, half occlusion, half3 normalWorld)
{
    // ����һ��UnityGI���͵ı���o_gi�����ڴ洢���ռ����gi��Ϣ
    UnityGI o_gi;
    // ����gi�ڵı���ֵ
    ResetUnityGI(o_gi);

    // ������Distance ShaderMask��ʵʱ��Ӱ��決��Ӱ�Ļ�Ϲ���
    // Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
    #if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
        half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
        float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
        data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
    #endif

    // ����ƽ�еƴ���gi��
    o_gi.light = data.light;
    // ��˥��Ӧ���ڵƹ���ɫ��
    o_gi.light.color *= data.atten;

    // �Ƿ������г����
    #if UNITY_SHOULD_SAMPLE_SH
        o_gi.indirect.diffuse = ShadeSHPerPixel(normalWorld, data.ambient, data.worldPos);
    #endif

    // ������Baked GIʱ
    #if defined(LIGHTMAP_ON)
        // Baked lightmaps
        // ����ͼ�Ĳ��������ģ�
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
        half3 bakedColor = DecodeLightmap(bakedColorTex);

        // ������Directionalģʽʱ
        #ifdef DIRLIGHTMAP_COMBINED
            fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #else // not directional lightmap
            o_gi.indirect.diffuse += bakedColor;

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #endif
    #endif

    // ������Realtime GIʱ
    #ifdef DYNAMICLIGHTMAP_ON
        // Dynamic lightmaps
        fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
        #else
            o_gi.indirect.diffuse += realtimeColor;
        #endif
    #endif

    o_gi.indirect.diffuse *= occlusion;
    // ���ؼ�����gi
    return o_gi;
}

inline UnityGI UnityGlobalIllumination1 (UnityGIInput data, half occlusion, half3 normalWorld)
{
	return UnityGI_Base1(data, occlusion, normalWorld);
}

inline void LightingLambert_GI1 (SurfaceOutput s, UnityGIInput data, inout UnityGI gi)
{
	gi = UnityGlobalIllumination1 (data, 1.0, s.Normal);
}

#endif