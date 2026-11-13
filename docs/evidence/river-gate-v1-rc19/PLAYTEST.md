# 河关 0.16.0-rc.19 试玩记录

[直接下载 macOS Universal ZIP](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/2db3813aaf94f27cb28dc67af96d76b8a49640d8/candidate/River-Gate-RC19-macOS.zip) · [游戏源码](https://github.com/haohongfei2001-png/luanshi-game/tree/8ba9daec9b1dbed8717ecef5cfd15ac2e35e0566) · [PR #54](https://github.com/haohongfei2001-png/luanshi-game/pull/54) · [七项 CI 与完整日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43510132831)

下载 ZIP 后解压，打开其中的 “Luanshi - Border Skirmish.app”。该包为测试候选，包含 Apple Silicon / Intel 架构；仅托管 Apple Silicon 跑过原生窗口。安装包 SHA-256 为 `16ee9ef10b0b2ce62fcf49451567b08d2cefe5ab787e26a865e5c1e210bd4491`。导出检出 `9357483bc54c28e0c5d3c04b42dbe5c7e41b4bfd`，与游戏源码使用相同的 Git 树 `a34d6e66c2caf2da27109d99b1724bf4328ffca7`。[导出包与许可校验](shipping-packages.json)

## 正常游玩画面

[22 米跟随镜头原始 1920 × 1200 截图](normal-camera-before-after/after.png) · [同一击前后对照](normal-pair.jpg) · [军阵](wide.png) · [托管 Mac 直接截取的 Metal 窗口](metal-window.png)

两军从原有军议出发，共 1024 名普通兵，另有玩家和军官。种子 61112，100% 内部比例、4× MSAA 与阴影。相同输入在第 43 步起枪、第 48 步命中 #584。原片保留相同目标、相同姿态时刻和实际血量。两军普通兵的袖口与披肩在弓手、枪兵和持盾者身上各不相同。主角半披从肩胛落到腰间。城楼近镜沿建筑屋脊让出玩家，远镜可见完整望楼。驿道的车辙和断续石板继续穿过双方部队。

攻门时发现旧版部分装备的倒地终姿一只靴底进入地面 29.85 厘米，另一只靴尖在地面以上 61.07 厘米。重做九种武器的倒地动作，靴底最低约 −0.3 厘米，脚踝分别约 8.0 / 8.7 厘米。肩、腕和膝在下落时连续衔接，影子沿躯干落点收长。[实际倒地、跟随镜头与逐装备原始量测](fitted-infantry/ground-rest/kits.json) · [等速前后片](fitted-infantry/ground-rest/equal-speed.mp4) · [攻门全窗](fitted-infantry/ground-rest/approach-pair.jpg)

[普通兵行进等速对照](fitted-infantry/equal-speed.mp4) · [林地与门楼六机位](watchhall/REVIEW.md) · [单独美术审核](artref-verdict.md) · [再分发许可](assets-and-licenses.md)

## 战前、交锋、结算与回营

[59.2 秒军议至回营](playthrough-full.mp4) · [正式导出包的 40 秒键鼠操作，24 FPS 原速与双声道](combat-normal-speed.mp4) · [导出包输入与声音记录](export-recording.json) · [九种兵器实操录像](player-nine-weapons.mp4) · [整场攻城录像](full-siege.mp4) · [指挥和存档回归](measurements.json)

在同一场河关军议部署，每边 512 名普通兵，主角和 32 名军官另计。经过门前交锋、破门、占领和战果结算，第 1030 步夺取城内阵地。结算友敌战死 257 / 308，回营休整 1 小时后成功读档继续。两条独立护送、撤离和主角败亡均有回归。旧版 V3 / V4 存档在第 235 / 746 步与原进度完全一致。正式导出包通过 Linux 原生键鼠操作保持带声的正常速度，最终一段确实在城门损毁之后。

## 实战性能和启动

托管 Apple M1 (Virtual) / Apple Paravirtual device (Apple5)，正式 macOS Metal 默认档，实际渲染 1024 × 640，内部比例 100%，4× MSAA 与阴影。连续 24.01 秒、2089 个真实帧、1159 次命中。平均 87.02 FPS，P50 / P95 / P99 为 8.804 / 25.616 / 35.720 毫秒，最长 176.035 毫秒，超 16.67 毫秒 380 帧。进程峰值 RSS 489.4 MiB。[逐帧原始数据](native-frame-times.json) · [硬件、GPU 时间戳支持和镜头区间](metal-renderer-comparison.json)

每次用新进程和空的 Godot 游戏数据目录独立启动，保留系统与驱动缓存。完成 8 / 9 次。首次默认 Metal 在场景准备后、第一张画面提交前超时退出。在另一台干净托管 Mac 上同一 ZIP 再次出现相同失败，第二次启动和人工前后台切换对照成功。失败进程的 88 / 88 个主线程样本停在移动材质的 ShaderRD::_compile_version_end 等待编译工作线程。[同包两次超时后的复现原栈](startup/same-package-fresh-host/default-metal-1-before-frame.sample.txt) · [独立同包三次启动](startup/same-package-fresh-host/renderer-comparison.json)。[启动里程碑和日志](startup/) · [前版首次启动卡住的原始现场](https://github.com/haohongfei2001-png/luanshi-game/blob/be32d2d765a3bb05b2b2d918c9602d9bd29ffc29/docs/evidence/river-gate-v1-rc16/startup/default-metal-1-before-scene.sample.txt)

Ubuntu 24.04 的 Mesa llvmpipe 用 CPU 进行 OpenGL 渲染。以下各组均在 1280 × 800、100% 内部比例、4× MSAA 和真实部队下记录 20 个图形帧；长片使用的固定回放帧率单独记录。内存是 Godot 静态分配量，与上面 Mac 进程的峰值 RSS 口径不同。

| 每方普通兵 | 平均 FPS | P50 ms | P95 ms | P99 ms | 内存 MiB |
|---:|---:|---:|---:|---:|---:|
| 20 | 2.67 | 377.087 | 394.418 | 396.009 | 64.3 |
| 100 | 1.74 | 579.836 | 593.210 | 598.060 | 65.4 |
| 250 | 1.46 | 683.007 | 704.834 | 721.166 | 67.4 |
| 512 | 1.17 | 850.930 | 903.764 | 909.223 | 70.8 |

真实 MacBook Air M5 二十分钟热稳态、外屏 4K 高刷、Intel Mac 图形实跑和最终美术认可均未验收。近景手脸的硬折、军阵中头盔辨识度、桥头柳枝与营地的层次仍需改进。[前一候选与回退包](https://github.com/haohongfei2001-png/luanshi-game/blob/233927d31835bddc96cb42e1fddea3dc50af77d9/docs/evidence/river-gate-v1-rc18/PLAYTEST.md)
