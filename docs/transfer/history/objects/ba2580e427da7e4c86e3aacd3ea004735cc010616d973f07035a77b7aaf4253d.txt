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

## 9. 交接条件

Dot 完成首个世界三城架构时，应提交：模块接口说明、示例保存文件的**脱敏版本**、三种安平救援不同结果的测试脚本与日志、资源守恒测试、战斗结算恰好一次测试。此后可进入剧情层；不需要再问用户选哪个架构。
