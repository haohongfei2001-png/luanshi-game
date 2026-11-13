# 河关 0.16.0-rc.9 试玩记录

**艺术自审未达标。** 默认战场里，轻兵的布肩、重盾的木板和主角的绛披已经能从阵中辨认。最明显的缺口仍然在整屏：前排甲兵的肩髋和发力相似，敌我侧身时都以灰甲为主，马脸在近景偏硬，树冠中层重复，河岸直线与裸岩过于整齐。这版保留给玩家试玩，也保留可回退的 RC8。

[下载 macOS 包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624/artifacts/14014222258) · [59.2 秒完整军旅回放](playthrough-review.mp4) · [1280×800 立体声原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624/artifacts/14015470539) · [1920×1200 默认跟随镜头](normal-full.jpg) · [RC8 / RC9 同时刻阵前对照](formation-rc8-and-rc9.jpg) · [全部原图、34 秒连续战线与同镜头录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624/artifacts/14014862187)。

## 包与复现

[游戏 PR #43](https://github.com/haohongfei2001-png/luanshi-game/pull/43) 最终源码 `be80dc767dc5dcaa3f6e217fbcce93f3dc1347b7`，实际导出提交 `1ec3a54c97b8fc87ad476c9e97918d26a1813e0f`，main 游戏合并 `4a3ebc4d3c8e687337b27829c6bc13be20810f09`。已比较后两者完整 Git tree，均为 `1b665850dd2d21e4a11cbf5295d8c44d6765bfe9`。六项 GitHub CI 均通过。[完整记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624)。

解开 Actions 附件，再解开内层 `Luanshi-macOS.zip`，打开 `Luanshi - Border Skirmish.app`。内层 ZIP SHA-256 为 `99cf54f3954549cc042fee1f1af3031af4b64677bc1d773ca07a8a1b493bb8fe`。托管 macOS 运行了这份包。下载[Linux 版](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624/artifacts/14015020189)的归档内文件 SHA-256 为 `8532da7d806f7d9f88155565c9413711ba988fc5dbde2c5c745ab5701a6de382`。本次为开发候选。

## 实际退回和修正的画面

1. 第一轮重建征卒的束袍、卷袖和脸型，盾兵低盔、裙甲和曲面木板，主角不对称披肩，以及马匹中远景背线和关节。看默认视角时，两军的浅衣太亮，改为偏灰的麻布并把军色抬到肩部。[第一轮窗口](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43366685292)
2. 第二轮发现角色远离城门时，巡视镜头仍掀掉了整座屋顶。已用屋顶实际遮挡范围和近战视距控制，并加上中央木楼、墙窗和支承。新冲车收短后篷，悬梁从前臂和吊索之间可见。黄色平路和球状榆冠在自审中退回。[未采用的实帧](rejected-terrain.jpg) · [最终门楼](gate-full.jpg) · [近景马匹与冲车](horse-and-ram.jpg)
3. 第三轮将榆树改为有枝叉和空隙的叶簇，恢复路面的旧辙与断续草边，桥两侧有草皮下沿和入水岩台。相同种子、时刻、摄像机、人数、实际屏内 ID、命中与伤亡全部相符。12.5、22、42 米的同场镜头分别有 72、148、362 名普通兵真正落在画幅内；全战始终按双方各 512 普通兵、另加 32 军官和玩家计算。[河岸](river-window.jpg) · [近阵](front-12m.jpg) · [远阵](ranks-42m.jpg) · [全部匹配取景和血量](three-window-studies.json)
4. 第一次全包回归在军议近景发现盾挡到鼻梁，握剑手检测为 0。降低休息时的盾板、把握点移向内侧、左前臂斜挂，保留抬盾格挡。原来的相机、肤色取样和门槛未改，同一帧最终脸部 19、持械手 106 个像素通过。102 条负重变化在命中端点相差 0，烘焙最大腕缝 0.168 毫米以内。[失败图](guard-before.jpg) · [修正图](guard-after.jpg) · [动作与握点记录](guard-orbit.json) · [曾失败的整包回归](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43371530553)

默认 22 米真实鼠标出枪，主角第 43 步起手，第 48 步击中 584 号敌兵，生命 62 降至 39.76。军事任务和普通游戏入口运行了部署、亲战、军令、战报、驻营、继续行军、F5/F9、打开旧存档；59.2 秒片含 888 帧、双声道，第 1030 步结算，战后推进一小时。另有 30 FPS、1020 帧的连续随军战斗。九武器依次实际命中 3、2、3、3、3、5、3、3、5 次。将领回归、骑马与战车、护送、胜败及撤离通过。自然攻城第 518 步伤门、第 630 步破门、第 1000 步守住内庭胜利，双方将领各造成 7、6 次击杀并经历 6、4 次指挥继任。[九武器及完整攻城原片](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624/artifacts/14014891844) · [军议、军令和战后存档回归](raw/journey.json) · [图形与战役检测](raw/field.json)

## 性能和冷启动

托管 `Apple M2 Pro (Virtual)`、Apple Paravirtual GPU、默认 Metal，实际窗口 1024×645、渲染附件与内部都是 1024×640，比例 100%，4× MSAA，阴影开。含移镜的 24.002 秒有 5,889 帧、1,124 次新增命中；平均 245.35 FPS，P50/P95/P99 为 3.432 / 10.288 / 12.594 ms，RSS 峰值 541.0 MiB，最慢 48.986 ms。60 / 90 / 120 Hz 帧预算各有 3 / 162 / 491 帧超出。最长帧出现在移镜边界后 250 毫秒内；这个时序不能单独判明原因。模拟和显示脚本分别均摊 0.640、2.118 ms/帧；设备未回报非零 GPU 时间戳。[原始 macOS 证据](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43374886624/artifacts/14014556794) · [逐帧预算和分段](raw/frame-budget.json) · [计算过程](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43377555178)。

独立新进程与空游戏目录的 9 次窗口试验全部完成，记录了场景、首帧、部署、首个命中和非黑 PNG。系统驱动缓存保留；包括兼容渲染器和默认 Metal 分别两次自然启动。上一个工程点在另一台托管虚拟 M1 的默认窗口为 P95/P99 12.527 / 16.692 ms。不同宿主/代码条件无法用来计算优化提升。RC8 曾有第零步启动失败，RC9 增设了只采自身游戏进程的超时诊断，此次没有复现那次故障。[九项原始启动与环境记录](raw/native-windows.json)。

Linux 为 Ubuntu 24.04 的 llvmpipe 软件光栅，1280×800，100% 内部比例、4× MSAA、阴影，每档 20 个实战图形帧。表内 RSS 为 MiB。它用于重现负载，无法代表 Apple GPU。

| 每方普通兵 | 平均 FPS | P50 / P95 / P99，ms | RSS | 新增命中 |
|---:|---:|---:|---:|---:|
| 20 | 4.27 | 232.20 / 255.81 / 256.55 | 816.0 | 33 |
| 100 | 2.52 | 399.36 / 439.87 / 446.35 | 890.1 | 172 |
| 250 | 2.15 | 461.17 / 486.61 / 491.98 | 947.3 | 262 |
| 512 | 1.71 | 582.42 / 626.82 / 630.00 | 987.1 | 288 |

**真实 MacBook Air M5 为 NOT_RUN。** 内屏、4K 120 Hz 外屏、高画质至少 20 分钟和热稳态均待真机验证。[正式质量标准](../../OWNER_QUALITY_FIDELITY_PERFORMANCE_TARGET_20261113.md)。

## 下一次实机复看

在独立云端检出本页游戏提交，执行 `./tools/prepare-font.sh` 与 `godot --headless --editor --path . --import`。在有显示服务的环境运行 `godot --path . --resolution 1920x1200 --audio-driver Dummy --disable-vsync --fixed-fps 30 --script tests/rc7_personal_contact.gd -- --field-size=512`。用该窗口和 `tests/river_craft_camera.gd` 同种子的 12.5/22/42 米实帧，先复看枪兵进攻的肩髋发力、敌军重甲侧影和骑兵马头，再复看成排时的轮廓与地形。全军最终美术和整部游戏仍在开发。
