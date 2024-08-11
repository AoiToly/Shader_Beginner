Shader "Shader Learning/Builtin/E14_PostProcessing/TestImageEffectShader"
{
    Properties
    {
        // ���ں���shader�У��޷��ڲ���������޸����Ե�ֵ
        // ��˳���_MainTex֮������Զ�û��Ҫ��Properties������
        _MainTex ("Texture", 2D) = "white" {}
        // _Value ("Value", float) = 0
    }
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

            sampler2D _MainTex;
            fixed _Value;

            // v2f_imgΪUnity�ٷ��ṩ��Ƭ����ɫ��
            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return step(_Value, col.r);
            }
            ENDCG
        }
    }
}
