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

## 9B. 中晚唐式政治、俘获、归国与关系链的数据契约

本节建立在 PRODUCT_DECISIONS.md 1C 最新用户方向上。用户并未批准固定 NPC 名册或固定朝廷崩溃剧情。

- `CourtState`（建议）：中央机动军、都城守备、军粮国库、诏令可执行程度、政治正统性、皇帝当前政策目标、派系压力、中央对地方的真实控制关系。不能只有一个 `court_good_or_bad` 数值。
- `FactionAffiliation`：角色正式编制归属、实际庇护者、当前掌控军队、被朝廷如何记载（忠臣/失踪/已故/嫌疑/叛将）、角色本人承认的义务，这些字段可能互相矛盾。
- `CaptivityState`：`free / captured / detained / conditional_service / exchanged / escaped / returned / defected`，以及俘虏的羁押势力、地点、约束、可用物资、允许的动作、在途谈判、保释或换俘条件、主角仍在世的持续时间。
- `CourtInvestigation`：指控来源、证据/假证、知情派系、是否曾获赦、未送达诏令、受牵连人员、司法/政治决定、生效时间与角色所知的区别；不能把“被俘”直接映射“朝廷必然抄家”。
- `RelationshipHistory`：两名角色共同事件、承诺履行、授职与功劳分配、野心、自尊、道德立场、家族风险、各自掌握的情报、分离时间、当前利益冲突。人物自主决策可从这些维度评估合作、争权、拒命、归附、背叛、和解。
- `ReunionEvent`：双方真实存活、实际位置/通讯渠道连通、角色彼此已知的历史、事件前后关系更新；离屏死亡会取消面对面重逢而改为消息/遗物路径。

**一致性约束**：
1. `captured` 不是主角死亡/本局结束；若俘虏被执行死刑、病死或自然死亡，才触发主角终章。被俘时主角的部队、城池、好友继续演化。
2. 玩家被囚禁时不能仍直接指挥原军队，除非拥有实际可行的秘密传信或代理指挥路径。
3. 外方接纳不代表全方立即信任；归国不等于立即清白也不等于必遭惩罚，所有路径必须有角色视角的证据和时间线。
4. 同一旧友可能服从主角、公开竞争、另赴军镇、做敌将、和平离别或死亡；角色是否响应要有可审计理由，不由单一忠诚掷骰。
5. 朝廷可能在战役中损失某支强军，也可能因税赋/补给/胜仗恢复；实际主导权必须由可动员军力、传令、兵权和财政而不是“好皇帝”标签决定。

## 9C. 生涯、军功、社会关系、婚姻、后嗣系统的数据契约

**不要把本节全部系统塞进现有小规模战斗原型**。它规定增量的数据边界，供 Dot 在 G3 少年从军小故事到 F 成年政治/继承阶段逐步实现。设计详见 `NARRATIVE_LIFE_ARC_V0_3.md`。

### 生涯事件和军功争议
- `CareerState`：身份/家庭出身、入伍缘由（被征发/主动从军）、军籍状态、实际品级、所控制小队、名义上级、实际庇护者、已有战功、授职/罚俸/军纪记录。
- `BattleMerit`：交战 ID、真实功劳参与者、现场见证人与战报版本、功劳被谁申报、谁能审批、是否颁赏、资源和声誉变动；**真实功劳与朝廷/军中登记的功劳允许不同**，但这种不同必须有具体篡报/权力/误传行为。
- `InjusticeIncident`：有动机的冒功/诬告/夺赏/克扣造成的处分及证据、发生时间、知情人物、后续申诉/翻案机会；初期应触发至少一次结构性军功不公，但玩家可以影响其性质/程度/证据与后续。
- `CommandAuthority`：实际可用军队、被法律/军令承认的职位、士兵真实服从对象、军饷来源与政治支持，不能靠单人等级自动生成军队。

### 生涯时间与人际
- `LifeStage` 可由实际年龄、军职、地区、资源、战局与身体状态共同决定可候选事件，**不要固定游戏时长/固定六章节**。
- `SocialBond`：情感、信任、尊重、期望、承诺、共同风险、地理距离、交往和书信时间、个人动机/家族压力；相互关系可以非对称（甲喜欢乙，但乙已不在意甲）。不能用一维“爱情条”直接判婚变或死亡。
- `IndependentLife`：即使不在玩家身边，重要旧识和亲友随世界时钟可能迁徙、成婚、改志向、生子、参军、受伤、死亡，并生成可供未来见面/信使告知的事实；严禁玩家回乡的瞬间临时按剧情抽签决定她是否已婚。

