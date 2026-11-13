# 河关 0.16.0-rc.15 · 实际游玩与候选包

[下载 macOS 候选包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/artifacts/14062229339)。下载 CI 外层压缩文件后，解开里面的 `Luanshi-macOS.zip` 取出应用程序。内层文件的 SHA-256 为 `9ef8b874dd856022bedd05b2706473aad38c75f8e07486588a5e7b9ac967eb66`。这个包已在托管 Apple Silicon 主机运行，带 arm64 与 x86_64 可执行架构。[完整 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574) · [PR #53](https://github.com/haohongfei2001-png/luanshi-game/pull/53)

游戏源码 `05f0c7f1ff5ccea0f6cdba7da1b357111c1fcc09`、CI 检出 `331ede4b126658da7cb4cae08edd05cd2b468c9b`，两者的 Git 树均为 `76edaed1a40dab7e782e87eba5646d963c87e3cc`。旧版 [RC14 包与录像](https://github.com/haohongfei2001-png/luanshi-game/blob/04afc93a0242fc45eda69e6c5ba98eaa2413b9c9/docs/evidence/river-gate-v1-rc14/PLAYTEST.md) 仍可回退。

## 从玩家的位置看

[未裁剪的 1920×1200 游玩画面](normal-camera-before-after/after.png) · [同种子同镜头的修改前后](normal-pair.jpg) · [近距人物](close.png) · [中距离交锋](mid.png) · [51 米全阵](wide.png) · [正式包托管 Metal 的原帧](metal-window.png)

种子 61112，原跟随镜头 22 米，每方 512 名普通兵和 16 名军官，另计玩家。第 43 步主角起枪，第 48 步打中同一名敌兵 #584，生命从 62 降至 39.76。操作者的执枪臂、腰带与短披衣在取景中央连成一套动作。全军改用实物来源的掌指网格，弓手可见勾弦手与弦上箭。按原双手绑定核对九种兵器，近中远档共用材质和相同的命中过程。[各距离的造型退回与修订](STUDIES.md) · [资产和许可](assets-and-licenses.md)

正常缩放时多数士兵向前的肩线仍相似，长枪穿过相邻轮廓，冲车旁尤其明显。阔叶树形已换掉旧折面树，远景中个别树冠仍重复且偏实。普通士兵在中景缺少清楚的腰肩承接，仍有木偶感。美术维持 `ART_REVIEW_REQUIRED`。[实机与商业参考的逐项差距](reference-gap-analysis.md)

## 真实战役与回归

[59.2 秒从军议到回营，带声小体积版](playthrough-review.mp4) · [1280×800 永久原片](playthrough-full.mp4) · [原始记录包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/artifacts/14065591136) · [九套武器、骑乘和整场攻城](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/artifacts/14062713990)

军议、部署、交战、破门、战报与还营均通过窗口操作。第 1030 步占领内庭，我方死亡 257、敌方死亡 308；其余兵员按实际状态结算。主角命中 7 次，发出的军令到达了部队。驻营后前进一小时，重新读档后仍在营中。常规护送第 724 步结算，另一条路线第 630 步先锋先开门，第 632 步仍显示距门 10 米，第 700 步完成护送。两条路线继续驻营均通过，上次 RC14 的 900 秒外层超时保留在旧版记录。另以 20 对 20 走过撤离与主将阵亡两条不同结果。

九武器实际按键、马与战车的上车/动作/下车、双方将领接触/受伤/救援/继任、存档重启均通过。V3 旧档恢复至第 235 步，V4 至第 746 步，与预期状态逐项相同。完整存档检查 1467 项，失败 0。[读档、将领、军令和动作的原始记录](measurements.json)

## 普通游玩速度录像

同一个已校验的 Linux 发行二进制经 17 组实际键鼠输入，录制 1280×800、40.00 秒、24 FPS 的 960 帧和双声道引擎声音。持续计数至第 774 步，6 段合计 2081 次命中，后段随镜头看到城门破开。初次因录制器的绝对 1200 秒上限于第 822 帧中止，当时仍在产出新帧。复测只更改录制端，保留了 115 秒无新帧的卡死检测，两次校验的 Linux 包均为 `5f2b464ed24b36e0dc96f6719c7b8c321c3d7097d9c5b1bfb71b28ceb1510d56`。40 秒影片 SHA-256 为 `e12fa26f0352f0dbf6293eed6a50cff6912c86d783ae0ed65df53a23b6f941d7`。[实际播放文件](combat-normal-speed.mp4) · [镜头序列](export-sequence.jpg) · [首次失败日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/job/132063843905) · [同包复测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43481342797)

## 帧时间、启动与设备

托管 Apple M1 (Virtual) 的 Metal 默认档，每方 512、100% 内部比例、4× MSAA、开启阴影。实测渲染附件 1024×640，窗口 1024×645。24.011 秒收集 1835 帧、1160 次命中，平均 76.42 FPS，P50/P95/P99 为 9.583 / 30.040 / 42.664 毫秒，峰值 130.734 毫秒；455 帧超过 16.67 毫秒，进程最大 RSS 930.4 MiB。原生 GPU 计时没有提供非零时间戳。峰值位于第 333→334 步，可见 446 人，该帧模拟段 124.527 毫秒、呈现脚本 4.287 毫秒。目前证据不能将这 124.527 毫秒归因给具体子程序。[逐帧采样](native-frame-times.json) · [完整原生试验与日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/artifacts/14063707196)

9 次独立的空应用数据启动均进入实际交手，包含兼容后端两次、默认 Metal、主动暂停与返回窗口。系统与驱动缓存保留。首次默认 Metal 的首帧迟至 59.12 秒，第二次为 15.32 秒；耗时波动和此前出现的第 0 步停滞仍值得追查。托管成功只证明本轮样本。真实 MacBook Air M5 的内屏、外接 4K 与超过 20 分钟的千人热稳态尚待实测。

下表为 Ubuntu 24.04、Godot 4.6.3、llvmpipe 软件 OpenGL，1280×800、100% 内部比例、4× MSAA、同一实战种子。每种规模仅取 20 个提交的窗口帧；P99 在这个样本量等于最慢帧。该结果用于跨规模与图形回归。[图形测量原件](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/artifacts/14063772502)

| 每方普通兵 | FPS | P50 ms | P95 ms | P99 ms | RSS MiB | 采样命中数 |
|---:|---:|---:|---:|---:|---:|---:|
| 20 | 3.05 | 332.03 | 346.66 | 347.29 | 962.3 | 33 |
| 100 | 2.12 | 472.75 | 486.71 | 499.07 | 1062.7 | 172 |
| 250 | 1.89 | 519.74 | 555.83 | 560.26 | 1096.6 | 262 |
| 512 | 1.54 | 646.73 | 687.70 | 705.85 | 1156.5 | 288 |

云端复现先行 `./tools/prepare-font.sh`、`godot --headless --editor --path . --import`，继而运行 `./tools/test-field-render.sh footage`、`./tools/test-field-journey.sh` 和 `./tools/test-field-render.sh journey`。原图同机位运行 `./tools/compare-river-art.sh`，原生测量运行 `python3 tools/rc3_native_probe.py package/Luanshi-macOS.zip package/unpacked mac-evidence`。导出包重录使用 [同包验证工作流](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43481342797) 内的校验值、命令和外层时限。
