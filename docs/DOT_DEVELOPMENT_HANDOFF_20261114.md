# Dot 开发交接与 Codex 暂停记录

记录时间为 2026-11-14 12:58 UTC，即北京时间 20:58。

## Owner 最新决定

Owner 要求“暂停开发，转交给 dot 开发，进行收尾”。此决定覆盖此前 Codex 连续自主开发和自动续接要求。Codex 持久 Goal 已返回 PAUSED，automation-2 已返回 PAUSED。定时任务提示已写入本次暂停和 Dot 交接决定，重新启动须有 Owner 明确授权。子代理已停止。现存测试运行列于下文，接手时重新读取最终状态。

当前工具没有可确认的 Dot 消息会话。交接通过本文件、CODEX_CONTINUATION.md、AUTONOMOUS_DEV_STATE.md 和 Issue #12 发布。此记录不能代表 Dot 已收到或已经开始开发。

## 源码现场

| 内容 | 精确位置 | 收尾时状态 |
|---|---|---|
| main 起点 | 844f83191daf8223464a35711e5a428d09e5d92f | 本次交接文档基于它追加 |
| RC25 完整候选 | codex/river-whole-rebuild，d1c1895221c33386d471922807ed590a6987dbe1 | 草稿 PR #59，完整原生马与正式回归修复已集成，正式 CI 未全过 |
| 新整片环境源码 | codex/river-biome-rebuild，f480f11506032ca9020db0781b7a9d211a5d17fd | RC25 的独立后续环境重建 |
| 新环境烘焙 | 5babe5c1983952c1f44b7776d254155858417740 | 完整原作者柳树、枫树、宽冠栎树与草丛 |
| 新环境实机静帧 | 814417f12092d95d0086d59b5e90ce8db00964cb | 同种子正常镜头 2K/4K 已生成，暂停前尚未自审新图，输入影片仍在录制 |
| 双手枪实验 | codex/river-rc25-native-spear，7aaf21be288a607132ec96e1c9a1f5cdbf2f16f3 | 已推送，实验尚未达到可集成条件 |
| 双手枪产品烘焙 | 9b2dce04f0fd97af3e337692b0be6253ff6fe716 | 完整作者枪链和局部密钥加密度，尚有入步问题 |
| 已跑完的 RC24 | 4f3c0819cf44a89c24bd825c90f241d8974fbbb6 | 同源 macOS 包、影片、两后端与冷启动可回退基线 |

