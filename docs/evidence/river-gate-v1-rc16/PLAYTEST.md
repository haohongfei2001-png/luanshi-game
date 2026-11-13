# 河关 0.16.0-rc.16 · 实际游玩与安装包

[下载 macOS 通用候选](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137/artifacts/14067999483) · [完整源码](https://github.com/haohongfei2001-png/luanshi-game/tree/7c9ac667ded0a8e80a05cd47593a4af70c28486c) · [PR #53](https://github.com/haohongfei2001-png/luanshi-game/pull/53) · [完整 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137)

解开 GitHub 下载件，再解开里面的 `Luanshi-macOS.zip` 取出应用。macOS 内层 ZIP 的 SHA-256 为 `5ad3811dbbc8419a78fe3218a4ebd27b4fdebb20bc514efa2c68c63bcd7c81d0`。Linux 包 SHA-256 为 `03648c05d20ae52a7f381e47b719dd5d1a1b3e3fa29d70c4ad4b35baede52d61`。游戏提交 `7c9ac667ded0a8e80a05cd47593a4af70c28486c`，导出提交 `d0d665d6c61a7676ff8f4785c3f5be4bccb74b08`，两者的树均为 `baab128db9541014a3332620d1ebfb003f790cb0`。托管 Apple Silicon 运行了这个包；Intel 架构在通用应用内，未在 Intel 硬件运行。正式公证与发行不在本次交付范围。

## 从玩家的位置看

[1920×1200 原始游戏窗口](normal-camera-before-after/after.png) · [22 米同一击的前后](normal-pair.jpg) · [起手](normal-camera-before-after/windup.png) · [近景](close.png) · [交锋全窗](mid.png) · [宽阵](wide.png) · [托管 Metal 原帧](metal-window.png)

每方 512 名普通兵和 16 名军官，另有一名玩家。种子 61112、22 米跟随相机、100% 内部比例、4× MSAA 与原有阴影。第 43 步起枪，第 48 步命中同一名敌兵 #584，生命由 62 变为 39.76。普通枪刀、重盾长刀、弓弩各用一套 Wildfire Games 的成衣；原衣片、袖、UV 和蒙皮接入河关既有动作。第 94 号弓手从起手、满弓到第 36 步实发一箭，箭数 19→18，目标 #582。[衣甲近景与行进原速录像](garrison/equal-speed.mp4) · [弓手正面与手臂](garrison/archer/fingers-pair.jpg) · [持械走跑等速双窗](march/march-pair.mp4)

第一遍衣服的米白横带和空手跑时约 80° 的扭肩已退回。实机中成衣的腰、肩、袖口比旧身清楚；近距离脸颊仍可能出现深色斑点，密集阵列里邻兵的刀枪会穿过面前。马背与役车沿用已验证的轮/足接地。具体不足和来源见[逐作美术对照](reference-gap-analysis.md)、[素材许可](assets-and-licenses.md)和[美术验收](artref-verdict.md)。

## 两种带声音的真实游戏录像

[59.2 秒从军议到回营](playthrough-full.mp4) · [快速预览](playthrough-review.mp4) · [40 秒正常速度的正式包键鼠实录](combat-normal-speed.mp4) · [导出录制逐段数据](export-recording.json)

军议、部署、交战、破门、结算与回营均从实际界面运行。第 1030 步夺取内庭，我方死亡 257、敌方死亡 308，主角贡献 7 次命中；发出的 1 道军令抵达。战后营中时间增加 1 小时，保存并重启仍能继续。另一条普通护送于第 724 步完成，先锋路线第 630 步城门开放，第 632 步仍显示距门 10 米，送车到位后第 700 步结算。20 对 20 其他路线分别得到“成功撤离”与“主将阵亡”。

额外的正式 Linux 二进制实录有 960 个正常速度帧、1280×800 和双声道引擎声音。在固定时间步录制中，系统键鼠实际下达攻击、技能和军令并移动镜头，战役运行至第 774 步，分段共 2081 次命中，城门耐久 0。此片 SHA-256 为 `9f016d76c9cefb4a1f1893869e715c16a0a309d3aff7c9603fcc03ae85076475`。实际帧率来自独立的实时窗口。

九套武器均通过正式输入，马与战车各有实测上车、转向、技能及下车。双方军官有战斗、负伤、救援、继任与俘获记录。存档共 1467 次检查、0 个失败；V3 和 V4 检查点分别续到 235 和 746 步，状态与预期相同。[九武器与攻城](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137/artifacts/14068633019) · [战役与营中流程](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137/artifacts/14069074956) · [原始测量](measurements.json)

## 实战帧时间与冷启动

托管 Apple M1 (Virtual)、Apple Paravirtual device (Apple5)，实际颜色附件 1024×640、默认 Metal、100% 内部比例、4× MSAA 和阴影。24.004 秒窗口共 3526 帧、1159 次命中。平均 146.89 FPS，P50/P95/P99 为 5.552 / 14.829 / 19.789 毫秒，最长 81.970 毫秒，97 帧超过 16.67 毫秒。最大进程 RSS 489.7 MiB。原生 GPU 时间戳状态 `no_nonzero_device_timestamps`。[逐帧数据](native-frame-times.json) · [托管日志与原生窗口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137/artifacts/14069178566)

最慢一帧第 421→421 步，可见 249 名单位，模拟区间 0.000 毫秒、呈现脚本 4.943 毫秒。该帧没有固定模拟步，七个模拟子段都是 0；GPU 在虚拟机没有返回有效时间戳。全窗口累计最多的是 `unit_actions_and_density` 2745.369 毫秒。计时包含操作系统调度等待。留存完整七段、时间戳与请求摄像机间隔以便复核。[完整 Metal 计时](metal-window-frames.json)

共 9 次新进程、空应用数据启动，8 次进入实际交手，包括兼容后端和焦点暂停恢复。第一个默认 Metal 空数据进程达到 75 秒时尚未提交首帧，完整采样保留。82 次主线程采样都在临时几何节点析构时等待 Godot 着色器编译，渲染管线工作线程在等锁。单次栈采样不能证明永久死锁或唯一原因。驱动/系统缓存保留。[失败的现场采样](startup/default-metal-1-before-scene.sample.txt)。同一默认 Metal 包第二次启动的首帧为 28.52 秒。真实 MacBook Air M5、内外屏与连续 20 分钟热稳态均未测。

下表为托管 Ubuntu 24.04、Godot 4.6.3、llvmpipe 软件 OpenGL。原图 1280×800、100% 内部比例、4× MSAA，实测每方 20/100/250/512、每档 20 个渲染帧。样本量较小，P99 等于最慢帧。[四档原始记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137/artifacts/14069267223)

| 每方普通兵 | FPS | P50 ms | P95 ms | P99 ms | RSS MiB | 窗口命中 |
|---:|---:|---:|---:|---:|---:|---:|
| 20 | 3.72 | 274.75 | 287.03 | 287.69 | 915.5 | 33 |
| 100 | 2.47 | 406.20 | 423.82 | 426.43 | 1012.3 | 172 |
| 250 | 2.10 | 471.13 | 491.34 | 527.67 | 1052.4 | 262 |
| 512 | 1.68 | 595.20 | 630.24 | 635.57 | 1117.7 | 288 |

同宿主独立 A/B 中，158 棵内陆树共享两个树木网格后，场景构造中位 1615.3→740.1 毫秒，Godot 静态内存构造峰值 658.6→133.4 MiB；构造结束后的常驻静态约 69.6→70.1 MiB。四个机位的兵员、命中、死亡与屏幕人数相同，像素通道平均绝对差最多 0.000131/255。绘制次数增加 10–28，部分视角帧时间略升。六次新进程、分区位置、首帧耗时和原始视图均保存。[树林分项](groves/measurements.json) · [树与士兵的实机对照](groves/trees-pair.jpg)

在托管游戏环境运行 `./tools/prepare-font.sh`、`godot --headless --editor --path . --import` 后，`./tools/compare-river-art.sh` 对比 RC15/RC16，`./tools/test-field-render.sh footage` 复测规模、武器与车马，`./tools/test-field-journey.sh` 与 `./tools/test-field-render.sh journey` 复测完整战役与护送，`./tools/export.sh` 产生安装包。托管 macOS 上用 `python3 tools/rc3_native_probe.py package/Luanshi-macOS.zip package/unpacked mac-evidence` 重新启动。正式包实机录像命令见[工作流](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488066137)。
