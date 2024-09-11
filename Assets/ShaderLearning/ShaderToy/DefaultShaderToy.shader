Shader "ShaderToy/DefaultShaderToy"
{
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

            // v2f_img为Unity官方提供的片段着色器
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
