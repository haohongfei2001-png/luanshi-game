# 河关 RC16 的实物与许可

| 在真实游戏中使用的部分 | 母版、修改及再分发 |
|---|---|
| 双方常备枪刀兵 | 《0 A.D.》Wildfire Games 的 `m_pants_tunic_long`，使用原衣片、袖筒、UV 和实际蒙皮，以河关的肢段/握点适配。 |
| 双方盾兵和长刀兵 | 同作者 `m_armor_tunic_long` 的衣片与重装札甲配色。第一次原图里亮裤纹成了一条白边，第二次只保留衣片，裤与靴用河关原资产。 |
| 双方弓弩兵 | 同作者 `m_tunic_short`，保留斜领、短袖、腰系，佩戴河关的软巾、箭箙、护腕。#94 在第 25 步起手、第 32 步满弓、第 36 步朝 #582 实发，箭数 19→18。贴身邻兵的大刀从腰前经过。 |
| 肩、胯行进与跑步 | Quaternius Universal Animation Library 的免费 Standard 版，`Walk_Loop`、`Walk_Formal_Loop`、`Jog_Fwd_Loop`。32 点/周期的源曲线绑定原有体段，持盾/双手持杆角色按负重收窄摆肩与纵向起伏。原作 CC0。 |
| 树林 | Quaternius 免费 Stylized Nature MegaKit 的 CommonTree_1/3，已在上一版署名。树干与叶片的两个真实网格在同一地块内供树实例共享。19 棵岸柳与临水草丛维持现有资源。 |
| 其余 | 头和手的 MakeHuman CC0 来源、河关原创盔、披挂、兵器、马车与鞍具、岸土的 Poly Haven CC0、Noto 字体 OFL 和游戏引擎的授权随候选包附带。在单独的坐骑试作中使用的素材以其独立清单与实机审核为准。 |

Wildfire Games 的上游版本为 `61a3b9507d974084e6badb88a0826bd89a6d5b8b`。署名、改动和相同方式共享的范围随成衣原件和打包发行品附带。转换器核验三份 COLLADA 和三张原始底色文件的 Git blob。工程持有可重新生成的输出和脚本。[原作者授权](https://github.com/0ad/0ad/blob/61a3b9507d974084e6badb88a0826bd89a6d5b8b/binaries/data/mods/public/art/LICENSE.txt) · [本版署名](https://github.com/haohongfei2001-png/luanshi-game/blob/7c9ac667ded0a8e80a05cd47593a4af70c28486c/assets/third_party/wildfire_garments/NOTICE.txt) · [转制脚本](https://github.com/haohongfei2001-png/luanshi-game/blob/7c9ac667ded0a8e80a05cd47593a4af70c28486c/tools/art/import_garrison_issues.py)

实物源蒙皮约 48 骨，转制后每部位从共有动作纹理采样。三个代表外衣分别为 354、474 与 426 三角面。共用贴图，三档分别保留身、脸、手、鞋袜的几何层级，身体、衣服和武器通过索引网格拼为一个批次。云端可用 `python3 tools/art/import_garrison_issues.py /tmp/river-wardrobe` 复建。[衣物三档部署录像](https://github.com/haohongfei2001-png/luanshi-game/blob/9fc4f0567bd09a42ba60e8479348e99dbbe9a7ca/docs/evidence/river-gate-v1-rc16/garrison/equal-speed.mp4)

三段步态来源从带 CC0 的原始归档读取。未加负载约束的空手短跑试作曾出现 79.8° 躯干扭转、约 25 厘米的纵向跨度，已退回。游戏中的接地脚及腕部位置对照见 [持械步态验证](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43482687885)。可重建的脚本和归档校验见[动作母版](https://github.com/haohongfei2001-png/luanshi-game/blob/7c9ac667ded0a8e80a05cd47593a4af70c28486c/tools/art/source/COMPANY_MARCH.md)。
