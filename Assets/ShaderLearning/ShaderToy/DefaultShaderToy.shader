Shader "ShaderToy/DefaultShaderToy"
{
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            // ���ں���shader�Ķ�����ɫ�����ִ�඼һ��
            // ���ָ��Unity�ٷ��ṩ�Ķ�����ɫ��
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            // v2f_imgΪUnity�ٷ��ṩ��Ƭ����ɫ��
            fixed4 frag (v2f_img i) : SV_Target
            {

                // Time varying pixel color
                fixed3 col = 0.5 + 0.5*cos(_Time.y + i.uv.xyx + half3(0,2,4));

                // Output to screen
                fixed4 c = fixed4(col,1.0);
                return c;
            }
            ENDCG
        }
    }
}
