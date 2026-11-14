# 《乱世》｜成熟资产优先：高强度学习 → 真实高品质底座 → 再精修原创（OWNER-ASSET-FIRST-20261114）

## OWNER-AUTONOMOUS-20261114｜资产先行必须转化为真正持续的开发产物

[长期自主开发与跨会话续接执行协议](CODEX_AUTONOMOUS_DEVELOPMENT_PROTOCOL_20261114.md) 现在与本文件共同约束 Codex：不能停留在付费候选资产研究、无限评分和整理引用。必须用已合法取得的专业/CC0/原创资源实际构建 Blender/GLB/Godot 导入、近中远人物和动作、河关游戏内真实视觉母版，做同条件录屏/测试/提交；付费资源未授权时绕过并推进可独立完成部分，保留 ARTREF 与设备未验收状态。每个会话持续选择下一条高价值切片、发布 GitHub 真实增量，并尝试在可用 Codex Automations 中设置可验证的定时续接。


> **最新 Owner 视觉制作方法；执行优先级高于此前“用程序化基础网格不断小修”的习惯。** Codex 应以可合法利用、可实际导入 Godot 的成熟高品质模型、骨架、衣甲、动画、建筑和环境为生产起点，学习商业游戏中可迁移的镜头、构图、模型制作、动画、材质和信息可读性。**优先做出真实可玩的高品质游戏，再进行符合《乱世》时代与玩法的个性化精修、创新。**
>
> 这不是批准复制商业游戏的角色或提取其内部资产，也不是允许购买付费素材。请同时遵循 [八款商业游戏参考及 ARTREF-01～12](ART_REFERENCE_GAMES_AND_VISUAL_ACCEPTANCE_20261114.md)、[已获认可的国风 3D 动画式画风](ART_DIRECTION_CEL_SHADED_BATTLEFIELD_20261113.md) 和 [不再迭代粗糙外观的要求](VISUAL_RESET_AND_REJECTION_GATES_20261113.md)。规范已发布不代表游戏已做成。

## 一、对目前工程的实际判断

2026-11-14 读取 GitHub main 发现：
- scripts/field/figures.gd 使用 Builder.rod/block/loft/quad 拼装肢体、衣甲、头脸；scripts/field/presentation.gd 通过 CompanyArt.fighter + MultiMesh 分组呈现士兵。
- scripts/field/landscape.gd 用 Builder 制作部分城墙、地形、营帐；已有 river_ram.gltf、原创地面材质和 Poly Haven CC0 纹理。
- **这些是可保留的战斗/渲染工程设施，不是已经合格的美术资产。** 再反复改几何参数、颜色、光照、阴影、雾、轮廓和少量配件，不应被当作通往商业级美术的主路线。

新执行原则：**真实成熟资产作为近景/中景的可编辑质量底座；原程序化几何只用于逻辑、碰撞、占位和经实测视觉质量足够的远景优化。** 不必为换美术资产推倒伤亡、军令、存档、军团模拟和现有场景。

## 二、增加三个有针对性的真实游戏参考

它们只提供质量/设计参考而不提供可使用的游戏资产：

