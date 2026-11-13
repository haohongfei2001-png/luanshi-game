# 河关 22 米持械行进复核

产品源 `73a57949a496c6e25a49223205eadde6f357b485` 从 `126091196db530aa7ec13de61f839c9c41cac24b` 分出，只含离线动作源 `tools/art/company_motion.py` 和实际动作图集 `assets/river_gate/figures/company_motion.png`。图集尺寸仍是 528×1668，基础步态同时用于普通兵、步行将领与玩家。摄影、曲线检测和下列实拍另存在本分支。已有 Quaternius 原始步态数据和归属继续使用。

RC20 里普通枪兵的完整正步周期，骨盆总转幅 4.30°，肩线侧倾总幅 0.40°，躯干前后倾总幅 0.40°。接地时两肩跟着骨盆同向走，负重枪盾兵尤其像躯干随双腿整体搬运。第一稿的枪兵胸廓对骨盆反扭到了 49.33°，踏下时部分人出现上身独自晃动。选用的第二稿将它收回到 34.12°。脚承重时重心移到同侧，另一边肩向前送；重盾压在左侧、弩手收肘，长枪有承握的前臂和自由的后肘。调整只由已有运动曲线离线烘焙。

本人看过原尺寸 1920×1200 的正反窗口、等速序列中的连续步相和原生视频帧。第 12 步正面镜头在展开的蓝军里，左盾、持枪和右手持短兵的人有不同的前倾量。第 41 步逆向镜头能看到推进中的肩线与已经停下持械的人区分。第二次摄影改跟开阔地的真实枪兵 167，随后转到战斗中的 37，解决了第一稿镜头被树冠挡住的问题。静帧中局部区别小于连续步相；近身服装本身依然有硬折。本次不包含袖甲两个退稿。

固定种子 61112，双方各 512 名普通兵。用 Godot 4.6.3、Ubuntu 24.04、Mesa llvmpipe 兼容后端录制，以 1.0 内部分辨率输出。每个版本在三个相同步分别拍摄正反两向，随后重新开始同一个真实场次，按 20 次/秒实际模拟节拍录下 76 步，1280×800，前 38 步看 167、后 38 步逆向看 37。相同第 41、61 步长枪手 37 起手、第 46、66 步进入收势，实走 6.210 米、累计命中 2 次；第 76 步全军命中 239/129、伤亡记数 21/57。两次运行的全帧镜头、十名兵的状态、血量、朝向、位置、攻击、两军伤亡和军令文件逐项相同。

枪兵成品图集正步的骨盆转幅 10.10°、肩线侧倾 12.57°、上身前后倾 11.26°，盾兵分别为 10.05°、11.26°、13.06°。417 条已有动作中改变 207 条行走、跑动和静止持械轨。其余 210 条逐字节相等，含九兵器击发、受伤和格挡方向、伏骑、溃逃、倒地。左右靴轨共 834 条全部相等，按现有 16 向走跑采样的最坏支撑脚漂移为 0.765 毫米。所有改写行最大腕口偏差 0.166 毫米，已有九武器回归的弓弦与手偏差为 0；36 条专用反应轨逐字节相等。这次只测动作和真游戏交战画面，未测硬件帧率或 M5。

复验动作源时运行以下命令。两个工作树的实际图像和输入回放命令在 [工作流](../../../../.github/workflows/loaded-advance-window.yml) 中。

```sh
PYTHONPATH=tools/art /usr/bin/python3 -c 'from pathlib import Path; from company_motion import bake_motion; bake_motion(Path("assets/river_gate/figures"))'
/usr/bin/python3 tools/art/check_company_motion.py
/usr/bin/python3 tools/art/check_contact_motion.py
/usr/bin/python3 tools/art/check_loaded_advance.py /tmp/rc20-company_motion.png assets/river_gate/figures/company_motion.png
```

[本轮完整托管记录](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43523499380) · [原始正面](after/front-012.png) · [原始逆向](after/reverse-041.png) · [RC20 原片](before/advance.mp4) · [成品原片](after/advance.mp4) · [等速并排](equal-speed.mp4) · [逐步战局](after/film.json) · [骨骼实测](motion.json) · [第一稿](https://github.com/haohongfei2001-png/luanshi-game/tree/dafbd46431f2563ce4e225b6e1e5063dba4688c7/docs/evidence/river-gate-v1-rc21/loaded-advance)
