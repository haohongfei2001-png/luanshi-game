# 《乱世》世界—战争—剧情技术接口契约 v1.0
本文件由 Pro 设计，给直接云端开发的 Dot 一个**可执行的模块边界**，减少开发到三城、军团和存档后推倒重做。以 PRODUCT_DECISIONS.md 和 FINAL_GAME_DESIGN_SPEC.md 为准。它不是要求在 Gate 1 立即实现全部字段或复制具体代码类名。

## 1. 核心模块与方向

```text
WorldClock + RNG + EventQueue
              |
         WorldSim (唯一事实)
       /       |          \
  Logistics  Factions     Knowledge / NPC decisions
       \       |          /
          WorldEventLog
              |
       BattleAdapter (交战快照/事务)
              |
           BattleSim (实时局部)
              |
          Presentation
       /      |          \
   BattleUI  StrategyUI  StoryUI
```

- WorldSim：对世界状态有唯一写权限。世界状态可独立于场景执行自动测试。
- BattleSim：仅负责给定参战快照的局部运动、攻防、死亡、撤退、士气和结果；不自行生产战略军粮、城池人口等。
- BattleAdapter：锁定参战兵员/装备，创建战场快照，回写结果**恰好一次**。
- Knowledge：可读取事实生成观察、发送消息，但角色必须先收到消息才能用于 AI 决策。
- Narrative：只读取权威世界/角色知识并发出合法世界动作，不直接随意重置阵营/军队。
- UI：只渲染玩家有资格知道的数据；开发调试面板可另有全知模式，但正式运行不可启用。

**保留现有 battle_sim.gd 的纯逻辑优点**，通过小适配器接入世界。不要在多个节点复制一份状态后长期独立演化。

## 2. 初始数据类型（建议字段，按功能阶段逐步扩展）

- WorldState：schema_version, game_id, seed, time_seconds, next_entity_id, cities, armies, characters, factions, intel_by_character, pending_events, applied_transaction_ids, story_flags, rng_streams。
- City：id, faction_id, location, population, workable_population, food, weapon_stock_by_type, armor_stock_by_type, horse_stock, production_rates, defense, stability, garrison_army_ids。
- Army：id, faction_id, commander_id, position, destination, detachments, food, animals, condition, morale, standing_orders, intelligence_state；人数从 detachments 派生，禁止额外维护不一致的人数。
- Detachment：id, army_id, soldier_type, able, wounded, captured_or_missing, weapon_allocation, armor_allocation, experience_level, morale；未来可有具有独立 ID 的老兵。
- Character：id, faction_id, role, location, age_time_reference, health, fatigue, permanent_injuries, attributes, equipment_refs, relation_map, goals, current_order, knowledge_ref, alive。
- IntelReport：id, observed_event_id, target_entity_id, observed_at, dispatched_at, received_at, source, confidence, claim, is_known_to，内容允许错误或过时，不能只通过 UI 缓存。
- WorldEvent：event_id, at_time, event_type, actor_id, affected_ids, deltas, cause_event_ids, visibility_rules；供调试、存档和失败复盘。
- BattleTicket：battle_id, time, location, participating_force_ids, reserved_roster_snapshot, terrain, tactical_seed, status（reserved/running/committed）。
- BattleOutcome：battle_id, surviving_ids_or_counts, wounded, dead, missing, captured, recovered_equipment, destroyed_equipment, spoils, retreat_positions, elapsed_world_time, result。

初版用普通整数的食物/件数/人数方便审计。以后装备品质、运力等可以扩字段，不能改变“没有的物资无法配发”原则。

## 3. 战略层的固定更新序

建议将一天分为固定小时离散步，不依赖实际渲染 FPS。每个世界时钟步按稳定顺序执行：
1. 处理玩家或 NPC 已提交的合法命令（记录提交时间、通信时间）；
2. 推进行军、侦察、消息递送、已安排的运输；
3. 结算到点消息并更新接收者的知识视图；
4. 到日界线时结算粮耗、病伤、疲劳和人口状态；到月/季节点结算生产与治理；
5. 推进围城、交战、溃散、驻军变更；
6. 基于**角色已知情况**评估下一步 NPC 行为并排入事件队列；
7. 依据合法触发条件产生剧情/消息；
8. 写事件日志、审计关键守恒式、提交存档安全点。

若同一时刻有多个事件，以时间戳 + 稳定 ID 保证序列可复现。不同细度的步骤都由同一世界时钟驱动，不能战略按天、战斗按秒运行成两个互不相干的世界。

战斗发生时离屏世界按游戏内已流逝时间更新；短时间战斗期间的快速模拟可批处理，不需要在每帧重新结算所有城市的农业。

## 4. 核心 API（行为契约，不强制函数名）

