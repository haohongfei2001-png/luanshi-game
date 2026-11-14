# 《乱世》自主开发状态

| 项目 | 已核对的状态 |
|---|---|
| 工程基线 | main `844f83191daf8223464a35711e5a428d09e5d92f`，候选工作在 [PR #58](https://github.com/haohongfei2001-png/luanshi-game/pull/58)。RC22 的代码、录像和兼容记录保存在祖先提交中。 |
| 优先级 | Owner 要求按 [战场全图](art-direction/river-gate/battle-view.png) 和 [人物近图](art-direction/river-gate/pose-detail.png) 高还原。必须看正常可操作的 2560×1440、3840×2160 原始游戏帧。 |
| 最近的游戏源码 | `d5ea3052449377f8d389a30fbacaa005cfec0869`。PR 头 `7481b60411540e8c6c23a4553a0a99cc2a3a5df2` 随后把旧战场 HUD 回归改为检查实际绘制的按钮、屏底和场地中心。 |
| 实装 | 游戏内原生分辨率与宽屏设置、可通行门洞上的门楼比例、石基与土墙、2K 扫描岸石、4K 车辙路面、握在左掌的盾及落主马离开遗体。 |
| 实机 | [2560×1440 第 50 步原帧](https://raw.githubusercontent.com/haohongfei2001-png/luanshi-game/aac32eb883aa05844e812bbd62cfafa3eee04058/docs/evidence/river-gate-v1-rc23/fitted-crossing/2560x1440/view-0050.png)；[512v512 宽屏和 UHD 运行](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43546458665)。 |
| 试验取舍 | 拒收普通兵的第一版贴脸和闭筒战袍。正在同机位复查真实枝条柳冠、桥板以及第二版交领宽带，取舍以相同战斗输入的原帧为准。 |
| 质量与设备 | Owner 已明确拒绝此前画面。全图视觉还原仍未通过；`ART_REVIEW_REQUIRED`。真实 MacBook Air M5 `DEVICE_NOT_RUN`。 |
| Codex 长期 Goal | `ACTIVE`，所在对话 `01a1cbad-2467-7310-b9fc-81b5a5b96466`。 |
| 自动续接 | 单项原生 heartbeat，`automation-2`，北京时间每天 10:00、22:00。状态和目标对话已核实。10:00 当期在本对话开发期间推迟，读回时尚无独立运行记录。 |
| 接续与验收 | [本轮可执行入口与历史](CODEX_CONTINUATION.md) · [正式 CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43547163844) · [Issue #12](https://github.com/haohongfei2001-png/luanshi-game/issues/12)。 |
