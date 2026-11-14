# Dot 全面重建检查点 · 2026-11-14

## 2026-11-14 16:44 UTC · 原生工程归档完成，整体美术仍淘汰

**ART FAIL / OWNER NOT ACCEPTED**。下面的 macOS 包是被淘汰的 R1 美术工程底座，
不是全面重建的新美术候选。main、RC24/RC25、默认角色和正式文学剧情均未改变。
Codex PAUSED / Dot 自主接续继续有效。

### 已完成的原生证据，不掩盖失败

- 固定游戏源 `caec14c18bb063210eae0a7098fe6870a5763870`，
  [run43612407649](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43612407649)。
  export job 完整 SUCCESS（玩法/旧档回归、三输入模式校准、macOS/Linux 导出及许可检查）。
  native job 已结束；整条 CI **FAIL** 于最后固定步进电影编码器的同机位中心校验，
  正常 follow camera 从 x34.2 移至约31.17。未降低原±0.35m门槛，未伪报全绿。
  实际完整战斗走到tick2240守城结算，失败影片与日志保留。
- 已恢复、独立复算并保存内部 ad-hoc ARM64 包 `Luanshi-macOS-arm64-world-review.zip`：
  364,124,927 bytes，SHA256 `41e7b36915acbf685b4418462ef58483c1f2adaa0f55901b9aee9ce10290f956`。
  含引擎来源/许可；未公证、非正式商业发行。原 run 的 internal-package 00–03 artifacts
  可按manifest拼回同一包，当前有效至2026-12-14 16:30 UTC，下载需GitHub登录。
  完整包与原速影片已存用户Library；聊天单文件20MB上限已改用单包artifact交付。
  [完整内部Mac包](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43617369748/artifacts/14121709569)
  单件下载可用，需GitHub登录，有效至2026-12-14 16:46 UTC；重组job全绿，
  只重组同一已签名字节、不重编译。分发工作流59539b37不是新的游戏源。
- 硬件是 GitHub M1 Virtual / Apple Paravirtual，3 cores / 7GB，macOS26.7.2。
  **实际 MacBook Air M5 DEVICE_NOT_RUN**。原生内部像素比例1.0。
  512v512的2K均值35.852 FPS / P50 29.103ms / P95 47.752ms / P99 55.723ms；
  4K均值27.680 FPS / P95 53.067ms / P99 58.227ms。稳定60 FPS未达标。
  20/100/250/512每方均有样本，前3档自然提前结算，采样28.9–36.8秒，不冒称全部45秒。
  camera-tour512单独记录，均值32.117 FPS；它不是固定机位比较。
- 两个真实原速VFR视频未补帧：QHD553帧/60.030315秒/9.208855捕获FPS，
  UHD143帧/29.984647秒/4.764751捕获FPS。捕获成本显著，不能冒充上述游戏性能。
  无音频；完整动作美术验收仍失败，UHD窗口无主角命中。总格挡遥测不代表主角可见举盾。
  全时间戳、每帧hash和选定原生JPEG保留，不声称保留全部原始JPEG。
- 独立亲看发现首次受击frame60仍显示100/100，与同一CPU记录63.5577不同；随后
  原视频frame61实际HUD64/100、frame70实际10/100，支持刷新延迟而非永久冻结。
  下一轮补实际HUD值/刷新tick与CPU采样关联，不修图、不把日志当动作画面验收。

### 全面重建与渲染保真继续

- Sprite Fright 原生专业统一环境转换已保存远端
  `dot/river-authored-reset` / `ace9eabd65ee0c8dc106e51a0a3618209acac75e`。
  完整灌木可显式烘焙导入；整树185,676三角/1surface派生已生成但黑叶方案自行拒绝。
  主因是2,622叶片各自展开到1K图集导致有效纹素丢失，现改按原作者约14种共享几何复用UV。
  不是调曝光或染色补救。原母版、UV、全部枝叶布局、失败纹理与图像均保留。
  **尚无新的完整Godot战场美术达标图**。
- 完整专业成衣母版另取得Sintel Guardians r854工作版；不是最终电影角色。
  本地禁autoexec审计实际保留308主rig/79变形骨、原笼与Multires，FK变化确实带动完整袖子。
  2026-11-14 16:47核完官网原包发布与CC BY3全部公开数据授权、36成员hash，
  原13缺图均为禁用槽/编辑器/工作参考，启用表面依赖齐备，已准入完整源适配。
  原ZIP无独立LICENSE，不伪称包内有；必须保留官方署名、来源与改编说明。
  旧shader现代迁移仍在验证，不冒称已成中国兵；电影身份/徽记不直接入游戏。
- 官方Compatibility原生Skin切线缺陷仍是原门禁FAIL；第三方CPU全权重静态mesh+原材质
  已与batch实际像素严格通过。独立同源引擎原版/补丁实验
  `dot/godot-native-tangent-fix` / `8c937c111a99f98da8df334ad7c899a64d286b9c`，
  run43615580739正在编译。构建源35e80b3与已下载release报告7d41c59不是相同SHA，
  因此必须先复现干净35e80b3再比较补丁，不能改版本字串伪装同版。未改游戏默认引擎。

下一条恢复：先fetch各分支与读取最终CI，再继续完整自然母版共享材质转换、成衣原生结构
迁移、同源引擎原版/补丁实际像素比较。不要重复昂贵Mac
运行来包装旧画面，先在本地修复取证契约、保留失败场景后续样本，再用于新完整样板。

## 2026-11-14 16:23 UTC · 完整母版准入与原生渲染阻塞定位

全画面仍为 **ART FAIL**；R1/R2 与两版新程序裁片衣甲都已自行淘汰，不是接近通过的基础。
默认玩法、main、RC24/RC25均未被这些实验替换。Codex PAUSED / Dot 接续不变。

