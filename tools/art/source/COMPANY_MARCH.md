# 行军动作母版

河关的步行、持械列队与跑步采用 Quaternius 的免费 Standard 版 Universal Animation Library 中的 `Walk_Loop`、`Walk_Formal_Loop`、`Jog_Fwd_Loop`。作者在包内 `Animation Library[Standard]/License.txt` 标注 CC0。公共源仅保存可复现的转换器、三组骨骼曲线及游戏使用的共享动作纹理。[作者和许可](https://quaternius.com/packs/universalanimationlibrary.html) · [作者分发页](https://store.godotengine.org/asset/quaternius/universal-animation-library/)

取得的原始 ZIP SHA-256 为 `18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2`。转换器核验归档及内置 CC0 文本，按左脚前踏同步，用躯干与脚的实际跨度换算米制。每个循环保留 32 个骨盆和肩带采样。持盾、长兵及轻兵各有承重，挥击、触盾、受伤和倒地仍读取原本的动作段。

在云端使用 `python3 tools/art/import_company_march.py Standard.zip tools/art/source/march_curves.json` 重新取样，然后运行 `python3 tools/art/bake_river_company.py`。游戏用同一张 GPU 调色板完成三档的骨骼运动。母版源艺术归 Quaternius。
