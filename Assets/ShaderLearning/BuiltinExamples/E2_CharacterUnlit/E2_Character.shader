Shader "Shader Learning/Builtin/E2_Character"
{
    // �����
    // �Է���Ч�������ܵƹ�Ӱ��
    // ����ʱ���ױ���
    // �ж�ʱ���̣�����ʱ���
    // ����ʱ�ܽ���ʧ
    Properties
    {
        [Header(Base)]
        // ��ͼ
        [NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)

        [Space(25)]

        [Header(Dissolve)]
        [Toggle]_DissolveEnabled("DissolveEnabled", int) = 0
        _DissolveTex("DissolveTex(R)", 2D) = "white" {}
        [NoScaleOffset]_DissolveRampTex("DissolveRampTex(RGB) ", 2D) = "white" {}
        _DissolveRampColor("DissolveRampColor", Color) = (0, 1, 1, 1)
        _DissolveEdge("DissolveEdge", float) = 0.1
        _Dissolve("Dissolve", range(0,1)) = 0

        [Header(Shadow)]
        _Shadow ("Shadow x(xOffset) y(groundPos) z(zOffset) w(intensity)", vector) = (0.2, 0, 0.3, 0)
    }

    SubShader
    {
        Tags { "Queue" = "Geometry" }

        // ��cs�ű��п��Կ���LOD�Ĵ�С
        // Shader.GlobalMaximumLOD
        // LODֵԽ������Խ��
        LOD 600

        // �����������ص�ʱ��������˸Ч��
        Offset -1, -1

        UsePass "Shader Learning/Builtin/E7_XRay/XRAY"

        pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // ������ζ��ᱻ����ı���
            #pragma multi_compile _ _DISSOLVEENABLED_ON
            //#pragma multi_compile_fwdbase
            #pragma multi_compile _DIRECTIONAL SHADOWS_SCREEN

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            sampler2D _DissolveTex;
            // _DissolveTex��Tiling��Offset
            float4 _DissolveTex_ST;
            // ֻ��һά�����ݣ���Ϊ�ڶ�ά����û����
            sampler _DissolveRampTex;
            float _DissolveEdge;
            fixed4 _DissolveRampColor;
            fixed _Dissolve;

            struct appdata
            {
                float4 pos : POSITION;
                float4 uv : TEXCOORD;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD;
                float4 worldPos : TEXCOORD1;
                UNITY_SHADOW_COORDS(2)
            };

            // �Ż�׼�����ڶ�����ɫ������������Ͳ�Ҫ�ŵ�Ƭ����ɫ����ȥ��
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv.xy = v.uv.xy;
                // Transform_TEX����ʵ��Tiling��Offset�Ĺ���
                // o.uv.zw = v.uv.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);
                o.worldPos = mul(unity_ObjectToWorld, v.pos);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos)
                fixed4 c;
                // ����
                fixed4 tex = tex2D(_MainTex, i.uv.xy);
                // ��ɫ���
                c = tex * atten;
                c *= _Color;

                #if _DISSOLVEENABLED_ON
                    // �ܽ�Ч��
                    // ��UV��Tiling���Ե����ܽ���Ӿ�Ч��
                    fixed4 dissolveTex = tex2D(_DissolveTex, i.uv.zw);
                    fixed edge = dissolveTex.r + _DissolveEdge;
                    clip(edge - _Dissolve);
                
                    // ʵ���ܽ��ԵЧ��
                    // ����smoothStep��ʵ�֣���smoothStep�������Դ�ƽ�����ܣ��˴�����Ҫ��Ϊ���Ż����ܣ����޸�ʵ��
                    // float rampValue = smoothstep(_Dissolve, _Dissolve + _DissolveEdge, edge);
                    float rampValue = saturate((edge - _Dissolve) / _DissolveEdge);
                    fixed4 dissolveRampTex = tex1D(_DissolveRampTex, rampValue); 
                    // ��DissolveRampColor��ɫ�ں�
                    c += dissolveRampTex * (1-rampValue) * _DissolveRampColor;
                #endif

                return c;
            }

            ENDCG
        }

        pass
        {
            // ���Pass��������shadow map
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ _DISSOLVEENABLED_ON

            #include "UnityCG.cginc"

            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            fixed _Dissolve;

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.uv, _DissolveTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                // ��ӰͶӰ��Ҫ�ֶ������ܽ�Ч��
                #if _DISSOLVEENABLED_ON
                    // �ܽ�Ч��
                    // ��UV��Tiling���Ե����ܽ���Ӿ�Ч��
                    fixed4 dissolveTex = tex2D(_DissolveTex, i.uv);
                    clip(dissolveTex.r - _Dissolve);
                #endif

                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }

    SubShader
    {
        LOD 400

        Offset -1, -1

        UsePass "Shader Learning/Builtin/E7_XRay/XRAY"

        pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // ������ζ��ᱻ����ı���
            #pragma multi_compile _ _DISSOLVEENABLED_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            sampler2D _DissolveTex;
            // _DissolveTex��Tiling��Offset
            float4 _DissolveTex_ST;
            // ֻ��һά�����ݣ���Ϊ�ڶ�ά����û����
            sampler _DissolveRampTex;
            float _DissolveEdge;
            fixed4 _DissolveRampColor;
            fixed _Dissolve;

            struct appdata
            {
                float4 pos : POSITION;
                float4 uv : TEXCOORD;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD;
            };

            // �Ż�׼�����ڶ�����ɫ������������Ͳ�Ҫ�ŵ�Ƭ����ɫ����ȥ��
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv.xy = v.uv.xy;
                // Transform_TEX����ʵ��Tiling��Offset�Ĺ���
                // o.uv.zw = v.uv.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 c;
                // ����
                fixed4 tex = tex2D(_MainTex, i.uv.xy);
                // ��ɫ���
                c = tex;
                c *= _Color;

                #if _DISSOLVEENABLED_ON
                // �ܽ�Ч��
                // ��UV��Tiling���Ե����ܽ���Ӿ�Ч��
                fixed4 dissolveTex = tex2D(_DissolveTex, i.uv.zw);
                fixed edge = dissolveTex.r + _DissolveEdge;
                clip(edge - _Dissolve);
                
                // ʵ���ܽ��ԵЧ��
                // ����smoothStep��ʵ�֣���smoothStep�������Դ�ƽ�����ܣ��˴�����Ҫ��Ϊ���Ż����ܣ����޸�ʵ��
                // float rampValue = smoothstep(_Dissolve, _Dissolve + _DissolveEdge, edge);
                float rampValue = saturate((edge - _Dissolve) / _DissolveEdge);
                fixed4 dissolveRampTex = tex1D(_DissolveRampTex, rampValue); 
                // ��DissolveRampColor��ɫ�ں�
                c += dissolveRampTex * (1-rampValue) * _DissolveRampColor;
                #endif

                return c;
            }

            ENDCG
        }

        pass
        {
            Stencil
            {

                Ref 1
                Comp NotEqual
                Pass Replace
            }

            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Shadow;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float worldPosY = worldPos.y;
                worldPos.y = _Shadow.y;
                worldPos.xz += _Shadow.xz * (worldPosY - _Shadow.y);
                o.pos = mul(UNITY_MATRIX_VP, worldPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                return _Shadow.w;
            }

            ENDCG
        }
    }

    // ����ڵ�ǰShader���Ҳ���ShadowCaster��pass���ͻ��FallBack��Ѱ��
    //FallBack "Legacy Shaders/VertexLit"
}