### 婚姻/家庭
- `Household`：关系和住址、法律/风俗婚配状态、实际共同生活/分居时长、人口、财产、家族利益和风险；不要求始终嫁娶，另一方可以拒绝。
- `MarriageProposal`：提议者、接受者、各自意愿、家族压力、政治条件、承诺、合法性、传令/回报状态。婚姻不能由主角单方菜单操作就强制成功。
- `ChildOrWard`：人物 ID、父母/监护人/养父母、年龄、出身与合法性、健康、独立目标、与政权/家族关系；可以有女儿、儿子、义子、义女、其他合适继任者，但**是否具备正式继承资格由该架空政权制度决定，不能把任何孩子自动等同皇储**。
- `SuccessionPlan`：遗诏/遗嘱、拟定继任者、见证者、被谁认可、约定的军权与财物转移、竞争者和执行条件。在主角活着时可观察准备结果；主角死亡后本局结束，不继续实时模拟让玩家全知观赏百年后果。

### 支线稀有性
- `CaptureOpportunity` 只由真实战败、无法逃离、主角仍活着、对方有俘获动机和接触条件产生；不把“到第4章必须被俘”当作合法触发。被俘后的状态链继续可用，但必须处于低频条件分支。
- `AssassinationAttempt` 的策划者、资金/人力、地理可达、暴露线索、警卫强度、具体时间应进入世界事件；它可能失败或被发现，不允许纯不可防御的系统强制杀死玩家。

### 小型世界验证样例
1. 初期同场战斗功劳事实由 `BattleMerit` 正确记录；上官借军报权力据为己有，玩家通过留证得到一条未来申诉机会，尚未凭空改写朝廷。
2. 固定军粮/不同军令执行“炮灰任务”；不同撤退时机产生真实不同阵亡人数，小队补员的武器和粮食从已有城市消耗。
3. 主角战死后旧友/婚姻/子嗣信息仅用于当时可知的局末总结；不强制操控继承人。
4. 玩家未遭战败或成功撤离时永不凭剧情强制被俘，罕见真实被俘则能按本来的 `CaptivityState` 接续。

## 9D. 百年战争压缩的世界时代与技术演变模型（2026-11-12 新长期契约）

**只定义接口和不变量，不要求 Dot 当前 G2/G3 立即实现全部时代与海军**。完整战争压力谱系、用户决策与可达性见 `CENTURY_WAR_ERA_CAMPAIGN_V0_1.md` / `PRODUCT_DECISIONS.md` §1E。

### 时代不能是剧情章节枚举

建议把世界状态分成**相互作用但不完全同步**的对象，而不是 `current_dynasty = Tang`, 过关后 `Song`：
- `EraPressure`：id, kind (military_fragmentation / northern_rivals / territorial_split / succession / dual_front_fiscal / coastal_foreign_pressure), actors, initiating_causes, earliest_possible_time, current_intensity, trigger_conditions, countermeasures, resolved_or_transformed_by。它是**压力/风险**，而非固定结果。
- `PoliticalOrder`：polity_id, form, legitimacy_sources, central_army, provincial_forces, regional_autonomy, fiscal_capacity, court_factions, succession_rules, capital_city_ids, active_claimants。中央与地方均可因战争/财政改变。
- `CapitalPolicy`：principal_seat, secondary_seat, army_hq, northern_garrison_locations, tax_origins, supply_routes, grain_transport_cost, capital_exposure, local_command_autonomy。南京/北京只是重要可选城市的地理原型，效果来自地图/供应链。
- `FiscalPressure`：tax_rates_by_region, taxable_population, weather_and_harvest, collection_efficiency, court_spending, corruption/leakage, military_pay, grain_stock, legitimacy_and_unrest, roads_and_grain_canals。税赋与民变不是同一个布尔变量。
- `TechnologyDomain`：polity, metallurgy, powder_arms, artillery, shipbuilding, navigation, industrial_workshops, transport, taxation, military_organization, education_and_diffusion, knowledge_sources, effective_deployed_capacity。区分已知、可制造、已训练与实际装备率。
- `ForeignPolity`：独立的人口、疆域、内部派系、军力、野心、技术、财政、外交与资源；草原联盟和新兴北方集团不能仅因为故事需要改名重生。若合并/吞并产生新敌，记录 `PoliticalSuccessionEvent` 和实际兵员/领土来源。
- `DynasticTransition`：前政权是否实质失去首都/军队/税收控制，征服者、残存地区、合法性主张、继承关系及战役记录。新皇朝不是点击“统一”后凭空刷新一整套军粮和人口。
- `NavalForce`：船只数量与类型、造船/维修产能、船员训练、舰炮、火药粮草、港口补给、航路、天气/水文。第一阶段允许在世界战略层聚合模拟，不要求马上渲染海战。

