# 河关独立美术预览

这一入口读取 `assets/river_gate/art_v1` 的实际标准 glTF 模型。它不读取战役存档，不创建战斗模拟，也不替换默认游戏入口。

## 打开

使用仓库 CI 同版本的 Godot 4.6.3，或兼容的 Godot 4.6+：

```bash
godot --path . scenes/art_review/river_gate_review.tscn
```

| 操作 | 内容 |
|---|---|
| 1 / 顶栏按钮 | 双方全部17种角色，LOD1军容排列 |
| 2 | 同一角色双方近景对照 |
| 3 | 器械与环境模型；扩展器械仅资产预览 |
| 4 | 236×128米河关地图 |
| 5 | 512+512个静态LOD2人物，按双方MultiMesh合批 |
| 空格 | 角色待机 / 行走 / 攻击动作；第五页不播放动画 |
| L | 近景人物LOD0 / LOD1 / LOD2 |
| 左右方向键 | 切换近景角色 |
| WASD / 右键拖动 / 滚轮 | 平移 / 环绕 / 缩放 |
| H | 显示或隐藏说明 |

第五页把样本待机姿势烘成静态网格，再复用到1024个实例。它没有AI、伤亡、寻路、命中或动画更新成本，不能证明正式千人战斗性能。

## 真实截图与出处记录

```bash
GODOT=/absolute/path/to/godot tools/art_review/capture_review.sh army /absolute/path/godot_army.png 45
GODOT=/absolute/path/to/godot tools/art_review/capture_review.sh portrait /absolute/path/godot_commander.png 45 --art-role=commander --art-lod=0
GODOT=/absolute/path/to/godot tools/art_review/capture_review.sh equipment /absolute/path/godot_equipment.png 45
GODOT=/absolute/path/to/godot tools/art_review/capture_review.sh map /absolute/path/godot_map.png 45
GODOT=/absolute/path/to/godot tools/art_review/capture_review.sh crowd /absolute/path/godot_crowd.png 45
```

输出PNG旁同时写入JSON和运行日志。JSON记录引擎版本、渲染器、显卡/软件适配器、镜头、分辨率、模型路径与SHA-256、截图SHA-256。缺少当前视图需要的资产时，脚本失败，拒绝生成完成截图。

无图形会话的Linux环境需要Xorg、dummy驱动、xauth及Python 3。脚本为本次启动创建临时授权cookie，禁用TCP监听，退出时关闭自己启动的显示服务并清理临时文件。默认强制软件OpenGL以便复现；这些图像可以证明资产进入引擎，不能当作M5性能结果。

## 无图形的导入检查

```bash
godot --headless --path . --script tools/art_review/validate_imports.gd
```

这个检查直接通过 `GLTFDocument.append_from_file()` 和 `generate_scene()` 导入每个GLB，记录网格实例、骨架、动作和文件hash。默认输出 `docs/art/river-gate-20261113/godot_import_report.json`；可用 `-- --art-report=/absolute/path/report.json` 指定位置。它只证明文件可由Godot导入，不证明实际画面、战役替换或目标设备帧率。

API依据：[GLTFDocument](https://docs.godotengine.org/en/4.6/classes/class_gltfdocument.html)、[MeshInstance3D骨架姿态烘焙](https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html#class-meshinstance3d-method-bake-mesh-from-current-skeleton-pose)。
