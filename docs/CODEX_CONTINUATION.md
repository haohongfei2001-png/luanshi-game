# 《乱世》Codex 可恢复工程状态｜统一记录

**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务。每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令。正式文学剧情完全留空。不新增费用或远控个人 Mac。

## 当前主线已合入候选 0.16.0-rc.2（2026-11-12，最新）

**当前可玩代码与证据基线：** `7aa2934080e1618ad61e670ec00d40a94714b852`。其后 main 有总指令/续接文档等纯文档提交；Codex 开始下一轮前必须重新 fetch 实际 `origin/main`，不要把此处的快照 SHA 当作最新分支头。河关玩法 PR [#29](https://github.com/haohongfei2001-png/luanshi-game/pull/29) 已于 04:55 UTC 合入，交付证据 PR [#30](https://github.com/haohongfei2001-png/luanshi-game/pull/30) 已于 05:21 UTC 合入。不要重复合并旧 PR #24/#25，也不要从 71889537 旧主线继续覆盖新证据。

| 项目 | 已核实结果 |
| --- | --- |
| VERSION / GAMEPLAY_EVIDENCE_SHA | `0.16.0-rc.2` / `7aa2934080e1618ad61e670ec00d40a94714b852` |
| GAME_CODE_SHA | `71889537db0d74b9cf6f372d50c830e9e5e32278`（#29 玩法合入） |
| EVIDENCE_SHA | `7aa2934080e1618ad61e670ec00d40a94714b852`（#30 归档） |
| CI | [Actions 43157917697](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43157917697)，最终 attempt 2 三个 job 全部成功；attempt 1 的 macOS runtime 曾在第 0 步停住，原因尚未查明，重测成功。 |
| macOS BUILD | [下载 70.2 MB Actions artifact](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43157917697/artifacts/13917576349)，内层 `Luanshi-macOS.zip` SHA-256：`ce539ea4e08477838d24df6d3d437b6057a8fd00ab77361172a07d672ed9c930`。临时签名、**未公证**；artifact 当前到期日 2027-02-10 UTC。 |
| GAMEPLAY | [59.1 秒带声完整旅程](evidence/river-gate-v1-rc2/playthrough.mp4)：军议部署 → 512v512 接战 → 破门 → 内庭占领 → 结算 → 随军行军 → 读档。主角 7 次命中、1 次军令送达，双方普通兵阵亡 257/308，仍有 255/204 存活。 |
| OTHER MODES | 护送冲车成功（守军保城）、成功撤离、主将阵亡后军队继续作战均有实际窗口回归。九种武器的普攻/Q/E/空格与防守/闪避入口均通过；骑马/战车上乘、转向、动作、下乘通过。 |
| SAVE COMPAT | v3 与 RC1 中 v4 旧档由旧版原程序生成后再交新版续演，对照历史字段一致。 |
| CROWD / TRAFFIC | 同种子 A/B 中 soft crowd + traffic lanes：3m 区域峰值 42→19，半米格峰值 7→3，最大同坐标单位 2→1，拥挤邻接对 1897→742，前后队形更展开。此处允许近距离视觉重叠，不追求严格刚体互斥。门前向后折返显著下降，跨门人数持平或增加。详见 `measurements.json` 的 `FIELD_CROWD`、`FIELD_TRAFFIC_AB`。 |
| M1 PERFORMANCE | 托管 Apple M1 Virtual，512v512，720×450 根渲染目标，清晰档巡场 24 秒：平均 121.9 FPS，P50 5.69 ms，P95 21.93 ms，P99 30.29 ms，峰值 RSS 342 MiB。短时虚拟机数据**不代表稳定 60 FPS**。性能档平均 62.3 FPS，但 P95 43.31 ms 且估算内部尺寸仅 504×315，不应作为最终画质档。 |
| M5 / 4K | 真实 MacBook Air M5 内屏和外接 4K 的 ≥20 分钟持续接战：`DEVICE_NOT_TESTED`。不允许从 M1 推算通过。 |
| KNOWN ISSUES | ① 门洞混战中前排遮住玩家起手/武器动作，近战可读性仍需提高；② 密集场景长尾帧，M1 P95/P99 未达到 60 FPS 帧时间标准；③ 首次 macOS 兼容后端启动停在第 0 步，虽同包重测通过但根因未定位；④ 音效辨识度待真人试听；⑤ 主角/敌将一战击败数十普通兵缺少完整连续实录。 |
| NEXT PRIORITY | 从实时 fetch 后的最新 main（当前可玩基线 `7aa2934`）新建短分支，优先解决近战动作可读性（不把士兵隔开、不牺牲密集感），同步 profiling 长帧热点和首次启动停步问题。之后再做 M5 真机 20 分钟 512v512 验收。不要重做已经通过的九武器、骑乘、护送和旧档迁移。 |
| OWNER / SCOPE | 遵守 `PRODUCT_DECISIONS.md §1K/§1L/§1M`：历史战役是可选灵感；战场面积和实际兵力可变；软密度允许少量贴靠/重叠但不能堆成一点。剧情仍由 Owner 写。 |

**下一步可执行入口**：读取 `docs/CODEX_MASTER_EXECUTION_MANDATE_20261112.md` 与本表，从最新 main `7aa2934` 开始。先用 `./tools/test-field-render.sh` 固定同种子、同镜头、同画质，比较门洞近战的起手、盾挡、受击和武器可见性；然后结合 profiler 找出 512v512 密集接战 P95/P99 长帧来源。每个修复都保留真实游戏前后画面、帧时间和回归数据。**不要让 Owner 为下一阶段再传一条小指令。**


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
