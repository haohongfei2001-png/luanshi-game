# 河关军士的盔与巾

角色仍使用原来的头部绑定、身高、脸、手、武器、伤害判定和批次。弓弩手穿有额缘与颈后垂带的软帻，枪刀兵穿转缘浅盔，持盾与长刀重装使用向颈后下垂的护片，军官使用压低的束缨。部分征募兵保留头带，主角沿用发髻。头饰独立于 HM08 的脸、既有衣甲与动作资源。

Wildfire Games 的四件 0 A.D. 服饰母版均可按 CC BY-SA 3.0 再分发。上游原作者提供的 COLLADA、版本、文件哈希和本次适配步骤可追溯。这是架空军队的服装改编，不能据此断言装备是唐代实物复原。[同包归属](../../../../assets/third_party/wildfire_headwear/NOTICE.txt)、[可编辑变换](../../../../tools/art/fit_field_headwear.py)

前两轮均未选用。第一轮浅盔在侧光中出现黑斑。其 168 个面中有 84 对几何重合、方向相反的面，在双面着色中给出相互抵消的法线。移除反向面后仍能从高处看穿部分后冠，实测这一母版不能独立封住后冠。改用闭合的骑兵刀手兜鍪、按实际头型重切额缘后，再把它作为普通军士的军需头盔。重装护颊的着色改沿连续外壁，第一版按三角形高度分档会留下一排锯齿。前两轮原片保留。[首轮](https://github.com/haohongfei2001-png/luanshi-game/tree/bf763fae1e463b4ab82d74b6ff8c30c20f7c57c6/docs/evidence/river-gate-v1-rc20/headwear)、[第二轮](https://github.com/haohongfei2001-png/luanshi-game/tree/b6ff0664c8c12c7e2cfecb0642f9057ff04c3240/docs/evidence/river-gate-v1-rc20/headwear)

三次均在托管 Ubuntu 24.04 / Godot 4.6.3 / X11 Mesa llvmpipe 下，用官方引擎启动同一战役。起始双方各 512 名普通士兵，并各有 16 名军官。正反机位的正常镜头均为 22 米，画面 1920×1200、内部缩放 1.0。第 41 步双方命中计数 78/35、损失 1/11。第 48 步玩家 #1056 使用枪击中 #584，其生命由 62 变为 39.7627。原速 20 Hz 录像在同一场景跟随弓手 #94 与枪兵 #37 共 102 步，枪兵实际运动 7.7067 米。[两边原始逻辑步和原片](after/film.json)、[同一命中](after/input.json)、[原速对照](equal-speed.mp4)、[单窗原速录像](after/march.mp4)

* 两个可独立打开的 22 米原始窗口分别是[阵线](after/line.png)与[反向阵线](after/reverse.png)。[同击窗口](after/personal-contact.png)
* 近景用来检查帽沿、颈后和脸的交界。[普通枪兵](spearman-pair.jpg)、[弓手](archer-pair.jpg)、[盾兵](guard-pair.jpg)、[军官](officer-pair.jpg)
* 当前批次的 GPU 绑定、画面和伤亡属于云端等速画面检查。M5 的真实持续帧时间仍待真机测量。[烘焙和实机作业](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43515355514)

第三版在实际正向窗口中能分出低软帻、浅色转缘铁盔、长护颊和原有发髻。反向机位军官的短束缨容易融入人群，不能据此认为全军美术已经获验收。四件独立头饰分别为 54、96、236、344 个三角形，共 29,980 字节。弓手、步兵和军官使用现有头骨并入原有批次，未添加逐兵节点。[第三版实机网格回执](fit.log)、[完整产品差异](https://github.com/haohongfei2001-png/luanshi-game/commit/1824f9afca93554569af1e5900ec327d3cce174e)
