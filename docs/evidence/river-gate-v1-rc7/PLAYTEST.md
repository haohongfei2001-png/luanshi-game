# 河关 0.16.0-rc.7 · 实机证据

**游戏美术仍未达到最终标准。** RC6 的玩法基线保留；RC7 交付可检验的美术返工和真窗口。玩家在默认跟随镜头下能追踪绛披与长枪，步弓手的袖口接到手腕，解弦与手的后收分离。普通兵的肩背、体型和面貌仍有重复，密集处枪头仍会重叠，河岸块石和器械仍显规则。最终审美不以模型数量、代码通过或概念图代替。

- [默认镜头的起手与真实扣血](PERSONAL.md) · [1920×1200 接敌](formation.jpg) · [1920×1200 城门](gate.jpg) · [RC6 / RC7 同时刻接敌](formation-rc6-rc7.jpg)。两套游戏在同一个窗口按种子 61112 重放，15 个镜头逐项比对实际屏内 ID、时间、伤亡、镜头、画质。[无损 PNG 和动态 A/B 原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/13999897275)。
- [完整 512v512 攻城与九武器录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000780863)；[弓手正侧、背侧的 21 个原始镜头](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340490104/artifacts/13999975015)。不靠摆拍，普通兵分别独立受击、倒地、溃逃；动作演示夹具与正常部署录像分别保存。
## 最终交付包 · 录制修复后的重建

[macOS 下载](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14001017125) · [Linux 下载](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14001545329) · [完整录像：千人攻城／九种武器](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14001586116) · [原始 PNG／同步动态对照](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14002015521) · [Mac 包直接输出](NATIVE.md)。

游戏分支提交 `dbae207abe51a305d2b9f392383dc00d016531cd`；导出源码 `4b9557b6d811880dffb9e6dc28d4531b27fd3456`；共同 Git 树 `24a9bec3ce2e4475abf1497b2e3c17c9cfa24b31`。Actions 下载的外层归档解压后，校验 **内层** `Luanshi-macOS.zip`：`2758b370eb60d848eaa6b4c026337d5eb29fe54838d8302ab03c8aa115cc2a44`。Mac 上可用 `shasum -a 256 Luanshi-macOS.zip`。托管 macOS 26.7.2 检查了 .app 的签名、可执行文件、持久化与实际图形启动。这是内部游戏候选，没有对外正式发布。

**最终包不是稳定 60 FPS。** 第二台托管 Apple M1 (Virtual)，Apple Paravirtual Apple5，实际附件 1024×640，画质 100%、4× MSAA、阴影开启，24.01 秒共 2,333 帧，接敌和移镜时新命中 1,124 次。平均 **97.18 FPS**，P50/P95/P99 **7.29 / 24.34 / 36.10 ms**，峰值 RSS **539.5 MiB**。空游戏数据启动 9/9 通过，首次兼容后端／Metal 首帧为 20.11 / 40.06 秒。不清理操作系统或驱动缓存，真实 M5 的可持续帧率、外接显示器和热稳态均未验证。[这份包的原生日志与图](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14001257614)。下方较快数字来自上一个不可变构建，不以它替代此包。

[带进度保护的完整随军复测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43342950441/artifacts/14000703565) 记录到第 1030 步打开战报，之后由按钮驻营、行军、等待一小时、F5/F9 以及再次从军议继续成功。输入菜单回退为 0，原视频 888 帧、59.2 秒、双声道，两条护送路线均通过。用进度判断的测试工具也验证了“反复打印同一 tick”确实超时退出。

最终重建在 Linux llvmpipe 原生 1280×800、4× MSAA、阴影下每方 20 / 100 / 250 / 512 人的 P95 为 **236.90 / 361.92 / 431.27 / 538.67 ms**；对应 P99 为 238.51 / 362.63 / 431.83 / 543.72 ms，RSS 为 736.0 / 857.2 / 880.2 / 931.3 MiB。它是 CPU 软件光栅器数据，不能证明物理 Mac 的帧率。[原始四档数据](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14001461458)。

