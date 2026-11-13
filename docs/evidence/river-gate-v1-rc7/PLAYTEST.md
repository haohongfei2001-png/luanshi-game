# 河关 0.16.0-rc.7 · 实机证据

**游戏美术仍未达到最终标准。** RC6 的玩法基线保留；RC7 交付可检验的美术返工和真窗口。玩家在默认跟随镜头下能追踪绛披与长枪，步弓手的袖口接到手腕，解弦与手的后收分离。普通兵的肩背、体型和面貌仍有重复，密集处枪头仍会重叠，河岸块石和器械仍显规则。最终审美不以模型数量、代码通过或概念图代替。

- [默认镜头的起手与真实扣血](PERSONAL.md) · [1920×1200 接敌](formation.jpg) · [1920×1200 城门](gate.jpg) · [RC6 / RC7 同时刻接敌](formation-rc6-rc7.jpg)。两套游戏在同一个窗口按种子 61112 重放，15 个镜头逐项比对实际屏内 ID、时间、伤亡、镜头、画质。[无损 PNG 和动态 A/B 原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/13999897275)。
- [完整 512v512 攻城与九武器录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000780863)；[弓手正侧、背侧的 21 个原始镜头](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340490104/artifacts/13999975015)。不靠摆拍，普通兵分别独立受击、倒地、溃逃；动作演示夹具与正常部署录像分别保存。
- [已做 9 次原生冷启的 macOS 内部候选](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000466949) · [Linux 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/13999852645) · [全部源码、导出与测试日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060)。解开 Actions 外层 ZIP，再解开里面的 `Luanshi-macOS.zip`。游戏提交 `cb85d58318b1379127a2465816a3917f79298090` 和实际导出 `14d2d73af3a0bf0a599c9f7743b5c4bdbab1bac6` 的 Git 树相同，内层 Mac ZIP SHA-256 为 `50d52811595a6416e3e26fe900513279e1c5cd5500b5c197d963b3ccddd128ff`。
- [完整原始数字](measurements.json) · [托管 Mac 每次启动、截图与帧采样](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000910119)。

## 审过并改过什么

第一轮把草甸和车道投射到真实三维地形，重建榆树的弯折枝叶与河坎。[第一轮实机](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43337847031) 的道路过橙、柳枝像垂布，近看重兵的护胸像横箍；我们没有把这一轮作为成品。下一轮重校原生光照下的泥土颜色，用分片札甲和偏肩绛披重塑人物。第三轮原生导入曾因局部变量顺序失败，[失败](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340127706) 和[修好后的同镜头](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340367719) 均保留。此后将浅岩边缘埋入草皮，恢复柳冠上层，补修肩袖与弓弦。[最终固定机位复审](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43340843876)。

九类武器的图形输入均造成了实际伤害。马和战车经过上乘、驾驶、转向、动作和下乘。自然攻城第 630 步破门、第 1000 步持续占领内庭结算，普通兵存活 242 / 214。双方将领各造成 7 / 6 次击杀，发生 6 / 4 次指挥继任。V3、V4 旧存档推进到第 235、746 步，比较结果无差异。全长 34 秒、30 Hz 的随军战线镜头包含 8 次玩家攻击输入、7 次主角实际命中；15 个镜头、输入时刻、场内士兵数和旧版照常核对。

## 可比的测量与失败

默认清晰档，托管 Apple M1 (Virtual) / Paravirtual Apple5，实际 1024×640、内部比例 100%、4× MSAA、阴影开启。24.00 秒、512v512、快速移镜及新增 1,124 次命中：平均 154.23 FPS，P50/P95/P99 **4.45 / 14.47 / 35.94 ms**，最大驻留 **540.1 MiB**。游戏数据清空并重起进程共 9/9 次取得首帧、第一击及实战窗口；不清系统驱动缓存。首次 Metal 首帧 31.07 s，首次兼容后端首帧 14.78 s。平均帧率不代表长帧已解决，也不是无风扇机器的持续热态样本；GPU 时间戳未提供。真 MacBook Air M5：**NOT_RUN**。

以下为 Linux 软件光栅器在 1280×800 清晰档、移镜、真实攻击下的短样本，不能当成 Mac GPU 帧率。P95 超过了 60 FPS 所需的 16.67 ms。

| 每方普通兵 | 平均 FPS | P50 / P95 / P99 (ms) | 最大驻留 (MiB) |
|---:|---:|---:|---:|
| 20 | 4.76 | 201.06 / 264.17 / 264.90 | 735.0 |
| 100 | 3.29 | 306.06 / 318.04 / 319.87 | 858.2 |
| 250 | 2.79 | 354.84 / 387.70 / 388.82 | 880.2 |
| 512 | 2.34 | 426.80 / 450.44 / 467.47 | 929.8 |

1,024、3,000、5,000、10,000 名普通兵的 24 步 CPU/军籍短测保存在 JSON 内。已有分队与装备批次，近战仍保留每名普通兵的活动对象；四档不是万人的实时帧率认证。外接显示器和 M5 热稳态均未测。

首次全程随军电影在第 1030 步已开战报，Linux 软件渲染后超出旧 550 s 时限而中断；这次运行的驻营、F5/F9 和继续按钮**未通过这条录制**。[保留的失败](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/job/131609950084)。录制驱动保留 15 帧/秒、原始分辨率、全部模拟步与操作，用实际进度设独立的空闲时限及总时限；[完整回归入口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291)。

在有 Godot 4.6.3、Xvfb、FFmpeg、Python/Node 的 Linux 云端检出 `dbae207abe51a305d2b9f392383dc00d016531cd`，执行 `./tools/prepare-font.sh`、`./tools/compare-river-art.sh`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh journey`。其他验证入口与逐步环境由本版本工作流记录。
