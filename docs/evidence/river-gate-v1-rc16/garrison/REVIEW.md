# 实机评审 · 河关普通兵衣甲

本组仅评估服装接入。左图是 RC15 `05f0c7f1`，右图是衣甲试装 `219e14b1`。每侧使用同一随机种子 61112、每方 512 名普通兵和 16 名军官，Ubuntu 24.04、Godot 4.6.3、X11/llvmpipe，原图 1920×1200，内部比例 1.0。

* [正常镜头实际命中](final-personal-contact.jpg)。镜头 22 米，tick 48 时主角攻击 #584，敌方生命由 62 降至 39.76。[两侧同速实机录像](equal-speed.mp4)，[候选原始录像](after/motion.mp4)。
* [枪兵 #37](final-spear.jpg)和[盾兵 #550](final-shield.jpg)。相同的 5.8 米相机下，可以在旧版外套边缘的位置看到独立肩袖、腰带和有重量的搭接甲裙。第一轮[盾兵下摆有亮色断边](first-shield.jpg)；复染内襟并扩下摆后，亮条收回到甲裙里面。近看肩褶的折角仍明显。
* [弓手 #94 正面满弓](archer/fingers-pair.jpg)、[同一游戏时刻的侧面](archer/fingers-side-pair.jpg)、[放箭](archer/loose-pair.jpg)、[正常 22 米镜头](archer/draw-normal-pair.jpg)。4 米图可观察面颊、两侧袖口、护腕和持弓手。邻兵刀从腰前经过，侧镜仍有兵器重叠。tick 25 开始拉弓，32 满弓，36 向 #582 放箭，箭数 19 变 18。[完整原图和战斗状态](archer/after)。
* [13 米兵线](final-line.jpg)和[49 米远景](final-wide.jpg)。22 米和远景保留甲衣的大色面，面部、甲片和小配件只可在近景分辨；远景服装对辨认盾/长兵的帮助有限，武器和队列仍是主要线索。

可复现的采集命令保存在[普通兵及实机动作工作流](../../../../.github/workflows/river-garment-master.yml)和[自然弓手射击工作流](../../../../.github/workflows/garrison-archer-review.yml)。[完整两侧录制](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43486113614)、[同相机弓手补拍](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43488312217)、[服装来源、改动与 CC BY-SA 3.0 归属](NOTICE.txt)。这组固定帧率采集没有测量 M5 帧率。