## 审过并改过什么

第一轮把草甸和车道投射到真实三维地形，重建榆树的弯折枝叶与河坎。[第一轮实机](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43337847031) 的道路过橙、柳枝像垂布，近看重兵的护胸像横箍；我们没有把这一轮作为成品。下一轮重校原生光照下的泥土颜色，用分片札甲和偏肩绛披重塑人物。第三轮原生导入曾因局部变量顺序失败，[失败](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340127706) 和[修好后的同镜头](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340367719) 均保留。此后将浅岩边缘埋入草皮，恢复柳冠上层，补修肩袖与弓弦。[最终固定机位复审](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340843876)。

九类武器的图形输入均造成了实际伤害。马和战车经过上乘、驾驶、转向、动作和下乘。自然攻城第 630 步破门、第 1000 步持续占领内庭结算，普通兵存活 242 / 214。双方将领各造成 7 / 6 次击杀，发生 6 / 4 次指挥继任。V3、V4 旧存档推进到第 235、746 步，比较结果无差异。全长 34 秒、30 Hz 的随军战线镜头包含 8 次玩家攻击输入、7 次主角实际命中；15 个镜头、输入时刻、场内士兵数和旧版照常核对。

## 首次导出样本与失败记录

默认清晰档，托管 Apple M1 (Virtual) / Paravirtual Apple5，实际 1024×640、内部比例 100%、4× MSAA、阴影开启。24.00 秒、512v512、快速移镜及新增 1,124 次命中：平均 154.23 FPS，P50/P95/P99 **4.45 / 14.47 / 35.94 ms**，最大驻留 **540.1 MiB**。游戏数据清空并重起进程共 9/9 次取得首帧、第一击及实战窗口；不清系统驱动缓存。首次 Metal 首帧 31.07 s，首次兼容后端首帧 14.78 s。平均帧率不代表长帧已解决，也不是无风扇机器的持续热态样本；GPU 时间戳未提供。真 MacBook Air M5：**NOT_RUN**。

以下为 Linux 软件光栅器在 1280×800 清晰档、移镜、真实攻击下的短样本，不能当成 Mac GPU 帧率。P95 超过了 60 FPS 所需的 16.67 ms。

| 每方普通兵 | 平均 FPS | P50 / P95 / P99 (ms) | 最大驻留 (MiB) |
|---:|---:|---:|---:|
| 20 | 4.76 | 201.06 / 264.17 / 264.90 | 735.0 |
| 100 | 3.29 | 306.06 / 318.04 / 319.87 | 858.2 |
| 250 | 2.79 | 354.84 / 387.70 / 388.82 | 880.2 |
| 512 | 2.34 | 426.80 / 450.44 / 467.47 | 929.8 |

1,024、3,000、5,000、10,000 名普通兵的 24 步 CPU/军籍短测保存在 JSON 内。已有分队与装备批次，近战仍保留每名普通兵的活动对象；四档不是万人的实时帧率认证。外接显示器和 M5 热稳态均未测。

重录前，首次全程随军电影在第 1030 步已开战报，Linux 软件渲染后超出旧 550 s 时限而中断；这次运行的驻营、F5/F9 和继续按钮**未通过这条录制**。[保留的失败](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/job/131609950084)。录制驱动保留 15 帧/秒、原始分辨率、全部模拟步与操作，用实际进度设独立的空闲时限及总时限；[完整回归入口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291)。

在有 Godot 4.6.3、Xvfb、FFmpeg、Python/Node 的 Linux 云端检出 `dbae207abe51a305d2b9f392383dc00d016531cd`，执行 `./tools/prepare-font.sh`、`./tools/compare-river-art.sh`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh journey`。其他验证入口与逐步环境由本版本工作流记录。
