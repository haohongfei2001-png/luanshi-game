# 《乱世》Codex 可恢复工程状态｜统一记录

**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务。每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令。正式文学剧情完全留空。不新增费用或远控个人 Mac。

## 当前主线已合入候选 0.16.0-rc.2（2026-11-12，当前可玩基线）

**可玩代码/证据基线**：`7aa2934080e1618ad61e670ec00d40a94714b852`；其后 main 可能有文档更新，Codex 每次启动都必须 fetch 实时 `origin/main`。PR #29 玩法、PR #30 证据已合并，不得重复开发/合并。

### 已交付且应保留
- 战前部署、双方 512 名普通兵、32 名军官、玩家角色；同一入口完成战斗、胜利/撤退/主将阵亡结算、随军行军与存读档。
- 九武器实际输入回归、骑马/战车上乘/转向/攻击/下乘、号角/军令、冲车护送、软密度与交通车道改进、旧档 v3/v4 兼容。
- 59 秒完整战役录像、原始截图、测量和 macOS 候选包。M1 Virtual 512v512 清晰档 24 秒巡场平均 121.9 FPS，但 P95 21.93 ms、P99 30.29 ms；M5 真机仍未测。

### 视觉质量问题已升级为当前 P0（先美术基础，后零碎优化）
代码结构审计（实时 main）发现：
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

### 新增 Owner 战斗胜负决定（§1N，2026-11-12）

完整规则：[BATTLE_MORALE_COMBAT_COMMITMENT_AND_OUTCOMES_V1.md](BATTLE_MORALE_COMBAT_COMMITMENT_AND_OUTCOMES_V1.md)；验收：[ACCEPTANCE_MATRIX.md §7F-G](ACCEPTANCE_MATRIX.md)；Simulation contract §9F。

- 战役结束可以是全歼、溃败逃散（战后玩家选追击/停止）、有序战略撤退、投降；原有占点/护送/守城/救援等任务结果保留，敌方有大量幸存者仍可判任务成功。
- 两个独立指标：**士气**影响战斗力/阵型/命令服从/忠诚倾向；**战斗强迫性**由首府/政权威望、合法性、军纪、使命、指挥链/副将继任、退路/投降条件形成，决定低士气时仍会否守阵/服从/继续抵抗/有序撤退。它不是攻击力加成。
- 主帅阵亡不自动胜利/溃败：高首府威望+合法继任者可稳定军心；无继任、权威弱、原本军心低且被包围则可能逃散/投降。
- 当前代码已有士兵归一化士气、局部 ROUT、目标层崩溃计数和军官继任；尚缺独立强迫性、主帅自主逃跑/投降、有序战略撤退及溃逃追击选择。Codex 应审查 `battle.gd`/`field_objectives.gd`/`officer_corps.gd` 后增量开发，避免重复造轮子。
- 视觉纵切片仍是当前 P0；[PR #31 RC3](https://github.com/haohongfei2001-png/luanshi-game/pull/31) 正在整合原创角色/兵器/马匹/场景资产。不要因新规则中断视觉主线；视觉基础稳定后，士气/强迫性/结局系统是下一重要玩法阶段。若并行，必须文件隔离。
- 玩家只做简单追击/停止选择，不做逐兵微操；普通兵轻量 FSM，后台聚合计算，剧情继续留空。

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
