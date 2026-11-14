# 河关 0.16.0-rc.20 试玩记录

[直接下载 macOS Universal ZIP](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/66c8172d8f5a616e525ecaa090c71b2e54a96869/candidate/River-Gate-RC20-macOS.zip) · [游戏源码](https://github.com/haohongfei2001-png/luanshi-game/tree/126091196db530aa7ec13de61f839c9c41cac24b) · [PR #55](https://github.com/haohongfei2001-png/luanshi-game/pull/55) · [七项 CI 与完整日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43517463436)

下载 ZIP 后解压，打开其中的 “Luanshi - Border Skirmish.app”。该包为测试候选，包含 Apple Silicon / Intel 架构；仅托管 Apple Silicon 跑过原生窗口。安装包 SHA-256 为 `742ee0c369b992ed70d31e620488333e1bf962923e0bc38669e3dd74217828ec`。导出检出 `1cb28abbe3013771da2a0d73a698ea0a4d420c5d`，与游戏源码使用相同的 Git 树 `19b3436df3d3f913150e692b11d7a9724e4f53b9`。[导出包与许可校验](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/shipping-packages.json)

## 正常游玩画面

[22 米跟随镜头原始 1920 × 1200 截图](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/normal-camera-before-after/after.png) · [同一击前后对照](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/normal-pair.jpg) · [军阵](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/wide.png) · [托管 Mac 直接截取的 Metal 窗口](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/metal-window.png)

现有战役的 1024 名普通兵均使用服装与角色批次，玩家和 32 名军官另计。靛衣与茜衣各用自己的领袖颜色，皮革、铁与裸手按其本色。弓弩手改戴有带结的软帻，长枪和刀兵用浅檐铁盔，重装有护颊和护颈，军官保留短缨。双方阵列在野战与攻门时均采用这些实体头饰。[头饰四类近照与原速行进](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/headwear/REVIEW.md) · [靛与茜在同一击上的表现](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/dyed-company/REVIEW.md)

过桥时老柳的根沿河岸斜伸，七根主枝上分别配入多面的下垂叶群。近镜头能看见桥面与对岸的前排；前几轮试作分别出现了整冠太亮、从侧面缺枝的问题。前版已落地的关门、裙甲、弓手腕部、倒地与软拥挤方案继续用于本版。[桥上和两岸的固定种子实机对照](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/ford-willows/REVIEW.md) · [打包的资产归属](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/assets-and-licenses.md)

## 战前、交锋、结算与回营

[59.2 秒军议至回营](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/playthrough-full.mp4) · [正式导出包的 40 秒键鼠操作，24 FPS 原速与双声道](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/combat-normal-speed.mp4) · [导出包输入与声音记录](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/export-recording.json) · [九兵器实操](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/player-nine-weapons.mp4) · [攻城全程](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/full-siege.mp4) · [军官和存档回归](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/measurements.json)

固定种子 61112。第 57 步进入第一段交锋，第 642 步破门，第 1030 步结算。两军死亡 257 / 308，另有逃离者 13 / 122。主角命中 7 次。守军余部尚存时，占领内庭已经胜利。随后从军议结果进入营中，行军一小时并恢复存档。另一场护送分别从作战菜单选常规和先锋路线。九种兵器逐一有输入与命中记录，另查骑马、下马和战车。1,467 条存档断言零失败；两份早期格式的战役重载后分别在第 235 / 746 步与原战局相符。[完整战果与回归](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/measurements.json)

## 实战性能和启动

托管 Apple M1 (Virtual) / Apple Paravirtual device (Apple5)，正式 macOS Metal 默认档，实际渲染 1024 × 640，内部比例 100%，4× MSAA 与阴影。连续 24.00 秒、2626 个真实帧、1157 次命中。平均 109.40 FPS，P50 / P95 / P99 为 6.979 / 20.806 / 30.303 毫秒，最长 181.785 毫秒，超 16.67 毫秒 256 帧。进程峰值 RSS 493.0 MiB。[逐帧原始数据](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/native-frame-times.json) · [硬件、GPU 时间戳支持和镜头区间](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/metal-renderer-comparison.json)

每次用新进程和空的 Godot 游戏数据目录独立启动，保留系统与驱动缓存。完成 8 / 9 次。记录涵盖默认 Metal、兼容后端、不同画质、窗口焦点和默认包连续交战。[启动里程碑和日志](https://github.com/haohongfei2001-png/luanshi-game/tree/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/startup) · [RC19 两次冷启动挂在第一帧的现场](https://github.com/haohongfei2001-png/luanshi-game/blob/2db3813aaf94f27cb28dc67af96d76b8a49640d8/docs/evidence/river-gate-v1-rc19/startup/same-package-fresh-host/default-metal-1-before-frame.sample.txt)

Ubuntu 24.04 的 Mesa llvmpipe 用 CPU 进行 OpenGL 渲染。以下各组均在 1280 × 800、100% 内部比例、4× MSAA 和真实部队下记录 20 个图形帧；长片使用的固定回放帧率单独记录。内存是 Godot 静态分配量，与上面 Mac 进程的峰值 RSS 口径不同。

| 每方普通兵 | 平均 FPS | P50 ms | P95 ms | P99 ms | 内存 MiB |
|---:|---:|---:|---:|---:|---:|
| 20 | 2.79 | 363.855 | 373.437 | 374.340 | 64.3 |
| 100 | 1.86 | 533.724 | 556.391 | 560.607 | 65.5 |
| 250 | 1.57 | 635.396 | 658.808 | 659.233 | 67.5 |
| 512 | 1.26 | 791.173 | 831.798 | 831.836 | 70.9 |

首次默认 Metal 启动在 54.82 秒交出第一帧，第二次 10.19 秒。两次都进入实战。刻意切走兼容后端窗口的试验失败，原生助手观测到应用失去前台，Godot 没有记录焦点离开，军士继续行动到第 173 步。七项 CI 六项通过。默认全窗里最长的一帧是 181.785 毫秒，发生在移动镜头后两帧；该帧没有模拟步，视图脚本使用 4.775 毫秒。虚拟 GPU 没有报告有效 GPU 时间，余下耗时未归因。另一台托管 M1 用同一 ZIP 切换 Forward+ Metal，三次启动均进入实战，全窗 P95 24.826、P99 40.286 毫秒，保留现有默认后端。RC19 上的原生着色器烘焙试验在 25 分钟宿主时限到达前没有导出候选。[失败窗口与 Cocoa 日志](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/startup/focus-control-focus.log) · [真实焦点与战斗步](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/startup/focus-control-boot.json) · [同包 Forward+ 的原始数据](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/startup/clustered-metal/renderer-comparison.json) · [RC19 原生导出日志](https://github.com/haohongfei2001-png/luanshi-game/blob/decff89e6c255832318c3981584159f33d0b86b3/docs/evidence/river-gate-v1-rc20/startup/rc19-native-export-study.log)

真实 MacBook Air M5 二十分钟热稳态、外屏 4K 高刷、Intel Mac 图形实跑和最终美术认可均未验收。近景肩袖和手脸的硬折、反向密阵里军官短缨的辨识度，以及营地建筑的层次仍需改进。[前一候选与回退包](https://github.com/haohongfei2001-png/luanshi-game/blob/3735816ace0a861b8e23619f0a320e76f7ec79b3/docs/evidence/river-gate-v1-rc19/PLAYTEST.md)
