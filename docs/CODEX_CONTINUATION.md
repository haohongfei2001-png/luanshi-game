# 《乱世》Codex 可恢复工程状态｜统一记录

**此文件是实际编码代理的交接日志，不是对未执行任务的完成声明。**
**主任务**：[CODEX_MASTER_EXECUTION_MANDATE_20261112.md](CODEX_MASTER_EXECUTION_MANDATE_20261112.md)，总 Issue [#12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。
**Owner 要求**：一次下达完整战斗 V1 研发任务；每个阶段应在能力允许范围内自主继续，不要求用户再次代传指令；正式文学剧情完全留空；不新增费用或远控个人 Mac。

## 河关运行记录

| 项目 | 已核验的状态 |
| --- | --- |
| 统一基线 | `edc89fcf949774daf890d248dbfae07eef711583` 已合入 main。#10 至 #25 的开发和证据提交均可沿父提交找回。 |
| 基线验证 | [整合候选的完整 Linux 和原生 macOS 检查](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43116899178)已通过。合并提交的[独立重测](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43119189602)另行记录。 |
| 开发候选 | [#27](https://github.com/haohongfei2001-png/luanshi-game/pull/27)，分支 `codex/river-gate-command-and-objectives`。双边军官、护送任务、伤员及俘虏、入营后存档、军旗、城楼剖视和九兵器输入同时进入正常游戏。 |
| 回归与修复 | [aa517095](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43118298014) 的整合 A/B 暴露冲车在 x=9.30 停住，守军完好守门。当前改为按门板实际位置命中，东进先头展开，临近护送兵可接替阵亡役兵。需以最新 CI 核验。 |
| 云端复现 | 在 Godot 4.6.3 开发环境运行 `./tools/test.sh`、`./tools/test-field-journey.sh`、`./tools/test-field-render.sh`。全量构建采用 `./tools/export.sh`，托管 Mac 验证由仓库 workflow 运行。 |
| 检查设备 | 真实 M5 Air 持续 20 分钟为 `DEVICE_NOT_TESTED`。上一代[可回退版的录像与实测](evidence/river-gate-round-two/PLAYTEST.md)保留。 |
