# 《乱世》 Codex 自主开发续接状态

> OWNER-AUTONOMOUS-20261114：此文件为跨会话的**可更新状态表**，不是新的规划文档。每次实际开发运行都应更新并链接真实 SHA/PR/截图/日志。未知不得填 PASS。最高执行协议：[CODEX_AUTONOMOUS_DEVELOPMENT_PROTOCOL_20261114.md](CODEX_AUTONOMOUS_DEVELOPMENT_PROTOCOL_20261114.md)。

| 字段 | 初始已知状态（2026-11-14 指令创建时） |
|---|---|
| 当前事实起点 | README 记载河关 RC13 为试玩候选；真实源码和分支以**每轮最新 main/PR/CI 为准**，请先读和同步 |
| 艺术质量 | ART_REVIEW_REQUIRED；Owner 之前否定粗糙画面。旧 RC3/RC13 不能作为已认可的画质底座 |
| 商业参考 | ARTREF-01～12 和八游戏对标规范已写入；对标实现仍待逐项实测 |
| 当前 P0 | 真正高质量可玩角色/普通兵/持械动画 + 城门/河岸统一美术，替换近景粗糙程序化视觉基础 |
| 素材状态 | Fab/Unity 付费素材只是候选，NOT_ACQUIRED；使用前须授权、格式、可移植性评估。已有原创/CC0 环境素材可以合法使用 |
| 真实 M5 性能 | DEVICE_NOT_RUN，不能用托管 M1 Virtual 的数据标达标 |
| Codex Goal | NOT_CONFIGURED_OR_UNVERIFIED；下一次 Codex 执行应设置或检查 |
| Codex Automation | NOT_CONFIGURED_OR_UNVERIFIED；应设置现有订阅内的定时续接并验证；不可虚报已安排 |
| 权威总任务 | [Issue #12](https://github.com/haohongfei2001-png/luanshi-game/issues/12) |
| 最新已验证游戏改动 SHA | 本文件创建不代表已改游戏；请 Codex 在实际下一轮后填写 |
| 最新可检查正常镜头与视频 | [RC13 正常镜头](evidence/river-gate-v1-rc13/normal-native.jpg) · [RC13 PLAYTEST](evidence/river-gate-v1-rc13/PLAYTEST.md) |
| 下一件具体工作 | 检查最新 main/未合并 PR，选一个真正可合法导入的高质量角色/装备/城门资源，**动手实现** Godot 近景模型/材质/动画替换及可复用导入路径；拍真实默认/近/中/远游戏画面，运行战斗与回归测试，并提交 PR |
| 禁止阻塞循环 | 无付费资源/无 M5/无法启动 Automation 时，记录 blocker，继续合法免费资产与真实可运行代码开发；不要交纯调研报告后退出 |

**Codex 更新纪律**：每轮保留此表的概括性字段，覆盖为实际最新的状态；实际测试用例链接放 docs/evidence/<candidate>/，真实代码/构建细节放 CODEX_CONTINUATION.md，不要在本文件堆积复制的长日志。提交时将本文的初始占位替换为本轮验证事实。不要把一次技术成功写成 Owner ART APPROVED。
