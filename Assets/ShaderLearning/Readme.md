这里记录了各个Example文件夹中展示的功能

#### E1_Framework

记录了一个普通built-in管线的shader的各个模块的功能

#### E2_CharacterUnlit

一个不受灯光影响的Shader，包括溶解效果，颜色叠加效果

包含multi_compile功能

#### E3_Effects

一个特效Shader，包含透明效果、正反面剔除效果、遮罩效果、UV扭曲效果，及简单的修改Inspector面板的Attribute

包含shader_feature功能





#### Shader 通用优化规则

**精度优化**

三种精度：fixed/half/float

位置坐标、纹理坐标类使用float

HDR颜色、方向向量类使用half

普通纹理、颜色类使用fixed

实际上，使用的精度取决于目标平台和GPU

现在桌面级GPU都是直接采用float，shader中的fixed/half/float最后都是用的float

现代移动端GPU大多仅支持half和float，所以能用half的就用half

fixed仅用于较旧的移动GPU

**能放顶点的不要放片段中**

多Pass少用，除了Unity内特殊作用的Pass之外（如meta），有n个Pass就会产生n个DC，同时不能进行合批

**小心使用AlphaTest和ColorMask**

AlphaTest，即在shader中使用了clip()函数，通常在大多数平台上使用AlphaTest会有些性能优势，但是在IOS和某些使用PowerVR GPU的Android设备上性能很低

ColorMask，在IOS和部分Android设备上性能很低

**NoScaleOffset**

在不需要Tiling和Offset中的贴图加入该属性，并在Shader中不做计算

**DisableBatching**

`Tags{"DisableBatching" = "true"}`

true表示不能进行合批，false表示能合批就合批（默认值），此值会同时影响静态合批和动态合批

如果顶点上的计算需要在模型的本地空间下进行，则需要开启，否则最好不要开启，因为合批和物体的本地空间坐标系会发生变化，导致产生错误结果

**GrabPass**

`GrabPass { "_GrabTex" }`

GrabPass指定贴图名称后，不同的对象只需要抓取这一个Tex即可

**Surface Shader**

能不用就不用

**ShaderLOD**

实现硬件配置区分

**Overdraw**

即同一个像素点被渲染多次的情况，多见于半透明材质的渲染叠加

减少半透明对象的屏幕面积、层数，降低半透明shader的计算，将多个半透明物体合并为一个半透明物体

可以通过Scene视图下的设置改为Overdraw模式查看场景具体Overdraw情况

**变体优化**

变体的数量直接影响shaderlab内存的占用，能少则少

尽量不要去用standard材质，会产生大量的变体，可以自己修改定制一个

另外，shader_feature优先与multi_compile使用

使用变体收集器，将需要用到的shader统一加载

另外在`Project Settings -> Graphics`中可以调整项目中默认包含的shader，可以对无用shader进行剔除

**编译时间优化**

针对不同平台，Unity会编译不同的Shader，可以通过`#pragma only_renderers`和`pragma exclude_renderers`两个指令指定并剔除特定平台，较少shader编译的时间，但不会影响shader的运行时的效率

**指令优化**

编译后的指令可以通过编译shader查看

写代码时可以将乘法和加法合并起来写，如`t = a * b; o = t + c; `可以改写为`o = a * b + c`，编译后的指令会从2条（一条乘法一条加法）减少为1条（一条乘加指令，即mad），又如`t = (a+b) * (a-b)` => `t = a*a + (-b*b)`

其他类似的指令优化可以参考`Shader参考大全->Math->常用指令`

如果abs()指令是作为输入修饰符的话，它是免费的，即`abs(a * b)` => `abs(a) * abs(b)`

负号可以适当移入变量中，即`-dot(a, b)` => `dot(-a, b)`

同一维度的向量尽可能单独相乘，即`t = M.xyz * a * b * M.yzw * c * d` => `(M.xyz * M.yzw) * (a*b*c*d)`

部分方法开销很大，如`asin/atan/acos`

#### 合批

**动态合批规则**

材质相同是合批的前提，但如果是材质实例的话，则无法合批

支持不同网格的合批

单个网格最多225个顶点，900个顶点属性，如果Shader中用到了网格的Position、normal和uv的话，则最多是300个顶点，如果Shader中用到了Position、normal、uv0、uv1和tangent的话，则最多是180个顶点

每一批支持的网格数量不超过32k个顶点属性

scale中有负值则无法合批

Lightmap对象无法合批

**静态合批规则**

相同材质球

勾选Batching Static

一个批次内最多2^16个顶点，及65536个顶点

**静态合批缺点**

导致内存占用增加：需要存储合并后的网格数据

导致包体占用增加：Scene文件中会有更多的数据

**合批优化**

为了保证一批物体是相同材质球，可以多种物体公用贴图，采用图集&uv映射的方式，由美术层面进行优化

**GPU实例化规则**

对硬件有要求