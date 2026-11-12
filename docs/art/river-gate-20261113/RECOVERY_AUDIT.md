# Pro 未完成建模：接续来源核查

核查日期：2026-11-13（北京时间）。本次工作从用户要求“继续 Pro 未做完的建模”接续；以下是开始工作时的远端快照，并非对随后新增资产的评价。

## GitHub 中实际留下的内容

| 来源 | 核查基线 | 实际新增 |
|---|---|---|
| `main` | `d5498a6b0e03528ae5f28a85ed98fa3ade758fd1` | 已有河关 RC3 游戏与美术 |
| `design/river-gate-complete-art-20261113` | 同为 `d5498a6b0e03528ae5f28a85ed98fa3ade758fd1` | 与 main 完全相同；0 个新增提交、0 个文件差异 |
| `design/character-models-20261113-v1`，PR #33 | `938c1e14d65c35c2d818c6145d545e21ee8f7807` | 只有 72 行 `docs/CHARACTER_MODELING_DESIGN_V0_1.md`；无新增模型、参考图、地图或器械 |
| Codex `codex/river-gate-rc4`，PR #34 | `2293008c2d76dcbd788aeaef0fb871de1bc8eee1` | 另一条活动中的游戏美术与工程候选；状态 `ART_REVIEW_REQUIRED` |
| Codex 证据 PR #35 | `519060c3861773a46db725b11efb08a1ce0619bd` | RC4 实机记录；不等于 Pro 建模成果 |

因此，能从 GitHub 恢复的是角色设计草案和当前游戏底座。不能宣称已经找回“Pro 做了一半的全套模型”；这两个分支没有保存那类文件。此前会话临时空间是否存在其他未提交资产，本次未取得证据。

来源：[全套分支](https://github.com/haohongfei2001-png/luanshi-game/tree/design/river-gate-complete-art-20261113)、[角色设计提交](https://github.com/haohongfei2001-png/luanshi-game/commit/938c1e14d65c35c2d818c6145d545e21ee8f7807)、[PR #33](https://github.com/haohongfei2001-png/luanshi-game/pull/33)、[RC4 PR #34](https://github.com/haohongfei2001-png/luanshi-game/pull/34)、[证据 PR #35](https://github.com/haohongfei2001-png/luanshi-game/pull/35)。分支与 PR 会继续移动，历史判断以上表 SHA 为准。

## 已有资产的能力与局限

旧主线有 4 个 glTF/GLB 文件，没有 `.blend`：`river_company.glb`、`mounts.gltf`、`river_ram.gltf`、`grain_cart.gltf`。前三者分别提供衣甲/武器网格、坐骑/牵引轻车、冲车；最后一个是辎重车。

`river_company.glb` 含 28 个网格：5 种身体 × Close/Line，加 9 套武器 × Close/Line。身体 Close 为 4,622–5,052 三角面，Line 为 354–370；武器 Close 为 186–372，Line 为 6–60。文件中标准 glTF skin、animation、material 数均为 0。这是自定义网格库：`TEXCOORD_1` 编码骨号与权重，`company_motion.png` 存动作，`company_art.gd` 拼装后通过自定义着色器和 MultiMesh 驱动。因此“标准带骨骼 GLB 可以导入”与“已替换当前战役角色”是两件事，须分别验证。

现有生成源位于 `tools/art/company_figures.py`、`company_line.py`、`company_weapons.py`、`company_motion.py`、`figure_mesh.py`、`figure_atlas.py`、`bake_mounts.mjs` 和 `tools/env_assets.mjs`。动作合同与批次渲染可继续利用，不能据此推定旧模型画质已经获准。

## 具体视觉问题

已查看旧版真实 `soldier-portrait.jpg`、`gate.jpg`、`ranks.jpg`。`company_figures.py` 原头部轮廓从下颏 y=1.425 m 到颅顶 1.736 m，约 0.311 m；全高约 1.736 m，约 **5.6 头身**，与角色草案中 7.2–7.7 头身的自然比例不符。头宽约 0.26 m，肩宽约 0.50 m。近景因此有头大、玩具感的问题；改配色或增加甲片不能单独消除该问题。

场景主要问题是大面积重复草地、笔直岸线、重复的立面与巨大屋面，军队则有同脸、同盔、圆桶状袍裙和过度一致的轮廓。新资产应修正比例、穿着结构、材料尺度和地景层次，不能仅扩充粗糙模型数量。

## 本次记录的真实性边界

- 建模源、导出 GLB、结构验证、实际 Godot 预览、正式战役接入和目标设备性能分别记录。
- AI 概念参考与 Blender 展示图须明确标注来源；均不能称为游戏实拍。
- 当前未获得用户对新外观的视觉验收；不得把“生成成功”写成“用户已认可”。
- Codex RC4 是独立活动中的工作；本次独立资产路径不代表已覆盖或已合并该候选。
