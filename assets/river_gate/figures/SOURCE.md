# 河关军容资产

河关的六种衣装、甲片、披风、头巾、马尾盔缨、九种兵器、调色和动作由本项目制作。游戏从 `river_company.glb` 合批绘制近、中、远三档，并从同一个动作库读取步伐、发力和失衡。躯干和袖子共用缝边顶点。持械手和武器共用握点。角色进入新的显示距离后沿用同一套姿势与相位。

脸和耳朵的形体使用 MakeHuman 团队的 HM08 头部网格及青年男性形态，已按 CC0 1.0 公开。取材文件为 `data/3dobjs/base.obj` 和 `data/targets/macrodetails/asian-male-young.target`。来源的版本、Git blob 校验、裁取范围和简化方法见 `tools/art/reduce_field_head.py`。额头、帽檐、眼睑、布料、铁甲和双色披风在游戏内重新贴图与装配。 [上游资产原文](https://github.com/makehumancommunity/makehuman/tree/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data) · [上游 CC0 授权](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md)

Python 3 与 Pillow 可用时，运行 `python3 tools/art/bake_river_company.py` 重建游戏模型、材质和动作。减面后的头部源数据 `tools/art/field_head.json` 随仓库提交，正常构建可离线运行。若重建该文件，运行 `python3 tools/art/reduce_field_head.py`。执行 `python3 tools/art/check_company_motion.py` 可量取量化后前臂与手腕的连接。动作的实际观感请用 `./tools/compare-river-art.sh` 在游戏窗口复核。

角色的布褶、夹袄、铁札、绛红披衣和三张头像使用为本项目单独创作的 AI 辅助平涂素材。原始画材在 tools/art/source 里，painted_company.py 分出材质、对齐眼鼻与下颌、烘进正式资产。三张头像都是虚构人物。贴图与持械骨架在实际战场里共用，远阵保留较低面数。主角靛衣和绛披、军官与士卒的衣料由装备区分。

动作库将相邻姿势按同骨、同分量放在一起。GPU 对相邻姿势连续采样，走路和跑步循环在首尾相接。建模和面料原画保存于 [画材目录](../../../tools/art/source/README.md)。

## 河关军士的盔甲

枪兵和刀兵的战袍外着短甲身、披膊和分片甲裙。盾兵、长刀兵及军官的裙甲较长。弓手戴软巾，有箭箙，轻装兵保留发髻。三档模型采用同一组兜鍪、护耳、裙甲开衩与肩甲轮廓，按镜头距离改变截面采样数。

兜鍪轮廓、护耳和甲裙的形制参考唐代武士俑。故宫藏三彩武士俑可见前后甲身与肩带，普林斯顿藏武士俑可见护耳与甲裙的叠札，旧金山亚洲艺术博物馆藏品记录了盔顶、披膊、袍裤与靴的组合。墓葬俑表现理想化的军容。游戏对河关军需与衣料配色做了简化，盔甲几何、札片与绑带纹理均由本项目绘制。[故宫博物院](https://www.dpm.org.cn/collection/sculpture/233426.html) · [普林斯顿大学艺术博物馆](https://artmuseum.princeton.edu/art/collections/objects/33588) · [旧金山亚洲艺术博物馆](https://searchcollection.asianart.org/objects/4875/warrior)

RC6 使用本项目绘制的 `campaign_colours.svg` 作为六种衣装、皮肤和九武器共用的色稿。共 32 个图格，与现有近中远三档网格的 UV 对齐。披风、盾面、面容、甲札与刀刃有独立色面，明暗取自游戏里的真实光源。旧版画材和重建脚本保留供版本复现。

各级甲兵披膊的铁片、束边和可见布衬、轻装兵软巾的垂结以及军官肩领来自原创附件 `field_garments.gltf`。它们绑定至原有躯干、头部与上臂，在载入时与身体和武器拼为同一张网格。用 `node tools/art/bake_field_garments.mjs --check` 核对三档实装模型与作者源文件。

RC7 的绛色半披、发髻、交领、下摆裁片、札甲裙与木盾凸脐使用本项目原创的模型和色稿。人物动作按既有命中时刻拉开持枪的前后步距，弓手与盾兵各自换重心。附加披膊沿袖身随骨骼运动，三档距离共用同一套色面和握点。

第一次 RC7 实机近镜暴露出胸甲横带过宽、弓手衣短。四片胸背札甲按胸背弧度独立取形，铁片、交错系绳和暗下沿分别着色。步弓手的袍摆落在大腿，侧开衩、前折襟跟随腰与腿。
