# 22 米军服辨识

左侧采用 RC17 `280ee8d9`，右侧采用 `5cab87bc`。普通步兵用靛染和茜染的肩衣区分，甲面与挂带沿用原材料。弓手上半身留出一整片交领色面，左右身体转向时仍能跟随曲面辨认。枪盾兵保留深铁色甲身，衣料从护肩和袖根露出。主角以偏灰的浅靛左半披覆在深色装束外。颜色域随军服的既有裁片、蒙皮和三档距离，士兵、屏幕比例、镜头与光照参数相同。

* [正常跟随镜头落枪一击](personal-contact-pair.jpg)。在同一个游戏 tick 48，主角 #1056 从 1.81 米击中 #584，生命 62 降到 39.76。[原始新画面](after/personal-contact.png)。
* [正视阵线](line-pair.jpg)和[反向看同一阵线](reverse-pair.jpg)。到 tick 41 时正向可见普通士卒为友军 161、敌军 107，反向为 158、126。两边均有远射部队、长枪和盾牌。正反两机位固定在世界 (0,−13) 并相差 180°，两版本分别复核屏幕内的单位 ID 散列、站位和镜头。分队服色在背光方向仍可区分，地面前后明度不变。枪尖、弓身和盾板仍负责兵种辨认。[正向原始画面](after/line.png) · [反向原始画面](after/reverse.png)。
* [第一轮试染原图](https://github.com/haohongfei2001-png/luanshi-game/blob/4d44289883e2e90b83726e88fe578cf22704fd7e/docs/evidence/river-gate-v1-rc17/field-livery/after/line-window.jpg)。正光区的部分红肩太接近桔色，第二轮收窄织物亮面的响应，改为偏灰的靛色与较暗茜色。在[第二轮同镜头](https://github.com/haohongfei2001-png/luanshi-game/blob/d7eeb8fbf20638c93e2fec4f7a486c1b0b571ee0/docs/evidence/river-gate-v1-rc17/field-livery/after/line-window.jpg)里，向阳弓兵的衣领和脸仍接近同一块暖色。选用的第三轮将陈茜红移向绛红，并保留原交领较暗的内折，近颈能看到一层布边。

实际拍摄使用 GitHub Ubuntu 24.04、Godot 4.6.3、X11/llvmpipe，原始游戏窗口为 1920×1200，内部比例 1.0，512+512 名普通兵、16+16 名军官另计，固定种子 61112。固定时步供同帧比对。在拥挤的密集区域，一部分脸、手和肩衣继续被邻兵兵器遮挡；本次固定时步采集没有测量真实 M5 性能。[最终工作流、日志与原图归档](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43495906846) · [复核状态与投影坐标](after/line.json)。
