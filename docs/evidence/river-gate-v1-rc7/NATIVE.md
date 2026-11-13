# 原生包的画面

同一只 [RC7 内部 .app](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000466949)，实际在 Apple M1 (Virtual)/Apple5 上起进程、部署 512v512 后由 Godot 截取。并非 Linux 截图调色。以下 JPEG 保留原尺寸，无 AI 增强或插帧。[PNG 原件及逐帧数据](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000910119) · [从已有附件读取的独立核对](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343869369)。

| 实机样本 | 实际附件 | 原 PNG SHA-256 |
|---|---:|---|
| [兼容后端](native-compat-1.jpg) | 960×600 | `8ce91a597684f2c63315861689eb91b89911f478ccd997cdfc49f0aeeda3a23a` |
| [默认 Metal](native-default-metal-1.jpg) | 960×600 | `f02d5aec8ac611ba7e1de9056e3c9d82e7e82a768e0f56b70b5262466111bca2` |
| [默认 Metal 移镜到城门](native-shipping-metal.jpg) | 1024×640 | `b23cc2d8fd03495d43ec48660109113a7e58903ab8a5458f547b0f7e80427fe6` |

兼容与移动渲染的首轮经过相近但不完全相同的实时时钟（窗口命中 400 与 398），只能肉眼对照衣甲和草泥的色值，不可逐像素相减。默认移动渲染的道路、布袍明显较暗；低分辨率的前排武器边线明显。后一张为 24 秒移镜取样，战斗区域不同。真实 MacBook Air M5 未测。

## Metal 同机调色试验（未采用）

我们在两版的第 65 步对照了同 196 名屏内普通兵，候选把衣甲和地表的中间亮度提高；正常阵列画面中央平均 RGB 由 91.26/87.47/66.51 变成 100.81/96.67/73.70。人物和背景同时变亮，近战兵器叠在一起的问题仍在。旧版首次近景回读为黑帧；两个阶段的 Godot 编辑器在托管虚拟 Metal 上出现 fence 超时。该[独立检验](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43344852040)明确失败；没有把改色合进通过冷启测试的安装包，所有失败日志和试验版本仍可复现。

## 实际像素复核 · 最终候选包

从[最终包的同一次九次启动](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343382291/artifacts/14001257614)读取原始 PNG，不重启游戏、不重新截图。[独立复核日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43347842763) · [每张的 SHA-256、尺寸和实测值](raw/window-pixels.json)。九张导出包画面的中央都有图像；默认 Metal 移镜样本为 1024×640，704 个中央采样点的亮度 P10/P90 为 77/120，70 组量化色。编辑器 A/B 的六张图里，旧版首次近景有 704 个零亮度点、0 组可辨色，其余五张有内容。旧检查曾接受过这张黑帧；保留该失败。

复核现有文件：`python3 docs/evidence/river-gate-v1-rc7/check_window.py /path/to/shipping-metal.png`。该脚本只使用 Python 标准库，适用于这里的日间战场，跳过 HUD 周边；均匀/过暗的中央区域会返回非零状态。它不能判断画面好不好、动作是否真实或是否达到目标帧率。

## 合并后的另一台托管 Mac · 两次失败

[主线重建](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43346502411) 5/6 项 CI 成功；[九次原生启动原始日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43346502411/artifacts/14002039551) · [逐项状态与时间](raw/main-rebuild.json)。7/9 成功。首次默认 Metal 进入场景用时 48.47 秒，第 71.67 秒已推进第 100 步、发生 607 次命中；原 75 秒硬截止未给后续采样留够时间，没有最终 PNG。第二次默认 Metal 出战后的首次焦点切换使第零步按游戏规则暂停，重新激活后测试没有按继续。这里不能把后端初始化、焦点暂停和画面回读一概归为一次卡死，也不能删除这些失败。该重建的默认 Metal 24 秒移镜样本另行通过，97.40 FPS，P95/P99 22.62/32.19 ms。以上不替代已交付的不同运行，也不能证明真实 M5。

[定向修复与导出包复测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43350173727)通过两次自然冷启与一次强制重现：另一个 Cocoa 窗口在出战第零步夺取焦点，游戏确实暂停；返回后仅测试操作者按一次正常“继续”，再推进到第 100 步并在录像采样期真实命中 401 次。自然启动均未代按继续。测试把触发首帧、命中、完成接敌等首次进展计入有上限的超时；重复焦点事件不能一直拖长测试。未修改玩家游戏的失焦规则。[三次数据与安装包指纹](raw/native-focus-regression.json)。这不是对原交付包重测，也不是 M5 验收。
