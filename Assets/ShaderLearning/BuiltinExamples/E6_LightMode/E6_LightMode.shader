Shader "Shader Learning/Builtin/E6_LightMode"
{
    Properties
    {
        _DiffuseIntensity ("Diffuse Intensity", float) = 1
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularIntensity ("Specular Intensity", float) = 1
        _Shininess ("Shininess", float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            half _DiffuseIntensity;
            fixed4 _SpecularColor;
            half _SpecularIntensity;
            half _Shininess;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = 0;

                // Diffuse = Ambient + Kd * LightColor * max(0, dot(N, L))

                fixed4 Ambient = unity_AmbientSky;
                half Kd = _DiffuseIntensity;
                fixed4 LightColor = _LightColor0;
                fixed3 N = normalize(i.worldNormal);
                fixed3 L = _WorldSpaceLightPos0;

                fixed4 Diffuse = Ambient + Kd * LightColor * max(0, dot(N, L));
                c += Diffuse;

                // Specular = SpecularColor * Ks * pow(max(0,dot(R,V)), Shininess)
                fixed4 SpecularColor = _SpecularColor;
                half Shininess = _Shininess;
                half Ks = _SpecularIntensity;
                fixed3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                fixed3 R = normalize(reflect(-L, N));

                fixed4 Specular = SpecularColor * Ks * pow(max(0, dot(R, V)), Shininess);
                //c += Specular;

                // BlinnSpecular = SpecularColor * Ks * pow(max(0,dot(N,H)), Shininess)
                fixed3 H = normalize(V + L);
                fixed4 BlinnSpecular = SpecularColor * Ks * pow(max(0, dot(N, H)), Shininess);
                c += BlinnSpecular;

                return c;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 生成计算逐像素光照时需要的各种内置宏
            #pragma multi_compile_fwdadd
            #pragma skip_variants DIRECTIONAL DIRECTIONAL_COOKIE POINT_COOKIE

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            half _DiffuseIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 计算衰减
                // 方法一：手写，只支持Point光，其他光的实现可看AutoLight.cginc
                // 将坐标转换为以灯光为中心的坐标，无阴影是实现
                //float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                //fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord));

                // 方法二，AutoLight.cginc中内置的方法
                UNITY_LIGHT_ATTENUATION(atten, 0, i.worldPos);

                fixed4 LightColor = _LightColor0 * atten;
                fixed3 N = normalize(i.worldNormal);
                fixed3 L = _WorldSpaceLightPos0;

                fixed4 Diffuse = LightColor * max(0, dot(N, L));

                return Diffuse;
            }
            ENDCG
        }
    }
}
