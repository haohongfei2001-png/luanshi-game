# 《乱世》Codex 可恢复工程状态｜统一记录

**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务。每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令。正式文学剧情完全留空。不新增费用或远控个人 Mac。

## 当前主线试玩候选 0.16.0-rc.2

| 项目 | 已核实的现场 |
| --- | --- |
| BASE_SHA / BRANCH / NEW_SHA | 从 RC1 `efcd91533e7cd50309375d1ab90138a041e7f674` 接续至 `main` `71889537db0d74b9cf6f372d50c830e9e5e32278`。[实现 #29](https://github.com/haohongfei2001-png/luanshi-game/pull/29) |
| TEST_STATUS / CI_URL | Ubuntu 的完整真实窗口、旧 v3 及 RC1 破门中 v4、九兵器、双边军官、六次托管 Mac 开窗均已通过。首次兼容窗口停在第 0 步，保留了失败和同包重测记录。[主线完整运行](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43157917697) |
| BUILD_URL / GAMEPLAY_EVIDENCE | [macOS 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43157917697/artifacts/13917576349)，内层压缩包 SHA-256 `ce539ea4e08477838d24df6d3d437b6057a8fd00ab77361172a07d672ed9c930`。[连续实录](evidence/river-gate-v1-rc2/playthrough.mp4) · [截图与完整试玩记录](evidence/river-gate-v1-rc2/PLAYTEST.md) |
| PERF_METRICS | Apple M1 (Virtual)，512v512 巡场 24.0 秒，P50 / P95 / P99 为 5.69 / 21.93 / 30.29 ms，峰值 342 MiB。[各规模、画质及原始数据](evidence/river-gate-v1-rc2/measurements.json) |
| 阶段结果 | 避免门前无谓折返。三个种子进门实际跨线人数持平或增加，撞入车体样本均为零。护送成功时遗留的撞门文字已修复。默认、先锋先行两种走法分别复测。[初次失败记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43153519636) · [窗口复测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43155329275) |
| BLOCKERS | M5 Air ≥20 分钟实机接战未测。高密度近身出招可能被前排挡住，狭口吞吐还受到真实交锋影响。 |
| NEXT_COMMAND | 在授权云端从 NEW_SHA 实施下一次视觉比较。从 `./tools/test-field-render.sh` 生成相同近景姿态，检查盾缘、武器交叉与受击轮廓，同时复核帧时间。 |

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
