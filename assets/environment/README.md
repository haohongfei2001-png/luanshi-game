# 河关战场环境资产

`river_ram.gltf` 包含冲车车架与独立悬槌。前后轮毂、轮辐、木箍、铁轮缘、车轴、梁架和皮罩在同一比例下制作。`grain_cart.gltf` 用于河关营地的两辆辎重车。两者由 Godot 直接导入；冲车悬槌使用战斗中已有的撞门节奏。

两张 128 × 128 循环纹理作为线性数据导入，并生成 mipmap。 `fieldbed.png` 的 RGB 分别存储碎土、草梗和河岸卵石；`joinery.png` 的 RGB 分别存储木纹、石砌面和织物纹理。地表、城门、木桥、营帐和植被共用现有的地形材质。屋面有分片筒瓦和起脊，门楼近景保留檐下斗栱与承重柱。

以上网格、配色和纹理是本仓库为此战场创作的原创资产，未使用外部模型或贴图库。原始制作文件为 `tools/env_assets.mjs`。在仓库根目录运行 `node tools/env_assets.mjs` 可重建船、冲车、辎重车和两张原始材质图，生成过程不依赖第三方包。Godot 常规项目导入会处理这些资产。

`floodplain-paint.png` 为原创 512 × 336 河关地表彩绘。主路、两条渡口支路、坡地熟田、石脊和树荫的位置来自 `foothills.json`。地图内的城门保留土筑墙体、错缝石基、木构额枋和可分离的远檐。`leaf-sprays.png` 是原创 256 × 256 带透明通道的叶簇图集，包括阔叶、垂柳、草穗和发黄的林冠。两张纹理均启用 mipmap，树枝和叶片分区合批。运行 `node tools/env_river_paint.mjs` 可重制两张纹理。此组资产未使用摄影、图库或其他游戏画面。

`stand-placements.json` 由同一制作命令生成，树木的实际树位同时参与林下地表着色。`trail-marks.png` 是原创 256 × 256 循环地面叠绘，包含泥缝、断草和碎石；坡道、田地和主路按地表材质混合。门额的“河關”沿用现有 Noto Sans SC 字体及其 OFL 授权。

`bank-willows.gltf` 的老柳与幼柳各有独立木质网格、弯折垂枝和叶帘，缩放后共同并入战场的静态树群批次。`willow-sprays.png` 是原创 512 × 256 河岸图集，包含两种垂柳叶幕、一种树梢和一簇莎草。`foothills.json` 固定大树的位置与朝水的方向。运行 `node tools/env_river_paint.mjs` 会调用 `tools/env_willow.mjs`，重建柳树网格、图集、树位与相应地表着色。

早期主战区地表使用 512 × 512 可平铺颜色与交界高度贴图。草根采用 [Amal Kumar 的 Sparse Grass](https://polyhaven.com/a/sparse_grass)，压实土采用 [Rob Tuytel 的 Brown Mud Dry](https://polyhaven.com/a/brown_mud_dry)，湿砂采用 [Dario Barresi 的 Sandy Gravel 02](https://polyhaven.com/a/sandy_gravel_02)。三项原始扫描适用 [Poly Haven CC0](https://polyhaven.com/license)。项目对其做了色阶分组、抑制细小亮斑、色彩整理和高度蒙版制作。游戏直接读取仓库里的 PNG。可用 Pillow 11.3.0 运行 `python3 tools/env_ground_materials.py` 重建，脚本对三份源 JPG 核验 SHA-256，游戏运行时不访问素材网站。

`soil-cover.png` 由 `node tools/env_river_paint.mjs` 从河关道路、营地、坡地旧田和河岸生成。四个线性通道依次记录裸土覆盖、湿砂、地表明暗和到道路中心线的相对距离。车辙随桥头和道路弯曲。近景草冠与土沿使用材料高度过渡。

`verge-and-track.svg` 是原创可平铺地表色罩。草丛的短叶、根际土色和零散路石分在三个线性通道，按世界地图上的草场、车道、坡田和潮湿河岸分别显现。远镜头使用 mipmap 滤除脚边细节。

当前河关的草场与路面读取 `valley-turf.png` 与 `valley-loess.png`，并共用既有的湿岸、军营与道路覆盖数据。陆地榆树以有底面和树肩的立体冠团接到弯曲的木枝，残缘叶尖使用 `painted-elm.png`。树冠的连贯色面来自 `elm-crown-paint.png`。四张图各自的来源和制作提示见[材质来源记录](../../tools/art/source/river-surface-materials.md)。

战场右上角的地形图以 `foothills.json` 中的河道、三处过河道路、城寨、耕地、林带生成。运行 `node tools/env_survey.mjs --check` 核对底图。视野框会随镜头转动，显示主角和部署阶段的己方阵位。

中桥上游的浅底木舟由横断面放样，船底、舷缘、内肋和横凳按同一水线制作，缆绳系在岸桩上。它占用既有河道的不可通行部分。原作网格由 `node tools/env_assets.mjs` 生成，`node tools/env_assets.mjs --check-skiff` 核对提交资产。

道边草甸和官道在分别采样广域色面、成簇矮草和压实路面的画稿后，按实际玩家镜头过滤。中桥木舟的吃水线把河面边界限定在船壳，木凳下可见真实板底。榆树的分叉树干、偏心冠团及末梢按空间格与原地面合批。

RC15 的陆地阔叶树采用 Quaternius 免费 Standard 版的两株专业 glTF 母版。枝形、树皮、叶片展开和透明轮廓来自原作；按河关实际树高标准化，在树冠范围重建连续法线，仍按原有地形格合批。树模型接入现有树位，与河岸原作垂柳分别落地。[取得的源、再分发许可与 Blender 复建命令](quaternius/README.md)