| 实际作品 | 分项学习目标 | 不应做什么 |
|---|---|---|
| [《烽沙 / Mandate Order》Steam](https://store.steampowered.com/app/1733690/Mandate_Order/) | 中国古代兵阵、千人军团、木栅/寨墙、投石/床弩、实际斜俯视攻城。这是战役结构**非常贴近《乱世》**的补充 | 不复制其兵种造型、关卡、代码或 UI，也不默认其美术水准就是最终上限 |
| [《帝国神话 / Myth of Empires》Steam](https://store.steampowered.com/app/1371580/) | 中国古代士兵、骑乘、军需、战场营造、城池与真实材质层次 | 不照搬第三人称镜头和照片式高频噪点 |
| [《The Valiant》Steam](https://store.steampowered.com/app/959860/) | 斜俯视小人物的占屏比例、兵团接触、地形分区、任务 UI 的信息层次 | 不使用欧洲盔甲/建筑设计替代唐末五代文化 |

## 三、可以合法取得后用于实际制作的现成资产候选

这些不是“可从网页直接盗用”的素材，**未购买、未取得许可、未实际导入**。商品描述是初筛，Codex 必须对每个候选核实价款/许可、可交付格式、真实游戏内质量、Rig/动画、LOD、性能和历史匹配。按优先级只试少量主资产，拒绝堆素材库。

| 优先 | 具体可访问候选 | 实际资源价值 | 关键限制 |
|---|---|---|---|
| P0 唐代甲士母版 | [Realistic Tang Dynasty Armored Warrior · Fab](https://www.fab.com/listings/c95fa2a9-c8a6-4bb8-bb83-525236f949a4) | 商品列出唐式盔甲、完整身体和表情骨骼、FBX + Blender、可动画；优先尝试为敌我普通兵与主将的高质量结构基础 | 未取得文件/许可；须核实甲衣可拆、骨架、实际精细度与 Godot GLB 导入 |
| P0 模块化兵装备选 | [Chinese Warrior · Fab](https://www.fab.com/listings/aa8154f7-a4bb-4696-8b9b-40a3b1e34fd7) | 标注主要参考唐式甲士，衣服/盔甲可组合、枪刀剑、多种盔甲色，模块化高质量模型 | **页面只有 Unreal Engine 格式**。先确认合法的 FBX/glTF 源文件可得性和可移植性；不应盲买 |
| P0 军营建筑 | [Three Kingdoms Military Camp · Unity Asset Store](https://assetstore.unity.com/packages/3d/environments/historic/three-kingdoms-military-camp-397822) | 军帐、中军帐、木制望楼、营寨门、鹿角、军旗、岩石/地面；页面描述 14 Mesh / 18 Prefab、PBR | Unity URP/ShaderGraph 不直接成为 Godot 材质，需合法导出网格/纹理并重建赛璐璐色阶 |
| P1 中国城镇模块 | [STYLIZED Far East Kingdom · Unity Asset Store](https://assetstore.unity.com/packages/3d/environments/historic/stylized-far-east-kingdom-269978) | 城门、城墙、建筑、街道、港口、植被等成套模块，适合提高场景制作速度 | 偏奇幻、饱和度高，部分建筑/装饰不符合唐末；要统一调整而不是一键照搬 |
| P1 低成本结构备选 | [Modular Ancient Chinese City Pack · Unity Asset Store](https://assetstore.unity.com/packages/3d/environments/modular-ancient-chinese-city-pack-186607) | 26 建筑、6 地面、6 道具预制体、30 网格，适合研究中国城门与城墙拼装 | 精细度参差不齐；不适合不经审查直接当质量母版 |
| P1 马匹动作试验 | [Animated Horse · Fab](https://www.fab.com/listings/2182ce90-52db-470c-9987-671112831f3c) | GLB/FBX，约 10,393 三角形、1 材质、30 个骑乘/移动/受击动作，可验证 Godot 骨骼/骑乘/LOD 流水线 | 页面标记 AI-generated；仅为候选，须检查实际动物形体和动作，不得自称美术达标 |
| P0 免费合法材质 | [Poly Haven CC0](https://polyhaven.com/license) | 土、石、木、岩石、植被、HDRI 基础，现有河关已经依法使用其中部分扫描材质 | 不是高品质角色；要重新整合材质分面避免照片纹理过度复杂 |
| P1 基础动作 | [Adobe Mixamo](https://www.mixamo.com/) / [Adobe 官方 FAQ](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400) | 角色骨骼绑定、走、跑、基本受击等动画试用流水线 | 普通动作不能冒充中国古代枪、盾、弓、骑兵的完整真实战斗动作；原始素材不得独立再分销 |

**不能只因为原素材单独渲染得好看就认为 Godot 内呈现同样好。** 在 Godot 真正的正常操作镜头、赛璐璐材质、真实动作和军阵中验收，失败则淘汰候选。

## 四、不可忽略的授权与公共 GitHub 问题

GitHub 仓库当前为 **public**。购买 Fab/Unity 标准商业许可常允许将资产集成入游戏及合理改造，但**通常不授权把付费原始 FBX/GLB/贴图/动作文件作为源码公开再分发**。参考：[Fab Standard License](https://www.fab.com/eula?lang=en)、[Unity Asset Store EULA](https://unity.com/legal/as-terms)、[Unity 官方跨引擎许可说明](https://learn.unity.com/pathway/creative-core/unit/introduction-to-creative-core/tutorial/copyright-for-creators?version=2021.3)。

- 公开 GitHub 只放**原创、CC0 或明确允许源码再分发**的资源，以及代码、许可和来源清单、转制脚本、指向商品的链接。
- 商用付费的受限原始模型只能在**私有资源库/受限构建阶段**保存；正式包按授权嵌入游戏；不得把带原始素材的公开 GitHub Action Artifact/LFS 当成私库。
- Unity/Unreal 专属 Shader、蓝图或工程不是通用 Godot 资产；需导出合法源网格/纹理并重建材质、碰撞、骨骼映射。Godot [官方首选 glTF 2.0 / GLB](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)。
- 如果商品写 NoAI 或另有特殊许可，须遵守相应限制，未经授权不得把商业素材喂入外部生成式模型或训练系统。
- 不得从商业游戏解包、提取、复制模型/地图/动画；参考可以学习通用造型规律、可读性、操作镜头、品质工艺，不复制独创角色和场景。
- **没有额外开支授权**，Codex 不得自动购买、建立付费账号或使用盗版；无许可的候选只能研究页面和公开样图。

## 五、强制改变 Codex 的工作顺序

**Gate A｜先筛成熟资产。** 对上表按 *真实外观 35% / 唐末国风可协调性 20% / Godot 可移植性 20% / 兵种骨骼扩展性 15% / 授权及成本 10%* 评分。任何缺少实物或可检验许可者标 UNVERIFIED / NOT_ACQUIRED，不能虚构得分。每类只选 1–2 个有希望的母版，不无限找素材。

**Gate B｜再做真正的导入验证。** 对合法可用的角色+一个场景模块用 Blender→GLB→Godot，真实检查网格/蒙皮/骨骼/动作/手握点/法线/贴图/碰撞/材质/抗锯齿。建立能复现的资源导入流水线。不得用现有 rods/blocks 充数或拿商店图片当实际导入证据。未购入付费角色时可用 CC0 素材验证**管线**，但绝不能声称角色美术达标。

**Gate C｜先高保真实现成熟基底。** 不要先追求原创炫技。尽量保留有许可的高质量几何、服饰装配、绑定和动作结构，把模型和动画真正接入现有 scripts/field/presentation.gd 与战斗逻辑。然后把颜色、光照、甲胄形制、布料、盾枪兵种、军旗和历史身份转成《乱世》自己的国风 3D 动画色块体系。**普通兵质量不能明显低于主角。**

**Gate D｜在正式河关场景做一段真实可玩的高品质纵切片。** 主角 + 双方枪兵/盾兵/弓兵 + 一名将领 + 城门/河岸/营地，正常 WASD/鼠标输入、交锋、命中/受击/撤退、镜头拉近拉远。提供真实原始截图及正常速度视频，不接受脱离游戏的离线精修作品替代。

**Gate E｜512v512 与 M5 验证。** 从小队到 100v100、250v250、512v512，按近中远不同等级用 LOD、合理材质复用、GPU 实例、动画分级等优化。不应把一个 50k 三角形、全骨骼的角色原样复制 1024 份，也不应把所有人简化为棒人。近景保证动作真实，中远景保持人体/兵种/方向与阵型可读。M5 20 分钟、60 FPS 基线，90/120FPS 研发目标，输出实际内外屏分辨率、内部像素、P50/P95/P99 和热稳态；未跑如实 NOT_RUN。

**Gate F｜最后精修和创新。** 当真实可玩的纵切片在近中远三档都形成成熟商业游戏的视觉基础，才批量拓展九武器、双方兵团、军阶、地区、器械、独特建筑，逐步原创美术语言。不要拿小修或模型数量代替品质。只有 Owner 看见真正的 Godot 正常游戏视频并接受，才可记 OWNER_ART_APPROVED。

## 六、每次必须给出的真实交付

在 GitHub 建立可追踪的资产筛选表（来源、许可、格式、费用/是否已获得、Godot 导入结果、正常镜头评分、风险），和可复现的资源流水线。每个新候选都提交真实 Godot 截图、带输入的正常速度交战录像、近/中/远图、旧新 A/B、修改了哪些原资产/Shader/动作、可复现构建和 ARTREF-01～12 判定。每轮完成提交代码并更新 docs/CODEX_CONTINUATION.md，未完成精确标明阻塞和下一件可独立完成的事。

当前状态：**已具备基础工程 + 外部资产候选清单；尚未买任何付费资产、未实际验证上述来源在 Godot 中的画面，也未获得 Owner 新美术验收；不能宣称完成。** 保留已有战斗和存档功能，别用无休止的设计报告取代真正提升游戏画面。

**目标：尽可能直接利用合法成熟资产所包含的专业设计价值，在真正可操作的《乱世》里先做到高品质，再逐步构建独特、统一、有历史质感的原创世界。**