```text
new_campaign(seed, start_identity) -> WorldState
advance_world(world, duration) -> list<WorldEvent>
issue_army_order(world, actor_id, army_id, order) -> Accepted | Refused(reason)
transfer_supplies(world, source_id, destination_id, resource_type, amount) -> Transaction
send_intel(world, observer_id, recipient_id, report, route) -> ScheduledMessage
get_known_world(world, observer_id) -> KnowledgeProjection
create_battle_ticket(world, location, participating_army_ids) -> BattleTicket
simulate_or_play_battle(ticket, commands) -> BattleOutcome
commit_battle_outcome(world, outcome) -> CommitResult
save_campaign(world) -> VersionedSave
load_campaign(save) -> WorldState
```

检查点：
- 不可让 Narrative/Presentation 调用“直接把安平状态设为必然失陷”这种绕过规则的后门；
- WorldSim 可根据游戏状态合法地产生新角色或敌军，但必须扣除人口、补给或有清楚的世界内来源；
- 一次 BattleTicket 的 Outcome 提交后不能二次增加战利品或减少兵数；
- 如果玩家在战斗中死亡，先结算真实世界影响，再结束可操作的一局并显示有限知识终章；
- 军队负数人口、负粮食、死亡角色继续指挥等情况必须抛出测试错误而不是悄悄钳位且不报告。

## 5. 确定性、消息与 AI

- 把战略 WorldSim 与局部 BattleSim 的随机数流分开。相同存档/种子/操作/时序应在战略层产生相同结果。不要把画面抖动、音效随机数混入世界决定。
- 真实事件一旦发生只写入 WorldEventLog；角色收到对应报告时才增添自己的 KnowledgeProjection。报告包含观测时间和接受时间，UI 显示“X 日前情报”。
- NPC 决策从角色目标、风险感知、物资、士兵状态、关系和自身知识出发。使用确定性效用评分加有限扰动、行动冷却及迟滞，避免每小时忠诚反复振荡。将领阵前倒戈可能产生士兵拒绝跟从的分支。
- 离屏城池不依靠是否进入场景才推进。围城军的补给、城里粮食和实际驻军决定是否守住。玩家出兵改变路程/粮道可以改变真实结果。
- 玩家失败复盘展示**可能由玩家获得的报告与因果解释**，而不是完整展示秘密 NPC 意图。开发者全知日志仅用于 QA。

## 6. 物资与兵员审计

推荐每项资源保持：
    quantity_after = quantity_before + production + incoming - outgoing - upkeep - lost_or_destroyed

生产和消耗须有对应的事件类型；迁移、缴获、配发不允许同时在两个地点保留原数量。士兵状态满足：
    initial_soldiers + recruited + transferred_in
      = able + wounded + captured + deserted + dead + transferred_out

按战役/每天审计，伤兵归队不能重复算新兵；死亡兵员不得重生。战场回写应有唯一的战役 ID 和已结算标记。

无武器士兵的武器栏为空，不等于“仍可使用默认枪”；视觉和伤害算法均须读取装备状态。

## 7. 存档、版本与重新开始

存储 schema_version、随机状态、世界时钟、实体引用、城池库存、角色关系与伤病、在途消息、排队事件、未结算战斗票据、已提交战斗 ID、剧情标记。加载前进行版本验证和损坏检查。不同旧版本允许显式迁移或提示不兼容，禁止无声丢弃重要状态。

重要人生节点是一份完整世界快照，而非只保存角色血量与坐标。同一个快照重播没有改变战略决策时不应该随机变换城池是否失陷。

## 8. 性能和工程边界

- 当前 20 对 20 原型先保持可重跑。场上人数扩大后，逐步从全对全最近敌人与排斥计算升级为空间索引和小队级计算；真实瓶颈由性能测试确定。
- 游戏画面层可以 LOD、实例化、隐藏远距动画，**不能通过删除世界士兵数据偷换真实兵力**。
- AI/世界计算在头无图形测试时可长时运行、输出每日变化摘要；重载后维持日志可追溯。
- 设计参数（粮耗、老龄风险、射程、士气阈值、军令延迟）保存在可配置数据中，不写死在散落的 UI 节点里。
- 一次变更只修改一个可测试机制，保留上次可运行构建。文档和代码如果有差异，以用户锁定规范为目标修复代码，而不是直接删掉规范。

## 9. 用户新确认的战场命令、攻击与时间模型（2026-11-08）

### 9.1 令旗/号角/传令兵是实体通信通道