### 历史压力推进与年龄

建议一个 `ScenarioGenerator / EraEngine` 只在世界真实人口/财政/政治/军事/技术条件满足时把新的压力放入同一 WorldEventQueue。**绝不根据玩家刚赢一仗就瞬间写入新朝/新装备**。
- 历史参考时间的“数百年”映射为**浓缩的世界演变速度/更强的外部扩散与危机频度**，但 `WorldClock` 仍以真实游戏内时日驱动人物年龄、行军、粮耗、生产。
- `EraEngine` 的阶段只是风险原型标签，经济与武备能力是真实连续变量；一场战争中仍可能用旧装备对新火器。
- 用户明确要求存在从约15岁到自然老年、能够遭遇 E0–E7 的合法高水平路线，目标测试不得依赖永久健康、瞬时物资、无条件赢战或切换继承人。
- 短程版本用可配置 `acceleration_profile` 和初始外部预存技术/政治条件（体现作者确立的架空历史）来实现总体速度，而不是强制玩家按世纪等待。该 profile 须记录在存档与 QA，世界模拟全局一致。
- 玩家中途失去政权、退守南方或不思进取时，其他势力的政治/技术/战争仍会演化；玩家失去主权不等于年龄停止或整个世界科技停止。

### 产业链与外交/财政核对

- 开放贸易和科研不直接生成现代军舰： `contact -> knowledge -> skilled_personnel -> production_facilities -> supply -> training -> deployed_units` 需要合法时间与消耗。政策与改革提升效率但受实际世界资源限制。
- 参考历史清末能力是平衡/美术上限的**目标带宽**，不是所有玩家每个属性固定锁死。长期开放可使相关领域略好，却不保证工业代际碾压领先海权国。
- 带来财政收益的南方税赋若需北运，真实商路/运河/海运的风险、军费、仓库与截运会产生代价。首都选北京可以有指挥利益及自身暴露风险，不允许设为绝对“选对免疫入侵”。
- 税收变化影响实际征收率、逃亡/叛乱动员、部队工资与财政，既可让民变滋生也可削弱北境防守；不得硬写 `if tax_raised: spawn_li_zicheng` / `else: spawn_qing`。
- 海上末战与近代舰队战争需读取真实港口、造舰材料、修理、船员、燃料/粮草、军备与国库；“剧情海战”造成的损失必须回写世界。

### 接口建议（行为而非强制函数名）

```text
evaluate_era_pressures(world) -> Array<EraPressureChange>
apply_governance_policy(world, polity_id, policy) -> Events/Refusal
simulate_foreign_innovation(world, years_or_months) -> TechDiffusionEvents
plan_and_build_unit(world, tech_profile, stock, facilities, training) -> Job
recompute_north_south_logistics(world, capital_policy) -> FiscalAndCommandCosts
resolve_world_crisis(world, conflict_id, actions) -> ConflictOutcome
replay_successful_lifetime(seed, action_script) -> ReachabilityEvidence
```

### 测试必须证明的边界

1. **一路成功可达性**：从约15岁起，合法世界状态和自然寿命可以经过 E0–E7 的主要压力原型，至少一次遭遇外来舰炮威胁；不通过暗改年龄/血条/兵力达成。
2. **不可自动重演**：同一关键阶段中，有玩家保卫北方的分支，不应仍强制给他“崖山亡国”；京师守住不应被脚本判亡国。
3. **首都与税制测试**：南京/北京在真实军事和财政结构下产生不同代价；高税/低税/改革路径均有资源结果，不是单一布尔结局。
4. **海军与军工测试**：只拥有新技术设计图而没有造船设施/熟练工/财政的政权，不能直接得到海军战力。
5. **政治沿革**：北元式联盟与后金式政权之间若存在继承、联盟或兼并，能在人物、兵力与领土日志中追溯，而非简单改名刷新国家。
6. **未能晋级仍有生命**：丧失首都、战败或流亡时，主角如果没死，个人剧情与世界技术仍向前。

## 9E. 战场类型、多层次武将与真实地形/补给通路（2026-11-12 新合同）

**主人新增要求，详细战役类型及研发排序见 `BATTLEFIELD_VARIETY_AND_FORCE_ROLES_20261112.md`、`PRODUCT_DECISIONS.md §1I`。** 下列仅是可替换的**数据契约/不变量**，不是指定必须照抄的实现代码，也不是要求当前 Codex 在一个任务里完成所有场景。

### 角色/兵种/将领合同

