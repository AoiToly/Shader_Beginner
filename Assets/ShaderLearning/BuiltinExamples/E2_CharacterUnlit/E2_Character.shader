Shader "Shader Learning/Builtin/E2_Character"
{
    // 需求点
    // 自发光效果，不受灯光影响
    // 被击时闪白表现
    // 中毒时变绿，火烧时变红
    // 死亡时溶解消失
    Properties
    {
        [Header(Base)]
        // 贴图
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

        // 在cs脚本中可以控制LOD的大小
        // Shader.GlobalMaximumLOD
        // LOD值越大配置越高
        LOD 600

        // 当两个物体重叠时，避免闪烁效果
        Offset -1, -1

        UsePass "Shader Learning/Builtin/E7_XRay/XRAY"

        pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // 无论如何都会被编译的变体
            #pragma multi_compile _ _DISSOLVEENABLED_ON
            //#pragma multi_compile_fwdbase
            #pragma multi_compile _DIRECTIONAL SHADOWS_SCREEN

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            sampler2D _DissolveTex;
            // _DissolveTex的Tiling和Offset
            float4 _DissolveTex_ST;
            // 只拿一维的数据，因为第二维数据没有用
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

            // 优化准则：能在顶点着色器里做的事情就不要放到片段着色器里去做
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv.xy = v.uv.xy;
                // Transform_TEX可以实现Tiling和Offset的功能
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
                // 采样
                fixed4 tex = tex2D(_MainTex, i.uv.xy);
                // 颜色混合
                c = tex * atten;
                c *= _Color;

                #if _DISSOLVEENABLED_ON
                    // 溶解效果
                    // 乘UV的Tiling可以调整溶解的视觉效果
                    fixed4 dissolveTex = tex2D(_DissolveTex, i.uv.zw);
                    fixed edge = dissolveTex.r + _DissolveEdge;
                    clip(edge - _Dissolve);
                
                    // 实现溶解边缘效果
                    // 可用smoothStep来实现，但smoothStep函数会自带平滑功能，此处不需要，为了优化性能，简单修改实现
                    // float rampValue = smoothstep(_Dissolve, _Dissolve + _DissolveEdge, edge);
                    float rampValue = saturate((edge - _Dissolve) / _DissolveEdge);
                    fixed4 dissolveRampTex = tex1D(_DissolveRampTex, rampValue); 
                    // 和DissolveRampColor颜色融合
                    c += dissolveRampTex * (1-rampValue) * _DissolveRampColor;
                #endif

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
                // 阴影投影需要手动计算溶解效果
                #if _DISSOLVEENABLED_ON
                    // 溶解效果
                    // 乘UV的Tiling可以调整溶解的视觉效果
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
            // 无论如何都会被编译的变体
            #pragma multi_compile _ _DISSOLVEENABLED_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            sampler2D _DissolveTex;
            // _DissolveTex的Tiling和Offset
            float4 _DissolveTex_ST;
            // 只拿一维的数据，因为第二维数据没有用
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

            // 优化准则：能在顶点着色器里做的事情就不要放到片段着色器里去做
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv.xy = v.uv.xy;
                // Transform_TEX可以实现Tiling和Offset的功能
                // o.uv.zw = v.uv.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 c;
                // 采样
                fixed4 tex = tex2D(_MainTex, i.uv.xy);
                // 颜色混合
                c = tex;
                c *= _Color;

                #if _DISSOLVEENABLED_ON
                // 溶解效果
                // 乘UV的Tiling可以调整溶解的视觉效果
                fixed4 dissolveTex = tex2D(_DissolveTex, i.uv.zw);
                fixed edge = dissolveTex.r + _DissolveEdge;
                clip(edge - _Dissolve);
                
                // 实现溶解边缘效果
                // 可用smoothStep来实现，但smoothStep函数会自带平滑功能，此处不需要，为了优化性能，简单修改实现
                // float rampValue = smoothstep(_Dissolve, _Dissolve + _DissolveEdge, edge);
                float rampValue = saturate((edge - _Dissolve) / _DissolveEdge);
                fixed4 dissolveRampTex = tex1D(_DissolveRampTex, rampValue); 
                // 和DissolveRampColor颜色融合
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

    // 如果在当前Shader中找不到ShadowCaster的pass，就会从FallBack中寻找
    //FallBack "Legacy Shaders/VertexLit"
}
