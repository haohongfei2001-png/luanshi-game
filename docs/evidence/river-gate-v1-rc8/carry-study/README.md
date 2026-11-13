# 河关 RC8 之后的步兵持械试作（单独的可运行源码）

正常 22 米跟随镜头里，RC8 相邻枪兵经常有相同的肩线和持枪角。这里为长兵、长刀与盾兵分别增加两种原创负重姿势，用已经存在的稳定个体标识分配。袍、躯干、髋、握持双手和兵器来自同一动作轨道；到真正命中时，姿势仍与发行候选的一致。未改 AI、单位数量、装备伤害、主角输入、将领或任何存档。参考的是 [Riot 对轮廓、朝向与视觉层级的说明](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)，没有使用其人物、贴图或动画。

**自行评估：局部有用，整幅仍不过关。** 在正常镜头，同一列长兵有把枪斜扛在肩侧的，也有提前压低前端、髋膝降低的。近景的枪尖和支撑手能够区分；原来整齐的兵器斜线在运动中有所打散。远景兵种的肩颈、头盔、袍甲宽窄仍接近，主角接敌时几根长杆仍会在目标身上交叉。场景、马匹轮廓没有被这一改动解决，**不据此提升候选版本，不代表整体视觉验收**。[正常跟随同一次命中](normal-pair.jpg) · [22 米实机阵线](formation-pair.jpg) · [近景](close-pair.jpg)。均为左右两个未插值的 720×520 原尺寸窗口裁片；完整 1920×1200 PNG 以及两段 30 帧动态对照见[原始录像及动画文件](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43361600180/artifacts/14008596647)。

Godot 4.6.3，Ubuntu 24.04 / llvmpipe，512v512 另有 32 名军官与主角，种子 61112。第 65 步的 12.5/22/42 米镜头实屏内普通兵 72/148/362，三档前后单位 ID、位置、军籍、命中和相机记录一致；推进到第 85 步双方累计命中 282/149。默认亲战第 43 步目标 584 的血量 62，第 48 步实际 39.76，距离 1.81 米；两份输入记录逐项相等。片段检验动作，并非性能样本。[基础动画检查与一次失败的编码环境](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43361092561)缺少 ffmpeg，保留了原始帧；[后续重用相同帧，只补拍试作并完成编码](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43361600180)。

旧的 279 段烘焙动作的所有字节完全相同；新加入的 102 段在 9 个武器共用的原始库之后，着色时每骨采样次数不变。102 段的最大腕缝 0.1673 毫米，实际打击关键帧相对原库的偏移为零。未引入额外网格批次；动作纹理从 528×1116 增到 528×1524，RGBA8 未压缩约多 0.82 MiB，纹理 SHA-256 `83c4fcda863bf0912cd418e47feddff28d54dbfd68454fa056732058ae4cc5e2`。**没有测此分支的 Metal 帧时间、冷启或真实 M5。** RC8 的安装包不含这里的改动。

在独立云主机检出这个分支，`./tools/prepare-font.sh`、`godot --headless --editor --path . --import`、`godot --path .` 可直接运行。`python3 tools/art/check_field_carries.py` 检验提交的烘焙。要复现三个阵线镜头：`godot --path . --resolution 1920x1200 --fixed-fps 30 --script tests/field_carry_camera.gd -- --field-size=512`，实际亲战用 `tests/rc7_personal_contact.gd`。下一次先重做盾兵与布衣征卒两种体型、头颈、肩袖与下摆的主要色面，在相同 22 米画面比较，再考虑与可下载候选合并。
