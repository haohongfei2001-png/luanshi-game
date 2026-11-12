# 河关军容资产

河关的五种衣装、甲片、披风、头巾、马尾盔缨、九种兵器、调色和动作由本项目制作。游戏从 `river_company.glb` 合批绘制近、中、远三档，并从同一个动作库读取步伐、发力和失衡。躯干和袖子共用缝边顶点。持械手和武器共用握点。角色进入新的显示距离后沿用同一套姿势与相位。

脸和耳朵的形体使用 MakeHuman 团队的 HM08 头部网格及青年男性形态，已按 CC0 1.0 公开。取材文件为 `data/3dobjs/base.obj` 和 `data/targets/macrodetails/asian-male-young.target`。来源的版本、Git blob 校验、裁取范围和简化方法见 `tools/art/reduce_field_head.py`。额头、帽檐、眼睑、布料、铁甲和双色披风在游戏内重新贴图与装配。 [上游资产原文](https://github.com/makehumancommunity/makehuman/tree/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data) · [上游 CC0 授权](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md)

Python 3 与 Pillow 可用时，运行 `python3 tools/art/bake_river_company.py` 重建游戏模型、材质和动作。减面后的头部源数据 `tools/art/field_head.json` 随仓库提交，正常构建可离线运行。若重建该文件，运行 `python3 tools/art/reduce_field_head.py`。执行 `python3 tools/art/check_company_motion.py` 可量取量化后前臂与手腕的连接。动作的实际观感请用 `./tools/compare-river-art.sh` 在游戏窗口复核。
