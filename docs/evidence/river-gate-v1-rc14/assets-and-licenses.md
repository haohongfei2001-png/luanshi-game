# RC14 实装资产与再分发来源

| 游戏中的资产 | 作者、来源与实际导入 |
|---|---|
| 人物与武器 | 身体、分片甲衣、头巾、肩披、九武器网格及持械动作由项目制作。MakeHuman HM08 的青年男性头部采用 CC0；公开来源、提交、裁取与简化流程可复核。生成的 GLB、附属服装 glTF、色图与动作贴图实际由正式战场的近中远三个等级读取。[角色源与授权](../../../assets/river_gate/figures/SOURCE.md) · [MakeHuman CC0](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md) |
| 马匹与鞍装 | 本项目的马身、口鼻、四肢、鞍座、鞍鞯与镶边使用同一套 glTF 节点和两档网格。毛色由批次实例数据选择。[马匹制作文件](../../../assets/art/mounts/README.md) |
| 地形、内陆树冠与河岸 | 此版本用项目的源网格、四张原创 AI 辅助二维画材、旧地绘覆盖与地图实测地形。原作网格含浅底船、内肋和船凳。早期三张 Poly Haven CC0 基材的原链接、作者、哈希与使用位置留在环境记录。此次材料已进战场；用作参照的商业游戏画面均为外链。[环境资产](../../../assets/environment/README.md) · [实际材料与生产记录](../../../tools/art/source/river-surface-materials.md) · [Poly Haven CC0](https://polyhaven.com/license) |
| 地图、军旗、声音与字形 | 依真实场地生成部署底图，普通指令、伤害与移动事件驱动原有游戏混音。军旗织缘与旗面、地形图和 UI 由项目制作；字体、引擎等第三方声明随导出包的 THIRD_PARTY_NOTICES.txt 一并分发。[地形著色及地图作者源](../../../tools/env_survey.mjs) · [音频事件](../../../scripts/field/sound.gd) |

在 Ubuntu 24.04 的 Godot 4.6.3 正式导入中复现。人物源可用 `python3 tools/art/bake_river_company.py` 重建；`python3 tools/art/check_company_motion.py` 对照动作，`node tools/art/bake_field_garments.mjs --check` 和 `node tools/art/bake_mounts.mjs --check` 核对衣装、马匹，`node tools/env_assets.mjs --check-skiff` 核对船体。原始 1920×1200 检查见 [CI](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43466044060)。

取得的额外第三方资产及后续试作另记。RC14 安装包的来源以本页和 [导出提交](https://github.com/haohongfei2001-png/luanshi-game/commit/584870655703f3b7f7cfd927500880ce4d966818) 为准。
