# 河关 0.16.0-rc.4 · 实机画面与可玩包

**美术状态为 ART_REVIEW_REQUIRED。** RC3 的人物美术已由 Owner 退回。这份候选把人物、动作、马匹和地形接入原战役。玩家的参考是《英雄联盟》实战镜头里清楚的轮廓、承重和挥击节奏。河关的兵器、衣甲、地图和声音均沿用本作设定。

[34 秒连续实战](battlefield-motion.mp4) · [同输入脚步对照](footwork-pair.mp4) · [从布阵到行军](playthrough.mp4) · [九种武器](nine-weapons.mp4) · [macOS 候选包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43275529020/artifacts/13970062784)

![真实战斗片段](contact-loop.webp)

## 镜头里能看到什么

- 对照左为 RC3，右为 RC4。在两版正式 Godot 场景重放同一批 512+512 名普通兵、32 名军官与主角。十四组截图的随机种子、模拟时刻、镜头中心、角度、缩放、画内单位、伤亡与城门状态一一对应。1280×800，内部缩放 1，阴影开启。 [主角](hero-pair.jpg) · [对阵](contact-pair.jpg) · [箭线](bowline-pair.jpg) · [军官](officer-pair.jpg) · [城门](gate-pair.jpg) · [坐骑](saddle-pair.jpg) · [战车](cart-pair.jpg) · [渡口](ford-pair.jpg) · [柳树与水岸](bank-pair.jpg) · [林缘](margin-pair.jpg) · [军营](camp-pair.jpg) · [远阵](formation-pair.jpg)
- 贴地的步伐、侧身移步、胯肩反向承重、抬手预备、击后收势都采样自正式输入与动画。第一次等输入回放发现起始镜头不同，最终镜头统一。持枪主角近身前走了 19.47 米，命中 1 次、承受 5 次打击后倒下。两版均记录到模拟第 80 步。 [连续动作分帧](motion-steps.jpg) · [两版数据](raw/after-motion.log)
- 弓手连续实录 1020 帧，主角命中 7 次，镜头随后沿交战线移向冲车。两军累计有效命中 1035 / 797 次，累计伤亡 200 / 233。此片按正常 30 帧时基录制，设备性能见实测表。 [原始日志](raw/battlefield-motion.log)

- 后续实装了靛蓝粗布、夹袄、深色铁札与绛披。主角和士兵在持枪行军时把枪尖举过前排肩线，交战时降至命中高度。服装和三张脸的原画只作为 UV 贴图使用。 [正式角色画面](hero.jpg) · [连续持械步伐](footwork.webp)
- 对 16 组方向步态的接地段在每个姿势之间再采 16 个点，最差鞋底位移从 79.1 毫米降至 0.77 毫米。1280×800 同宿主软件绘制四个镜头的 P95 变化为 −0.02 至 +3.21 毫秒，镜头内几何、伤亡及命中一致。此表检验了插值改动，最新包的完整帧时另列于下。 [逐项 A/B](raw/motion-sampling.json)

## 性能与启动

Godot 4.6.3。GitHub 托管 macOS 的 Apple M1 (Virtual)，mobile 清晰档，阴影开启，实际画幅 1024×640。双方各 512 名普通士兵的战役实际巡场 24.0 秒。

| 托管设备与普通兵/方 | 平均 FPS | P50 ms | P95 ms | P99 ms | 进程内存 MiB |
|---|---:|---:|---:|---:|---:|
| Apple M1 (Virtual) · 512 | 176.5 | 4.62 | 13.24 | 15.94 | 510 |
| Linux 软件渲染 · 20 | 6.74 | 147.09 | 158.07 | 158.88 | 463 |
| Linux 软件渲染 · 100 | 5.05 | 198.40 | 207.28 | 208.67 | 498 |
| Linux 软件渲染 · 250 | 4.53 | 222.00 | 232.57 | 238.60 | 542 |
| Linux 软件渲染 · 512 | 3.63 | 277.89 | 292.57 | 293.38 | 577 |

表中 macOS 为峰值 RSS，Linux 为各场景采样时的 RSS。不同宿主的结果分开读。真实 MacBook Air M5 为 **NOT_RUN**。实测采样含阵线接触、镜头平移、攻城、骑兵与投射物。软件绘制和虚拟显示器不代表玩家设备。[逐帧时间、画质与设备](measurements.json)

托管 Mac 正式游玩摄像巡场中，模拟与战场显示脚本平均每个渲染帧分别占 1.13 与 3.08 毫秒。渲染线程 CPU P95 为 0.47 毫秒。该次驱动没有交回非零 GPU 时间戳，原生 GPU 毫秒数保留为空。Linux 千人窗口的每个模拟步平均 22.15 毫秒，软件绘制计时的 P95 为 215.54 毫秒。 [原生逐帧样本](raw/shipping-metal-frames.json) · [四档同宿主窗口](measurements.json)

