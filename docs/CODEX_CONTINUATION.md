# 《乱世》Codex 可恢复工程状态｜统一记录

**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务。每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令。正式文学剧情完全留空。不新增费用或远控个人 Mac。

<!-- river-gate-current-review -->
## 河关 0.16.0-rc.5 衣甲与原生清晰度

Owner 退回 RC4 的清晰度、人物质感与装备可辨性。本轮已将短甲枪刀兵、重装裙甲、头盔护耳、软巾弓手和轻兵袍裙接入正式战争；美术为 **ART_REVIEW_REQUIRED**。衣甲采用随动作的连续袖面，重拍了相同种子和同一机位的七组 1600×1000 PNG。当前版本为原生 4× MSAA，并提供全尺寸单采样档。 [原始军容](evidence/river-gate-v1-rc5/fitting/officer.png) · [同像素并排](evidence/river-gate-v1-rc5/fitting/officer-native-pair.png) · [正常指挥距离](evidence/river-gate-v1-rc5/fitting/formation.png)

代码已推到 [PR #34](https://github.com/haohongfei2001-png/luanshi-game/pull/34)，源码 `d16244aa1a7b360516d1a7819174a4ab741a007a`，本轮全包验证 [run 43300526960](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43300526960)。首次全量任务在工程导入阶段误把旧版证据目录的动图当作游戏纹理，已用 Godot 的目录排除标记修好，原录像保留。美术复核与 M5 真机均待验证。

继续命令为 `gh run view 43300526960 -R haohongfei2001-png/luanshi-game`。通过后归档 macOS 安装包摘要、1920×1200 PNG、实战录像、四规模战斗、九次空数据 macOS 启动与单采样对照。
<!-- /river-gate-current-review -->

## 上一份可回退候选 0.16.0-rc.4

主线的游戏代码仍为 RC3。RC4 的完整游戏来自开放的 PR #34。美术状态为 **ART_REVIEW_REQUIRED**。常用俯斜游玩视角参考第二张美术方向稿，角色近景用于检查动作与材质。当前优先继续提升正常战斗视角的人物与环境，RC3 的阶段排程留作历史记录。 [实机连续片段](evidence/river-gate-v1-rc4/battlefield-motion.mp4) · [实际游玩流程](evidence/river-gate-v1-rc4/playthrough.mp4) · [配对实机画面](evidence/river-gate-v1-rc4/before-after.mp4) · [美术方向稿](art-direction/river-gate/battle-view.png)

本候选的游戏源码为 `2293008c2d76dcbd788aeaef0fb871de1bc8eee1`，CI 实际导出的提交为 `eabe0b211892064b2dce9270d72468cfcff3c412`。从 Actions 归档解出 `Luanshi-macOS.zip` 后，内层 ZIP 的 SHA-256 应为 `c560adb20aad487ef89aad77c23b531948c828d9d108c13fac5704293cc8249a`。 [源码](https://github.com/haohongfei2001-png/luanshi-game/commit/2293008c2d76dcbd788aeaef0fb871de1bc8eee1) · [游戏 PR](https://github.com/haohongfei2001-png/luanshi-game/pull/34) · [macOS 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43288570098/artifacts/13975154019) · [五项 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43288570098)

角色按行进距离播放八向步态，双脚连续接地，转身时胸、肩与衣摆保留跟随。加入实机衣料、三种面部、持械行军姿势、战马鞍具、军营、柳岸和湿土。 草根、压实车道和湿砂随旧田、道路和河岸分布。关楼的木、石、瓦已在正式包窗口复查。 [两次托管 Mac 包窗口](evidence/river-gate-v1-rc4/native-gate-pair.jpg) 十四组前后对照在同一时刻与机位采集，两军各 512 人，另计玩家和军官。隔离测试中 16 组方向步态最大承重鞋底漂移从 79.1 毫米降至 0.77 毫米。 [动作对照](evidence/river-gate-v1-rc4/footwork-pair.mp4) · [分项量测](evidence/river-gate-v1-rc4/raw/motion-sampling.json)

军议、部署、实战、战报、驻营和读档继续均已在正式入口重放。九武器、骑马及战车、护送、军令、救援和继任都有实测。原始 RC3 破门档从第 629 步推进至第 746 步，逐字段差异 0。 [流程与原始日志](evidence/river-gate-v1-rc4/PLAYTEST.md)

在 Apple M1 (Virtual) 托管宿主，默认清晰档、阴影开启且内部缩放 1，实绘 1024×640，24 秒千人实战平均 99.5 FPS，P50/P95/P99 分别为 6.87 / 24.39 / 38.78 毫秒，峰值 RSS 505 MiB。托管环境已记录八次空游戏数据进程启动，保留系统图形缓存。真实 MacBook Air M5 为 **NOT_RUN**。 [全兵力分档、逐帧记录和冷启动](evidence/river-gate-v1-rc4/measurements.json)

本轮可回退的人物与柳岸版本为 `d2f0180c0865b3746bef11e43a2239659188fa6f`。 [该阶段 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43275529020) · [该阶段 macOS 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43275529020/artifacts/13970062784)

在有图形显示器的 Linux 云端和 Godot 4.6.3 上，先取回精确版本，再复现相同的镜头和实测。

```sh
git fetch origin codex/river-gate-rc4
git switch --detach 2293008c2d76dcbd788aeaef0fb871de1bc8eee1
./tools/prepare-font.sh
./tools/compare-river-art.sh
./tools/test-field-render.sh
```

托管 Mac 本次 2,388 个渲染帧中，358 帧超过 16.67 毫秒，最长 185.12 毫秒。首次 Metal 首帧耗时 47.67 秒，八次新进程均进入交战。 [分段时序](evidence/river-gate-v1-rc4/raw/renderer-comparison.json)

下一项以正常战斗镜头查正面持械的手、兵刃接触和密集门洞中识别主角的速度，保留相同种子、兵力和画质做对照。继续拆分近景蒙皮与阴影的绘制成本，核对多个相同摄像位置的 P95、P99 和命中结果。


## 上一版可回退候选 0.16.0-rc.3

游戏源码 `799e1e41a098bf534b63f699ea6f683e4707306f` 已合入 main 并完成主线五项 CI。可回退游戏基线为 RC2 `71889537db0d74b9cf6f372d50c830e9e5e32278`。[游戏 PR #31](https://github.com/haohongfei2001-png/luanshi-game/pull/31) · [主线构建](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43245656470) · [macOS 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43245656470/artifacts/13956928552) · [验收、录像及原始数据](evidence/river-gate-v1-rc3/PLAYTEST.md)

- 正式战役使用原创衣甲、脸手、九武器、16 骨骼姿势、马具、牵引车和河关地景。十二组同机位实战保留相同画内士兵、命中、伤亡与地形目标。近、中、远景军容与中景阴影合批已进游戏。
- 主角、双方 512 名普通兵与 32 名军官贯穿部署、战斗、战报、行军、存读档。原始 RC2 破门档从 629 步推进到 746 步，逐字段差异为零。九武器、两种载具、军官救援与继任均有独立回归。
- `Apple M1 (Virtual)` 默认清晰档实绘 1024×640，巡场 24.0 秒，P50/P95/P99 为 6.02 / 17.59 / 29.13 ms。八次新游戏数据进程启动均留存时间线。真实 M5 为 **NOT_RUN**。
- 首轮重模后软件渲染的第二场护送超时。已缩减中景几何、降低近兵投影成本并按斜视锥剔除屏外提交，完整回归已通过。软件渲染高速横移仍有长帧。自动跟随俯角在 11 对同景画面中改善中位数为零，4 对变差，保留手动镜头。 [首次失败](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43224638297) · [遮挡对照](https://github.com/haohongfei2001-png/luanshi-game/blob/072ebed4f53bee02c990f9f948ec5f9bafbf25e3/docs/evidence/river-gate-camera-lab/READBACK.md)

**续接入口**　在云端工作树执行 `git fetch origin main`，从最新 `origin/main` 建立独立分支，运行 `./tools/compare-river-art.sh` 重放十二个机位。若继续压低镜头横移长帧，运行 `godot --path . --resolution 1280x800 --disable-vsync --audio-driver Dummy --script tests/company_render_cost.gd -- --field-size=512`。兵员、装备和士气的后续迁移按 PRODUCT_DECISIONS §1P 与 SIMULATION_CONTRACTS §9H，保留旧档结算和当前实战影像作为基准。

**下一阶段优先顺序（RC3 已交付视觉纵切片后更新）**
1. **P0：实现普通兵 Cohort 数量模型（Owner §1P）**。当前产品决策已经明确：普通士兵不需要永久个人 ID、个人士气/伤势/武器持有者记录。按兵种/装备/训练/编制批次维护可战、伤兵、无武器、疲劳、逃散、被俘、阵亡数量及武器库存；不同分队可有不同共享士气/命令。近景临时 Actor 负责实际动作、命中、倒地和死亡表现，事件结算回批次数量；离开近景可回收。只有主角、具名角色和重要将领保留个人档案。先检查当前 `battle.gd`、`officer_corps.gd`、`field_objectives.gd`、存档格式，提出最小迁移方案并保留 RC2/RC3 旧档兼容。
2. **P1：落实士气与战斗强迫性及四种军事结果**。按 §1N/§9F：全歼、溃逃（追击/停止追击）、有序战略撤退、投降；保留目标完成。主帅阵亡不能自动胜利/溃败，首府威望与副将继任应影响战斗强迫性。士气/强迫性优先军队/分队共享，不逐兵算心理。结算分别记录阵亡、伤兵、逃散、被俘、投降、撤出、存活和装备数量。
3. **P2：战斗画面剩余问题**。在不拉散军阵的前提下改善门洞近战武器动作可读性；完善九武器以外兵种/服饰变化和受击/倒地/死亡表现。RC3 已交付的资产和动画必须保留，不重复做完整美术纵切片。
4. **P3：性能与规模扩展**。RC3 默认清晰档 M1 Virtual 512v512、1024×640、24 秒平均 128.2 FPS，但 P95 17.59 ms、P99 29.13 ms；先降低长尾，再做 1k/3k/5k/10k cohort 压测。不能只用模拟人数或远景假人宣称万人完成。
5. **P4：M5 真机**。MacBook Air M5 内屏与外接 4K 各至少 20 分钟真实 512v512 战斗，未实测保持 NOT_RUN。

**验收原则**：普通兵按批次/编制数量记账，重要人物按个人记账；临时小人是群体数据的可视化和近景交战执行体，不是永久 NPC 档案。人数/装备守恒、存档迁移、旧档续演、镜头离开再返回、伤亡和战报均需回归。具体见 `SIMULATION_CONTRACTS.md §9H`、`ACCEPTANCE_MATRIX.md §7F-I`。此节覆盖下方 RC2 历史记录中的旧优先级排序；RC2 仅作为回退基线，不是当前开发起点。


## 上一候选 0.16.0-rc.2（2026-11-12，回退基线）

**可玩代码/证据基线**：`7aa2934080e1618ad61e670ec00d40a94714b852`；其后 main 可能有文档更新，Codex 每次启动都必须 fetch 实时 `origin/main`。PR #29 玩法、PR #30 证据已合并，不得重复开发/合并。

### 已交付且应保留
- 战前部署、双方 512 名普通兵、32 名军官、玩家角色；同一入口完成战斗、胜利/撤退/主将阵亡结算、随军行军与存读档。
- 九武器实际输入回归、骑马/战车上乘/转向/攻击/下乘、号角/军令、冲车护送、软密度与交通车道改进、旧档 v3/v4 兼容。
- 59 秒完整战役录像、原始截图、测量和 macOS 候选包。M1 Virtual 512v512 清晰档 24 秒巡场平均 121.9 FPS，但 P95 21.93 ms、P99 30.29 ms；M5 真机仍未测。

### 视觉质量问题已升级为当前 P0（先美术基础，后零碎优化）
当时对 RC2 的代码与资产审计发现：
- `scripts/field/figures.gd` 用基础 rod/block/loft 程序几何构造角色；
- `scripts/field/figure.gdshader` 通过顶点变形表达多种动作；
- `scripts/field/landscape.gd` 通过程序化几何构造地面、河流、城门、营寨、植被和冲车；
- 资源树几乎没有成体系的真实 3D 角色/环境模型、材质贴图、骨骼与可复用动画资产（当前正式 assets 主要是字体，其他图片多数是验收截图/录像）。
因此当前粗糙感是**核心资产和美术基础问题**，不是只调整光照或修复一处遮挡即可解决。

新权威目标：[VISUAL_QUALITY_TARGET_V1.md](VISUAL_QUALITY_TARGET_V1.md)，主执行顺序已改为视觉纵切片 P0：
1. 直接接入正式游戏做高品质视觉纵切片：玩家主角、普通步兵、弓弩手、精锐/叫阵小将、马匹、至少三类武器真实握持与动作、河关地形/城门/植被。
2. 在正常游戏镜头/常用缩放下达到“克制写实的小模型、真实材质、服装/脸/手/甲胄/武器可辨”的质量；不要玩具感、卡通、奇幻夸张重甲。
3. 建立合法原创或可再分发资产流水线，优先真实模型/材质/骨骼动作；近/中/远 LOD 与 MultiMesh 批量渲染保持大军性能。
4. 真实 Godot 战斗录像和相同镜头升级前后图通过自审后，再扩展至全部兵种/武器/环境。
5. 不需要 Owner 对普通美术细节逐项审批；不要用概念图/Blender 静态渲染替代正式游戏实际资产。

### Owner 最新补充 §1P：普通兵伤病、缴械、俘虏也按批次数量记录

普通士兵不仅共享攻防和士气，**伤兵、无武器、被俘、逃散、阵亡以及装备损失也默认按 cohort/分队数量聚合**。例如 80 可战、12 伤兵、5 无武器、3 逃散、2 被俘；只记录这些数量与装备库存，不需要记录哪个普通兵受伤/拿哪把刀/被俘，也不需要永久普通兵 ID 清单。

近景可临时生成 SoldierActor 表现挥砍、受击、倒地和死亡；结算后更新 cohort 分类人数和库存，Actor 可回收/重建。远景/屏外直接按批次统计模拟。只有玩家、具名角色、主帅/主将/副将、先锋/叫阵骁将等重要人物保留独立个人档案。实现与验收见 SIMULATION_CONTRACTS.md §9H 和 ACCEPTANCE_MATRIX.md §7F-I。确保人数/装备守恒，不把不同兵种和分队混成一个总数字。

### 新增 Owner 计算架构决定（§1O）：批次/编队共享普通兵属性

- 普通士兵无需逐人保存独立攻击/防御/士气/强迫性。同兵种、训练、装备批次共享静态模板；小队/连队/军队共享士气、强迫性、阵型、命令、目标等动态状态。
- 个体仍有唯一 ID、位置、动作/目标和伤亡/俘虏/逃散/装备等确有差异的数据。个别伤病/缴获/特殊事件用稀疏覆盖值。
- 近景士兵仍逐个真实行动和受击，不能合并成虚假人数。重要将领/玩家可独立属性。
- 实施合同 `SIMULATION_CONTRACTS.md §9G`；验收 `ACCEPTANCE_MATRIX.md §7F-H`。视觉 P0 继续推进；士气/强迫性逻辑实现时优先采用聚合状态，避免每兵心理 AI。

### 新增 Owner 战斗胜负决定（§1N，2026-11-12）

完整规则：[BATTLE_MORALE_COMBAT_COMMITMENT_AND_OUTCOMES_V1.md](BATTLE_MORALE_COMBAT_COMMITMENT_AND_OUTCOMES_V1.md)；验收：[ACCEPTANCE_MATRIX.md §7F-G](ACCEPTANCE_MATRIX.md)；Simulation contract §9F。

- 战役结束可以是全歼、溃败逃散（战后玩家选追击/停止）、有序战略撤退、投降；原有占点/护送/守城/救援等任务结果保留，敌方有大量幸存者仍可判任务成功。
- 两个独立指标：**士气**影响战斗力/阵型/命令服从/忠诚倾向；**战斗强迫性**由首府/政权威望、合法性、军纪、使命、指挥链/副将继任、退路/投降条件形成，决定低士气时仍会否守阵/服从/继续抵抗/有序撤退。它不是攻击力加成。
- 主帅阵亡不自动胜利/溃败：高首府威望+合法继任者可稳定军心；无继任、权威弱、原本军心低且被包围则可能逃散/投降。
- 当前代码已有士兵归一化士气、局部 ROUT、目标层崩溃计数和军官继任；尚缺独立强迫性、主帅自主逃跑/投降、有序战略撤退及溃逃追击选择。Codex 应审查 `battle.gd`/`field_objectives.gd`/`officer_corps.gd` 后增量开发，避免重复造轮子。
- 视觉纵切片仍是当前 P0；[PR #31 RC3](https://github.com/haohongfei2001-png/luanshi-game/pull/31) 已合入原创角色、兵器、马匹与场景资产。不要因新规则中断视觉主线；视觉基础稳定后，士气/强迫性/结局系统是下一重要玩法阶段。若并行，必须文件隔离。
- 玩家只做简单追击/停止选择，不做逐兵微操；普通兵轻量 FSM，后台聚合计算，剧情继续留空。

### 新增 Owner 数据粒度决定（§1O，2026-11-12）

权威：`PRODUCT_DECISIONS.md §1O`；完整设计：`BATTLE_MORALE_COMBAT_COMMITMENT_AND_OUTCOMES_V1.md §3.3`；Simulation contract §9G；验收 BF-DATA-01..10（`ACCEPTANCE_MATRIX.md §7F-H`）。

- 普通士兵不逐人存储独立攻击、防御、护甲和士气。同兵种/装备/训练批次引用共享 `CombatProfile`，复用基础攻防、护甲、武器性能、移动速度和最大生命。
- 军队共享基础士气、战斗强迫性、首府威望、军纪、使命、整体补给/指挥权威；Company/Detachment 共享动态士气、凝聚力、疲劳、局部伤亡比例、命令与接敌压力。整军士气由分队聚合。
- 单兵保留 ID/位置/朝向/动作/必要 HP 与伤势、生死/俘虏/逃散、确实不同装备/弹药；不复制静态攻防/护甲/最大生命。共享 profile 不等于共享血条。
- 当前 `battle.gd` 已确认 `Unit.morale` 逐兵随机初始化、受击逐兵扣减，护甲也重复保存；攻击招式主要来自共享 Arms.Move。后续在视觉 P0 后增量迁移士气至分队，建立共享 profile，保持旧档兼容和真实单兵伤亡。
- 不强制 ECS；按 Godot profiling 选共享资源/引用、紧凑数组或批次结构。普通兵保持轻量 AI，玩家不管理这些数据。

### 之后的质量顺序
1. **P0 视觉纵切片和美术资产基础**（最高优先级）。
2. 近战可读性：前排遮挡主角起手/武器动作，在不拉散密集军阵、不取消合理重叠的前提下解决。
3. profiling 密集交战长帧，保持真实兵员/伤亡/命令和 M5 目标。
4. 首次 macOS 兼容后端停在 tick 0 的根因与冷启动稳定性。
5. 双方强将/目标型胜负等确实未完成的系统缺口。
6. 对升级后的资产与战斗进行 M5 Air 内屏及外接 4K 各 ≥20 分钟实机验证；未实测保持 `M5_DEVICE_PENDING`。

**执行约束**：不要重新实现九武器、骑马/战车、护送、行军或旧存档。不要为了“先解决视觉”而重做引擎/停止一切代码；采用纵切片逐步替换关键近景资产，再扩展。历史战役是可选灵感，剧情仍由 Owner 创作。Codex 持续执行，不要求 Owner 每个阶段再发一条指令。

## 回退候选 0.16.0-rc.1

| 事项 | 现场 |
| --- | --- |
| BASE_SHA / BRANCH / NEW_SHA | `edc89fcf949774daf890d248dbfae07eef711583` → `main` `efcd91533e7cd50309375d1ab90138a041e7f674`。[#27](https://github.com/haohongfei2001-png/luanshi-game/pull/27) 已合并。可回退到 [#26 完整验证](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43119189602)。 |
| TEST_STATUS / CI_URL | 下拉菜单实操与护送分支回归已通过。主线 Linux 实际键鼠旅程、旧存档、双边军官、九兵器、导出启动、托管 macOS 原生六次开窗均通过。[独立主线构建](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43147112051) |
| BUILD_URL / GAMEPLAY_EVIDENCE | [下载 macOS](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43147112051/artifacts/13912902186)。内层 `Luanshi-macOS.zip` SHA-256 `0abed710f526225276d0f1565df183f80d319b794044302153a5eea25567d610`。[连续实录](evidence/river-gate-v1-rc1/playthrough.mp4) · [截图、安装与验收](evidence/river-gate-v1-rc1/PLAYTEST.md) |
| 战役 | 窗口操作第 1065 步夺取内庭，英雄命中 7 次，战后行军再读档成功。护送第 724 步交车，守军保城。平陵巡防 27 对 14，撤离者与后卫按实际军籍结算。 |
| PERF_METRICS | 512v512、托管 Apple M2 Pro（虚拟机）清晰档 24.0 秒巡场，267.7 FPS，P95 11.26 / P99 14.45 ms。X11 软件渲染样本 11.1 FPS。[原始四档与六场 Mac 测量](evidence/river-gate-v1-rc1/measurements.json) |
| BLOCKERS | 真实 M5 Air 内屏及外接 4K 的 ≥20 分钟千人交战 `DEVICE_NOT_TESTED`。门洞排队、近景多人叠影以及长尾帧仍有改善空间。 |
| NEXT_COMMAND | 在云端从本表 NEW_SHA 建独立分支。`godot --headless --path . --script tests/field_traffic.gd` 重放同种子门洞基准，比较破门后六秒通行人数、狭口密度和伤亡。随后 `./tools/test-field-render.sh` 复核真实画面。 |

## 上一阶段集成与回退

| 项目 | 可复核的记录 |
| --- | --- |
| 已入主线 | `edc89fcf949774daf890d248dbfae07eef711583` 整合 #10、#17、#18、#23、#24、#25 与 #22 的早期实录。该 SHA 的 [Linux、导出包和原生 macOS 全套 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43119189602) 已通过，可回退。 |
| 候选 | [#27](https://github.com/haohongfei2001-png/luanshi-game/pull/27)，分支 `codex/river-gate-command-and-objectives`。攻门、护送、平陵巡防、营地与旧三城在同一游戏可达。普通兵、双方军官、接任者和俘虏均按已有身份结算。 |
| 实战 | `c60efd5a` 的真实 X11 玩法在第 1115 步完成内庭占领，玩家命中 6 次，存读恢复战后行军。护送第 724 步交车但不占城。该运行仍因巡防下拉框键盘导航而红灯。[云端记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43121977670)。 |
| 狭口与平地 | 实际 512v512 的同种子分流录像、近远景帧时间、CPU 与密度记录保存在[早期对照](evidence/river-gate-formation-traffic/soft-density/)。另有 641 对 389 名普通兵的战中存读与持续命中。 |
| 军官与巡防 | [军官真实交手及救离](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43119954664)；[巡防真实 3 小时行军、军籍及错误存档 F9 回归](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43122705272)。 |
| 历史兼容 | `tools/test-field-history.sh` 用 #24 的原版 Godot 脚本另进程产生 v3 存档，再由新程序继续，对照所有历史字段和原版自然结束时刻。 |
| 九兵器与真旧档 | [同树云端独立校验](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43123489510)已记录九种兵器的鼠标命中、Q/E/空格和防守或闪避。#24 原版在第 161 步保存，第 235 步自然结束，新程序续演所得历史字段全部相同。 |
| 当前验证 | 先读取 #27 的最新 SHA 和检查。云端依次运行 `./tools/test.sh`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh`、`./tools/export.sh`。合并后查 main 对应的独立构建、校验值及托管 Metal 原生窗口。 |
| 设备门槛 | 真实 M5 Air 内屏、外接 4K 的 20 分钟持续帧率为 `DEVICE_NOT_TESTED`。 |
