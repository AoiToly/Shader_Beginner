Shader "Shader Learning/E12_ShaderTarget"
{
    CGINCLUDE
    #include "UnityCG.cginc"

    struct appdata
    {
        float4 vertex : POSITION;
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
    };
    v2f vert (appdata v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        return o;
    }

    fixed4 frag (v2f i) : SV_Target
    {
        fixed4 c = 1;
        #if (SHADER_TARGET >= 30)
            c = fixed4(1, 0, 0, 1);
        #elif (SHADER_TARGET >= 25)
            c = fixed4(0, 1, 0, 1);
        #else
            c = fixed4(0, 0, 1, 1);
        #endif
        return c;
    }
    ENDCG


    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 600
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            ENDCG
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 400
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.5
            ENDCG
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            ENDCG
        }
    }
}
