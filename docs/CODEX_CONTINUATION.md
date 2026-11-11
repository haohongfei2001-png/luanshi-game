# 《乱世》Codex 可恢复工程状态｜统一记录

**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务；每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令；正式文学剧情完全留空；不新增费用或远控个人 Mac。

## 河关基线整合 · 首次提交

基线为 `06ddf43fd43733d74aa8b2df49c0538f146235d9`。分支 `codex/battle-v1-integrated` 同时保留 #25 与 #22 的祖先、两轮实录、旧档及世界模拟。合并候选修复营地耗尽给养后仍能用旧战报继续行军的问题。Linux 图形、macOS Metal 导出包、最终整合提交的 CI 及 M5 实机均待本轮验证。

上一份通过双平台运行的可回退源为 `6a061ba29f7cf2ba488dedc2f01e09992e75dd27` 的父开发系列 #24，游戏源码为 `77ad69619972975a015fa2890a75d5993e87e68c`。[对应的包、录像和性能记录](evidence/river-gate-round-two/PLAYTEST.md)。

云端复验命令为 `./tools/test.sh` 和 `./tools/test-field-render.sh`。接续时先取此分支最新提交及其 PR 检查，再运行河关，核验冲车通行、军官救援与战役裁决。实际目标机状态为 `DEVICE_NOT_TESTED`。
