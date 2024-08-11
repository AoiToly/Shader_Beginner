Shader "Shader Learning/Builtin/E14_PostProcessing/TestImageEffectShader"
{
    Properties
    {
        // 由于后处理shader中，无法在材质面板上修改属性的值
        // 因此除了_MainTex之外的属性都没必要在Properties中声明
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
            // 由于后处理shader的顶点着色器部分大多都一致
            // 因此指定Unity官方提供的顶点着色器
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            fixed _Value;

            // v2f_img为Unity官方提供的片段着色器
            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return step(_Value, col.r);
            }
            ENDCG
        }
    }
}