- 完整专业自然环境来源已实际取得，不再仅搜零散资产：Blender 官方
  `https://download.blender.org/demo/sprite_fright_030_0020_A.zip`，254,374,945 bytes，
  SHA256 `21ee25dfffc76030770b644de5fe897559aead064b384fba77166b71a9337791`。
  包内readme明确整个collection为 **CC BY 4.0**，保留署名/来源/改作说明。
  64成员CRC/哈希已核，独立sprite_village在Blender4.3.2禁自动脚本可读；
  22链接库齐备、实际材质图像齐备，仅两张未参与材质的工作参考图缺失。
  这是统一源模型、材料、散布与场景，不是中国战场成品。整set求值曾exit137，
  已保留失败并改分区；原作者完整灌木collection实际Cycles预览成功，但**不是Godot画面**。
  新生产须保留专业源与统一材料体系，显式烘焙/LOD/实例预算，不用plain glTF丢材质。
  成套中国城防/门桥与专业短袍仍未获得，不以源合法或技术能打开冒充达标。
- `dot/river-authored-reset` / `572d416b90fbc885af37c6659e7ee60621bcbd0e`
  是可恢复生产/契约代码，12文本已远端核验；无该分支CI运行，不是新艺术交付。
- `dot/mh-natural-fullrig` / `8ca3ee5b0f7641c6acbfb8d9d829ea0f538541a4`
  的40固定源→Blender→9动作→Godot→ID/动作整链真实exit0。修复source目录缺.gdignore、
  验证器参数错误及硬超时。旧冻结静态GLB6853fbca、动画b735dc82、sidecar8a580adf
  自身一致，但新审计确认163骨roll使用了不同于官方默认轴的约90度约定。
  **不得再称原作者rest轴完全原样。** 新官方轴独立母版ddfd0662/83cfe096已本地通过
  163骨轴、65 mesh/UV/全导出权重accessor、9动作与完整源权重测试；正规源恢复脚本
  `tools/art/mh_character/build_official_seed.sh` 已远端发布于同分支
  `b778bc0f016a7d339fcd8459e6b622387ad3a755`，主线程fetch核验，整链exit0。
  接地/布料/持握仍未通过，不用数据通过掩饰。旧冻结源未覆盖。
- `dot/native-character-parity` / `a3665f4d8d9e5f27060e44763d923226b261aed5`
  已保存完整163骨源ID/完整影响权重桥、独立CPU姿态oracle、固定值单元与原始JSON。
  主线程fetch逐字节核7个代码/报告文件。18单元与9动作×3相位549,063数据检查通过；
  20,159渲染点及33个>8影响点无截尾，原UV/材质/LOD保留。不是图像或动作合格证明。
- 真正图形探针发现官方4.6.3 Compatibility原生Skin切线错误：run43614620176，
  artifact14121359013；3顶点/单identity骨/精确一权重下，静态TBN色与Skin色不同，
  mesh数组roundtrip仍同错，故与UBC重定向/palette无关。
  官方GLES3 mesh_storage输入切线绑定与skeleton.glsl UNORM解码路径已定位，正在独立补丁验证。
  **旧原生Skin门禁仍红，不故意把正确batch改坏来仿引擎错误。**
  run43614764419的第三方位比较（本项目独立全权重CPU静态mesh+原材质）与batch
  4实际姿态均严格过，MAE约0.69–1.97e-6，>2色阶点仅1/3/4/7；这不是原Skin已修复。
- 原生Mac工程取证最新源为 `dot/river-native-review-source` /
  `caec14c18bb063210eae0a7098fe6870a5763870`，run **43612407649**。
  export整个job已最终SUCCESS：完整回归、旧存档、三输入模式校准、真实macOS/Linux导出
  与包检查通过；402,881,462B源macOS包已分组恢复并逐字节核验。Mac固定引擎/编码器准备通过，
  现处原生窗口2K/4K性能矩阵与原速录像步骤；**尚不宣称其最终成功、FPS或可交付包**。
  这是旧被否决画面的工程基线，不是合格新美术；M5仍DEVICE_NOT_RUN。

恢复先核最新refs/CI，勿重复create既有分支；实验独立、默认关闭。继续分区转换完整专业森林母版、
修正原作者骨轴并重验全动作、验证原生切线补丁。每一步区分源保真、工程、图形正确性、性能、
完整玩法、整体美术和Owner验收。只有真正的新Godot样板可作为美术进展。


## Owner 后续整体否决与方法重置

Owner 随后再次明确：这一轮不是部分不足，而是整张画面全部不达标，
必须改变方法。人物、建筑、环境、材质、光影、构图全部按淘汰处理。
**R1/R2不是接近合格的基础，不再围绕现图逐项补桥补门。**
现转为单一成熟整体视觉标杆、统一空间/造型/材质的可执行场景母版，
以及自然比例完整人物与成套专业衣甲。重新核验成套成熟生产资产，
不以随机合法零件的数量、骨数、工程通过或灰模冒充美术质量。
先由Dot自行整图筛掉失败稿，不让Owner承担筛选工作。

下文保留各实验的真实工程结果与失败证据用于恢复，不代表继续采用其
视觉方案。设计灰模、诊断台、模拟时间片、CPU断言均不能作新美术成果。

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
R2已整体否决，恢复时不要沿R2继续逐项修补；落实新的统一整片生产母版。
人物继续自然163骨专业衣甲整件制作、原生动作与真实战斗接入验证。
工程、安装包、视觉、Owner验收、M5性能分别报告。只依赖已验证现有
运行与可恢复源码，不声称无限后台执行或未实际配置的自动调度。
