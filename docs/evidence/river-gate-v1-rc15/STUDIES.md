# RC15 的实际造型复审

[22 米同一枪起手](shoulder/22m-personal-windup-native.jpg)和[8 米同一帧](shoulder/8m-personal-contact-native.jpg)中，左侧是原来盖住后背的披风，右侧是偏肩的罩衣。玩家身份、目标 #584、帧、伤害、输入与机位相同。改后在背面可看见腰带、甲襟和右臂；从远处辨认主角更仰赖轮廓与原指示标志。

[弓手四米实拍，左旧右新](hands/fingers.jpg)可辨弓把前方的指腹。第一轮使用实际 HM08 手部后，刀兵腰间仍成了一个空握圈，定稿换成自然微屈。[22 米枪击](hands/22m-personal-contact.jpg)与[双方普通兵](hands/enemy-haft.jpg)显示手与武器的相对位置。近/中/远每手分别约 785、213–214、55–56 个三角形，仍沿用原有战斗腕骨与批次。枪斜过脸、邻兵遮住拉弦侧的问题保留。

[内陆树形前后](grove/personal-contact-pair.jpg)与[宽镜头](grove/grove-pair.jpg)来自种子 61112 的实际战局。左边由折面手工生长，右边使用公开 CC0 原作的树根、分叉、树梢与叶片展开。第一版用卡片原法线，林冠近乎纯墨绿。定稿在整冠方向求受光，保留叶片和地形原有位置；内层细叶仍较密。[失败原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43472097582) · [复拍](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43473412580)

[较早 RC14 的失败与回退](https://github.com/haohongfei2001-png/luanshi-game/blob/c5962a730038168ac0079f46650a6be1a0fc6765/docs/evidence/river-gate-v1-rc14/PLAYTEST.md)

同一台 Ubuntu llvmpipe 渲染器上，半披基线与新手部的军阵、近战、城门、转镜分别仍是 159、123、145、178 次绘制调用。场景三角数分别增加约 13.7%、15.6%、14.1%、9.9%。近战 P50 由 729 增至 825 ms，P95 由 788 增至 842 ms；静态内存约加 117 KiB。补充指节并非没有代价，应优先减轻中远档几何；是否影响目标机由真实 M5 复测。[四景原始记录](hands/render-cost.json)
