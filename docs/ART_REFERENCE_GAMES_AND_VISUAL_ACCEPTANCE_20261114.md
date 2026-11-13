# 《乱世》｜八款真实游戏美术参考、Codex 强制执行与实机视觉验收（OWNER-ARTREF-20261114）

> **最高优先级 OWNER 已决定目标；不是当前游戏已达到目标的证明。** Codex 必须主动研究真实游戏实拍，模仿可迁移的镜头、制作工艺、造型、动画、战场信息组织及商业级完成度，落实为实际能玩、能录屏、能复现的 Godot 战场。禁止以研究报告、AI 概念图、静态渲染或对既有粗糙画面的轻微修饰替代实际完成。
>
> 本文专门规定参考对象、分项技术与美术标准、P0 工作次序和交付证据；与早期文档冲突时，以本文件和 [11-13 正式国风 3D 动画式方向](ART_DIRECTION_CEL_SHADED_BATTLEFIELD_20261113.md)、[商业级质量目标](OWNER_QUALITY_FIDELITY_PERFORMANCE_TARGET_20261113.md)、[拒绝粗糙迭代准则](VISUAL_RESET_AND_REJECTION_GATES_20261113.md) 为准。非美术的战斗机制、规模、角色生涯、存档和性能要求仍有效。

## 1. 八个真实游戏参考：每一个必须学习的维度

最终形成统一的**唐末/五代式中国古代 3D 战场、6–7 头身探索起点的非大头人物、干净连续的色块、2–3 档分级明暗、少量克制描边、可信衣甲、武器接触和真实千人军阵**。绝不是把八款游戏原画风直接拼起来。

