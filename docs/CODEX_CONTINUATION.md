# 《乱世》Codex 可恢复工程状态｜统一记录

## 2026-11-14 当前 P0 · 完整战场与人物重建

整体美术继续标记 **ART_REBUILD_REQUIRED / OWNER_REJECTED**。参考图是最低门槛。当前地表、树冠、人物动作、尸体持械和整体构图仍需重建。开发、烘焙、导出与图形运行均在托管环境进行。真实 M5 为 **DEVICE_NOT_RUN**。

- 活跃分支为 `codex/river-whole-rebuild`，继承既有玩法、世界和严格存档回归。完整人体/军服母版 bb0729、原生剑刀枪、完整城防/营地、木桥、扫描自然资产已集成。
- 最新已审核整图提交 `7d901d4ceccfd9453aeb4f955fd9e1852e2a8001`，run43573261325，原生2K/4K、内部1.0、seed61112、512+512、22米/yaw-33。同景存在稀碎树冠和平坦地表，整体继续判退。已修正正交相机距离导致的树冠LOD选择，门楼按8米实际通道收窄并恢复分片遮挡。
- 只保留全部叶片使单树达到109万三角形，实际画面收益不足。原始资产审计确认44168个完整小叶，叶片中位跨度5.3厘米。当前重建改为保留间隔完整叶、保持原轮廓/UV与枝干接点，放大到适合正常游戏镜头的叶片体量。地表接入匹配扫描法线、碎石层与分区批量草石，水流也重做。此改动等待新的真实运行审核。
- 独立动作线为 `codex/river-rc23-authored-combat`。第二版真实普通刀兵617走近/攻击/恢复对照已保存于 `ef6d27ac40e51cdadbb25e993e1906b0742238f9`。主线尚未集成。正在隔离骑乘原条带并修复倒地手部轴导致刀枪竖起。此前新马动作因1.53–3.34米/秒支撑蹄滑移判退。
- 成功原生完整包与连续战斗影片的固定源为 `5d6aa17716d0b7206a10288405957b13e4764357`，run43570498673。完整模拟回归、九武器、军官/继任、军令、旧档与战后行军通过。严格v3/v4逐字段比较保留。该包早于本次树冠和地表重建，后续完整候选仍待重新导出。
- 同源原生影片41.041667秒、985帧、24fps、2560×1440、内部1.0，使用正常菜单/WASD/鼠标/J/Q/E/Space和军令输入。主角实际命中，双军交战，8次盾牌接触，未踏入深水。影片录至40秒战斗，战役结算尚未进入片尾。所有985帧保留。完整179MB影片在artifact14104662482，可直接观看的四段在证据提交 `e2e48d531ee9c85131706c27828a3682d7cdc30b` 的同源 `movie/parts`。逐视频数据包SHA256完全相同，未重编码、降分辨率或改变速度。
- 同源独立实时样本为Apple M1 Virtual、3核7GB、macOS26.7.2、Metal Mobile、2K内部1.0、4×MSAA，44.55秒1375帧。平均30.8637FPS，P50/P95/P99为32.318/49.427/63.177毫秒，最大148.821毫秒，RSS561.14MiB，峰值内存占用1498.44MiB。**低于60FPS目标**。GPU时间戳不可用，不能据此断言GPU瓶颈。原始逐帧数据在证据分支同源profile-qhd。
- 同包9次冷数据启动通过，其中6次自然Metal启动与3次刻意首步前焦点中断，首帧7.39–9.04秒。窗口1000×600，系统驱动缓存保留。不能据此宣称2K/4K冷启动或真实M5通过。
- 实际运行的arm64包SHA256为 `fbc7564d36afb8cb57ac03ce53812ddadce2c0212c352b8eaf9d5c88de003c24`。使用Godot4.6.3上游PR123312隔离锁修复，源码35e80b3，二进制a15d4f69。包内含MIT、补丁与出处，adhoc签名验证通过，未公证。完整包、片和日志均在run43570498673 artifact14104662482。
- Goal为active。automation-2已配置上海10点/22点，独立计划触发仍未证实。

下一轮获取本分支最新head，先看whole-rebuild工作流的新地表/树冠/河流正常游戏画面，逐一审查近中远和4K。继续判退薄弱资产。人类动作确认后再合入明确的模型/动作文件，随后使用whole-world-delivery导出同源完整包、固定镜头原速片和独立实时样本。正常运行入口为 `godot --path . -- --whole-battle-review --native-qhd`。廉价输入校验为 `godot --headless --path . --script tests/whole_input_calibration.gd`。不要复制任何未验证目标为通过。

## OWNER-AUTONOMOUS-20261114｜自动续接入口（真实进展仍以本文件最新 commit 为准）

所有后续 Codex 执行窗口遵循 [长期自主开发与自动续接协议](CODEX_AUTONOMOUS_DEVELOPMENT_PROTOCOL_20261114.md)。**已授权持续开发、常规修复/测试、现有规则允许的 PR/合并与内部可玩候选交付，无需 Owner 每步中转**。应优先完成真实高质量角色/环境/战斗，而不是无限方案或对旧粗糙图做小修；每轮留真实 SHA、截图、录像、运行结果、当前 ARTREF 与真实 M5 状态、下一轮第一件工作。尝试 Codex Goal/Automations 跨会话续接；未实际启动则标记 AUTOMATION_UNAVAILABLE，不得假称 Codex 正在后台运行。当前此节仅新增执行约束，不宣称 Codex 已安装资源、跑出新美术、测试通过或真正设置定时工作。


## 河关 RC22 · 桥头攻门

[1600 × 1000 等速原声回放](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/c6fc9d564244eaca4c9c40ba9b3bf3a7e207312d/docs/evidence/river-gate-v1-rc22/bridgehead/river-gate-bridgehead.mp4) · [托管 Mac 系统窗口原片](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/fd411e7e6e1209d5d3b1ea84e05005771735e35e/docs/evidence/river-gate-v1-rc22/native-bridgehead/hosted-bridgehead.mp4) · [可试玩的 macOS 包](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/9ed812d8dd8036ea92d54c3f77a17e58b771e22c/candidate/River-Gate-RC22-macOS.zip) · [逐项测量](evidence/river-gate-v1-rc22/PLAYTEST.md)。游戏与画面固定于 `dc9805fd2930344be9737cfc19074442618d7e5c`，PR #56 目前 `48ace1db4ee1d807de28b67eba9cd4c546c67053`，后一个提交只调整头像验收位置。桥头 22 米同机位的 Mac 全军样本 P95 为 30.663 毫秒。首次默认 Metal 在首帧前卡住。代码栈、失败样本、其余原生次数和逐帧间隔均已保留。M5 尚未测试。

