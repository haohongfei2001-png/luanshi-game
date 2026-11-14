# 《乱世》自主开发状态

## Dot 实际接管与全面重建检查点 · 2026-11-14

Dot 已按 Owner 新授权实际编码、测试和发布隔离源码。Codex Goal/Automation 继续 PAUSED，不得恢复旧 Codex 自动执行指令。最新实际源码、原生画面失败、保护版本、许可证边界和恢复命令见 [Dot 重建检查点](DOT_REBUILD_CHECKPOINT_20261114.md)。下面的原交接状态保留为历史快照，不代表当前在途 CI。正式美术仍未通过，真实 M5 未测。

Owner于2026-11-14暂停Codex开发并转交Dot。[完整交接与恢复入口](DOT_DEVELOPMENT_HANDOFF_20261114.md)。

| 项目 | 当前状态 |
|---|---|
| 研发交接 | Dot接续，Codex停止开发，尚未确认Dot收到或开工 |
| Codex Goal | PAUSED，工具已确认 |
| Codex Automation | automation-2 PAUSED，暂停提示已同步 |
| 子代理 | 全部停止，所有仓库工作已推送 |
| 整体美术 | ART_REBUILD_REQUIRED / OWNER_REJECTED，效果图为最低线 |
| 主候选 | PR59 Draft，d1c1895221c33386d471922807ed590a6987dbe1，RC25 |
| RC25正式验证 | 基础通过，footage/escort失败，其余图形任务收尾中 |
| RC25原生候选 | run43595539334，export通过，native收尾中 |
| 新环境实验 | codex/river-biome-rebuild，2K/4K静帧814417f，尚未自审，输入录像收尾中 |
| 双手枪实验 | 7aaf21be，实拍完成，入步位移与近景遮挡仍未通过 |
| 已完整运行版本 | RC24源4f3c0819，run43587113557，包/115秒2K片/原始数据可用 |
| RC24实时千人2K | M1 Virtual平均27.47FPS，P95 60.954ms，P99 78.508ms |
| 真实M5 | DEVICE_NOT_RUN |
| 下一步归属 | Dot读取交接和GitHub最终运行状态后决定恢复与集成 |

完整分支SHA、失败日志、安装包SHA256、许可、录像和恢复命令见交接文件。所有在途运行状态需在接手时重新读取。