建议增量数据模型：
- `CommandIntent`: id, issuer_id, target_detachment_id, type, desired_position, issued_at, origin, urgency。
- `SignalChannel`: kind = local_voice / flag / horn / runner, effective_area_or_route, reliability, is_observable。
- `Courier`: id, position, route, speed, health, faction_id, carrying_command_ids, status = traveling / intercepted / missing / delivered / captured / returned。
- `OrderDelivery`: order_id, dispatched_at, last_confirmed_at, recipient_id, status = drafted / dispatched / pending / acknowledged / refused / timed_out / suspected_lost / confirmed_lost / superseded。

单条军令的世界内进展为：`issue` → 选择可行通道 → 时延/路径仿真 → 收件人获知 → NPC 根据**自己**的情报决定是否执行 → 回信可能再次受运输、战争影响。令旗/号角在适当距离传播，不需要实例化几千个传令兵；远距命令才需要实体信使/路网。

事件表区分 **world_true_delivery** 与 **player_known_delivery**：例如传令兵已被伏击，世界真实状态标记 intercepted，但玩家界面仍显示“派出中/超时失联”，直到目击者回报、己方发现遗物或通讯超时被合理推断。不要发送全知提示“敌军在某坐标击杀了传令兵”，除非当事人真的知道。

可复现测试情境：相同世界种子中正常送达与改变敌军巡逻路线后信使被拦截的两种结果；未送达命令不得改变远方部队的执行任务。信使遇险不能影响已经在其之前送达的令旗或号角军令。

### 9.2 角色进攻成长与脆弱性

`CharacterCombat` 建议把 `damage_per_hit`, `attack_arc`, `attack_speed`, `skill_effectiveness`, `weapon`, `stamina`, `armor`, `hp` 和 `incoming_hit_exposure` 独立存储，不设 `hero_invincible_flag`、`enemy_count_buff` 或高等级强制伤害免疫。

- 初期与普通士兵处于可一敌一/一敌二的能力区间；后期因攻击/招式/装备能在大量散兵中持续获胜，**血量增长仍有上限**。
- 多敌攻击应按照真实命中、攻击面、武器射程和角度造成累计伤害；玩家被几十个敌方有效打中仍可死。
- 大战可承载大量时间跨度内的累计杀敌统计，不能将“以一敌百”解释为 100 名敌军无条件同时攻击时必然存活。

### 9.3 基于活动的世界时间

`WorldClock` 按一个权威时钟，`ActionDurationPolicy` 区分：
- `ui_zero`: 菜单、阅读、装备选择、点击给指令（除真实送令时间之外）不额外推进游戏时钟；
- `minor`: 普通移动、即时交互、战斗按照实际经过的秒/分钟累计；
- `scheduled`: 行军、休养、训练、等候、围城和剧情事件明确占据小时/天/月，触发统一世界推进；
- `skip_until(condition)`: 可选择快速等到预计到达、夜晚或伤愈，同时推进所有离屏战斗、粮耗、消息和人物行为，不能跳过历史代价。

无动作不代表永久冻结：若游戏当前未暂停，世界钟按合理比例推进；如果玩家主动使用暂停查看信息，世界可以暂停以保障公平，但恢复后所有在途事件继续。UI 时间接近零≠免费生产、免费训练、免费增兵。

### 9.4 叙事锚点与条件性历史分支

建议 `NarrativeAnchor`：id, kind = structural_pressure / external_campaign / historical_shock, initial_conditions, trigger_conditions, earliest_time, originating_faction_or_person, mutable_outcomes, active_status。

- structural_pressure 指朝廷-地方矛盾、边境战争风险与资源争夺等**不能被主角忽然消除的时代状态**。
- external_campaign 指已由外部大势力在现实政治条件下准备/发动的战争，起因不依赖玩家观看或出场，后续是否获胜/撤兵/兵变仍由世界推进。
- historical_shock 指少量关键节点的外部行动，影响范围大，但不直接赋值最终胜者；玩家只有在具备位置、军权、资源/消息等真实条件时才可能改变结果。

`NarrativeOutcome` 从真实世界条件和关键人物知识生成，不使用事件脚本把胜负、人口、军队库存置换成既定结局。普通互动影响局部，不自动改写全国；重大历史改写需通过明确影响力阈值和真实世界行动实现。

### 9.5 不可重复刷任务的世界推进

每个重复任务应具备：真实资源成本、世界条件/次数限制或设计上的自动汇总，避免为增加游戏小时数无意义强制刷怪。世界战争不随玩家退出军职停止；玩家隐居后可以通过季节/月度消息/城池状态/战争推进继续经历其历史后果，而不是切换成和平农场模式。

## 10. 交接条件

Dot 完成首个世界三城架构时，应提交：模块接口说明、示例保存文件的**脱敏版本**、三种安平救援不同结果的测试脚本与日志、资源守恒测试、战斗结算恰好一次测试。此后可进入剧情层；不需要再问用户选哪个架构。
