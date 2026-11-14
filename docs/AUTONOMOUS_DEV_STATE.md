# 《乱世》 Codex 自主开发续接状态

> OWNER-AUTONOMOUS-20261114：此文件为跨会话的**可更新状态表**，不是新的规划文档。每次实际开发运行都应更新并链接真实 SHA/PR/截图/日志。未知不得填 PASS。最高执行协议：[CODEX_AUTONOMOUS_DEVELOPMENT_PROTOCOL_20261114.md](CODEX_AUTONOMOUS_DEVELOPMENT_PROTOCOL_20261114.md)。

| 字段 | 最近一次实机核对（2026-11-14，RC22） |
|---|---|
| 当前事实起点 | RC22 正常菜单「全军 → 桥头攻门」可玩。[游戏 PR #56](https://github.com/haohongfei2001-png/luanshi-game/pull/56) |
| 艺术质量 | ART_REVIEW_REQUIRED。枪盾各有承重与回复。骑兵在桥东合拢时仍会挡住后排枪锋。 |
| 商业参考 | [本轮实际视觉差距](evidence/river-gate-v1-rc22/reference-gap-analysis.md) · [ARTREF 实机记录](evidence/river-gate-v1-rc22/artref-verdict.md) |
| 当前 P0 | 保持 22 米正常机位，改善骑兵出口队形与普通兵动作读法。 |
| 素材状态 | 0 A.D. 桥架、门楼、衣甲、马和柳树，MakeHuman 手脸与 Quaternius 步态。包中附原始许可和改制来源。[素材归属](evidence/river-gate-v1-rc22/assets-and-licenses.md) |
| 真实 M5 性能 | DEVICE_NOT_RUN。托管 M1 桥头 P95 30.663 毫秒，P99 62.157 毫秒。 |
| Codex Goal | NOT_CONFIGURED_OR_UNVERIFIED；下一次 Codex 执行应设置或检查 |
| Codex Automation | NOT_CONFIGURED_OR_UNVERIFIED；应设置现有订阅内的定时续接并验证；不可虚报已安排 |
| 权威总任务 | [Issue #12](https://github.com/haohongfei2001-png/luanshi-game/issues/12) |
| 最新已验证游戏改动 SHA | `dc9805fd2930344be9737cfc19074442618d7e5c`，实机包导出 `34b5af8db16793566df89139ccdd783ad7d6b723`。[正式 CI 六项通过，一项首次 Metal 启动失败](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43538171412)。 |
| 最新可检查正常镜头与视频 | [原像素等速录像](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/c6fc9d564244eaca4c9c40ba9b3bf3a7e207312d/docs/evidence/river-gate-v1-rc22/bridgehead/river-gate-bridgehead.mp4) · [Mac 窗口原片](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/fd411e7e6e1209d5d3b1ea84e05005771735e35e/docs/evidence/river-gate-v1-rc22/native-bridgehead/hosted-bridgehead.mp4) |
| 下一件具体工作 | 复现固定种子第 135 步，改善桥头骑兵与后排枪兵轮廓，跟踪首帧着色器编译。实测细节和下一条可执行命令见 [续接记录](CODEX_CONTINUATION.md)。 |
| 禁止阻塞循环 | 无付费资源/无 M5/无法启动 Automation 时，记录 blocker，继续合法免费资产与真实可运行代码开发；不要交纯调研报告后退出 |

**Codex 更新纪律**：每轮保留此表的概括性字段，覆盖为实际最新的状态；实际测试用例链接放 docs/evidence/<candidate>/，真实代码/构建细节放 CODEX_CONTINUATION.md，不要在本文件堆积复制的长日志。提交时将本文的初始占位替换为本轮验证事实。不要把一次技术成功写成 Owner ART APPROVED。
