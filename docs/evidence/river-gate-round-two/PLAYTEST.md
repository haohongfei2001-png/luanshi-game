# 河关 · 第二轮连续试玩记录

候选源码 [77ad69619972975a015fa2890a75d5993e87e68c](https://github.com/haohongfei2001-png/luanshi-game/commit/77ad69619972975a015fa2890a75d5993e87e68c)；[开发 PR #24](https://github.com/haohongfei2001-png/luanshi-game/pull/24) 从 PR #23 接续。[对应云端运行](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43108736632)。源分支、GitHub 为此次 PR 生成的测试合并提交、安装包哈希分别记录在 measured.json 中。

## 可以直接复查的交付物

- [普通入口至战后营地，有游戏原声的录像](journey.mp4)（完整连续 47.200000 秒；708 帧；没有补帧或后配战斗音）。[原尺寸录像与九兵器对照录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43108736632/artifacts/13897110304)。
- [macOS 候选包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43108736632/artifacts/13896157180)（包内 ZIP 的 SHA-256：`3e0c85b00965aa92f76c143564f2205f63b0a9c96d3e7a4a16d0d9d09a2837a9`），[Linux 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43108736632/artifacts/13895318562)，[原始回归和帧时间](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43108736632/artifacts/13895523264)，[原生 macOS 运行记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43108736632/artifacts/13896756115)。这里没有发布正式版或进行 Apple 公证。
- [全尺寸数据摘录](measured.json)，[第一次失败与重测](inspection/first-playthroughs.json)，[部署](01-muster.jpg)、[调阵](02-deploy.jpg)、[城门](03-gate.jpg)、[交战](04-contact.jpg)、[战报](06-report.jpg)、[继续随军](07-camp.jpg)。

## 连续战争与可玩性

原有游戏入口 → 选择弓与全军任务 → 更换本队阵型及前排已有兵种 → 勘察城门 → 开战、疾跑、短按射击、Q、号角 → 自然结算「守军已失去战斗能力」→ 继续原部队、行军、整备一小时、F5/F9 恢复同一军籍和军报 → 重新部署。未改士兵位置、伤害、时钟或结局。输入驱动菜单语义回退 0 次。

512+512 名普通兵之外另有 32 名军官及主角。在此录像中，主角造成 5 次命中，余箭 13，军令送达 1 次。普通兵阵亡双方 218 / 334，撤出 6 / 35；结算后保存、载入、继续结果一致。演示只覆盖这次真实战局，不能当作胜率或平衡依据。

独立出口检验：成功撤离（每方 20，可继续原部队：是）；主将阵亡（每方 20，可继续原部队：否）。另一段原始攻城录像的首次门损在 27.80 秒，破门在 33.20 秒。

九兵器为剑、刀、棍、枪、长刀、弓、弩、剑盾、双剑。每种兵器在独立同距对照里从 GUI 选择、通过指针普攻与 Q；模拟检验 36 个动作窗口（每套普攻及三技）。没有把所有 36 项都称作人工实机体验。骑马与战车分别经真实按键驶动、转向、出招和下乘：horse 移动 6.80 场地单位；cart 移动 4.31 场地单位。城门斜视与局部屋盖避让改善了门前视线（上层平台仍会挡住部分模型），发令后自动收起，已与旧视角的实帧对照。

## 实时性能（录像渲染另进程）

Ubuntu 24.04，Godot 4.6.3，llvmpipe (LLVM 20.1.2, 256 bits)，1280×800，缩放 1、阴影开启。各档在真正出现命中后按墙钟采样，并移动镜头。表内 RSS 是该进程当前常驻，不是显存或机器总内存。

| 每方普通兵 | FPS | 平均 / P95 帧时间 | 进程常驻 | 模拟 / 20 Hz tick | 窗口内命中 |
|---:|---:|---:|---:|---:|---:|
| 20 | 15.7 | 63.6 / 67.5 ms | 341 MiB | 0.56 ms | 53 |
| 100 | 11.6 | 86.4 / 91.0 ms | 367 MiB | 2.74 ms | 203 |
| 250 | 9.1 | 110.4 / 121.8 ms | 376 MiB | 7.52 ms | 338 |
| 512 | 6.0 | 165.4 / 188.3 ms | 392 MiB | 19.03 ms | 349 |

相同 tick、视角与存活编号，末帧可见 601 名普通兵。原双层 LOD 中位 147.94 ms / 302578 图元；本轮三级 125.14 ms / 248568 图元；强制近景参考 432.04 ms / 1386208 图元。主张基于同场景对照，不把不同 CI 宿主间的差异归因于本次修改。

托管 macOS 的导出程序：

| 路径 | 渲染器 | 时长 | FPS | P95 / P99 | 峰值 RSS | 窗口内命中 |
|---|---|---:|---:|---:|---:|---:|
| compat-1 | gl_compatibility | 4.85 秒 | 24.73 | 74.55 / 99.18 ms | 324 MiB | 644 |
| default-metal-1 | mobile | 3.51 秒 | 135.20 | 20.05 / 24.81 ms | 384 MiB | 422 |
| default-metal-2 | mobile | 24.00 秒 | 57.11 | 36.09 / 56.47 ms | 335 MiB | 1246 |
| compat-2 | gl_compatibility | 6.26 秒 | 19.18 | 86.03 / 111.73 ms | 309 MiB | 806 |

以上视口列为程序报告的窗口尺寸。设备标识：Apple M1 (Virtual) / Apple Paravirtual device (Apple5)，1000×600；默认 Metal 巡场各 4 秒窗口的命中与帧数在 measured.json。**真实 MacBook Air M5、持续至少 20 分钟：NOT_RUN。** 云端没有使用用户电脑。

## 同一安装包的三档画质对照

[单机四次巡场](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43112250498)，使用同一个已校验的候选包。每次在真实伤害开始后采样约 24 秒，每四秒记录命中、帧数和可见人数。顺序为清晰 A → 均衡 → 性能 → 清晰 B；这是另一台托管 M1 虚拟机，不能将其结果与前一台主机混为一组。

| 画质 | 窗口 / 内部尺寸估计 | FPS | P95 / P99 | 峰值 RSS | 命中 |
|---|---|---:|---:|---:|---:|
| 清晰 A | 1000×600 / 720×450 | 136.7 | 18.2 / 27.2 ms | 384 MiB | 1252 |
| 均衡 | 1000×600 / 612×383 | 96.8 | 25.6 / 39.1 ms | 335 MiB | 1247 |
| 性能 | 1000×600 / 504×315 | 143.2 | 15.6 / 25.1 ms | 336 MiB | 1248 |
| 清晰 B | 1000×600 / 720×450 | 133.8 | 17.3 / 25.5 ms | 336 MiB | 1252 |

实际缩放和阴影由导出游戏的分段日志核对。内部尺寸是渲染纹理尺寸乘缩放所得，非桌面分辨率，也不是系统 GPU 计数器。性能档的 P95 较好，但仍有超过 16.7 ms 的帧；均衡档在本样本更慢，不能断言降低一个档位总会变快。两台虚拟 M1 的清晰档结果明显不同。原生 Mac 未提供 GPU 独立计时，不能把缺失值当作零。

[比较程序](https://github.com/haohongfei2001-png/luanshi-game/blob/192eb0ba523c52a73c2ce9efbefae888bb732c39/tools/measure-field-presets.py)、[完整帧记录与截图](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43112250498/artifacts/13896702569)、[汇总 JSON](quality-presets.json)。首次补充尝试超过原设进程时间，不记成绩；上述四组是经过启动预热、重新验证的同包结果。

## 复现与剩余范围

在安装了官方 Godot 4.6.3 的 Linux 图形 runner 执行 `./tools/test.sh`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh`；后两者需要 Xvfb、Mesa、ffmpeg，菜单按键验证还需 xdotool。导出和原生 macOS 启动/图形/计时命令均在 [.github/workflows/verify.yml](../../../.github/workflows/verify.yml)。Linux 使用正常场景及固定录像帧率分别采证；计时测试不开录屏、不固定帧率。接战时 CPU/GPU 分位值以实测读数为准。

声音取自游戏实际主混音：AAC 双声道，峰值 -11.2 dB，平均 -32.3 dB。固定帧率、自动操作与波形指标不能替代主观听感或人工手柄/鼠标连续盲测。画面仍是原创程序化低多边形风格；近景不是最终角色美术。胜负和继续均接入本战役；营地允许整备、补粮和行军，不代表完整后续多场战役或长期成长已交付。当前 Linux 千人样本模拟平均 19.03 ms / 20 Hz tick，软件 GPU P95 116.14 ms；门前冲车队仍显拥挤。进一步工作：针对复杂门楼与密集步骑继续测帧，校准近景遮挡、阵列拥挤和长时间手感；真实目标设备需单独获得授权后做规定的持续采集。正式剧情未新增。