[PR #59](https://github.com/haohongfei2001-png/luanshi-game/pull/59) 保持 Draft。旧 PR #18、#22、#23、#24、#25、#33、#53～#58 存在重叠内容，接手须比较实际差异。全部本轮源码通过 GitHub 保存，根代理及人物子代理均没有本机未提交文件。人物子代理提到的一份图集高度检查构想仅在会话中，未进入仓库。

环境和原生交付 workflow 会把生成的资源或证据推送回各自分支。上述 SHA 为固定恢复点，接手须等待相应运行结束再读取分支最新 head，避免覆盖其提交。

## 当前真正完成的工程范围

RC25 包含完整城防、桥梁、河床、城壕、营地、合法原始网格和材质，保留既有战斗、军令、世界、伤亡结算、旧档和行军。地面剑/刀普攻整合完整作者 ready→过顶斩→ready 链，原技能时序和其他动作保留。

完整马匹整合原作者 51 关节蒙皮、鬃尾、walk/trot、统一比例与真实鞍位曲线。GPU 鞍具与骑手读取相同曲线，战车轮轴保留。原始动作和派生资源使用 CC BY-SA 3.0，包内保留来源、许可与哈希。固定 512v512 的 32 个连续步骤前后模拟序列一致，正常 22 米和近景画面已检查。完整主角任意瞄准方向、地面接触和大范围骑乘画面仍需扩大审核。

环境后续分支替换整个树木库与林地构图，重做埋入式河岸石群、浅地表起伏、林缘和城外聚落深度。它保留 native willow/maple/oak 的全部原始三角形、UV 和对应贴图，并按原图集区分树皮与叶面。它还改变地形/植被材质及环境布局。最新静帧和影片需要 Dot 自审后再判断是否保留。

整体美术仍为 **ART_REBUILD_REQUIRED / OWNER_REJECTED**。Owner 批准的效果图是最低质量线。RC24 已观察到岸石规则排列、柳树发白、重复树冠、远景空旷、尸体堆叠和部分僵硬动作。新环境实验尚未经过视觉自审。真实 M5 为 **DEVICE_NOT_RUN**。

## 暂停时的 CI 与具体失败

### RC25 正式 PR 验证

[运行 43595547108](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43595547108) 使用合并测试 SHA 0532c0a94dacc8797d2f11671f22ba62fcad5d9b，候选 head 为 d1c1895221c33386d471922807ed590a6987dbe1。

- 基础 verify-and-export job132449130733 已成功。正常渲染场景、世界军队、存档、包导出和固定目标查询对照均通过。
- 512v512 与 2500v2500 的旧战斗字段逐字节一致，新增 terrain_revision 元数据显式独立记录。512 每方 canonical hash 为 e9fb94604eddfb5041f80d148bb430d2de0e331f8c6e2dcb8cdde7d6c9a43567。新旧完整快照 hash 不同，差异记录保留在目标对照输出。
- footage job132453651327 失败。llvmpipe 1280×800 的 100v100 在约 19.76 秒只有 9 个采样帧，42 次采样期间命中。断言报 Sampled moving, damaging combat frames，exit1。20v20 有13帧。需接手诊断采样条件和软件渲染成本，保留失败记录。
- escort job132453651347 在约100秒后 exit124，尚未定位具体超时层。不要把 RC24 护送通过结果当本轮正式用例通过。
- Linux 正常输入、macOS runtime、完整 journey 和美术前后对照仍运行中。

[footage 失败 artifact14114872816](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43595547108/artifacts/14114872816) 和 [escort 失败 artifact14114857789](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43595547108/artifacts/14114857789) 均已归档。

### 其余在途运行

- [RC25 同源 macOS 交付 43595539334](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43595539334) 的 export 已通过，native job132451160692 正在完整 QHD 运行。最终结果和新马匹性能未确认。证据回写 codex/river-whole-native-evidence。
- [完整环境实验 43596936650](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43596936650) 已生成并提交静帧、通过导入/地形旧档/桥头测试，job132453341234 正在原速输入录像。证据位于新环境分支的 docs/evidence/river-whole-rebuild/review，影片和原始记录在运行 artifact。
- [双手枪实拍 43596250213](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43596250213) 成功结束，当前无人物线运行任务。未启动 737 重拍及盾链。

Codex 暂停后没有触发新开发或新测试。上述既有运行允许完成其归档，运行状态以 GitHub 接手时显示为准。

## 双手枪的未通过项与净文件

固定 548 号枪兵近景被树冠遮挡，完整发力链验证不足。入攻击左踝单步位移从0.320m增至0.382m。回收接行进改善至0.049m，帧间腕缝从29.7mm降至0.565mm。这些局部结果不足以接纳整套动作。

其余412条动作带逐像素保持，新增密钥约149KiB未压缩图集。GPU 每骨骼采样次数保持4。若未来采纳，需要更新 check_native_chain.py 的 RC24 固定图集高度假定，同时保留旧动作像素一致检查。下一项原计划是 737 号实际枪兵110～132步同源完整重拍与入步检查。

待评估产品文件为

```text
assets/river_gate/figures/company_motion.png
assets/river_gate/figures/WILDFIRE_PIKE_NOTICE.txt
scripts/field/company_skin.gdshader
tools/art/company_motion.py
tools/art/import_wildfire_pike.py
tools/art/source/wildfire_pike_curves.json
tools/art/check_field_carries.py
tools/art/check_native_pike.py
```

先读该分支 docs/evidence/river-gate-v1-rc25/native-spear/draft/ 下的 chain-check.json、actual-ankles.json、verification.json。

## 可用的 RC24 包、影片与实测数据

完整验证来源为 [运行 43587113557](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43587113557)，export/native 均成功。功能覆盖正常军议输入、九武器、骑乘、战车、军令/军官、护送、严格 v3/v4 恢复与战后继续行军。正式 PR 的另一轮验证43587148752失败，具体历史记录保存在候选分支 CODEX_CONTINUATION.md。

[artifact14111959283](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43587113557/artifacts/14111959283) 包含真实测试的 arm64 包、完整115秒影片、原始性能数据与许可。安装包为 adhoc 签名验证通过、未公证。

- 测试包 SHA-256 为 b6b44df6c19c1b74efd22a66bd761df770a1110bf123dcd813adcbd1089e0910。
- artifact ZIP SHA-256 为 a00e224e3b7709d01af7b55088ceebbf0b8f87d57d2f88305b21374dbe1d614e。
- 影片 SHA-256 为 14e4615dbdf45a68a9288b9f46810c625ff73c804a3f4e619314ca1b190bcaa9。
- 影片为原生2560×1440、内部1.0、4×MSAA、115秒/2760帧/24fps，111秒自然守城成功，之后72个结果画面帧。24fps是影片采样率。整个连续影片尚未完成人工完整播放审核，已检查抽帧与连续动作片。
- 证据提交 d5877f0c3187d2eefc2efd44a25b4bc148a111b7，路径 docs/evidence/river-whole-rebuild/native/4f3c0819cf44a89c24bd825c90f241d8974fbbb6/。movie/parts 含12个数据包一致分段。
- 两种后端的初始化样本通过，另9次冷用户数据启动通过。驱动缓存保留，冷启动窗口1000×600。
- 引擎为固定 Godot4.6.3 源码35e80b3a8822a9df9be390814b62f44c0a9c69e8加上游PR123312修复及静态ANGLE7578。完整构建脚本、补丁和许可保留。实际M5未运行。

托管 Apple M1 Virtual，Metal Mobile，原生2K、内部1.0、4×MSAA的实时数据如下。

| 每方普通兵 | 采样秒 | 平均FPS | P50毫秒 | P95毫秒 | P99毫秒 |
|---|---|---|---|---|---|
|20|29.05|52.97|18.295|25.124|30.812|
|100|29.75|41.21|23.360|36.563|47.606|
|250|44.72|34.70|28.729|44.181|56.005|
|512|44.52|27.47|34.986|60.954|78.508|
|512巡游|44.46|42.04|20.006|53.396|78.916|

512固定镜头RSS约589MiB，峰值约1664MiB。60FPS目标未达到，真实M5未测试。

## Dot 接手入口

先同步当前 GitHub 和在途运行的最终状态，再比较上述候选与实验。恢复点的获取命令为

```sh
git fetch origin main codex/river-whole-rebuild codex/river-biome-rebuild codex/river-rc25-native-spear
gh run view 43595547108 --repo haohongfei2001-png/luanshi-game
gh run view 43595539334 --repo haohongfei2001-png/luanshi-game
gh run view 43596936650 --repo haohongfei2001-png/luanshi-game
git diff d1c1895221c33386d471922807ed590a6987dbe1..origin/codex/river-biome-rebuild --stat
```

所有运行命令在已有授权云端使用。既有权限未增加新费用、额外账号、用户电脑访问或正式发行权限。原产品、史料、玩法与存档规范保留。画面标准继续以 Owner 参考最低线和真实 Godot 正常游玩镜头为依据。新环境实验先看实际2K/4K静帧与原速输入片，枪链先解决可见性和入步问题，RC25先诊断正式失败，再由 Dot 自主决定后续集成。
