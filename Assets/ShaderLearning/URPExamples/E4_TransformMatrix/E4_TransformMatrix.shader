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
                // ƽ��
                float4x4 T = float4x4(
                    1, 0, 0, _Translate.x,
                    0, 1, 0, _Translate.y,
                    0, 0, 1, _Translate.z,
                    0, 0, 0, 1);
                v.positionOS = mul(T, v.positionOS);

                // ����
                // v.positionOS = _Scale * v.positionOS;
                // ������ʽ
                float4x4 S = float4x4(
                    _Scale.x * _Scale.w, 0, 0, 0,
                    0, _Scale.y * _Scale.w, 0, 0,
                    0, 0, _Scale.z * _Scale.w, 0,
                    0, 0, 0, 1);
                v.positionOS = mul(S, v.positionOS);

                // ��ת
                // x��
                float4x4 RX = float4x4(
                    1, 0, 0, 0,
                    0, cos(_Rotation.x), -sin(_Rotation.x), 0,
                    0, sin(_Rotation.x), cos(_Rotation.x), 0,
                    0, 0, 0, 1);
                // y��
                float4x4 RY = float4x4(
                    cos(_Rotation.y), 0, sin(_Rotation.y), 0,
                    0, 1, 0, 0,
                    -sin(_Rotation.y), 0, cos(_Rotation.y), 0,
                    0, 0, 0, 1);
                // z��
                float4x4 RZ = float4x4(
                    cos(_Rotation.z), -sin(_Rotation.z), 0, 0,
                    sin(_Rotation.z), cos(_Rotation.z), 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1);
                v.positionOS = mul(RZ, mul(RY, mul(RX, v.positionOS)));

                // ���ؿռ�ת����ռ�
                float4 positionWS = float4(TransformObjectToWorld(v.positionOS.xyz), 1);

                // ����ռ�ת��ͼ�ռ�
                // float4 positionVS = float4(TransformWorldToView(positionWS.xyz), 1);

                // ԭ��Ϊ������ϵ�任������ƽ�Ʊ任ʹ����������ϵԭ����ͬ������ת�任ʹ��z�᷽�������泯����һ��
                // ��ʽΪ��
                // Wv��ʾ��ͼ�ռ��£�����ռ�Ļ���ֵ
                // Vw��ʾ����ռ��£���ͼ�ռ�Ļ���ֵ
                // Pw��ʾ����ռ��µĵ㣬Pv��ʾ��ͼ�ռ��µĵ�
                // ����Ҫ�����Pv
                // Pv = Wv * Pw
                // Pv = Vw^-1 * Pw  Wv��Vw��Ϊ�����
                // Pv = Vw^T * Pw  ������ֱ������ϵ => �������� => Vw^-1 = Vw^T
                // ������ʽ���������������ת�任
                // ���ڵ����ת�ǻ�����ͼ�ռ����ת������ڼ�����ת֮�䣬����Ҫ����ƽ�Ʊ任
                // T��ʾƽ�Ʊ任����
                // ��Pv = Vw^T * T * Pw

                // �����������ķ���
                float3 cameraForward = -1 * mul(UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))[2]).xyz;

                // ����UnityĬ����������ϵ����view�ռ�����������ϵ
                // �����view�ռ��£�Z����������������ռ��෴�����ȡ�෴��
                float3 viewZ = normalize(-cameraForward);
                float3 viewY = normalize(float3(0, 1, 0));
                // ����viewZָ��Z��ĸ�������˸������ֶ��򣬲�����viewY ��� viewZ�����Ƿ�����
                float3 viewX = normalize(cross(viewZ, viewY));
                // �˴�����ͬ��
                viewY = normalize(cross(viewX, viewZ));
                
                // ע����������Ѿ���ת�ú�ľ�����
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
                
                // ��ͼ�ռ�ת��βü��ռ�
                // float4 positionCS = TransformWViewToHClip(positionVS.xyz);
                // ͸�����
                #if _ISPERSPECTIVE_ON
                    // ���Fov��һ��Ļ���
                    _CameraFOV = radians(_CameraFOV);
                    // ���ü���
                    float n = _ProjectionParams.y;
                    // Զ�ü���
                    float f = _ProjectionParams.z;
                    // ��Ļ��߱�
                    float aspect = _ScreenParams.x / _ScreenParams.y;
                    // ���ü���ĸ�/2
                    float h = n * tan(_CameraFOV / 2);
                    // ���ü���Ŀ�/2
                    float w = h * aspect;

                    // ͸�Ӿ���
                    float4x4 MatrixPerspToOrtho = float4x4(
                        n, 0, 0, 0,
                        0, n, 0, 0,
                        0, 0, n+f, n*f,
                        0, 0, -1, 0);
                // �������
                #else
                    // ���ü���
                    float n = _ProjectionParams.y;
                    // Զ�ü���
                    float f = _ProjectionParams.z;
                    // ��������Ŀ�/2
                    float w = unity_OrthoParams.x;
                    // ��������ĸ�/2
                    float h = unity_OrthoParams.y;
                #endif
                // ��������ͶӰ
                // ԭ��Ϊ����ƽ�Ʊ任ʹ����������ϵԭ��һ�£������ű任ʹ�û�������ͬ
                // ע�⣬������ͼ�ռ�����������ϵ���ü��ռ�����������ϵ����˼���ʱҪ��-n��-f
                // DXƽ̨������ϵԭ�����Ͻǣ�
                #if UNITY_UV_STARTS_AT_TOP
                    // DXƽ̨�£�z����Ҫ���ŵ�1��0��Χ
                    // ע����1��0��Χ��������0��1��Χ
                    // ����Ϊ�˱��⾫�ȶ�ʧ����˼���ʱ��Ҫ���е���
                    float4x4 MatrixViewToClipOrthoS = float4x4(
                        1/w, 0, 0, 0,
                        0, -1/h, 0, 0,
                        0, 0, 1/(f - n), 0,
                        0, 0, 0, 1);
                    // ԭ����0�㣬��ĩβ��
                    float4x4 MatrixViewToClipOrthoT = float4x4(
                        1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, f,
                        0, 0, 0, 1);
                    
                // OpenGLƽ̨������ϵԭ�����Ͻǣ�
                #else
                    // OpenGLƽ̨�£�z����Ҫ���ŵ�-1��1��Χ
                    float4x4 MatrixViewToClipOrthoS = float4x4(
                        1/w, 0, 0, 0,
                        0, 1/h, 0, 0,
                        0, 0, 2/(n - f), 0,
                        0, 0, 0, 1);
                    // ԭ����0�㣬���м䴦
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
