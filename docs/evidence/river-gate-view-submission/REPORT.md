# 同画质渲染提交实验

在同一台 GitHub 托管 Ubuntu 24.04 运行器上，以 Godot 4.6.3 启动河关游戏窗口。每方 512 名普通兵，推荐画质，1280×800，100% 内部渲染比例，开启阴影。对照源码为 `22d5c85abf18296c0d299075f68e287102b004e7`，仅提交显示脚本的候选为 `f8ba442e25a7795b54d082234a7cac2ed37454f0`。候选重复使用角色朝向，简化脚下阴影缓冲区，仅在数量改变时向渲染器提交批次数量。

| 场景 | 显示脚本 P50，ms | 显示脚本 P95，ms | 整帧 P95，ms | 每帧可见普通兵中位数 |
|---|---:|---:|---:|---:|
| 固定近景 | 5.085 → 4.805 | 5.446 → 5.062 | 297.671 → 295.068 | 392 |
| 近线至城门巡场 | 5.549 → 5.171 | 6.670 → 6.337 | 233.669 → 233.101 | 453 |

A0→B0、B1→A1 两组交叉测试，每种源码在每个场景有 258 个计时样本。四次配对里显示脚本 P95 均下降，幅度分别为近景 5.4% / 8.1%，巡场 5.9% / 3.5%。巡场整帧 P95 在两组独立配对上分别增加 0.217 和 2.160 ms，合并分位数轻微下降。结论限于显示 CPU 的改善，整帧巡场改善尚未证实。此数据来自 Linux 软件渲染器，M5 Air 仍需实测。

在近景和巡场分别选取三个相同模拟时间，全军正常可见。每个时间点在四次运行中，实际画面 RGBA、显示中的变换与装备姿态、可见批次、全量存档、命中及伤亡完全相同。四次正常运行均未出现脚本或渲染错误。

[运行和完整命令](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43286228399) · [原始逐帧数据、运行日志、12 张正常截图](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43286228399/artifacts/13975496371) · [各次统计及画面对照结果](comparison.json)。Actions 原始包 SHA-256 为 `ad5abedba475ac83f9f40b9db7f1e54efe6d596fa7a53d41399d2b4ffd7e7f16`，到期日为 2026-12-27 UTC。

在已安装同一 Godot 4.6.3、Xvfb 的 Linux 云端完整克隆中复现：

```sh
git switch --detach 0a61c2001e67a38f1bd0b3638618ab9cfb85684b
./tools/prepare-font.sh
godot --headless --editor --import --path .
VIEW_OUT=/tmp/river-view-results VIEW_PIXELS=/tmp/river-view-raw LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s '-screen 0 1440x900x24' python3 tools/view_submission_trial.py
```
