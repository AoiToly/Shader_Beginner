// Shader路径
Shader "Shader Learning/E1_Framework"
{
    // 公开属性
    Properties
    {
        // 语法格式
        // [Attribute]_Name ("Display Name", Type) = Default_Value
        [HDR]_Color("Color", color) = (1,1,1,1)
        _Int("Int", int) = 1
        // range可以在Inspector面板中添加滑动条
        [PowerSlider(3)]_Float("Float", range(0,10)) = 1
    }

    // 遍历寻找第一个设备支持的SubShader
    SubShader
    {
        // 每有一个pass渲染一次，多pass可以实现更丰富的效果
        // pass越多越耗，并且在URP中只支持单pass
        pass
        {
            // CG代码块
            CGPROGRAM

            // 常用include
            // HLSLSupport.cginc，编译CGPROGRAM时自动包含此文件，其中声明了很多预处理宏帮助多平台开发
            // UnityShaderVariables.cginc，编译CGPROGRAM时自动包含此文件，其中声明了很多内置的全局变量
            // UnityCG.cginc，需手动添加，其中声明了很多内置的帮助函数与结构
            #include "UnityCG.cginc"

            // 建议将Unity内置的shader从官网上下下来然后导入项目中

            // 指定顶点和片段着色器
            #pragma vertex vert
            #pragma fragment frag

            // 数据类型
            // float/half/fixed
            // Integer
            // sampler2D/samplerCUBE
            // 数组声明举例: float3 point = float3(10, 3.8, 1); float4 pos = float4(point, 1);

            // 应用程序阶段数据
            struct appdata
            {
                float4 pos : POSITION;
                float4 color : COLOR;
            };

            // 顶点片段传递数据
            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            // Properties中的属性需要再声明一遍
            fixed4 _Color;

            v2f vert(appdata v)
            { 
                // 为了防止部分GPU报错，结构体定义时需要初始化
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.pos);
                return o;
            }

            // SV_TARGET指定输出
            float4 frag(v2f i) : SV_TARGET
            {
                return _Color;
            }

            ENDCG
        }
    }

    // 自定义材质面板，指定脚本名称
    CustomEditor ""
    // 如果所有SubShader都不支持，指定使用的Shader名称
    FallBack ""
}
