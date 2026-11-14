# 《乱世》自主开发状态

Owner于2026-11-14暂停Codex开发并转交Dot。[完整交接与恢复入口](DOT_DEVELOPMENT_HANDOFF_20261114.md)。

| 项目 | 当前状态 |
|---|---|
| 研发交接 | Dot已接手，正在云端开发；Codex停止开发 |
| Codex Goal | PAUSED，工具已确认 |
| Codex Automation | automation-2 PAUSED，暂停提示已同步 |
| 子代理 | Codex子代理全部停止；Dot在独立工作树研发 |
| 整体美术 | ART_REBUILD_REQUIRED / OWNER_REJECTED，效果图为最低线 |
| 主候选 | PR59 Draft，d1c1895221c33386d471922807ed590a6987dbe1，RC25 |
| RC25正式验证 | 基础通过，footage/escort失败，其余图形任务收尾中 |
| RC25原生候选 | run43595539334 成功；RC25同源原生证据保存在2872bb2，真实M5未测试 |
| 新环境实验 | codex/river-biome-rebuild，2K/4K静帧814417f已审：白岩/荧黄柳/规则岸线仍未通过；不直接合入 |
| 双手枪实验 | 7aaf21be，实拍完成，入步位移与近景遮挡仍未通过 |
| 已完整运行版本 | RC24源4f3c0819，run43587113557，包/115秒2K片/原始数据可用 |
| RC24实时千人2K | M1 Virtual平均27.47FPS，P95 60.954ms，P99 78.508ms |
| 真实M5 | DEVICE_NOT_RUN |
| Dot新切片 | PR61，70cdb716；真实结构/桥头/结算通过，托管2K/4K自审中 |
| 下一步归属 | 以RC25为底修复验证并重建岸坡、林地、道路层次；保留所有实验和RC24 |

完整分支SHA、失败日志、安装包SHA256、许可、录像和恢复命令见交接文件。所有在途运行状态需在接手时重新读取。