正式 CI 七项中六项通过。导出、同镜头 15 个画面对照、九兵器、战前到战后、护送和正式 Linux 包系统键鼠均完成。macOS 冷启动一项失败，游戏 PR 保持开放。[七项实测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43538171412) · [Linux 导出包 40 秒原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43538171412/artifacts/14092435981)

下一项具体工作是用第 135 步的真实碰撞重放观察骑兵肩部与前后排长枪交叠，再比较保持桥宽、在编兵力和交战结果可追溯的两种骑兵出口路线。先运行 `godot --headless --path . --script tests/field_bridgehead_outcome.gd`，同镜头原片与输入见上述链接。第二台托管 Mac 同样在第一次默认 Metal 启动时超时，两批各八项启动通过。另行实测 Metal 预烘焙，工程资源导入完成，14 分钟内未完成 PCK 打包，冷启动收益未知。[对照运行](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43538470616)。

军议的「全军 → 桥头攻门」使用完整两军，把先锋部署在外壕桥头，守军守在门前。7.4 米宽的桥面、桥外水域、绕行、冲车与援队使用同一套地形规则。木桥的绑扎木架、城楼和岗楼、衣甲、马、柳树均有可再分发的来源和包内署名。盾兵新增左右承击，持械步态和种子 61112 的实机回放可回看。[盾牌承击原片](https://github.com/haohongfei2001-png/luanshi-game/tree/bff9e6be588f16c086e7dffc6856a678ef767cb9/docs/evidence/river-gate-v1-rc22/shield-brace) · [持械步态原片](https://github.com/haohongfei2001-png/luanshi-game/tree/703ce4e31b82c2ee130631d324cd6387fac280ae/docs/evidence/river-gate-v1-rc21/loaded-advance)

首轮桥头部署中，先过桥的主角在第 71 步阵亡，渡过桥面的后队仅两人。调整为两支在编先锋先据东岸，西岸纵队再跟进，保留原有兵力、伤害、箭矢和永久伤亡。在军议即可选择、交战、存档和重新部署，同镜头原速片与本版本原生包仍以对应证据为准。

固定窗口第一跑确认城门和桥心同屏，但主角直接沿路心冲入射界，在第 128 步阵亡。复看实机后给桥两侧补了小片水边莎草，收暗木板湿端，在同一镜头保留主角足边的两段识别线。压力测试还覆盖桥头横阵、疏列与纵队的换位。原速采集改用现有长枪进步刺，随先锋过桥，从桥的一侧交手后退到同伴身后。常规兵力、战斗伤害和敌方决策维持原规则。[原始失败窗口](https://github.com/haohongfei2001-png/luanshi-game/tree/b8dd831a1506277702eabeee83a1703fd4624732/docs/evidence/river-gate-v1-rc22/bridge-scout) · [同种子 21 条进退路线实测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43531597957)

门已被攻破的回放另外暴露了一个问题。五分钟后双方仍在整队，内庭有 64 名守军、没有攻方，军报却一直不出。桥头各队现在回本部一侧就近整队。内庭仍有守军、无人进攻、主角未逼近且没有军令在途，连续五十秒停止交战后可以判定守城成功。新回放在第 112 秒结算，阵亡 316 / 292 名普通兵。战后军籍、读档、驻营与行军已核对。复现用 `godot --headless --path . --script tests/field_bridgehead_outcome.gd`。[未结算的原始日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43533921991) · [修复后同种子实测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43534219405)

复现渡桥和读档：`godot --headless --path . --script tests/field_bridgehead.gd`。录制步骤使用 `tests/bridgehead_window.gd` 的常规键鼠入口，22 米，默认画质，固定 61112。真实 M5 尚未测试。

## 河关 RC21 · 守军院落和城墙

RC20 代码 `126091196db530aa7ec13de61f839c9c41cac24b`。新版本从相同战斗的四个机位检查城池。两侧城墙从地基、墙身接到城墙上的木质通道，四座角楼使用同一套屋脊和角柱。原先四个同款房屋分为临门的营舍、靠粮道的库房。战役视线遮挡时可独立打开各自屋面。第一轮原地摆放使列队的守军站进屋内，最终版将建筑移至城墙内缘。行动逻辑、驻军位置、路线和旧存档格式继承 RC20。完整验收以本版导出包为准。[正反四个真实镜头与退回记录](https://github.com/haohongfei2001-png/luanshi-game/blob/0437ebc6891399d34fd23423bcb509de64046540/docs/evidence/river-gate-v1-rc21/fort-corners/REVIEW.md)

复现 `godot --headless --path . --script tests/model_library_parity.gd`，随后在 1920 × 1200 的图形窗口运行 `godot --path . --resolution 1920x1200 --fixed-fps 20 --script tests/fort_corner_window.gd -- --field-size=512`。原片与步时保留在上述固定提交。美术和真实 M5 20 分钟验收仍待完成。


### 已归档的 RC20 默认原生包

托管 M1 的默认 Metal 千人战斗实测 109.40 FPS，P50 / P95 / P99 6.979 / 20.806 / 30.303 毫秒，峰值 RSS 493 MiB。9 项原生启动及焦点测试有 8 项通过；刻意切窗的兼容后端未收到失焦，正式 CI 6/7。托管 M1 默认 Metal 两次进入战斗；冷启动首帧分别用了 54.82 和 10.19 秒。旧档、军令、九兵器、坐骑、攻城、回营和后续行军均可回看。[下载经过校验的 RC20](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/66c8172d8f5a616e525ecaa090c71b2e54a96869/candidate/River-Gate-RC20-macOS.zip) · [完整原片、数据和失败现场](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/PLAYTEST.md)

## 河关 RC20 · 过河军阵实机

RC19 建筑、衣甲、倒地动作与存档在此基础上保留。过桥时可辨老柳向水探出的枝干和桥面留白；四个 1920 × 1200 实机机位与 RC19 同种子、同一批士兵，进度、伤亡相同。前几版整株过亮、露枝和方向遮挡的缺点已保留。[桥上军阵的完整对照](https://github.com/haohongfei2001-png/luanshi-game/tree/aeb09e7a3f9f7ecc12c7997ba238e4fc11cb0232/docs/evidence/river-gate-v1-rc20/ford-willows)

普通弓弩手戴软帻，枪刀手用有翻边的浅铁盔，重装有护颊和护颈，军官用低束缨。底下的头脸、既有握点、士兵编队和发号逻辑沿用原件。第一轮发现一顶盔的三角面前后重叠产生黑块；下一轮又发现头盔上沿缺片，第三次才选取完整帽胎并检查两军同一击。[四类兵员正反面实拍](https://github.com/haohongfei2001-png/luanshi-game/tree/3a43d35148eb3c026faeca8c2262ca7d2a8a6fa7/docs/evidence/river-gate-v1-rc20/headwear)

军服染料单独用同一输入对照；靛与茜现在集中在接近手臂和肩的布面，甲片、手与主角披肩保留自己的明暗。[同击、两军及衣袖的原窗](https://github.com/haohongfei2001-png/luanshi-game/tree/c65a580a95ebf32ea933de1c4c6081ea485c779d/docs/evidence/river-gate-v1-rc20/dyed-company)

两个托管 Mac 的 RC19 第一次 Metal 启动都在第一帧前超过期限。场景几何已齐，88 个进程栈样本全在 Godot 等待正向移动渲染材质的着色器编译。新分支在创建地形与兵员之前设置已保存的抗锯齿和分辨率；首次绘制前后记录各类管线编译，并可直接采样等待中的原生进程。保持正常游玩画质、原来的启动时限及显式恢复按钮。是否改善以正式导出包上连续冷启动的记录为准。[同包复现与原始调用栈](https://github.com/haohongfei2001-png/luanshi-game/tree/2db3813aaf94f27cb28dc67af96d76b8a49640d8/docs/evidence/river-gate-v1-rc19/startup/same-package-fresh-host)

完整复拍用 `./tools/compare-river-art.sh`。单独复查桥头用 `xvfb-run -a -s '-screen 0 1920x1200x24' godot --resolution 1920x1200 --disable-vsync --fixed-fps 20 --script tests/ford_willow_view.gd -- --field-size=512`，随后检查 `artifacts/river-art/views.json`。

## 河关 RC19 · 可回退的实机基线

RC19 源码 `8ba9daec9b1dbed8717ecef5cfd15ac2e35e0566`、Git 树 `a34d6e66c2caf2da27109d99b1724bf4328ffca7`、macOS 导出 `9357483bc54c28e0c5d3c04b42dbe5c7e41b4bfd`。完整军议、进军、攻城、结算、回营、旧存档和九种武器通过。59.2 秒全流程片和 40 秒导出包键鼠实录均附原声。[可直接下载的 Mac 应用](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/2db3813aaf94f27cb28dc67af96d76b8a49640d8/candidate/River-Gate-RC19-macOS.zip) · [原始图、逐帧样本、复测和校验](https://github.com/haohongfei2001-png/luanshi-game/blob/3735816ace0a861b8e23619f0a320e76f7ec79b3/docs/evidence/river-gate-v1-rc19/PLAYTEST.md)

托管 M1 的默认窗口实测 1024 × 640、100% 内部比例与 4× MSAA，P50/P95/P99 为 8.804/25.616/35.72 毫秒。首次 Metal 启动在场景就绪后到首帧之间超时，两个独立宿主复现，初次全套 8/9，第二台同包 2/3。第二台采到全部 88 个主线程样本等待 Godot 的材质编译；物理 M5 性能尚未验证。[首帧前原始栈](https://github.com/haohongfei2001-png/luanshi-game/blob/2db3813aaf94f27cb28dc67af96d76b8a49640d8/docs/evidence/river-gate-v1-rc19/startup/same-package-fresh-host/default-metal-1-before-frame.sample.txt) · [RC19 全部 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43510132831)

## 河关 RC19 · 军士衣身、守关望楼和行军地面

两军共用经过裁剪及重新蒙皮的衣甲。腰、股、肩、肘各带动不同衣片，骑行和持弓用原有手部握点。第一个版本的裙摆在迈步时被单侧腿硬拉，第二次在 22 米整窗、反打与等速行进中对照了两名普通士兵。[军士原窗与等速录像](https://github.com/haohongfei2001-png/luanshi-game/tree/910aa1eb35eed00c17b585df3eec1cb96949b23a/docs/evidence/river-gate-v1-rc19/fitted-infantry)

攻门录像中死亡动作结束后，有士兵一只靴尖还高出地面 61 厘米。九类装备重做倒地收势，脚踝高度回到 8.0 / 8.7 厘米，战斗判定相同。弓手、普通兵原速交战保留，地面接触阴影按身体落点收长。[同一名弩手与九类动作实测](https://github.com/haohongfei2001-png/luanshi-game/tree/2e909df4d715db8c47913565f44c21e0942cc61d/docs/evidence/river-gate-v1-rc19/fitted-infantry/ground-rest)

河关门楼由 Wildfire Games 的建筑母版按现有八米门洞适配。近镜沿实际屋脊切开挡住玩家的半片，远镜保留两座望楼。第一版瓦面发黑、路面泛黄；第二版校正了几何绕序和土色，第三版修掉屋面斜刺，重新铺设门前驿道残石并处理树冠明暗。六处机位以种子 61112、双方各 512 名普通兵在同一步比较，入镜士兵清单和命中数均一致。[六处前后原窗](https://github.com/haohongfei2001-png/luanshi-game/tree/82ee4e3752d705f9a2aa52a4c36f57bde1c115d8/docs/evidence/river-gate-v1-rc19/watchhall) · [第三次门厅与树冠实机运行](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43508615220)

回退到 RC18 可直接取托管设备实际运行的通用包。[RC18 应用 ZIP](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/43557e3cf888a347e171a4715e4ce0fb741ebb90/candidate/River-Gate-RC18-macOS.zip) · [RC18 原始数据与首次录像超时的复测](https://github.com/haohongfei2001-png/luanshi-game/blob/233927d31835bddc96cb42e1fddea3dc50af77d9/docs/evidence/river-gate-v1-rc18/PLAYTEST.md) · [RC17 全部实测](https://github.com/haohongfei2001-png/luanshi-game/blob/d19653cf6bb9099aa6cee0b7b22e0c8de6383810/docs/evidence/river-gate-v1-rc17/PLAYTEST.md)

在保有完整 Git 历史的 Linux 图形工作环境依次执行 `./tools/prepare-font.sh`、`godot --headless --editor --path . --import`、`./tools/compare-river-art.sh`。单跑攻门机位用 `xvfb-run -a -s '-screen 0 1920x1200x24' godot --resolution 1920x1200 --disable-vsync --fixed-fps 20 --script tests/watchhall_view.gd -- --field-size=512`。实际 M5 长测和最终画面验收仍在等待。


## 河关 RC18 · 正常战场距离的衣甲、中央路面行进

保留 RC17 游戏 `280ee8d92e04c5b9394093143f36ea273a611935`。新军服按跨肩衣片和实际缝线染色，近处的肤色、皮革和铁甲独立。固定种子 61112 在 22 米逐对比较同一次命中、两军正面阵线、反方向 180° 阵线。实录第 43 步起枪、第 48 步命中，#584 生命 62→39.76；正光和反向都复核过，两次退回过橙衣肩。采用第三次的绛色外衣，保留弓手暗色交领。[正常镜头的三个原窗](https://github.com/haohongfei2001-png/luanshi-game/tree/fe30b4c5e18cbebda7bee9f0885dc25730196da7/docs/evidence/river-gate-v1-rc17/field-livery) · [染布改动](https://github.com/haohongfei2001-png/luanshi-game/commit/5cab87bc4595e42ae82bbb308b0cf57f06a76902)。

普通兵在中央平坦地带行进时可跳过两个坡高的计算；原高度、兵力、跑速与伤亡相同。Linux 同机交替运行每方 512 和 2500 人，逐点 243122 次速度相等，实战第 140 步存档摘要逐字节一致。在 512v512 每组 400 个完整模拟步，P95 由 16.121 降到 15.748 毫秒；GPU 和实机帧时间另测。[保留全部原始耗时](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43494790061/artifacts/14072086144)

上一候选 [RC17 的程序、原生包、四规模、完整录像和首启](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43493877091)；前版 [RC16 的首次停步与可回退包](https://github.com/haohongfei2001-png/luanshi-game/blob/be32d2d765a3bb05b2b2d918c9602d9bd29ffc29/docs/evidence/river-gate-v1-rc16/PLAYTEST.md)。统一版本从仓库运行 `./tools/prepare-font.sh`、`godot --headless --editor --import`、`./tools/compare-river-art.sh` 和 `./tools/export.sh`。下一项是验证默认跟随下两军染布、整战役回营与该包的原生 Metal 记录。美术和 M5 实机性能均仍待验收。

## 河关 RC17 · 实战人物、坐骑与首次启动

承接 RC16 源 `7c9ac667ded0a8e80a05cd47593a4af70c28486c`。该版首次 Metal 启动有一次在进入场景前停住，保留原始包和失败采样。原包中 82 个主线程采样都在销毁临时绘制节点时等待着色器编译。新游戏从打包场景直接读取军士、马、柳树与阔叶树的网格资源。对每个目录逐资源与 Godot 原实例核对；相同源文件必须得到同一资源。[RC16 失败现场](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43491339985) · [独立托管 Mac 冷启动](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43491973680)

弓手、双方军士、玩家和军官共用重取的 HM08 脸部外皮，保留头型、耳部与眉眼。第一版去掉了斑点但眼窝也变平；第二版已在 #94、#1044、#1056 的原窗校准。战马来自可再分发的原骑兵表面和四种毛色，马鞍、缰手、衔铁、战车与脚下接触沿用河关尺寸。第一版马鬃有毛刺、灰马过亮；换成连续的鬃束轮廓后，实骑 #150 在 100 帧再走 9.94 米。[脸部两侧与普通机位](https://github.com/haohongfei2001-png/luanshi-game/blob/d2b308ff6512cf8fde85c03cd2e54e99e5e8b8b5/docs/evidence/river-gate-v1-rc16/face-shell/REVIEW.md) · [骑手/骑阵六机位](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43491137393)

从正式入口运行 `./tools/prepare-font.sh`、`godot --headless --editor --path . --import`、`godot --headless --script tests/model_library_parity.gd` 和 `./tools/compare-river-art.sh`。统一候选的真实包、连续录像、九武器/统军、两路护送、四规模和九次原生启动以 [PR #53](https://github.com/haohongfei2001-png/luanshi-game/pull/53) 的同一版完整验证为准。美术保留待审，真实 M5 尚未测。前版默认托管 M1 的 P95/P99 为 14.829/19.789 ms，有 97 帧超过 16.67 ms。

## 河关 RC16 · 可恢复的制作现场

本次集成取自上一候选 `05f0c7f1ff5ccea0f6cdba7da1b357111c1fcc09`，合入的军服母版 `219e14b1662990735eeda60cc2bdeaf3b54a19a4`，持械行军母版 `4b4f96f7a6a1760a09d1a17057298370fa865a10`，共享树林几何 `299eec62a60a4b0b88f9015d080b1b26bb85a61e`。三套服装、三段实物动作曲线已绑定正常军阵，枪盾弓、原有伤亡和兵籍沿用正式输入。树林在 Linux 的六次新进程、四个同机位对照已复核，场景建造中位由 1615 降至 740 ms；全程 512 对 512，热稳态帧率仍需实测。

统一候选在 [PR #53](https://github.com/haohongfei2001-png/luanshi-game/pull/53) 的当前源码运行全套验证。先看 22 米战场，再看枪、盾、弓五米多的实机细节。云端复现用 `./tools/compare-river-art.sh` 和 `./tools/test-field-render.sh footage`。托管 Apple Silicon 的峰值时间另按七个战斗步骤记录。正式包、窗口影片、验收数据以完成后的归档为准。美术质量仍在复核，真实 M5 未测。

[RC15 原始截图、完整录像与回退包](https://github.com/haohongfei2001-png/luanshi-game/blob/3477c960b68505d27b641a5bf214a391806d98c4/docs/evidence/river-gate-v1-rc15/PLAYTEST.md) · [持械行进的等速对照](https://github.com/haohongfei2001-png/luanshi-game/blob/4b4f96f7a6a1760a09d1a17057298370fa865a10/docs/evidence/river-gate-gait/march-pair.mp4) · [衣甲实机窗口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43486113614) · [原始树林帧对照](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43486379773)

## 河关 RC15 的实机基线

工程源码 `05f0c7f1ff5ccea0f6cdba7da1b357111c1fcc09`，录制原件 `4e83b2c287ea54fba97cb2e9b51e36970ab4e2b2`。两条护送均回营，旧档和九种武器已复跑。导出包 40 秒原速录制已按同一 SHA-256 复核。原生托管 M1 的 P95 为 30.040 ms，M5 待测。22 米画面仍有军服雷同和肩胯僵硬问题。

[完整战役原片](https://github.com/haohongfei2001-png/luanshi-game/blob/4e83b2c287ea54fba97cb2e9b51e36970ab4e2b2/docs/evidence/river-gate-v1-rc15/playthrough-full.mp4) · [原速操作](https://github.com/haohongfei2001-png/luanshi-game/blob/4e83b2c287ea54fba97cb2e9b51e36970ab4e2b2/docs/evidence/river-gate-v1-rc15/combat-normal-speed.mp4) · [本次报告](https://github.com/haohongfei2001-png/luanshi-game/blob/3477c960b68505d27b641a5bf214a391806d98c4/docs/evidence/river-gate-v1-rc15/PLAYTEST.md)

云端复现用 `./tools/compare-river-art.sh`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh journey`。下一轮在同一批角色与 22 米机位比较军服资产及持械步态，保留这套候选作回退。

## OWNER-ARTREF-20261114｜最新 Owner 强制视觉任务与可恢复入口

**优先级 P0：**立即沿用 [八作真实视觉对标与 ARTREF-01..12 可玩游戏验收](ART_REFERENCE_GAMES_AND_VISUAL_ACCEPTANCE_20261114.md)；不要将此前 RC3/RC13 的“技术视觉纵切片”和局部修补当作 Owner 认可的画面基础。Codex 应完成实际模型/骨架/甲衣/动画/河关环境的商业质量重建，在正式 Godot 512v512 战役中验证远中近景、军阵、正常速度交战和操作，并将证据按新文档归档。主任务仍 [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)，既有生效工程与存档/战场逻辑必须保留。**当前状态：规范已写入；新美术效果未通过 Owner 验收，M5 真实 20 分钟压力测试未通过/未完成，不能标 DONE。** 继续开发时以 RC13 真实代码/实拍为问题基线而非已经合格的美术目标。


**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务。每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令。正式文学剧情完全留空。不新增费用或远控个人 Mac。

## 河关 RC15 · 美术工作基线与恢复

RC15 使用 Quaternius 免费 Standard 版的两个可编辑阔叶树母版，把原先折成大片的树冠换成具有连续分枝、叶片 UV 和专用树皮的原模型。第一遍树影成了深色剪影，第二遍改用整冠法线，保留了第一次失败。树身与叶簇按原场地格合批，两种母版合计源三角形 9,770 个。主角改成偏肩披衣，同一敌兵在 22 米镜头中仍是第 43 步起手、第 48 步受伤。造型、树林和群体腿部姿态离美术目标仍有距离。[两版树林原片](https://github.com/haohongfei2001-png/luanshi-game/tree/75d94996e37c3292ca497bd5d1f9d7f4cacd8210/docs/evidence/river-gate-v1-rc15/grove) · [单肩披挂实拍](https://github.com/haohongfei2001-png/luanshi-game/tree/084a820a65b4f39a13d6627f3b0369a5115596d0/docs/evidence/river-gate-v1-rc14/hero)

使用 `blender -b --factory-startup --python-exit-code 7 --python tools/art/import_valley_grove.py -- /tmp/Stylized_Nature_MegaKitStandard.zip assets/environment/quaternius` 重建，源归档 SHA-256、再分发许可与转换结果均在 `assets/environment/quaternius/`。游戏启动和完整战役用同一个入口。双手使用经 CC0 核验的 HM08 掌指网格与原指骨，重做弓把、枪杆、扣弦和空手微屈。近档每手 785、远档 55–56 个三角形，实时合批内没有增加每指骨骼。操作者和敌我双方普通兵使用相同手部库。[真实窗及正常输入](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43474240506/artifacts/14061349563)。候选合并环境源 `89410bad7ed36018229f63388da5993f1e45aa36` 及手部源 `25558957154c4fb9a878edf17179986acb33cf48`，从 [PR #53](https://github.com/haohongfei2001-png/luanshi-game/pull/53) 查看正在验证的统一检出。图形回归的下一条可执行命令为 `./tools/test-field-render.sh footage`。

[RC14 可回退游戏包与原始录像](https://github.com/haohongfei2001-png/luanshi-game/blob/c5962a730038168ac0079f46650a6be1a0fc6765/docs/evidence/river-gate-v1-rc14/PLAYTEST.md)。RC14 托管 M1 的 24 秒样本 P95 13.199 ms、P99 16.640 ms，独立战役从部署到还营成功。第二条护送的最终营地点击遇到 900 秒托管超时，失败日志保留。真实 M5 与最终美术质量均待验。

## 河关 RC13 · 已合入的可玩候选

[下载、本版实战窗口、武器与军令实录、原始帧时间及 SHA](evidence/river-gate-v1-rc13/PLAYTEST.md)。游戏源 `03acb69b1621130f92bd940caa2cfb3b4e8653a5`，主线游戏合并 `12bdc945b7bb4ce2db655555a567244984496e45`，导出 `c96563beff02a8ad4f24458a228dcd426b4e2a72`，三者使用同一游戏目录树。前排枪盾兵根据真实迎敌距离分开收肩、压枪或继续行进。第一轮夸张的待步枪尖已由 0.869 米收成 0.156 米；原足底、手握点与真实命中核验通过。桥关道路经过三轮同镜头实拍，悬空的土片被退回，留下地面真实磨损、剥土和碎石。界面已明确区分城门耐久和夺取内庭。

正式包在托管 Apple M1 (Virtual) 进行 512 对 512 实战，实际 1024×640、100% 内部比例、4× MSAA；采样 24.02 秒，P95/P99 26.08 / 35.20 毫秒，最长 151.79 毫秒；应用数据从空目录启动 9/9。同树主线 P95/P99 18.79 / 26.66 毫秒，最长 61.02 毫秒。[主线验证](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43430982094)。九武器、骑乘与战车、独立将领/继任、两种护送、战后驻营/行军和 V3/V4 旧档均已回归。真实 M5、4K 内外屏热稳态以及最终美术目标仍待验证。

下一项优先看实际摄像机里多杆武器切过主角身体和交战树冠的情况。保持现有前排密度，同种子对齐输入与战果，再决定局部的动作/材质取舍。云端检出 `12bdc945b7bb4ce2db655555a567244984496e45`，运行 `node tools/env_cartway.mjs --check && ./tools/prepare-font.sh && godot --headless --editor --path . --import && ./tools/compare-river-art.sh`。托管 Linux 第 365 步四轮重放为 7.13–7.35 ms，最大的阶段是兵员状态与密度；原生 151.79 ms 长帧仍待同设备细分。为定位长尾，使用已导出包运行 `python3 tools/rc3_native_probe.py package/Luanshi-macOS.zip package/unpacked mac-evidence` 并按真实峰值步复盘。

## 河关 RC12 · 已合入的可玩候选

[安装包、原生画面、连续实录、原生窗口与校验](evidence/river-gate-v1-rc12/PLAYTEST.md)。游戏源 `5e12030486991d259c344b038605a13a70308ec7`，游戏合并 `e627086d985f0e458f187f4d691e816471574912`，导出 `92900dc79e381509e878ac0008e62fa9c3e95ba4` 的目录树相同。轻枪与重盾的头甲在 12 对实际画面中明确分开；过亮盔边和切顶后的悬空斗拱均已复修。正式固定镜头抓到盾盔遮眉，脸框从先前 19 个肤色像素降到 0。两次重烘后正式包读出 13，手框保持 106。第 635 步近侧檐枋让出攻城人群，其余四个机位保持逐像素一致。RC10/RC11 的左右受创、甲衣、马、四轮冲车与夺门结算均已保留。

九类武器经游戏输入，双方各 512 名普通兵、将领交手/继任、两条护送、战后驻营、行军与 V3/V4 存档均有完整回归。每方 512、100% 内部比例、4× MSAA，托管 Apple M1 (Virtual) 的 24.00 秒实战 P95/P99 14.29 / 18.41 毫秒。候选的空游戏目录启动 9/9。最长帧已和真实游戏步、可见兵、CPU 阶段及镜头移动关联。同树主线独立 Apple M1 (Virtual) 的 P95/P99 为 35.46 / 51.08 毫秒。 [主线 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43419880003)。真实 M5 内外屏 ≥20 分钟与最终画面风格仍待验收。

下一项实作优先改常用 22 米镜头里重复的步态/肩线及兵器遮挡，用自然推进时的截图和录像检验。云端检出 `e627086d985f0e458f187f4d691e816471574912` 并执行 `./tools/prepare-font.sh && godot --headless --editor --path . --import && ./tools/compare-river-art.sh`。另运行 `python3 tools/rc3_native_probe.py package/Luanshi-macOS.zip package/unpacked mac-evidence` 在已授权托管 Mac 查看实际最长帧上下文。还需压低默认画质长尾和在真机上验证。

## 河关 RC11 · 已合入并打包

[macOS 实测包、默认视角、战役实录、全套测试和内层 ZIP 校验](evidence/river-gate-v1-rc11/PLAYTEST.md)。游戏源 `e66ce35cdd0f81df5b8a28fffefa09050923682f`，游戏合并 `59969ee84014a72f764aec1537787c58ae69edf1`；正式导出 `157a91a4f76830bd0ec09e4821dccc6a890ecaaf` 与这两个提交的游戏树完全相同。玩家默认距离能看清独立主门与两座望楼，穿门时近侧屋面按遮挡局部处理。战马肩臀、四肢接合与鞍后桥经过两轮同场复拍，近/远为 7010 / 1612 面。

默认包在托管 Apple M1 (Virtual)、1024×640、原生 100% 和 4× MSAA 运行 24.00 秒，P95/P99 26.38 / 49.37 毫秒，最长 134.22 毫秒，空游戏目录启动 9/9。同树 main 在 Apple M1 (Virtual) 的 P95/P99 为 12.70 / 15.64 毫秒。 [主线验证](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43405594451)。真实 M5 内外屏持续 20 分钟 NOT_RUN。兵数、武器、本人命中、将领继任、两条护送、冲车轮距、V3/V4 及战后行军均在候选上回归。

下一个可执行动作是在授权云端检出 `59969ee84014a72f764aec1537787c58ae69edf1`，执行 `./tools/prepare-font.sh && godot --headless --editor --path . --import && ./tools/compare-river-art.sh`。沿第 43/48 步与 22 米固定镜头比较枪、盾、弓手头颈和肩线；同时以原生逐帧数据检查城门与移镜时的长帧并保留不同宿主的差异。用普通玩家尺度验收轮廓与动势。近侧骑手遮挡、背光马毛和门楼切顶梁架仍有可见问题。

RC11 的 PR 与独立 main 重建均通过六项 CI，同树主线包的原生内层 ZIP SHA-256 为 `48d2cd27b95c0d7847023e23cbd74c1cb2f77c9969183b7c54c3a4ca6c99a6ff`。后续枪、盾头颈已在[两轮定点复核](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43407686196/artifacts/14028361262)留下两份源码差异，候选源码 `9718f42a4d56c96fc5694da5d27d80397e68b958`，不包含在 RC11。城门破门后仍露出外侧悬空木块，另一路已做精确几何修正。可在下一阶段用受击姿势、默认游玩距离和破门窗口验证后集成。

## 河关 RC10 已合入 main

[macOS 下载、22 米正常镜头、连续战役、完整原始数据与复现方式](evidence/river-gate-v1-rc10/PLAYTEST.md)。游戏源 `c3e39a78a6028aa2d396f1cc37757f02c56a9679`；游戏合并 `74a79d1a6199eb82e965d3ba49c0400b0f1f086f`；三者同树的实际导出和[六项 PR CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43395721594)已核验。九次空游戏目录原生启动均进入战斗。512v512 托管虚拟 M1（1024×640、4× MSAA、100%）的 24 秒 P95/P99 为 17.85/27.35 毫秒，最长 763.73 毫秒，未达稳定 60。真实 M5 无授权或样机证据。

实战加入左右盾击承重与受创退步，前齐后分的裙甲、侧面的阵营布色、榆树枝叶、实际滚动的四只冲车轮、重塑过的马头与蹄。第一遍灰石状的甲片已重做，近景马的肩臀平面、普通兵的重复轮廓、门楼相连仍是可见问题。九种武器、护送、双方军官、存档 V3/V4 和战后行军均已回归。

从干净云端检出 `74a79d1a6199eb82e965d3ba49c0400b0f1f086f`，用 `./tools/prepare-font.sh && godot --headless --editor --path . --import && ./tools/compare-river-art.sh` 可重放固定机位。已经在分开的云端[门楼实拍](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43399255144)与[战马肩臀实拍](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43397792374)继续迭代。下一步以收窄的两座望楼、无遮挡骑手 150 号及马匹侧光作为实拍对照，再跑同树的整包原生验证。

## 河关 RC9 试玩候选已合入，美术自审未达标

[下载 macOS、正常视角、连续实录、测试和校验值](evidence/river-gate-v1-rc9/PLAYTEST.md)。游戏源码 `be80dc767dc5dcaa3f6e217fbcce93f3dc1347b7`，main 合并 `4a3ebc4d3c8e687337b27829c6bc13be20810f09`，与真实导出 `1ec3a54c97b8fc87ad476c9e97918d26a1813e0f` 的树相同。[游戏 PR #43 六项检查](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624)全部通过。曾失败的盾兵近景已按相同相机重做盾面和携行位置，原断言补回 106 个持械手肤色像素。过亮麻衣、光滑树冠与偏黄道路的退回版本有记录。主角实际出枪、九武器、战役目标、将领继任、骑乘、护送及战后行军/存读档有回归。最终画面和完整游戏仍未通过。以[新质量要求](OWNER_QUALITY_FIDELITY_PERFORMANCE_TARGET_20261113.md)为准。

托管虚拟 M2 Pro，默认 1024×640、100% / 4× MSAA，24.002 s，P95/P99 10.288/12.594 ms，最长 48.986 ms；九次空游戏目录启动通过。真实 M5、内外屏 20 分钟及热稳态仍为 NOT_RUN。同树 main 第二次六项通过，托管虚拟 M1 的同档 P95/P99 为 20.939/29.974 ms，9/9 启动；未达到稳定 60 FPS 的 P95 目标。

**下条可执行动作**：云端检出 `4a3ebc4d3c8e687337b27829c6bc13be20810f09`，执行 `./tools/prepare-font.sh && godot --headless --editor --path . --import`，再在有图形服务的环境运行 `godot --path . --resolution 1920x1200 --audio-driver Dummy --disable-vsync --fixed-fps 30 --script tests/rc7_personal_contact.gd -- --field-size=512`。取 43/48 步和 `tests/river_craft_camera.gd` 第 65 步三档原图，继续改人物肩髋受力、重甲侧影和马头轮廓。保留眼下包作可回退版本，M5 另验。

## RC8 之后的步兵动作试作｜独立分支，未装进 RC8

[三档实机、原生 22 米亲战与复现命令](evidence/river-gate-v1-rc8/carry-study/README.md)。目前枪、长刀、盾兵各有两种替代负重姿势，命中关键帧一致；正常距离轮廓有所改善，整套人物与场景仍未通过。可运行工作点分支 `codex/river-carry-reviewed`；可回退的安装包见下方 RC8。没有用这个动作试作宣称新运行包或 M5 通过。

## 河关 RC8｜已合入并可试玩；美术与 M5 未最终验收

游戏 [PR #40](https://github.com/haohongfei2001-png/luanshi-game/pull/40) 的[六项 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045)通过；main 合并 `2c92c7eace980d76d538a646ca64ce9817d191b4` 与实际导出树相同。源 `5cf51e2f7ad9e4fe2768e2088b11bdfd0ab4979e`，[安装包、完整实录和同输入对照](evidence/river-gate-v1-rc8/PLAYTEST.md)。每方 512 普通兵、32 位军官另计。正常 22 m 跟随镜头出枪第 43→48 步，584 号敌兵由 62 降至 39.76；九武器、坐骑/战车、自然攻城、战报后行军/读档与 V3/V4 回归通过。托管虚拟 M1 九次原生图形试验 9/9，实际 1024×640、全分辨率 4× MSAA、24 s、P95/P99 13.59/17.10 ms，RSS 545.1 MiB；**不是 M5 或持续稳定 60 的验收**。

**主线第二次重建未全绿**：[4/6 项](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43355984399)。相同游戏树及实际 1024×640、4× MSAA，托管虚拟 M1 实战为 46.60 FPS，P95/P99 46.67/64.73 ms；九次启动有一次默认 Metal 75 秒内未到场景就绪，8/9。Linux 长战线录像另在 660 秒时限退出，其他战役与战后连续录像通过。[新失败及全部九行原始数据](evidence/river-gate-v1-rc8/raw/main-rebuild.json)。用能捕获首个场景之前的诊断区分资源/引擎/宿主等待；不可把再启动成功或单次快速宿主当作修复。曲篷冲车在同一画面遮住悬梁，未替换交付模型。

**仍需解决**：普通兵肩颈、体态、脸与马匹外形过于同质，前线武器重叠，冲车与城门切顶时木框太直太空。弓手、枪兵、盾兵的携械重心、衣摆、背甲已经重做；一次糊地表/亮腰袋的实验被回退，补背廊与省查询只改善局部，没有当成最终美术或性能突破。P2 个体现场对象仍未全面分队化，长期独立世界与人生也未通过。**下一条可执行工作**：在新的云端工作树以 `2c92c7eace980d76d538a646ca64ce9817d191b4` 为基线，执行 `./tools/prepare-font.sh && godot --headless --editor --path . --import`，用有显示服务的 `godot --path . --resolution 1920x1200 --fixed-fps 30 --script tests/rc7_personal_contact.gd -- --field-size=512` 建立基准；以原生 22 m、密集阵前与第 490 步的城门镜头检验肩髋/腿承重、马的肩背和整车轮廓。既有 gameplay、人数与存档不降级，M5 仍需独立真机授权。

## 河关 RC7｜可玩候选，美术与 M5 未验收

[游戏 PR #38](https://github.com/haohongfei2001-png/luanshi-game/pull/38) 六项 CI 通过后，游戏合并提交 `b8e830f6d5f71620531ac76961decc31ef0b1581` 与导出源码树相同。源码 `dbae207abe51a305d2b9f392383dc00d016531cd`，实际导出 `4b9557b6d811880dffb9e6dc28d4531b27fd3456`，内层 macOS ZIP SHA-256 `2758b370eb60d848eaa6b4c026337d5eb29fe54838d8302ab03c8aa115cc2a44`。[候选包、实机和 A/B](evidence/river-gate-v1-rc7/PLAYTEST.md) · [自然出枪和敌兵扣血](evidence/river-gate-v1-rc7/PERSONAL.md) · [Mac 实机与未采用的调色](evidence/river-gate-v1-rc7/NATIVE.md)。两台独立托管虚拟 M1 结果有差异：最终包 9/9 冷启、默认 Metal 1024×640、P95/P99 24.34/36.10 ms，未达到稳定 60；M5 NOT_RUN。完整随军电影、战报、行军、F5/F9、两条护送已在修复后复核。正式剧情留白。

最终安装包的九张原生 PNG 已逐张解码，九张中央都有有效游戏画面；同一检查拒绝了编辑器首次回读的全黑 PNG。见[原件指纹和抽样结果](evidence/river-gate-v1-rc7/raw/window-pixels.json)。这是对画面确实出现的验证，不是对美术或流畅度的验收。

[后续正常镜头的兵种实装对照](evidence/river-gate-v1-rc7/FIELD_DRESS.md)未被采用为新候选包：箭囊、肩甲有改善，整屏角色仍太相似。主线同一游戏树独立重建为 5/6 项 CI 通过；原生 7/9，两个默认 Metal 测试分别在持续进展时被固定时限截断、部署后失焦停在第零步。保留[九次全部结果](evidence/river-gate-v1-rc7/raw/main-rebuild.json)和原来 9/9 的交付包。定向导出包[复现第零步失焦并验证一次“继续”](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43350173727)：两次自然启动、一次可控真实窗口中断均通过。此修正仅在测试入口；这不覆盖原包失败或 M5。

**下一步**：以已保存的第 43/48 步正常游玩镜头和城门/近景 A/B 为准，按排复查不同距离长兵、重甲、弓手的肩髋姿势与持械剪影，优先减少远景甲与兵器的跳点。托管 Metal 编辑器 A/B 曾报 fence 超时且首张回读全黑；需记录第一张非黑帧，切勿把“存在 PNG 文件”当作视觉通过。复现实际玩家接敌：在独立云端检出 `e1fa26e16da14545f0d83de0cf2c12638d4140ef`，按其工作流运行 `godot --path . --resolution 1920x1200 --fixed-fps 30 --script tests/rc7_personal_contact.gd -- --field-size=512`。全军最终美术、P2 全面分队后端、长期世界与人生闭环、M5 和正式发布均未宣称通过。

玩家明确拒绝 RC6 的视觉品质。保留 RC6 可回退；玩法/构建通过不等于美术过关。第一轮真实 512v512 摄像机对照发现路面过橙，柳叶看成大块垂布，近景的胸甲看成横箍；第二轮据此降低道路和草甸饱和度、制作独立柳条，重做分襟、绛披、轻重甲、枪的承重脚和用色。使用现有的九套武器、骨架、蒙皮及模拟。地表和树叶是实际用在战场里的材质，参考图不在游戏里作背景。

环境返工点 `2e049582dd2c5457b1207e4fc358df63965ba9bd`；[首轮窗口与原始 PNG](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43337847031)；[人物二次实机复核](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43338758045)。在集成版本执行 `./tools/prepare-font.sh && ./tools/compare-river-art.sh`，参考基线 `d6b03507c4ace8582ab9f821e604c499616b8dab`，比较时刻、朝向、实际屏内 ID、伤亡与输入相同。视觉需审正常 1920×1200 城门/接敌与近景，不用特写代替。[最终代码的主动出枪与目标失血](evidence/river-gate-v1-rc7/PERSONAL.md)：普通游戏镜头，敌兵 #584 在第 43 至 48 步由 62 降到 39.76。可玩源码 `cb85d58318b1379127a2465816a3917f79298090`；[实包回归](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060)。Linux 软件录制曾在第 1030 步已到战报后触到旧 550 秒上限；不把未走到的驻营或读档当作通过。录制脚本保留渲染质量与原始全部输入，改用可见 UI 阶段或递增模拟步心跳、135 秒无进展/840 秒总时限。

第三轮复查保留了开冠柳的上部叶影，并将能走过的浅岩边缘埋入草皮，避免石片像平放在场地上的道具。人物补修袖口到手腕、行军时的斜持弓与放弦，保留真实出手时刻与九套武器。全任务未完成；M5 真机 NOT_RUN。下方为已归档、未改写的 RC6 验证结果。

## 河关 0.16.0-rc.6

游戏源码 `89416f926e725d93d0ef86138dcbf333b9211576`，合入 main 的源码 `d6b03507c4ace8582ab9f821e604c499616b8dab`。PR 验证导出 `b067e79cce519a9cdf1abf3b3ff5acb080b38698`。角色和地图的三轮真实游戏窗口复查、操作回归、资源和性能数字均已归档。 [实机记录、包与运行命令](evidence/river-gate-v1-rc6/PLAYTEST.md) · [千人交战原片](evidence/river-gate-v1-rc6/playthrough-review.mp4) · [当前 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519) · [可回退阶段](https://github.com/haohongfei2001-png/luanshi-game/commit/4621944adf8e30dda2516b4291e7a0ceebc011d7)

正常战场已经使用六类衣甲与配套头巾、披膊、领衬，九套实际武器动作、部队、将领、坐骑、河岸、营地和城门采用同一美术方向。军议可点击继续旧档，战后幸存者带走亲历的战果，驻营与行军可接续。军械按队与武器登记，同时核对每个单位和伤亡。

同机位重放保留兵力、命中和动作。对 1,024 与 5,000 人两组实战，分别测量寻敌与完整模拟步，逐人校验目标、让位量和整个战斗存档。托管 Apple M1 (Virtual) 默认实际 1024×640、4× MSAA、阴影，24 秒窗口的 P95/P99 为 11.45 / 13.56 ms。该 PR 包九次空游戏数据启动都有首帧和命中。主线同树重建后，冷启动首轮 8/9，首次 Metal 在场景回调前超出 75 秒；相同包在独立托管机复测 9/9。主线默认档 P95/P99 为 14.77 / 20.61 ms。阴影绘制等待和 Metal 编译已在一次慢启动中测到。独立 Metal 烘焙包已拒绝，Apple7 着色程序在托管 Apple5 设备上每次报告 111 条错误。另见 [主线冷启证据](evidence/river-gate-v1-rc6/PLAYTEST.md#主线重建与独立冷启复核)。M5 实机 **NOT_RUN**，5,000 / 10,000 人的短程 CPU 数据不足以证明可玩帧率。

启动方向下一步是在显示军议与有效输入之前，分段加载近景、阴影与部队资源，并用同一 75 秒时限核对第一帧、军议可操作时刻和实际部署。美术下一项在同一种子门前接敌镜头细看主角、盾肩与枪头重叠的位置，分开量取近景蒙皮/远景批次的 CPU 时间。维持画质、伤亡和军阵。云端复现从 `git fetch origin main && git switch --detach d6b03507c4ace8582ab9f821e604c499616b8dab && ./tools/prepare-font.sh && ./tools/compare-river-art.sh` 开始。原生包的帧时可用 `python3 tools/rc3_native_probe.py <内层ZIP> <解压目录> <证据目录>` 在托管 macOS 重放。

<!-- river-gate-current-review -->
## 历史记录 · 河关 0.16.0-rc.4

归档这份 RC4 记录时，主线游戏代码为 RC3。RC4 的完整游戏来自开放的 PR #34。美术状态为 **ART_REVIEW_REQUIRED**。常用俯斜游玩视角参考第二张美术方向稿，角色近景用于检查动作与材质。当前优先继续提升正常战斗视角的人物与环境，RC3 的阶段排程留作历史记录。 [实机连续片段](evidence/river-gate-v1-rc4/battlefield-motion.mp4) · [实际游玩流程](evidence/river-gate-v1-rc4/playthrough.mp4) · [配对实机画面](evidence/river-gate-v1-rc4/before-after.mp4) · [美术方向稿](art-direction/river-gate/battle-view.png)

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
<!-- /river-gate-current-review -->

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