- `Combatant`：唯一身份，阵营/小队/隶属，武器与护甲、训练、伤势/体力/士气、位置、当前行为、受令与生死状态。
- `OfficerRole`：不能只用等级数值表示，应分别描述 `ordinary/officer/challenger/vanguard/specialist/field_commander/supreme_commander` 等可共存职能；**先锋**和**叫阵小将**不必由军职等级推出。个人武力与领兵能力分开，叫阵不强制开 1v1 副本，敌方仍独立作战。
- `ForceOrganization`：全军主帅（可在地图外）→ 战场主将 → 纵队/兵种将领 → 先锋/军官 → 小队兵员；真实授权/继任/失联/士气与军令影响战况。不同一场会战的主帅不必随机生成为可被玩家接触的单位。
- `TroopProfile`：盾步/刀剑/枪矛/长刀、弓弩、骑兵、亲卫、侦察、工兵/辎重、舟师/舰员与时代许可炮兵等，军种由装备/训练/补给/速度和阵型定义，可用低成本普通兵 FSM、较高预算的精锐与将领 AI。

### 交通/地理/任务合同

- `TerrainFeature`：ID/坐标或区域、地物类型（桥、坡、隘口、林、河、墙/门、码头、粮仓、水井、港口、陷阱/火场）、通行/地形成本、射界/视线、控制权、耐久/火势与当前可用性。
- `SupplyNode` 和 `SupplyEdge`：仓库/城池/水源/营寨/运输队/前线 + 道路/山路/桥/河航/海航；每段容量、时间、控制/风险与实际运输状态；流通的是粮、饮水、马料、箭/弩矢、工事/火攻、火药/炮弹和船材（存在且在该时代可用时），以库存/地点/时间核对。
- `BattleObjective`：军事任务目的、双方各自的达成条件、空间控制点/路径、持续时间/支援与撤离条件、相对重要性和当前已知情报；**允许不同阵营目标不相同**，局部夺点不立即代表整场战争胜利。
- `TacticalScenario`：平原、桥河、高差、夜袭、营寨、守城/攻城、山林、伏击/包围、粮水截运、多点争夺、舟桥/水战、海战等是可组合**战场条件/地形/初始编队/军令/战略目标**，而不是单个固定剧本“任务 ID→指定结果”。

### 可验证的守恒/因果

1. 占领/摧毁桥梁和道路改变真实可通行/可运输边；截运后仓库、车队和部队库存不能同时凭空多出同一批物资；断水/断粮影响随真实存量和时间推进，不必逐个士兵模拟喝水。
2. 夜袭/伏击从真实侦查、视野/照明、部署/巡逻与情报滞后出发，不能凭玩家进入预设坐标刷出无来源敌军；火攻扩散/灭火/风雨与可燃物是实际战场状态，可复现、可反制。
3. 机关陷阱、投石器/攻城机械、渡河船只、舟桥和舰船各自有位置、可用性、弹药/人员/负载/损坏状态，结果回写 WorldSim；武器/火炮随科技、造船与产业链允许时才真实存在。
4. **强将死亡≠战役胜利**：敌我仍按双方任务、有效部队、士气、指挥链、地形据点、退路、补给/援军判断结果，可能达成目标、继续、战败、投降、撤退或相持。
5. 所有重要地形、军阵、道路、水源、火势与船只状态应在存档/战斗恢复后按唯一世界事实延续，镜头外不能冻结世界或把死者重生。阶段性优化的屏外简化必须能追溯真实军损。
6. 火炮和成熟近代舰队必须满足已知→制造→部署→运输/训练的前置链，不能只因时间切换直接刷新武器；河道水战可以早于晚期成熟炮舰。

**验收规则**：`ACCEPTANCE_MATRIX.md §7F-C` 的 BF-THEATER-01..21。当前通过/未来能力状态分开标注，不能因文档存在而记 `PASS`。

### 9E.1 最新 Owner 简化约束（2026-11-12）

`PRODUCT_DECISIONS.md §1K` 覆盖本节中对“必须把所有地形、后勤、船只、天气和火器都做成独立微观系统”的潜在误解。上面的数据类是**有需要时可复用的设计选项**，不是必须逐个实现的数据库表。真正选用的玩法须保持可复现的基本因果；可使用区域/队伍/阶段级别的近似状态，自动将粮道/水源/火攻/弹药等转化为清晰军情及战力变化，**不要强迫玩家进行逐人逐物的后勤微操**。只在明显有乐趣收益时引入额外细节和复杂 UI；不做的历史候选项保留为研究资料，不以未实现作为工程失败。

## 10. 交接条件

Dot 完成首个世界三城架构时，应提交：模块接口说明、示例保存文件的**脱敏版本**、三种安平救援不同结果的测试脚本与日志、资源守恒测试、战斗结算恰好一次测试。此后可进入剧情层；不需要再问用户选哪个架构。
