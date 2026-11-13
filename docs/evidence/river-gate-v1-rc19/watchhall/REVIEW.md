# 河关城门、驿道与岸边

[最新全窗对照](gate-pair.jpg) · [夕照反向的门洞](after/ramp.png) · [中央部队](after/army.png) · [攻门阵列](after/approach.png) · [河岸](after/bank.png)

同一场河关战役，第 48 与第 490 步；初始双方各 512 名普通兵和 16 名军官。1920×1200，4× MSAA，100% 内部比例、阴影开启。Linux 图形运行器用 Godot 4.6.3、Xvfb 与 Mesa 软件 OpenGL。以 RC18 源 `01bcdb90a1edbc41d8cb43de61abe37b0461f357` 重放，同机比较六处相机、时刻、入镜普通兵 ID 摘要、生命事件、伤亡与门的耐久。门楼俯视图可数到 349 名入镜普通兵；地图上仍有双方共 1024 名普通兵。[逐帧记录](after/views.json) · [前版记录](before/views.json) · [屋面遮挡回归](gate-sightline.log) · [图形作业](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43508615220)

前一版城门由重复的几何屋顶组成。新的八米门洞使用 Wildfire Games 的 Han 墙门建筑母版，依据河关的实际通路、城台和视线适配。屋脊两侧的三角面按交点切开；当玩家在门楼下，镜头可收掉当前阻挡侧。相机移远后重新看见完整屋面。门板耐久、军队路径、守军坡道照旧使用战役数据。原始建筑引用的是汉式门楼，河关保留架空的时代设定。

第一个尝试在实机出现黑瓦和颜色过黄的空路。第二次校正面对光线的屋面，恢复道路车辙与草带的中间色；反向镜头仍露出沿三角形边线的半幅斜刺。第三次切到了实际屋脊，旧路石分成嵌土的短段，林缘暗部用树冠整体的日照方向，上层不再随叶片正反交替发黑。[第一版原窗](https://github.com/haohongfei2001-png/luanshi-game/blob/bd08bb0183ad1b43463eb3f4307ab6508b67c15b/docs/evidence/river-gate-v1-rc19/watchhall/gate-pair.jpg) · [第二版反看门楼](https://github.com/haohongfei2001-png/luanshi-game/blob/052cdac4e23b3edaaf1350f165dbc731b4f7fe3b/docs/evidence/river-gate-v1-rc19/watchhall/after/ramp-window.jpg) · [第三版原始图集](https://github.com/haohongfei2001-png/luanshi-game/tree/82ee4e3752d705f9a2aa52a4c36f57bde1c115d8/docs/evidence/river-gate-v1-rc19/watchhall)

全窗仍能看出角台和城内屋舍的造型重复。树冠比较整齐，桥头柳枝与河滩比城门更稀，远景和目标效果间仍有差距。项目以实际交战画面继续验收。

复现可在 `git checkout 82ee4e3752d7` 的独立检出运行 `./tools/prepare-font.sh`，接着运行 `godot --headless --editor --path . --import`、`xvfb-run -a -s '-screen 0 1920x1200x24' godot --resolution 1920x1200 --audio-driver Dummy --disable-vsync --fixed-fps 20 --script tests/watchhall_view.gd -- --field-size=512`。当前待测为实际 M5。
