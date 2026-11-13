# 美术验收口径

本页逐项审核河关 RC15 的原始画面。玩家曾明确退回 RC13；此次工程回归不会替玩家作出美术验收。

| 项目 | 本轮可复核的结果 |
|---|---|
| ARTREF-01 镜头 | 22 米跟随镜头用同一英雄、同一敌兵重放。从人物、短兵接触到 51 米阵列保留原始 PNG。三档能操作。[默认前后](normal-camera-before-after/) · [近](close.png) · [中](mid.png) · [远](wide.png) |
| ARTREF-02 普通兵 | 枪、盾、弓有独立装备轮廓和三档网格，弓把、枪杆、盾把与空手使用 HM08 掌指母版，远档沿用低面数。拥挤时盾侧身份和枪杆相交仍难辨，商业品质待审。[盾手](hands/fingers.jpg) · [弓手](hands/bow-equal-speed.mp4) |
| ARTREF-03 阶级与身份 | 双方主将、军官、先锋在交战中有独立记录。单肩披挂露出主角执枪侧，敌方弓手与刀盾甲式可辨，重复的脸型与携行姿势仍削弱身份辨认。[近镜与军官原图](#evidence) |
| ARTREF-04 动作与接触 | 73 帧步兵 A/B、弓手同一时刻实发、格挡及伤害真实发生。步态的肩胯回转、近身避让和武器遮挡仍有缺口。[正常操作下的推进](hands/approach-equal-speed.mp4) · [接触记录](measurements.json) |
| ARTREF-05 军阵与人数 | 每方 512 名普通兵，军官、主角另计；跑出镜头后伤亡继续累积。兵员/武器结算与切换镜头的报告可查。[原阵列](wide.png) · [军籍与战果](measurements.json) |
| ARTREF-06 关、岸与营 | 道路、桥台、官道、内庭、营地、河岸在同一场景。木舟已有干燥板底；内陆树改为依据两棵实际 CC0 原作，修正了第一遍的暗面；冠内叶团仍偏密，营地和河岸人造物种类有限。[河岸原窗](grove/ford-pair.jpg) |
| ARTREF-07 风格与清晰度 | 正常对照输出及内部均 1920×1200、4× MSAA、阴影开启。草根、道路和衣甲在近景有不同的材质，远景排列的长杆仍会重叠。[原图](normal-camera-before-after/after.png) |
| ARTREF-08 连续战斗 | 实录直接从导出的 Linux 游戏二进制启动，用系统输入操作 40 秒；另有从军议到还营的 59.2 秒立体声图形回放。帧率性能在独立进程测量。详情见 [安装包录制记录](export-recording.json) 和 [战役记录](PLAYTEST.md)。 |
| ARTREF-09 对标 | 逐一核对八作中与河关相同的观察距离和问题，处理四处明确缺口。整体造型及动作仍达不到目标水准。[逐作对照](reference-gap-analysis.md) |
| ARTREF-10 来源与复建 | 普通兵、玩家、马匹、武器和地面有可再分发来源与实际烘焙脚本。原始记录把项目绘制与 CC0 源分开。[资产及许可](assets-and-licenses.md) |
| ARTREF-11 目标设备 | `DEVICE_NOT_RUN`。托管 M1 虚拟机的短窗口与无实体 GPU 的 Linux 四档样本独立列出。MacBook Air M5 的 20 分钟热稳态、内屏及外接显示均待真实授权测试。[测量](measurements.json) |
| ARTREF-12 整体完成度 | `ART_REVIEW_REQUIRED`。行军时部分人物像同一姿势的复制，军服与头面变化不足；中心标记周围武器相交，近景树冠仍有明显模型痕迹。整版商业画质仍未通过。 |

<a id="evidence"></a>
[完整窗口及军官原图](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43475734574/artifacts/14063772502) · [用户美术基准](../../ART_REFERENCE_GAMES_AND_VISUAL_ACCEPTANCE_20261114.md)
