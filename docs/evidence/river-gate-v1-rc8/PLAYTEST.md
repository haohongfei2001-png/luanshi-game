# 河关 0.16.0-rc.8 · 可玩候选，最终美术未通过

[macOS 安装包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14005925103) · [Linux 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14005441845) · [完整战役实录](playthrough-review.mp4) · [1920×1200 正常游玩全帧](normal-full.jpg) · [RC7 和 RC8：同一步、同一次命中](contact-before-after.jpg)。图像均来自 Godot 窗口，没有后期补画。版本为内部候选，未对外正式发布。

**自审裁决**：弓手的斜肩箭囊、重盾的裙甲与低重心、枪兵的负枪角度和主角的披肩改善了正常镜头的识别度。之前实验把草地做糊、腰袋做得过亮，最终恢复 RC7 的清晰地面、减弱腰袋及披肩边缘。[未采用的第二轮](iteration-2-side-by-side.jpg)。仍未达到约定的国风动画战场观感：成排普通兵的颈肩、体态与脸过于相似，群马背线和冲车轮架转折太硬；门楼切顶后像架子。[门楼背廊实机对照](gallery-rejected.jpg)对整屏改善不足，并未合入。

另一个[冲车弧篷实机对照](ram-study.jpg)在同种子、第 490 步和相同屏内单位下完成。侧前方轮廓更连贯，但护篷遮住了活动悬梁，读起来像普通篷车；试作保留在[独立提交](https://github.com/haohongfei2001-png/luanshi-game/commit/d4075c4141484986ec40dc741fd46f4f50dc09b5)，未装入本包。

## 这一包是谁构建的

游戏 [PR #40](https://github.com/haohongfei2001-png/luanshi-game/pull/40) 的[全部六项检查](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045)成功。游戏提交 `5cf51e2f7ad9e4fe2768e2088b11bdfd0ab4979e`，实际导出提交 `cc9058135598057e9b6477a77fa5b4b8cf0be3c0`，main 合并 `2c92c7eace980d76d538a646ca64ce9817d191b4`。三者的源码树均为 `ba73a5f0ea4d674e4b5ddd23517a5bd7a89f80ff`。[CI 记录和附件索引](raw/delivery.json)。Actions 下载的外层归档解开后，内层 `Luanshi-macOS.zip` SHA-256：`5828c4a9f13349c7a8a30c1a9fcdeab86a82a5485b2544aa3900b296b3a4c878`。解开后打开其中的 `.app`。Linux 内层归档 SHA-256：`8ec501fa11a57ee5af934ad0ff71dd82deec283a12215f0563c997d8864429d7`。

## 在真实游戏中通过

- 跟随视角、镜头大小 22 m、1920×1200、内部 100%，种子 61112。每方 512 名普通兵，另有 32 名军官及主角。第 43 步出枪，目标 584 的血量为 62；第 48 步相距 1.81 m、生命变成 39.76，主角此前也遭到命中。保留[两步坐标与健康值](raw/camera-and-motion.json)与[完整原始 PNG、15 组环场观测、动态对照](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14005802330)。
- 九类武器经图形输入逐一命中。剑、刀、棍、枪、长刀、弓、弩、剑盾、双剑的命中数分别为 3 / 2 / 3 / 3 / 3 / 5 / 3 / 3 / 5。骑马、战车、军令、将领先手/负伤/救援/交接、防卫、护送、撤离、战败均有运行记录。自然攻城第 518 步首次伤门、第 630 步破门，在第 1,000 步持续占据内庭获胜。双方将领各杀敌 7 / 6，发生 6 / 4 次继任；结束时仍有 242 / 214 名普通兵存活。[完整攻城与九武器录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14004559713) · [逐武器与车辆记录](raw/scale-and-combat.json)。
- 另一条自然路线从军议、部署、亲战与军令连到战报和驻营，第 1,030 步结算、主角实际命中 7 次；战后行军时间推进 1 小时、F5/F9、返回军议选择继续，状态一致，菜单语义回退 0 次。59.2 秒、888 帧，带双声道；[1280×800 原声原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14006215827)，上面的 MP4 为等长观看副本（SHA-256 `a91644457b38eca94a496d7d031e9a7e5d3c92519df97da1e877b593578f263f`）。[逐场结果、军令与两条护送](raw/journey.json)。V3/V4 旧档分别推进到 235/746 步，比较无状态差异。[旧档、救援与军籍数据](raw/simulation.json)。
- 以 Godot 4.6.3 在云端实测，运动资产用 `python3 tools/art/check_company_motion.py`、`node tools/art/bake_field_garments.mjs --check` 检验，九武器的烘焙腕部误差最大 0.168 mm，落地承重阶段的最大脚掌漂移 0.765 mm。

## 托管 Mac 与软件渲染器实测

交付归档签名和启动验证在 **Apple M1 (Virtual)，Apple Paravirtual device (Apple5)** 上进行，未使用用户电脑。以新的游戏进程、空游戏数据目录逐次启动，保留系统/驱动缓存；兼容、默认 Metal 与显式焦点控制等共 **9/9**。9 张 PNG 均做实际中央像素检查。首次兼容和默认 Metal 的首次 `post_draw` 分别为 22.97、47.73 秒；不可声称首帧很快。之前 RC7 主线的 7/9 与两种失败[均保留](../river-gate-v1-rc7/NATIVE.md)，[第零步刻意中断与恢复](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43350173727)单列。

默认 Metal 512v512，实际 1024×640、100% 内部分辨率、4× MSAA、阴影开，随战线移镜。24.003 秒、3,640 帧、1,159 次新命中；**151.65 FPS，P50/P95/P99 为 5.44/13.59/17.10 ms，峰值 RSS 545.1 MiB**。GPU 时间戳未返回，模拟脚本、显示更新累积均值分别 1.35 / 3.13 ms/帧。[原生日志、PNG、逐帧时长](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14005242901) · [九次指标和实测像素](raw/native.json)。这只是单台虚拟宿主的一段；不同 M1 宿主负载差异很大。**真实 M5 热稳态 60 FPS：NOT_RUN**。

**同一源码树第二次完整重建：[4/6 项通过](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43355984399)。** 导出、战场录像、连续军旅和视频归档均通过。托管虚拟 M1 的九次原生窗口测试为 **8/9**：首次默认 Metal 只报告引擎和虚拟显卡，75 秒内没有场景就绪、首帧或 PNG，退出 124；第二次默认启动成功。另一次失焦的原生试验通过普通“继续”恢复。第二台宿主的默认千人样本在相同实际 1024×640、100%、4× MSAA 和阴影下，24.015 秒、1,119 帧、1,160 次新命中，**46.60 FPS，P50/P95/P99 14.15/46.67/64.73 ms，RSS 540.4 MiB**。GPU 没有非零时间戳，不能判定是 GPU、引擎、资源还是宿主导致首次超时。另一项失败为 Linux 软件光栅器的长战线录像 660 秒超时；两次第 490 步截图与两个短动作录像已先成功。[全部原始证据索引](raw/main-rebuild.json) · [第二台 Mac 的日志与逐帧记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43355984399/artifacts/14006857234) · [未完成的长战线录像日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43355984399/artifacts/14007425668)。**两次结果并列，不能从较快的机器推断稳定 60 FPS 或冷启动问题已解决。**

Linux llvmpipe 软件光栅器：1280×800、原生比例、4× MSAA、阴影开，每档 20 个图形帧。它检验规模与渲染负载，不代表硬件 GPU 或可玩的帧率。

| 每方普通兵 | 平均 FPS | P50 / P95 / P99 (ms) | RSS | 取样期新命中 |
|---:|---:|---:|---:|---:|
| 20 | 3.51 | 310.47 / 334.61 / 335.14 | 793.1 MiB | 33 |
| 100 | 2.54 | 395.07 / 411.27 / 411.78 | 859.3 MiB | 172 |
| 250 | 2.17 | 455.83 / 486.63 / 493.13 | 891.3 MiB | 262 |
| 512 | 1.76 | 559.28 / 610.19 / 621.32 | 936.8 MiB | 288 |

[四档原始结果](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353033045/artifacts/14004829322) · [长帧分布及未采用的 AI 查询优化](PROFILE.md)。1,024/3,000/5,000/10,000 普通兵另有 24 步 CPU 样本，仅作为压力测试，不是万人实机画面或 60 FPS 证明。当前仍保留逐兵活动对象，全面的分队后端、长期自主世界与人生闭环没有完成。

复现本候选：独立云主机检出上述游戏提交；`./tools/prepare-font.sh` → `godot --headless --editor --path . --import` → `godot --path .` 可玩。图形回归按 `.github/workflows/verify.yml` 的 `./tools/compare-river-art.sh`、四档实录以及实际随军流程执行；构建用 `./tools/export.sh`。在已获授权的托管 macOS 上，对该包运行 `python3 tools/rc3_native_probe.py package/Luanshi-macOS.zip package/unpacked mac-evidence`，再用 `python3 tools/check_playfield.py mac-evidence/*.png`。回退记录：[RC7](../river-gate-v1-rc7/PLAYTEST.md)。