| 优先级 | 真实作品（点击检查截图/视频） | 强制学习、在《乱世》实现的维度 | 明确不照搬 |
|---|---|---|---|
| P0 镜头 | [《赵云传：云汉腾龙》Steam](https://store.steampowered.com/app/2201710/Three_Kingdoms_Zhao_Yun/)；[斜俯视攻门截图](https://cdn.akamai.steamstatic.com/steam/apps/2201710/ss_8e6eb482d3c64a691653d98791dfd5a133f06590.1920x1080.jpg?t=1710128020) | 主角占屏比例、斜俯视正常可操作机位、城墙/地面/敌兵尺度关系、兵器攻击空间可读性 | 其偏旧的动作/材质水准不作为上限，不复制夸张招式 |
| P0 完成度 | [《王者荣耀》官方](https://www.honorofkings.com/global-en/)；[官方游戏地图图](https://www.honorofkings.com/img/map_bigimg3.jpg) | **普通士兵也要达到成熟商业游戏精度**，不是只精修主角；轮廓、色块、衣甲结构、地图材质、抗锯齿、动画与反馈的整体精致感 | 不复制具体英雄/皮肤、技能、地图/UI、阵营和华丽幻想效果 |
| P0 军阵 | [《全面战争：三国》SEGA 官方](https://asia.sega.com/totalwar-three-kingdoms/en/)；[实际攻城画面](https://www.vice.com/en/article/three-kingdoms-is-the-best-total-war-game-in-a-decade/) | 千人远景的编队阵列、前后排、旗帜、骑兵侧翼、城关及地形关系、占地与规模感 | 不沿用整套灰暗写实光照，不改变为纯 RTS |
| P0 近战 | [《战意》Steam](https://store.steampowered.com/app/835570/Conquerors_Blade/)；[盾枪军阵截图](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/835570/ss_0ddbbb1bc1a0f5f38ae2a22077330d38040c5611.1920x1080.jpg?t=1726748286) | 兵种轮廓、持械与承重、军阵之间真实接触、主将与部队同场、攻守城门 | 不复制欧式装备/竞技 HUD/视角或具体动作资源 |
| P0 动作 | [《真·三国无双 起源》光荣官方截图集](https://www.koeitecmoamerica.com/games/dynasty-warriors-origins/) | 多人冲锋，角色运动重量，起势—发力—真实接触—受击—收势，密集战场仍有清楚动势 | 不做只会放特效的假千人，不复制角色或招式 |
| P1 城池地形 | [《帝国时代 IV》中国文明官方](https://www.ageofempires.com/games/age-of-empires-iv/civilizations/chinese/)；[Xbox 官方实机介绍](https://news.xbox.com/en-us/2021/04/10/age-of-empires-fan-preview-recap/) | 中国城门/城墙/道路/院落/营地/树草/攻城器械的结构、地形分区与斜俯视可读性 | 不照搬 RTS 不真实的比例，也不把晚期火器放进唐末 |
| P1 中国气质 | [《燕云十六声》Steam 实机](https://store.steampowered.com/app/3564740/Where_Winds_Meet/) | 五代式城镇、古代生活空间、服饰建制、桥岸道路及场景文化密度 | 不复制关卡/人物/建筑独创细节，不改为高频照片级脏纹理 |
| P2 表现系统 | [《炽焰帝国 II》Steam 历史截图区](https://steamcommunity.com/app/1132210/screenshots/)；[SteamDB 画面档案](https://steamdb.info/app/1132210/screenshots/) | 一个人控制英雄又指挥大军的视听/交互层级和队伍表现 | 此作品年代较久，仅学玩法表现，**绝非**画质底线 |

**权重解释**：赵云传=操作镜头（不代表终极画质）；王者荣耀=成熟商业级细腻清晰度；全面战争=远景阵型；战意=兵种近战；真三起源=运动、战斗反馈；帝国时代 IV=城防地形；燕云=历史环境；炽焰帝国 II=英雄与军团共存。

### 实际参考截图（第三方外部链接，禁止当作游戏资产）

以下是可打开的实际游戏截图，按来源标注，供 Codex 在美术制作和验收时侧栏对照。图片版权属于各自权利人，本仓库只保留外链，不下载或重分发其素材；若 CDN 不再有效，以该作品官方页面截图集为准。

| 图像 | 需要观察的具体内容 |
|---|---|
| [![赵云传 Steam 斜俯视战场](https://cdn.akamai.steamstatic.com/steam/apps/2201710/ss_8e6eb482d3c64a691653d98791dfd5a133f06590.1920x1080.jpg?t=1710128020)](https://store.steampowered.com/app/2201710/Three_Kingdoms_Zhao_Yun/) | 镜头、主角/士兵/建筑相对比例 |
| [![王者荣耀官方游戏地图](https://www.honorofkings.com/img/map_bigimg3.jpg)](https://www.honorofkings.com/global-en/) | 清晰的地形色面、层次、细节与人物可读性 |
| [![战意 Steam 军阵](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/835570/ss_0ddbbb1bc1a0f5f38ae2a22077330d38040c5611.1920x1080.jpg?t=1726748286)](https://store.steampowered.com/app/835570/Conquerors_Blade/) | 战士站位、甲胄、盾枪、攻城 |
| [![真·三国无双 起源—真实战役画面（巴哈姆特媒体截图）](https://p2.bahamut.com.tw/B/2KU/19/284f82ef3a2bcf60dc0a69b99d1sqhr5.JPG?v=1736406719901)](https://www.koeitecmoamerica.com/games/dynasty-warriors-origins/) | 冲锋、动作重量、成军动势；[截图出处](https://gnn.gamer.com.tw/detail.php?sn=279446) |
| [![全面战争：三国—攻城实际截图（VICE）](https://www.vice.com/wp-content/uploads/sites/2/2019/05/1558614529731-TW33.jpeg)](https://asia.sega.com/totalwar-three-kingdoms/en/) | 军阵与战场地理关系；[截图出处](https://www.vice.com/en/article/three-kingdoms-is-the-best-total-war-game-in-a-decade/) |
| [![帝国时代 IV—中国式攻城实际截图（Steam 扩展）](https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/3746540/f94377217b41d44cebcfe41b7590614771c5ad69/ss_f94377217b41d44cebcfe41b7590614771c5ad69.jpg)](https://www.ageofempires.com/games/age-of-empires-iv/civilizations/chinese/) | 城池、道路、军阵、斜俯视场景；[Steam 图片出处](https://steamdb.info/app/3746540/screenshots/) |
| [![燕云十六声—古代城市实机画面](https://static.deltiasgaming.com/2025/11/3-Where-Winds-Meet_-Official-Gameplay-Trailer-0-0-42.jpeg)](https://store.steampowered.com/app/3564740/Where_Winds_Meet/) | 古代城市与自然景观；[截图出处](https://deltiasgaming.com/where-winds-meet-edition-guide-lite-vs-standard-vs-ultimate/) |
| [![炽焰帝国 II—真实大军战斗画面（历史商店截图）](https://gaming-cdn.com/images/products/5821/screenshot/kingdom-under-fire-2-hero-edition-hero-edition-pc-jogo-steam-wallpaper-1.jpg?v=1712761866)](https://steamdb.info/app/1132210/screenshots/) | 英雄/兵团同时运动；[截图出处](https://www.instant-gaming.com/br/5821-comprar-kingdom-under-fire-2-hero-edition-hero-edition-pc-jogo-steam/) |

## 2. 目标图像：三个镜头都必须像成熟商业游戏

**远景：全面战争式可读军阵 + 国风动画色块。** 512v512 的兵员有真实空间、成阵、旗帜、武器、骑兵和战术地形；一眼区分双方、兵种、朝向和哪处正在接战。宽镜头不要求每个人脸清楚，但绝不允许只是密集同色点、相互重叠成一个黑团。

**中景：战意式实际接触 + 王者级清晰度。** 普通枪兵、盾兵、弓手、骑兵能分清身体、四肢、盔甲分层、武器和动作；站/走/冲/攻/防/伤/撤有不同重心与姿态；密集步兵武器不大量穿模、遮蔽主角；地面不比人物更抢眼。

**近景：真三起源级的动作完成度 + 自己的赛璐璐美术。** 面部基本结构、双手实际抓握、札甲/布衣/皮革/铁器清楚成形；攻击有真实的身体动力链和受击反馈，死亡/倒地与地面接触；主角、将领和普通兵都像同一款精致游戏而非质量断层。

**地图：帝国时代 IV 结构清楚 + 燕云的中国古代氛围。** 当前河关必须完成道路、桥梁、河岸、城门、门楼、城墙内庭、军营、植被、泥土/石头等有功能、有结构、统一材质与光照的真实可玩地图，不是平草地、几块盒子与假树。场景朝唐末五代式架空历史统一，而非机械拼接各时代建筑。

**摄影与 UI：** 正常操作镜头始终优先；不使用电影特写、离线海报或 UI 遮盖问题。操作仍为 WASD、鼠标瞄准和可缩放相机，军令/任务 UI 简明而不压缩战场。

## 3. 严格验收 ARTREF-01—12（缺一不可）

| ID | 实际达成标准 | 必交证据；未满足则不可标完成 |
|---|---|---|
| ARTREF-01 | 正常跟随镜头 + 可操作近/中/远景，人物占屏和场景尺度合理 | 真实 Godot 同场景原始截图及连续实录，不以概念图替代 |
| ARTREF-02 | **敌我普通兵**：枪、盾、弓等至少基础代表，面/手/脚/衣甲/兵器成形，不是棒人/圆柱/积木；可复用 LOD | 每兵种近中景与正常战斗图 + 已导入源资产、骨架、材质 |
| ARTREF-03 | 主角、精锐/先锋、敌我将领有不同身份气质、衣甲等级和动作，不是复制换色 | 同场景多角色截图与游戏输入录屏 |
| ARTREF-04 | 跑/停/转/起手/发力/接触/格挡/受击/倒地有承重和真实接战 | 正常速度带实际命中/碰撞事件的视频，禁止预烘动画冒充 |
| ARTREF-05 | 512v512 普通兵+真实将领/主角有连续身份或按批次守恒；军阵真实占地，兵种/前后排可分 | 宽/中镜头实际运行，移动镜头后其他战斗继续，战果记录守恒。1024 是容量样本而非每战固定人数/必同屏 |
| ARTREF-06 | 河关场景有真实城门/墙/桥/官道/河岸/坡地/树林/营造物和统一光照材质 | 同一地图中近/中/远图，不允许大面积纯色平面、纸片树、悬浮拼装 |
| ARTREF-07 | 国风 3D Cel Shading 清楚，布/甲/木/铁分面，抗锯齿、轮廓和阴影可看；正常镜头不糊 | 原始输出像素 + 内部像素/比例 + 材质 Shader 设置，不得后期滤镜修图冒充 |
| ARTREF-08 | 连续 30–90 秒真实战斗有队伍冲锋、命中、反应、弓兵与至少一种攻防城/骑乘表现，镜头可操作 | 从真实可运行包录制带声正常速度片段，不是宣传 CG |
| ARTREF-09 | 八作各对标维度逐项比较，找出最严重的 3–5 项差距并**实际修改修好** | 参考源 URL + 自己同类实拍 + 对比清单 + 本轮实际模型/动作/环境变化 |
| ARTREF-10 | 素材合法且可维护，角色、装备、地图的源资产和导入流明确；近远 LOD/批渲染不会变画风 | 源资源、文件清单、许可证明或自有创作记录、Godot 资源引用 |
| ARTREF-11 | M5 实机在真实 512v512 高质量交战持续 20 分钟稳定 60 FPS 基线；继续争取 90/120 FPS 与 120Hz | 记录设备、内/外屏实际与内部渲染像素、画质、P50/P95/P99、长帧、内存、热稳态。未实测=DEVICE_NOT_RUN |
| ARTREF-12 | 实际游戏画面达到《王者荣耀》级或更好商业制作完成度，同时具有《乱世》独立的中国古代战场视觉 | 工程与性能独立于 Owner 美术判断。Owner 未亲自认可时只能 ART_REVIEW_REQUIRED，严禁自标“美术达标” |

**自动判退**：只是换颜色/光影/雾/描边/滤镜/增加小零件，底层小人和地图仍粗糙；仅精修主角而普通士兵低质；用 AI 美术效果图替代可玩成品；只与 RC3/RC13 等旧粗糙原型比较就宣称达标；高像素展示实则内部偷偷降采样；减少真实人数或冻结视野外战争；未经许可直接复制任何其他游戏资产、角色设计、动画、商标或场景。

## 4. 给 Codex 的直接执行顺序（P0，不得只写设计）

**S0 研究与差距归档**：每次美术任务先读本文件、视觉重置文件、RC13 真正正常跟随截图 [normal-native.jpg](evidence/river-gate-v1-rc13/normal-native.jpg) 与 [实战报告](evidence/river-gate-v1-rc13/PLAYTEST.md)。从八个真实游戏里选**对应实际问题**的截图/片段，写清楚哪些可以学习，哪些不能照搬，以及当前实机最明显缺失的造型、动作、场景质量。不得再把 RC3/RC13 的旧视觉称为已获 Owner 审美认可。

**S1 原生可玩的视觉母版**：保留已有 Godot 战斗、AI、伤亡/军籍、存档、性能与指挥架构；优先**重建而非修饰**主角、普通枪兵、盾兵、弓兵、双方精锐将领、马，以及河关城门—官道—河岸—树林。真正做出人体比例、手脸、衣甲、装备分件、骨架/运动、材质/贴图、共享资源和 LOD，并接入正常战役。资产美术质量不能以“当前工程原型不支持”为理由停留在棒状几何；允许改造视觉资产流水线，但不推倒已有功能。

**S2 三镜头 A/B**：在相同游戏代码条件、同种子/机位/输入/人数/输出及内部像素下，提交旧/新原始图、近/中/远图和真实交锋录像；在 ARTREF-01…12 下标记结果，逐项复核人物动作与战场的精致度。先修真实问题，不转去调色/截图摆拍凑图。

**S3 推广**：高质量母版在真实 512v512 场上成立后，再把统一风格/骨架/动作/装备扩展到九武器、更多兵种、将领、骑兵、战车、器械及环境，用共享材质/动画等级/实例化控制负载。不得以复制一千个劣质模型冒充规模；也不得以高面数冒充精致程度。

**S4 自主闭环**：实现—本机或可用真实 GUI 运行—截取原始游戏画面—审查商业参考差距—修复—运行性能/回归—提交 GitHub。每个完成的真实切片都进入可试玩候选与可检查证据。Codex 在可用执行周期内继续推进，无须让 Owner 一次次传递下一条指令；若运行结束，及时提交、在 [CODEX_CONTINUATION.md](CODEX_CONTINUATION.md) 交接 SHA、ARTREF 验收、下一步具体改动，供下轮继续。**写文档不会自动启动 Codex 进程**。

## 5. 每次可视质量 PR 的证据要求

在 docs/evidence/<candidate>/ 下附：reference-gap-analysis.md（八游戏对应对标与缺口）、normal-camera-before-after 原始图、close/mid/wide 原始图、combat-normal-speed.mp4（正常可玩交战）、assets-and-licenses.md（真正替换的模型/骨架/材质/动作、来源和导入）、artref-verdict.md（ARTREF-01…12 各项结果与证据链接）。目录是**下次交付要求**，不是已经生成的文件。

合格结论要同时区分 **ENGINEERING_PASS / NOT_RUN、DEVICE_PASS / DEVICE_NOT_RUN、OWNER_ART_APPROVED / ART_REVIEW_REQUIRED**。独立好看的静帧不能代替连贯游戏；原型正常运行不能代替美术合格；云端 M1 测试不能代替实际 M5。若素材、工具或设备不足，可清楚标阻塞与已完成证据，继续做不依赖该条件的任务，禁止伪造通过。

## 6. 当前实际状态（2026-11-14）

最新已核对 GitHub README 的试玩基线为 **河关 RC13**。已提供真实 Godot 截图 [normal-native.jpg](evidence/river-gate-v1-rc13/normal-native.jpg) 和 [RC13 报告](evidence/river-gate-v1-rc13/PLAYTEST.md)：有 512v512 战斗记录和 M1 Virtual 24 秒采样，但**并未完成 Owner 对新的精致美术的验收，也未完成 MacBook Air M5 20 分钟真机实测**。规范已创建 ≠ 视觉达标，初始状态：**ARTREF-01…12 待逐项核实 / OWNER ART_REVIEW_REQUIRED / M5 DEVICE_NOT_RUN**。此最新优先级在 [Codex 总任务 #12](https://github.com/haohongfei2001-png/luanshi-game/issues/12) 下继续执行，覆盖其中“RC3 美术已完成、可转去其他工作”的旧结论。

**一句话验收：远看是清楚有组织的动画式中国古代千人战场；中看是成熟商业游戏质量的士兵、武器和地形；近看是有面孔、双手、衣甲结构与可信动作的真实 3D 人物；三档都必须来自可操作的《乱世》游戏本体。**
