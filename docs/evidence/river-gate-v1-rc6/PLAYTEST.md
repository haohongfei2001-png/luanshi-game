# 河关 0.16.0-rc.6 实机验收

以正常游戏入口完成军议、交战、战后结算、驻营、行军和读档。人物美术在 1920×1200 的固定游玩镜头下逐版审看。当前仍需解决密集近战中的手与武器辨识，以及千人战场的长帧。

## 候选包与可复核画面

解开 Actions 下载的外层归档，再解开内层 `Luanshi-macOS.zip`，其中是游戏 .app。检查了 Apple Silicon 与 Intel 两种架构。托管 macOS 验证 .app 签名并连续九次从空游戏数据启动。本包为开发候选。

主线已合入同一棵受测源码树。源码 `d6b03507c4ace8582ab9f821e604c499616b8dab`，本页原图及候选校验值取自游戏 PR 的受测构建。 [主线回归](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519)

- [macOS 候选](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275/artifacts/13993090816) · [Linux 候选](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275/artifacts/13993355482) · [六项 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275)

- 游戏 PR 源码 `89416f926e725d93d0ef86138dcbf333b9211576`，实际导出源码 `b067e79cce519a9cdf1abf3b3ff5acb080b38698`。 [源码树](https://github.com/haohongfei2001-png/luanshi-game/commit/89416f926e725d93d0ef86138dcbf333b9211576) · [游戏 PR #36](https://github.com/haohongfei2001-png/luanshi-game/pull/36)

- 内层 macOS ZIP SHA-256 为 `d3a0d5f73d0f65abaac77c96e1c43e3d1a342137f2a1ceb48d7a1f1a30a7396d`。

- [原长随军录像，H.264 带双声道](playthrough-review.mp4) · [原尺寸原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275/artifacts/13992244385) · [完整攻城和九种武器录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275/artifacts/13992662840)

- [主角持枪出招](player-action.jpg) · [接敌阵型](formation.jpg) · [门楼](gate.jpg) · [RC5 与 RC6 同机位对照](rc5-rc6-same-camera.jpg) · [其余配对、近景与运动原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275/artifacts/13992733283)

- 全部数值、原始证据索引和逐项判定见 [measurements.json](measurements.json)。

## 主线重建与独立冷启复核

主线 `d6b03507c4ace8582ab9f821e604c499616b8dab` 重新导出同一游戏树。内层 macOS ZIP 的 SHA-256 为 `092e015b1776ba3b1ebf0d00907f133b70fdd7f340b9bba5e0a35a7714841d72`。 [主线 macOS 候选](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519/artifacts/13992554882) · [整场录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519/artifacts/13994326634) · [完整攻城](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519/artifacts/13992754791)

主线首次运行五项作业通过，原生 Mac 作业失败。这个包通过双架构、签名、存读档与无图形运行校验。九次空游戏数据图形启动中八次进入实战。首次默认 Metal 启动在 75 秒上限前仅输出引擎版本和 Apple Paravirtual 设备，没有 `scene_ready`、首帧、游戏步骤或报错栈。兼容后端的第一次启动成功。同包后续启动的结果单独记录。 [首次失败日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519/job/131567490905) · [原生输出与截图](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43327368519/artifacts/13993638955)

主线包默认清晰档 512v512、实际 1024×640、4× MSAA、阴影。在 3328 帧和 24.0 秒的接敌与移镜窗口，平均 138.66 FPS，P50 / P95 / P99 为 5.87 / 14.77 / 20.61 ms，峰值 RSS 575.0 MiB，取到 1159 次新命中。云端 Metal GPU 时间戳未提供有效样本。

在另一台全新托管 Mac 上，对相同内层 ZIP 以相同的 75 秒时限独立运行九次，9 次进战。第一次默认 Metal 首帧 56.8 秒。在第 45 秒采集的线程栈中，Godot 正等待移动渲染器的阴影绘制任务，Metal 编译请求线程同时工作。第一次超时没有留下调用栈，确切原因仍未确认。 [同包完整复核及调用栈](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43330059050/job/131572221262)

已在独立分支启动 macOS 原生着色器烘焙实验，先验证 PCK 内的实际数据，再由另一台托管机启动。 [独立实验](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43331468765)

## 实际游玩

- 固定种子 `61112`，玩家可在军议屏开始战争或继续现有快存。通过普通输入瞄准、出招、下令，夺城后进入战报和营地，再行军、保存、读回。录像包含 888 帧，共 59.2 秒。图形流程实际触发 F5/F9 和战前的继续按钮。音轨为双声道 AAC。

- 独立攻城录像出动 512 对 512 名普通兵，另计玩家及 32 名军官。城门在第 630 步突破，第 1000 步由「夺取城内阵地」结算，双方普通兵尚余 242 / 214。常规护送和先锋先破门两条路线均经可见界面完成。

- 剑、刀、棍、枪、长刀、弓、弩、剑盾、双剑的普攻、技能及相机转向后的选点经过图形输入回归。九种武器各自命中数为 3 / 2 / 3 / 3 / 3 / 5 / 3 / 3 / 5。近身瞄准分别检查四个相机方位，最大实机躯干选点误差为 0。马和战车均实测驾驶、转向、使用技能与离乘。

- 双方军官各自造成伤害，护卫救援、指挥继任与战后俘虏分别有独立用例。城门实战中双方军官击杀 7 / 6，继任 6 / 4。主动撤离、主角战败和驻营后继续分别记录。较旧 V3、V4 存档按原输入推进至第 235 和 746 步，逐项差异为零。

## 美术自审

六类衣甲、九种武器、部队、将领与战马均使用战场实际骨架与动画。披膊、布衬、头巾和后领拟合既有动作，树冠改为错落的扁平叶群。铁札取冷灰，战袍与军旗保留靛蓝和赭红，盾木用暖褐。实机正常视角经十五处对照，逐一核对时刻、单位标识与战况。成片保留原生缩放和 4× MSAA。头脸沿用 CC0 的 MakeHuman HM08，衣甲、武器、新附件和贴图由项目制作。 [素材说明](../../../assets/river_gate/figures/SOURCE.md)

镜头下仍需判断簇拥时前排手臂与兵刃的分离程度。六类衣甲共享基础人体，轮廓和动作尚有相似；这版作为可回退的视觉基线。

## 实战负载与冷启动

- 托管 macOS，Apple M1 (Virtual)，Apple Paravirtual device (Apple5)。默认清晰档实际附件 1024×640、内部缩放 1、4× MSAA、阴影开启。24.0 秒、4989 帧、期间新命中 1125。平均 207.8 FPS，P50 / P95 / P99 为 4.06 / 11.45 / 13.56 ms，进程峰值 RSS 576.7 MiB。原始逐帧及分段文件在 [macOS 验证归档](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43323872275/artifacts/13993475538)。

- 同一宿主共 9 次新进程，启动前游戏数据为空，系统与显卡缓存保留。9 次取得首帧、进入交战、记录命中并校验 PNG 与原始分段的实际像素。第一次兼容后端首帧 13.8 秒，第一次默认 Metal 为 30.9 秒。该样本仍有首帧等待。真实 MacBook Air M5 为 **NOT_RUN**。

Linux 云端软件光栅、实战窗口的四档数据如下。各机测量负载及采样方法详见 JSON。

| 每方普通兵 | 实绘窗口 | 平均 FPS | P50 / P95 / P99（ms） | 峰值 RSS（MiB） |
|---:|---|---:|---|---:|
| 20 | 1280×800 | 3.81 | 263.11 / 282.80 / 283.99 | 684.0 |
| 100 | 1280×800 | 2.44 | 410.66 / 428.34 / 431.05 | 799.8 |
| 250 | 1280×800 | 2.12 | 471.01 / 494.00 / 498.46 | 815.6 |
| 512 | 1280×800 | 1.69 | 596.67 / 632.89 / 637.02 | 865.1 |

前一轮独立托管 M1 的默认 24 秒窗口为 83.2 FPS，P50 / P95 / P99 分别为 8.10 / 28.59 / 45.36 ms。不同宿主波动明显，可归因的计算收益参见下面同机成对测试。 [上一阶段记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43319055162)

空间查询在同一 Linux 宿主交替运行前后版本。每档含五次完整的目标和分离向量记录，核对命中及整个存档。以下给出所有活动单位的一次目标查询中位数，以及单次完整模拟步 P95。

| 普通兵合计 | 查询改前 / 改后（ms） | 整步改前 / 改后 P95（ms） |
|---:|---:|---:|
| 1024 | 24.52 / 18.03 | 15.13 / 14.29 |
| 5000 | 131.38 / 82.20 | 89.15 / 80.06 |

出征与结算按队伍和武器归账，活动士兵仍保留独立身份、状态和伤亡。下列四档是各 24 个实际初始步的无图形应力样本，不能外推全程攻城帧率。

| 普通兵合计 | 实际角色数 | 旧逐人记录 / 分队军籍（字节） | 模拟步 P95（ms） |
|---:|---:|---:|---:|
| 1024 | 1057 | 106512 / 5832 | 13.78 |
| 3000 | 3095 | 311800 / 16496 | 46.65 |
| 5000 | 5159 | 519704 / 27504 | 85.88 |
| 10000 | 10315 | 1039056 / 54336 | 254.36 |

## 复现

在有图形显示器、Godot 4.6.3、Xvfb、FFmpeg、Python 3 和 Node 的 Linux 云端，取回包含历史对照提交的完整仓库。以下命令对应源码回归、军事编成、同机查询对照、逐镜头对照及两套图形流程。

```sh
git fetch origin main
git switch --detach 89416f926e725d93d0ef86138dcbf333b9211576
./tools/prepare-font.sh
./tools/test.sh
python3 tools/compare-river-targets.py
godot --headless --path . --script tests/field_cohort_muster.gd
./tools/compare-river-art.sh
./tools/test-field-journey.sh
./tools/test-field-render.sh
```

每次原生启动的完整命令、操作系统和实际证据见同一构建的 macos-runtime 作业。高清人物、实战包与图形性能应始终使用相应源码和种子复核。
