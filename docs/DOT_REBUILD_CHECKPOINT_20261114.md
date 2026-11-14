# Dot 全面重建检查点 · 2026-11-14

## 生效方向与不可越界事项

Owner 已授权 Dot 作为主要开发者接续；Codex 仍 PAUSED。不是重开项目。
整个地图、背景、人物、衣甲、武器、马匹和动作都须按实际差距大修，
参考图仅为及格线。不能以散放合法零件、颜色/照明微调或概念图代替
完整可玩的高品质样板。先完成桥至城门整片，再向全图和全军扩展。
保留九武器、技能、骑乘、战车、军令、将领、攻城、真实伤亡、部署、
结算、行军、世界模拟和旧档。正式文学剧情继续留空。

仅现有授权云资源、合法可公开再分发素材与内部候选交付。无新增费用、
无新账户、无用户电脑、无正式发行。核心人物/重大固定剧情留给 Owner
与 Pro 审定。美术必须由 Owner 看实际游戏后验收；M5 DEVICE_NOT_RUN。

## 已保护的可恢复基线

- main：`66c6b7d31d1fca03bf98e238b8e79ab71fd74114`，Codex 暂停交接不改写。
- RC25：PR59 Draft，`d1c1895221c33386d471922807ed590a6987dbe1`。
  原生 run `43595539334` 已成功，证据分支
  `codex/river-whole-native-evidence` 的 `2872bb2678e203221ca2e2322f82bacb95e1355f`。
  artifact `14115346270`。M1 Virtual 2K 512/512 平均33.105 FPS，
  P95 45.403 ms、P99 48.888 ms，不是 M5/60 FPS 验收。
- RC24：`4f3c0819cf44a89c24bd825c90f241d8974fbbb6`，
  run `43587113557`、artifact `14111959283`，保持全部回退包/证据。
- 旧 biome、spear 实验没有盲合。Dot 枪链实验默认关闭且已留拒绝证据：
  `dot/spear-contact-experiment` / `036d560749486ba9a5668129c7c3dc9b93535b0d`。
  踝点接地不等于鞋底不穿地；不得启用未验收动作。

## 新地图主场景与真实失败证据

1. `dot/river-pass-integration` / `735143aaad3e25a3d66671e336bf30cbf8dce86a`。
   官方来源恢复原素材后构建真实可编辑场景。13组、436完整原生实例、
   80地形块；正常部署入口、3次卸载无孤儿、旧档与完整 `tools/test.sh`
   在 run `43608658308` 通过。真实 Godot 图片 artifact `14119229066`。
   seed61112、tick135、22m、512/512、内部比例1.0、原生2K/4K。
   截图日志明确 `river-pass-master-v1`，不是旧入口误拍。
   **亲审视觉 FAIL**：复合石头按高度归一化铺满河道，林群碎散/荧光，
   旧城防/桥和旧人物仍不足。工程通过不能冒充艺术通过。
2. 第二轮独立源码 `dot/river-pass-r2-source` /
   `a3ef6216d3b55ebd141d983bf1851715410a922f`。
   去掉整条复合石毯，以12组单体稀疏岸岩和完整森林冠层/林下重排。
   643原生实例；不改兵数/战斗/存档。逐帧必须记录场景布局、可见节点和
   master文件hash。run `43610582960`：入口/生命周期/原生2K/4K步骤
   已完成，artifact `14120700400`；最终整个CI/完整aggregate均SUCCESS。
   2K图已亲审：白石毯消失、水面连续，但岸坡光秃、林冠硬黑、道路贫弱、
   旧门桥与人物仍远逊参考。**视觉 FAIL，禁止因实例变多而称高品质完成。**

历史 source 树可能继承旧 review 图片。只认可当次实际成功取证的
artifact、source SHA 和逐帧身份，不把仓库旧图/失败时 always-upload
带出的旧图标成新成果。旧失败artifact `14118716348` 不能作新场景图。

## 人物主路线与隔离工程验证

