# 河关坐骑肩臀实机对照

每张并排图的左半为 RC10，右半为本次改动。图像均取自实际 Godot 窗口，每半为原生像素裁切。颜色、光照、演员、路线、镜头尺寸、朝向和游戏状态直接沿用各次回放。六张永久 JPG 是从同次运行输出的 PNG 裁切生成。完整窗口、收据与影片在运行工件中。

| 视角 | 原像素并图 |
|---|---|
| 骑手 150 左侧，含肩、鞍和尻 | [moving-profile.jpg](moving-profile.jpg) |
| 骑手 150 后四分之三，含臀形转折与尾根 | [rider-rear.jpg](rider-rear.jpg) |
| 骑手 150 右前侧，第 92 tick | [opposite-092.jpg](opposite-092.jpg) |
| 正常 22 米队列 | [formation-22m.jpg](formation-22m.jpg) |
| 营门站马，前四分之三 | [saddle-standing.jpg](saddle-standing.jpg) |
| 营门站马，后四分之三 | [standing-rear.jpg](standing-rear.jpg) |

RC10 源码 `c3e39a78a6028aa2d396f1cc37757f02c56a9679`。最终坐骑 `2d79aade3766824396e8c11a8389b656c700b369`。[回放脚本与工作流](https://github.com/haohongfei2001-png/luanshi-game/tree/61a82adb76932ffadcf9473cd5e195d79331a3c5) 与正式资源在独立的分支上。

实机回放使用 Godot 4.6.3、Ubuntu 24.04、Mesa llvmpipe 兼容后端。固定种子 61112，双方各 512 名普通兵，窗口 1920×1200。前后两套源码各截 12 张全图并收录 100 个连续画面，骑手 150 在相同 5 秒游戏时间内移动 9.943615 米。两侧镜头收据逐项一致。两版 `node tools/art/bake_mounts.mjs --check` 均在托管运行器通过。这次固定步进录像只用于画面。M5 性能仍待实机测量。

首次修订在侧面与后侧压掉方形亮斑，复看发现臀头过圆、亮色鞍后桥还会被看成另一片硬块。第二次修订压低鞍后桥，让臀部顺着后膝转折。第 8 和第 33 tick 的反侧机位被路边树冠遮挡，第 92 tick 的前胸和鞍下侧面可见。原始失败视角也在完整工件内。深色马毛在低照背侧的肌理仍较平。

- [第一次修订截图和录像](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43397792374/artifacts/14024435647)
- [最终截图、原始收据和三段 MP4](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43400591082/artifacts/14025271558)
- [最终运行和完整日志](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43400591082)

最终原始 ZIP 的 SHA-256 为 `e895b1931db2626158846095a7a7e939998d9eb382e13ea54322787f201ad81f`。

```console
[["SaddleClose",3743,7050],["SaddleRank",670,1116],["DraughtClose",5165,9536],["DraughtRank",1412,2348]]
OpenGL API 4.5 (Core Profile) Mesa 25.2.8-0ubuntu0.24.04.4 - Compatibility - Using Device: Mesa - llvmpipe (LLVM 20.1.2, 256 bits)
MOUNT_LIVE_PASS id=150 travelled=9.94361538439989m shots=12 frames=100 seed=61112
[["SaddleClose",3723,7010],["SaddleRank",918,1612],["DraughtClose",5145,9496],["DraughtRank",1654,2832]]
OpenGL API 4.5 (Core Profile) Mesa 25.2.8-0ubuntu0.24.04.4 - Compatibility - Using Device: Mesa - llvmpipe (LLVM 20.1.2, 256 bits)
MOUNT_LIVE_PASS id=150 travelled=9.94361538439989m shots=12 frames=100 seed=61112
MOUNT_PAIR_PASS 12 61112
```
