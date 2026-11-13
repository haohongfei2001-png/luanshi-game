# 河关人物与地形试作的实机记录

RC13 已被退回。这些文件来自河关正式战斗场景的各次试作，完整候选的战报、安装包及硬件测量由同一源码另行归档。

- [步兵推进、转身与交锋](infantry-motion.mp4)保留相同的 73 个跟随画面。[22 米原位置对照](infantry-22m-pair.jpg)与[盾兵近镜](shield-pair.jpg)包含不同肩线、裙片和握点。生产源 `0dfd1c075652c5b603e99d3abdbb9df93311311c`。初次拼图环境缺 Pillow，中断发生在录制以后，随后复用了两边原始画面。[原片与日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43459976982/artifacts/14055957349) · [复用原片生成的对照](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43462893645/artifacts/14056583283)
- [弓手的实战松弦](bow/equal-speed.mp4)、[正面和旧版并排](bow/draw-front-native-pair.jpg)、[实际 22 米取景](bow/draw-normal-native-pair.jpg)与[29 个游戏步的记录](bow/frames.json)来自同一名弓手。第 25 步开始蓄力，第 32 步引满，第 36 步出箭，余箭从 19 变为 18。双箭囊被收为一具，搭在弦上的箭杆连接到飞箭出现的时刻。[原始 1920×1200 图与影片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43462682084/artifacts/14057162048)
- [头巾背侧](bow/headcloth-side.jpg)与[状态记录](bow/headcloth.json)摄于相同放箭动作，生产源 `82270fed42b66845b8f0e220f7a3e43dc4036fb2`。近景布顶现在盖住发髻。[本轮原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43464234177/artifacts/14057508831)
- [河岸窗口](river-bank.jpg)和[主战场地表前后对照](pasture-pair.jpg)取自 `f5daf78224b798670eab852c2a881a9e16cdd356`。中桥木舟起初呈现为一舱水，实拍后按船体吃水线切开河面。试作中浅绿的坡地缺乏草形；保留地上原有的草丛与压实土表，再沿路肩画出大片阴阳和实物草根。原片中的树冠仍有规律的折面。[原窗口、输入及军籍](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43465088036/artifacts/14059300525)
- 旧盾兵的颜色阈值测到了盾面。在固定取样区，以着色材质标识重放，旧盾侧区全为木色。改动后的持剑侧区实际出现 7 个皮肤像素。实图中的手仍小，相邻旗杆与枪杆仍有遮挡。[材质分辨窗口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43458261395/artifacts/14054318445)

美术仍为 `ART_REVIEW_REQUIRED`。窗图由 Godot 4.6.3 原始画面转码。战斗上下文为种子 61112、双方各 512 名普通兵，主角与军官另计。