八次独立进程均以空游戏数据启动，覆盖兼容后端、Metal、焦点控制与默认窗口。系统图形驱动和 WindowServer 缓存按实际宿主状态保留。兼容后端第一次首帧 15.94 秒，第二次 2.80 秒。每次记录首帧、前台、部署、首次模拟和命中。 [原始时序和启动日志](raw/renderer-comparison.json)

RC2 曾在首次兼容后端启动时停在模拟第 0 步。这次每个窗口均记录到实际命中。首开仍可能显著慢于再次打开，系统图形缓存及宿主差异仍待调查。 [RC2 失败现场](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43157917697/job/130986662440) · [本版启动时序](raw/renderer-comparison.json)

独立改动也保留了相同 GPU 与机位的对照。柳岸实装后的渡口软件绘制 P95 从 137.53 增至 157.37 毫秒。贴图与头部轮廓更新后，野战近身镜头的软件绘制 P95 从 155.46 增至 175.72 毫秒。完整包取样和单项实验分别记录。 [河岸对照](raw/willow-cost.json) · [角色对照](raw/garment-cost.json)

正常缩放下队伍装备与远景脸型仍有重复。密集门口前排偶尔会遮住主角持械手。柳冠体块与路面材质还有细化空间。是否达到美术方向以实际游玩画面为准。 [门洞](gate.jpg) · [接敌](contact.jpg) · [正常机位下的行列](formation-pair.jpg)

## 战役与存档回归

- 实际输入覆盖剑、刀、棍、枪、长刀、弓、弩、剑盾、双剑，并覆盖骑乘、下马、战车、部署、号令、敌我军官、救援、继任、护送与战后结算。主流程经过 7 个可交互阶段，从营地读档并推进 1 小时。 [武器与载具](raw/field-controls.log) · [将领](raw/field-officers.log) · [军令与战报](raw/journey.log) · [护送](raw/field-escort-gui.log) · [胜负分支](raw/field-outcomes.log)
- 原始 RC3 写出的破门存档从第 629 步继续至第 746 步。逐字段差异数 0。历史 v3、v4 存档和游戏内驻营继续已分别复验。 [跨版复验](raw/rc3-resume.log) · [历史样本](raw/field-history.log)

## 源码、素材与复现

- 候选源码 [d2f0180c0865b3746bef11e43a2239659188fa6f](https://github.com/haohongfei2001-png/luanshi-game/commit/d2f0180c0865b3746bef11e43a2239659188fa6f)，CI 实际导出的合并树提交 [f8129247cffe207f6fa0575e0cab3851662e5b96](https://github.com/haohongfei2001-png/luanshi-game/commit/f8129247cffe207f6fa0575e0cab3851662e5b96)。[游戏 PR #34](https://github.com/haohongfei2001-png/luanshi-game/pull/34) · [CI 与产物](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43275529020) · [RC3 可回退源码](https://github.com/haohongfei2001-png/luanshi-game/commit/799e1e41a098bf534b63f699ea6f683e4707306f)
- macOS ZIP 内含可运行的 .app、中文指南及第三方许可。SHA-256 为 `d91e3097ece6199b99c607457263d570ef49cb99a3be033f4bde6f688799052c`。这个散列校验解开 Actions 外层归档后的 Luanshi-macOS.zip。通用 .app 采用临时签名，尚未进行 Apple 公证。
- 脸部基础网格与形态来自 MakeHuman 的 CC0 数据。衣料和三张虚构面孔采用本项目生成并按衣片、五官对齐的贴图，马具、器械、动作与场景由本项目制作。资产与再分发记录见 [人物与动作](https://github.com/haohongfei2001-png/luanshi-game/blob/d2f0180c0865b3746bef11e43a2239659188fa6f/assets/river_gate/figures/SOURCE.md)、[马匹](https://github.com/haohongfei2001-png/luanshi-game/blob/d2f0180c0865b3746bef11e43a2239659188fa6f/assets/art/mounts/README.md)、[环境](https://github.com/haohongfei2001-png/luanshi-game/blob/d2f0180c0865b3746bef11e43a2239659188fa6f/assets/environment/README.md)。
- 在有 Godot 4.6.3、Xvfb、FFmpeg 和 Python/Pillow 的云端环境签出候选源码，运行 `./tools/compare-river-art.sh` 复拍十四组镜头与正常速度实战。性能与输入流程可重跑 `./tools/test-field-journey.sh` 和 `./tools/test-field-render.sh`。原生启动复验使用 CI macos-runtime 作业。