- 原 UBC 完整65骨/9动作源已在 `dot/character-native-source` /
  `bf520c13aa393c2fdc4b5c2596cfe5cbdb0bd7d9`。
  GLB SHA256 `64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0`；真实原生
  2K/4K、3.4m/22m图片 artifact `14120435693`。
  这是赤膊短裤源人体诊断，不是中国兵完成，不是实际战斗。
  首轮MovieMaker启动1280x800，后改窗口不等于原生2K视频；该片不作
  2K证据。独立复核run `43611011643`在运行，须以ffprobe结果为准。
- UBC超人肌肉体型不作为最终普通兵基础。新主路线改用文件级CC0的
  MakeHuman自然亚洲青年男体、完整163骨与全原权重/UV，以及同源专业
  交领衣料。自然体、衣料、眼球、皮肤和靴裤须逐文件保留来源/声明。
  原母版14个脸部顶点有9项权重；Godot8槽限制不得静默截尾后宣称完整。
  这一主路线仍本地制作/验证中，不冒称已进入游戏。
- 新完整权重适配实验保留额外UV和18原LOD，CPU68,047断言无失败；
  9/12/16槽及32bit LOD另125断言无失败。已在 `dot/native-character-parity` / `a3ddc837028e2e237395ca82cacb03ef9c9b7237`。
  GPU/material/full-battle尚未通过。
  独立实验保持关闭，不能用技术断言替代衣甲/手脚/攻防视觉审查。

## 许可已核与拒绝边界

- Stylized Nature MegaKit Standard 精确旧ZIP SHA256
  `298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9`，
  104088529 bytes，内附2024 CC0；作者OGA公开镜像同hash。
  后来QAL总页不撤回这一明确旧版CC0，不能据此把所有当前包一概CC0。
- UBC/UAL使用具体已校验CC0包，不以泛产品页代替包内许可证。
- Viking三件衣料的官网/mhclo CC0与OBJ AGPL头存在冲突。尽管工具手册
  解释默认字符串可改，当前项目仍拒绝公开这些原件/派生GLB，保持隔离。
  Mindfront交领源头与mhclo均CC0；替代裤CC0、靴CC BY 4.0，须署名。
- 已发布的旧0 A.D.美术保留CC BY-SA3.0与对应来源/文件例外。
  合法不等于好看。商业游戏只作构图/造型/动作参考，不擅取其资产。

## 原生Mac新取证与当前运行

`dot/river-native-review-source` / `b93f940f44c594c8e20a862a0a357a4c6567edf8`，
run `43611078127` 在运行。此前 `43610717621` 因浅检出缺历史存档
fixture `77ad6961` 失败，已改全历史检出，不跳旧档门槛。
新流程先完整回归/导出，再现有免费托管Mac：20/100/250/512的原生2K/4K
无readback性能采样，以及独立真实wall-clock动作录像，记录实际内部
分辨率、硬件、平均FPS/P50/P95/P99/内存和未覆盖操作。

24FPS固定步长MovieWriter片仅是模拟时间片，不能叫实际实时帧率。
新wall-clock以实际单调时钟PTS编码VFR，不插帧掩盖慢帧，目标24Hz不等于
已达24Hz。原JPEG序列暂存runner，持续交付只含抽选原生帧、完整有损MP4
可恢复分块、全部原JPEG哈希和时间日志，不能称无损全帧保存。
每artifact负载≤120MiB；60MiB块、每块/全文件hash、原子恢复，不覆盖已存
正确文件。新Mac包尚未宣称完成；即使完成也为ad-hoc内部包，非正式发行。

## 下一恢复操作

先重新核对上述在途CI最终结果及分支head，不重复发布既有branch：

```sh
git fetch origin dot/river-pass-r2-source dot/river-native-review-source dot/character-native-source
git worktree add --detach ../luanshi-r2-review a3ef6216d3b55ebd141d983bf1851715410a922f
cd ../luanshi-r2-review
./tools/prepare-font.sh
godot --headless --editor --path . --import
./tools/test.sh
```

用真实GPU从正常入口取相同seed/tick/22m/兵力、内比例1.0的2K/4K图，
亲看R2后继续整片桥/门楼/道路/背景构图，而非以去石毯为完成条件。
人物继续自然163骨专业衣甲整件制作、原生动作与真实战斗接入验证。
工程、安装包、视觉、Owner验收、M5性能分别报告。只依赖已验证现有
运行与可恢复源码，不声称无限后台执行或未实际配置的自动调度。
