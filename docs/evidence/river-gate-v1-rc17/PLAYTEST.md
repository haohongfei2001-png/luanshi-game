# 河关 0.16.0-rc.17 实机记录

[直接下载同一 macOS 应用 ZIP](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/9ea12dfbf647fd7d7888c68bd11e0b10ee790f4c/candidate/River-Gate-RC17-macOS.zip) · [GitHub Actions 构建件](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43493877091/artifacts/14070724176) · [本轮源码](https://github.com/haohongfei2001-png/luanshi-game/tree/280ee8d92e04c5b9394093143f36ea273a611935) · [PR #53](https://github.com/haohongfei2001-png/luanshi-game/pull/53) · [完整工作流](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43493877091)

macOS 内层 ZIP 的 SHA-256 为 `197da1c40fbe176bef27fa8d598fb6ad1388c3f480ba4f167df521169bbfacb0`。从 GitHub Actions 下载时先解开外层。应用包含 arm64/x86_64，托管 Apple Silicon 已实跑，Intel 实机和正式公证未测。游戏源 `280ee8d92e04c5b9394093143f36ea273a611935` 与导出提交 `2e69fb1e6289c91c04e4d5421e46c0a75b30d3b4` 具有相同的代码树 `211a8d087b49c804693b2e8edca25f6f89588085`。Linux 实录使用的压缩包 SHA-256 为 `33409fa94ee9ec3bc0cef8fd3b96879e79d6231f556893842f0f6125b9ad12b7`。[导出包与许可校验](shipping-packages.json)

## 玩家视角

[22 米原始 1920 × 1200 窗口](normal-camera-before-after/after.png) · [前后同一击](normal-pair.jpg) · [起手](normal-camera-before-after/windup.png) · [军阵](wide.png) · [原生 Metal 窗口](metal-window.png)

种子 61112，每方 512 名普通兵、16 名军官，另有玩家。跟随镜头保留 100% 内部比例与 4× MSAA。第 43 步起枪，第 48 步击中敌兵 #584，生命 62→39.76。两次原窗口记录的输入、朝向、兵力与人物相同。

实际军士按武器穿三种成衣、执行持械步态。移除脸颊处重叠的内层皮面，第二次修形恢复眉弓、眼睑和唇线。弓手、将领与主角均用同人同角度核对。按真实鞍、衔和脚点配过的战马在四种毛色下共享奔跑姿势，六处原机位看过步兵保护、骑行和大队行进。原动作、伤亡和骑兵数量沿用正式战役。[弓手侧脸](face/bow-side.jpg) · [军官侧脸](face/officer-side.jpg) · [主角四分之三面](face/hero/hero-quarter.jpg) · [骑阵](remount/formation-22m.jpg) · [骑兵等速对照](remount/mounted-pair.mp4)

在 22 米整窗里，脸部通常只有数个像素。优先看兵种的披肩、袖长、器械和朝向。兵阵里仍有武器杆交叠、同型头盔与近处鼻肩硬折，整张主战画面的军服与地表分离仍有提升空间。[美术审核](artref-verdict.md) · [衣甲、骨架与素材的来源](assets-and-licenses.md)

## 两段实际游戏录像

[59.2 秒从军议到回营](playthrough-full.mp4) · [快速预览](playthrough-review.mp4) · [40 秒键鼠操作正式包、原速、双声道](combat-normal-speed.mp4) · [预览帧](export-sequence.jpg)

第一段通过实际界面部署、交锋、攻门、占据内庭、结算、回营，再验证存档。第 1030 步取胜，双方死亡 257 / 308，玩家命中 7 次，送达军令 1 条，营中经过 1 小时。两条护送各在第 724、700 步完成，第二条由先锋第 630 步率先破门，冲车继续进入门洞。另两种实战结局是“成功撤离”和“主将阵亡”。

第二段为 1280×800，共 960 帧，以 24 FPS 原速回放。Linux 正式导出包接受系统键盘、鼠标和镜头输入，记录至第 774 步，区间共 2081 次命中，最终城门耐久 0。录像 SHA-256 `c6fe12ce93de953b7d33afaca7fb87eeea3357a172bedadbe1e2840a00936cbd`。[六段运行状态与声音](export-recording.json)

九种武器均走过正式输入、命中或耗箭。马和战车完成上下车、行进、转向及技能检测；军官覆盖叫阵、独立交手、负伤、营救、继任和被俘。存档 1467 项、失败 0 项，旧 V3 和 V4 检查点分别续到 235 和 746 步。[逐武器、将领、存档和军令原始记录](measurements.json) · [武器实机窗口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43493877091/artifacts/14072846077)

## 实时帧时间

托管 Apple M1 (Virtual)、Apple Paravirtual device (Apple5)，默认 Metal 实际渲染 1024×640，100% 内部比例、4× MSAA 与阴影。24.001 秒共 2496 帧，1152 次命中；平均 103.99 FPS，P50/P95/P99 6.254 / 25.853 / 37.763 ms，最大 277.573 ms。超过 16.67 ms 的帧数为 308，进程最高常驻内存 479.7 MiB。[全部逐帧时间](native-frame-times.json) · [各次镜头与模拟子段](metal-window-frames.json)

最长帧发生在第 338→339 步，视野内 352 人，模拟 18.929 ms，呈现脚本 4.663 ms。当步耗时最长的模拟段为 `unit_actions_and_density`，15.167 ms。GPU 时间戳状态为 `no_nonzero_device_timestamps`。真实 MacBook Air M5 的持续 60 FPS、外屏与 20 分钟热稳态仍待实测。

Ubuntu 24.04 软件 OpenGL 的四档使用相同 1280×800、100%、4× MSAA。每档 20 个渲染帧，保留每方真实人数、命中及 RSS。其数值主要反映 llvmpipe 软件渲染。[四档实战记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43493877091/artifacts/14072641342)

| 每方普通兵 | 平均 FPS | P50 ms | P95 ms | P99 ms | RSS MiB | 实战命中 |
|---:|---:|---:|---:|---:|---:|---:|
| 20 | 2.69 | 373.09 | 387.40 | 397.70 | 920.1 | 33 |
| 100 | 1.67 | 592.00 | 640.49 | 661.40 | 1021.2 | 172 |
| 250 | 1.38 | 733.79 | 768.59 | 771.07 | 1066.9 | 262 |
| 512 | 1.11 | 904.70 | 972.38 | 985.42 | 1145.8 | 288 |

## macOS 空数据启动

同一签名校验过的导出应用，新进程加空应用目录 9/9 次通过；保留系统/驱动缓存。两次正常默认 Metal 启动的首帧分别是 44.64 秒、7.50 秒。默认/兼容、画质档、焦点中断和原生实战均有各自日志。[本包每次启动的原始记录](startup/) · [渲染器对比汇总](metal-renderer-comparison.json)

前版第一次默认 Metal 启动在 75 秒到期前尚未进入场景，82 次主线程采样落在销毁临时渲染节点后等待编译。此次让场景资源库直接返回网格；保留了旧包失败栈和独立的首步前焦点中断试验。[前版原始采样](https://github.com/haohongfei2001-png/luanshi-game/blob/be32d2d765a3bb05b2b2d918c9602d9bd29ffc29/docs/evidence/river-gate-v1-rc16/startup/default-metal-1-before-scene.sample.txt) · [隔离验证](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43491973680)

## 复现

Godot 4.6.3。运行 `./tools/prepare-font.sh`、`godot --headless --editor --path . --import`，然后 `godot --headless --path . --script tests/model_library_parity.gd` 和 `./tools/compare-river-art.sh` 对照两版。运行 `./tools/test-field-render.sh footage`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh journey`，由 `./tools/export.sh` 产生相同配置的包。托管 macOS 用 `python3 tools/rc3_native_probe.py package/Luanshi-macOS.zip package/unpacked mac-evidence`。正式导出物录像和脚本调用按[候选工作流](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43493877091)复现。
