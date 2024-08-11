Shader "Shader Learning/Builtin/E3_Effects"
{
    // 通用特效Shader
    // 1. 半透明效果，可设置不同的混合叠加模式
    // 2. 可单面显示，也可以双面显示
    // 3. 纹理自流动
    // 4. 遮罩功能
    // 5. UV扭曲效果
    // 6. 溶解效果

    Properties
    {
        [Header(RenderingMode)]
        // 注意这里的枚举，方便捏
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("Src Blend", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("Dst Blend", int) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", int) = 0
        [Space(25)]

        [Header(Base)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Intensity ("Float", range(-10, 10)) = 1
        _MainUVSpeedX ("MainUVSpeedX", float) = 0
        _MainUVSpeedY ("MainUVSpeedY", float) = 0
        [Space(25)]

        [Header(Mask)]
        [Toggle]_MaskEnabled ("MaskEnabled", int) = 0
        _MaskTex ("MaskTex", 2D) = "white" {}
        _MaskUVSpeedX ("MaskUVSpeedX", float) = 0
        _MaskUVSpeedY ("MaskUVSpeedY", float) = 0
        [Space(25)]

        [Header(Distort)]
        [MaterialToggle(DISTORTENABLED)]_DistortEnabled ("DistortEnabled", int) = 0
        _DistortTex ("DistortTex", 2D) = "white" {}
        _Distort ("Distort", range(0, 1)) = 0
        _DistortUVSpeedX ("DistortUVSpeedX", float) = 0
        _DistortUVSpeedY ("DistortUVSpeedY", float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }

        // 颜色混合
        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cull]

        // 使用两个Pass来做透明效果，这样会增加消耗，但多一个Pass存下深度信息后，计算结果会更为准确
        // 此Pass不输出颜色，仅用于写入深度信息
        // 如果不使用此Pass，只使用单Pass，简单的情况会是正确的，但当场景复杂时，容易穿帮
        pass
        {
            ZWrite On
            ColorMask 0
        }

        pass
        {
            // 关闭深度写入，否则会导致出错
            // 如果开启深度写入，会将透明物体后面的颜色覆盖，导致出错
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 根据材质的使用情况来决定是否会被编译的变体
            // 只需要在Inspector面板勾选Skip unused shader_features即可
            #pragma shader_feature _ _MASKENABLED_ON
            #pragma shader_feature _ DISTORTENABLED

            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            half _Intensity;
            float _MainUVSpeedX, _MainUVSpeedY;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float _MaskUVSpeedX, _MaskUVSpeedY;

            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float _Distort;
            float _DistortUVSpeedX, _DistortUVSpeedY;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // 前两个通道存MainTex的uv
                // 后两个通道存MaskTex的uv
                float4 uv : TEXCOORD0;
                // 前两个通道存DistortTex的uv
                float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex) + float2(_MainUVSpeedX, _MainUVSpeedY) * _Time.y;

                #if _MASKENABLED_ON
                    o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex) + float2(_MaskUVSpeedX, _MaskUVSpeedY) * _Time.y;
                #endif
                
                #if DISTORTENABLED
                    o.uv2.xy = TRANSFORM_TEX(v.uv, _DistortTex) + float2(_DistortUVSpeedX, _DistortUVSpeedY) * _Time.y;
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = _Color * _Intensity;

                float2 uv = i.uv.xy;
                // uv扭曲效果
                #if DISTORTENABLED
                    // distort
                    fixed4 distortTex = tex2D(_DistortTex, i.uv2.xy);
                    uv = lerp(i.uv.xy, distortTex, _Distort);
                #endif

                c *= tex2D(_MainTex, uv); 

                // 遮罩效果
                #if _MASKENABLED_ON
                    // mask
                    fixed4 maskTex = tex2D(_MaskTex, i.uv.zw);
                    c *= maskTex;
                #endif

                return c;
            }
            ENDCG
        }
    }
}
