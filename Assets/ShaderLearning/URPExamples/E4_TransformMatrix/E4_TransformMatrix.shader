Shader "Shader Learning/URP/E4_TransformMatrix"
{
    Properties
    {
        [Header(Base)]
        _MainTex("Main Tex", 2D) = "white" {}
        [Space(25)]

        [Header(Transform)]
        _Translate("Translate", vector) = (0, 0, 0, 0)
        _Scale("Scale", vector) = (1, 1, 1, 1)
        _Rotation("Euler", vector) = (0, 0, 0, 0)
        [Space(25)]

        [Header(Camera)]
        _CameraFOV("CameraFOV", float) = 60
        [Toggle]_IsPerspective("IsPerspective", int) = 0
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
        }

        Pass
        {
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _ISPERSPECTIVE_ON

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                float4 _Translate;
                float4 _Scale;
                float4 _Rotation;
                float _CameraFOV;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                // 平移
                float4x4 T = float4x4(
                    1, 0, 0, _Translate.x,
                    0, 1, 0, _Translate.y,
                    0, 0, 1, _Translate.z,
                    0, 0, 0, 1);
                v.positionOS = mul(T, v.positionOS);

                // 缩放
                // v.positionOS = _Scale * v.positionOS;
                // 矩阵形式
                float4x4 S = float4x4(
                    _Scale.x * _Scale.w, 0, 0, 0,
                    0, _Scale.y * _Scale.w, 0, 0,
                    0, 0, _Scale.z * _Scale.w, 0,
                    0, 0, 0, 1);
                v.positionOS = mul(S, v.positionOS);

                // 旋转
                // x轴
                float4x4 RX = float4x4(
                    1, 0, 0, 0,
                    0, cos(_Rotation.x), -sin(_Rotation.x), 0,
                    0, sin(_Rotation.x), cos(_Rotation.x), 0,
                    0, 0, 0, 1);
                // y轴
                float4x4 RY = float4x4(
                    cos(_Rotation.y), 0, sin(_Rotation.y), 0,
                    0, 1, 0, 0,
                    -sin(_Rotation.y), 0, cos(_Rotation.y), 0,
                    0, 0, 0, 1);
                // z轴
                float4x4 RZ = float4x4(
                    cos(_Rotation.z), -sin(_Rotation.z), 0, 0,
                    sin(_Rotation.z), cos(_Rotation.z), 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1);
                v.positionOS = mul(RZ, mul(RY, mul(RX, v.positionOS)));

                // 本地空间转世界空间
                float4 positionWS = float4(TransformObjectToWorld(v.positionOS.xyz), 1);

                // 世界空间转视图空间
                // float4 positionVS = float4(TransformWorldToView(positionWS.xyz), 1);

                // 原理为，坐标系变换，即先平移变换使得两个坐标系原点相同，再旋转变换使得z轴方向和相机面朝方向一致
                // 公式为：
                // Wv表示视图空间下，世界空间的基的值
                // Vw表示世界空间下，视图空间的基的值
                // Pw表示世界空间下的点，Pv表示视图空间下的点
                // 我们要求的是Pv
                // Pv = Wv * Pw
                // Pv = Vw^-1 * Pw  Wv和Vw互为逆矩阵
                // Pv = Vw^T * Pw  由于是直角坐标系 => 正交矩阵 => Vw^-1 = Vw^T
                // 上述公式仅包含了相机的旋转变换
                // 由于点的旋转是基于视图空间的旋转，因此在计算旋转之间，首先要进行平移变换
                // T表示平移变换矩阵
                // 则Pv = Vw^T * T * Pw

                // 计算相机面向的方向
                float3 cameraForward = -1 * mul(UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))[2]).xyz;

                // 由于Unity默认左手坐标系，但view空间是右手坐标系
                // 因此在view空间下，Z轴的正方向与其他空间相反，因此取相反数
                float3 viewZ = normalize(-cameraForward);
                float3 viewY = normalize(float3(0, 1, 0));
                // 由于viewZ指向Z轴的负方向，因此根据右手定则，不能用viewY 叉乘 viewZ，而是反过来
                float3 viewX = normalize(cross(viewZ, viewY));
                // 此处理由同上
                viewY = normalize(cross(viewX, viewZ));
                
                // 注，这个矩阵已经是转置后的矩阵了
                // Vw^T
                float4x4 MatrixWorldToViewR = float4x4(
                    viewX.x, viewX.y, viewX.z, 0,
                    viewY.x, viewY.y, viewY.z, 0,
                    viewZ.x, viewZ.y, viewZ.z, 0,
                    0, 0, 0, 1);
                // T
                float4x4 MatrixWorldToViewT = float4x4(
                    1, 0, 0, -_WorldSpaceCameraPos.x,
                    0, 1, 0, -_WorldSpaceCameraPos.y,
                    0, 0, 1, -_WorldSpaceCameraPos.z,
                    0, 0, 0, 1);
                // Vw^T * T
                float4x4 MatrixWorldToView = mul(MatrixWorldToViewR, MatrixWorldToViewT);
                float4 positionVS = mul(MatrixWorldToView, positionWS);
                
                // 视图空间转齐次裁剪空间
                // float4 positionCS = TransformWViewToHClip(positionVS.xyz);
                // 透视相机
                #if _ISPERSPECTIVE_ON
                    // 相机Fov的一半的弧度
                    _CameraFOV = radians(_CameraFOV);
                    // 近裁剪面
                    float n = _ProjectionParams.y;
                    // 远裁剪面
                    float f = _ProjectionParams.z;
                    // 屏幕宽高比
                    float aspect = _ScreenParams.x / _ScreenParams.y;
                    // 近裁剪面的高/2
                    float h = n * tan(_CameraFOV / 2);
                    // 近裁剪面的宽/2
                    float w = h * aspect;

                    // 透视矩阵
                    float4x4 MatrixPerspToOrtho = float4x4(
                        n, 0, 0, 0,
                        0, n, 0, 0,
                        0, 0, n+f, n*f,
                        0, 0, -1, 0);
                // 正交相机
                #else
                    // 近裁剪面
                    float n = _ProjectionParams.y;
                    // 远裁剪面
                    float f = _ProjectionParams.z;
                    // 正交相机的宽/2
                    float w = unity_OrthoParams.x;
                    // 正交相机的高/2
                    float h = unity_OrthoParams.y;
                #endif
                // 计算正交投影
                // 原理为，先平移变换使得两个坐标系原点一致，再缩放变换使得基向量相同
                // 注意，由于视图空间是右手坐标系而裁剪空间是左手坐标系，因此计算时要用-n和-f
                // DX平台（坐标系原点左上角）
                #if UNITY_UV_STARTS_AT_TOP
                    // DX平台下，z轴需要缩放到1到0范围
                    // 注意是1到0范围，而不是0到1范围
                    // 这是为了避免精度丢失，因此计算时需要进行调整
                    float4x4 MatrixViewToClipOrthoS = float4x4(
                        1/w, 0, 0, 0,
                        0, -1/h, 0, 0,
                        0, 0, 1/(f - n), 0,
                        0, 0, 0, 1);
                    // 原点在0点，即末尾处
                    float4x4 MatrixViewToClipOrthoT = float4x4(
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, f,
                        0, 0, 0, 1);
                    
                // OpenGL平台（坐标系原点右上角）
                #else
                    // OpenGL平台下，z轴需要缩放到-1到1范围
                    float4x4 MatrixViewToClipOrthoS = float4x4(
                        1/w, 0, 0, 0,
                        0, 1/h, 0, 0,
                        0, 0, 2/(n - f), 0,
                        0, 0, 0, 1);
                    // 原点在0点，即中间处
                    float4x4 MatrixViewToClipOrthoT = float4x4(
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, (n + f) * 0.5,
                        0, 0, 0, 1);
                #endif
                float4x4 MatrixViewToClipOrtho = mul(MatrixViewToClipOrthoS, MatrixViewToClipOrthoT);

                #if _ISPERSPECTIVE_ON
                    float4x4 MatrixViewToClip = mul(MatrixViewToClipOrtho, MatrixPerspToOrtho);
                #else
                    float4x4 MatrixViewToClip = MatrixViewToClipOrtho;
                #endif
                float4 positionCS = mul(MatrixViewToClip, positionVS);

                Varyings o = (Varyings)0;
                o.positionCS = positionCS;
                o.uv = v.uv;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                return c;
            }
            ENDHLSL
        }
    }
}
