# 《乱世》开发转移清单（可公开草稿）

核对日期：2026-11-11 UTC。开发已停止。本清单描述保存与恢复边界，不是新功能完成报告。

## 当前交接基线

- 稳定文本基线：`0e525a4ddf56c774dab3f87278447a3b29444cfc`，tree `c9eb913e6389e4682dd12d2ffa8ffcfdcd98b2a1`，包含 v0.13 运行代码和最新设计同步。
- 最后完整本地受测版本：`e64a398a4b7c0f01abfac50decd516ea57c0ba3a`；实测运行代码 `b71a6c96c410808fba43beb96514962b7f75d05d`。之后到稳定基线的变化是文档同步。
- 停止开发后的 v0.14 WIP：`e8000836256587e9c721d34ce56b3ee8a2b4325d`，tree `9e9976c005af7ced2f1e58f128b84bca293db07f`。它未完成，未通过完整测试或导出，不应当作已验证发行版。接续说明：`docs/DEVELOPMENT_TRANSFER_V014_WIP.md`。
- 20 个项目 checkout 已全部干净。未删除旧阶段源码或构建；本次恢复材料不包含构建包、字体或完整 Git 对象库。

## 已保存的 5 组历史未提交内容

- **luanshi-save-ui**：`3c79fee263f44e64c72a42d93f8fe15ed6b369bf`，分支 `feature/campaign-save-ui`，原样保存 11 个文件。
- **luanshi-saves**：`b9536b1f8f4d507ebe6cbbfc6df65c9090d0bd10`，分支 `feat/campaign-saves`，原样保存 10 个文件。
- **luanshi-hometown-audit**：`efbaaab2ced331de2066111d7145c1dbc29758fb`，分支 `wip/preserve-hometown-audit-for-transfer`，原样保存 13 个文件。
- **luanshi-wounds-audit**：`141f61e7a699e94d30cf6014bb060b4214b1139a`，分支 `wip/preserve-wounds-audit-for-transfer`，原样保存 3 个文件。
- **luanshi-youth-ui**：`e084fc6e961081c946313122643a951bd043f9ff`，分支 `feature/youth-life-ui`，原样保存 1 个文件。

共 38 个文件。save-ui 为旧持久化/UI WIP；saves 为旧设计同步和饥饿属性测试；hometown-audit 和 wounds-audit 为独立审计；youth-ui 为现有测试 UID。旧文档不取代最新设计；旧补丁不自动合入当前运行代码。

## 20 个 HEAD 的原始标识

这些 SHA 是本地来源标识。文本恢复清单不代表这些原始提交对象已发布，也不保证可以直接检出原 SHA。

| 阶段标签 | 分支 | 原 HEAD | 原 tree |
|---|---|---|---|
| luanshi-appraisal | work/camp-appraisal | 5d90c217158f380d6248bd65e3da8ea69ebf7324 | 908af1b93d91fba6dc5ec53ce4f218d4a61d2b7f |
| luanshi-balance | experiment/finite-hero-profiles | 4654c686fa63747f3d3da9c35689e2c1ccc375c5 | 5d2a30d8db4d4fc1400751428133e47e81e31d50 |
| luanshi-comrades | feature/comrade-choices | c1c40c216505b51eaeaf2bd71859234ba79d4da8 | db6e89441eaac7bbfbea6a17a8558c5a9315738d |
| luanshi-couriers | feature/courier-orders-v09 | 78c785395e5e80be46afb638c002065c1e90959a | 6e6a3c15d3aea4022fa6180ca0fd30b01a2b9e5d |
| luanshi-economy | feature/population-economy | c1b25bb3d58349ea05e53732b40015552a53fed5 | 39596c33df8aca932f0e3b58a50d2e07c6a5b046 |
| luanshi-fatigue | feat/eco04-hunger | 0b3499d211763ae8258ab93e2b03b9bd0656f450 | ca898c54527ce7694b5d6386c2419242419c03b7 |
| luanshi-game | feature/finite-hero-profiles | c0c6d5351dea2e9f318f3ea46f4f0b5e9a3ee5a2 | b39852b10b62050609166e5e8f4018c25aad781e |
| luanshi-hometown | work/hometown-messages | dfc4ae88e0278e07a3bee32fa4f2fad71eff044e | e6b75744bd26b4edd661354a7032376b92fadfed |
| luanshi-hometown-audit | wip/preserve-hometown-audit-for-transfer | efbaaab2ced331de2066111d7145c1dbc29758fb | 01392ee2488440712af6db943ba36c0c1afd4354 |
| luanshi-mac-render | probe/native-macos-render | 54127f676e13719291131ad4d01012578013ee0c | 135d02f2a130858e0f91e6fb7a80dbeb1029ffed |
| luanshi-profile-integration | feature/finite-hero-profiles | e9f390482a49df920638a59793ecaa0e1e881a92 | 2a43c92a449e98119450a8bdaff39fedcb9aef18 |
| luanshi-progression | work/earned-combat-growth | e8000836256587e9c721d34ce56b3ee8a2b4325d | 9e9976c005af7ced2f1e58f128b84bca293db07f |
| luanshi-resume | feature/youth-finite-integration | 485dac648c9c4837cf8434758bd9c5faa1c8659c | e3ee0d21c98afbce2bb3f5c9798502b31da7afea |
| luanshi-save-ui | feature/campaign-save-ui | 3c79fee263f44e64c72a42d93f8fe15ed6b369bf | 4fdb972a052fac78ec80156c34c77663180a79b0 |
| luanshi-saves | feat/campaign-saves | b9536b1f8f4d507ebe6cbbfc6df65c9090d0bd10 | 6d31ae66e8ffccdedc531c9f51d1bf8982ce068b |
| luanshi-wounds | work/persistent-wounds | e64a398a4b7c0f01abfac50decd516ea57c0ba3a | 4f20125643bac3d29fd4c2e11118e840c4d2d607 |
| luanshi-wounds-audit | wip/preserve-wounds-audit-for-transfer | 141f61e7a699e94d30cf6014bb060b4214b1139a | 1184581cb54c5f546d2c732b1b762ce3fd06bc96 |
| luanshi-youth-attrition | DETACHED | 4304a173ca6049d643b9f45283b214c288e93ca2 | e254ceea480b90530994c3cb2c10707857c25662 |
| luanshi-youth-core | feat/youth-life-slice | e64070ae19f4455e77ecdce7a1570a464b2f55cf | d5a013941453f4f2a73be09d1d12ff9372287282 |
| luanshi-youth-ui | feature/youth-life-ui | e084fc6e961081c946313122643a951bd043f9ff | 4b5730237eb1afce99de24f69fe5ad24ac11aa33 |

## 独立成果与历史版本覆盖

只保存最新快照和 5 个末次 WIP 补丁不够恢复全部阶段。20 个 HEAD 中，仅 6 个在最新 HEAD 的祖先链内（含最新 HEAD 本身）；其余历史包含 65 个不在最新祖先链中的提交。`docs/transfer/history/COMMITS_OUTSIDE_LATEST.json` 只保存其 SHA、父 SHA 和标题元数据，不保存或重建原 Git 图。

- **Mac render 探针**：原分支新增的 8 个文件已经在最新快照中逐字节保留。涉及 `.github/probes/native-macos-v06.json`、`.github/workflows/macos-graphical-probe.yml`、`docs/NATIVE_MACOS_GRAPHICS_PROBE.md`、`tests/test_macos_graphics_probe.py`、`tests/test_macos_probe_source.cjs`、`tools/macos_probe_source.cjs`、`tools/macos_window_probe.c`、`tools/probe_macos_graphics.py`。没有发现遗漏的探针文件，但原两次提交历史不在最新祖先图中。
- **finite-hero 实验**：18 个分支改动文件中，14 个与最新快照逐字节相同。剩余历史版本是 `scripts/battle_sim.gd`、`scripts/hero_combat_profiles.gd`、`tests/test_legacy_profile_parity.gd`、`docs/HERO_COMBAT_CALIBRATION.md`；后续集成和迁移改变了它们。不能因此声称实验功能丢失，也不能只用最新版本代替实验时的源码。
- **早期 economy、hunger、save、profile、youth 阶段**：相关文件仍存在于最新快照，但原运行/配置/测试版本已经被后续版本替换。它们现在通过逐 HEAD 文本恢复清单保留，而不是假称五个末次 WIP 补丁能恢复原基线。
- **独立审计**：最新快照缺少的源码路径是 hometown 的 13 个脚本/UID 和 wounds 的 3 个脚本，均已进入各自保存提交及恢复池。hometown 的部分探索脚本仅输出结果，不能直接当成具有失败退出码的 CI 门禁。
- 若把稳定基线、最新 WIP 和五个 WIP 末次新增/修改文件都算作已提供内容，仍有 **158 种不同的历史源码/配置/测试文件版本**不在这些快照中。恢复池已保存这些版本；该数不表示新增或缺失的 158 个功能。

## 文本恢复材料

推荐仓库位置：`docs/transfer/history/`。第一层已验证发布提交为 `71215500d18fda0c6aeb0de885a76b6430406c11`，发布 tree 为 `1d4d76f64adf8b5eefefc88c1eba9ab71c52c30a`，与原始来源 tree 不同。以第一层稳定**发布提交**为基底，使用 `BASELINE.json`、`heads/*.json`、`objects/*.txt` 恢复。每个对象按 SHA-256 去重；旧脚本使用 `.txt` 后缀，避免被当前 Godot 工程导入。

- 共 20 个 HEAD、284 个去重文本对象，正文共 3,656,035 字节。
- 序列化后逐 HEAD 重新读取清单和对象，在内存重建全部路径、模式和内容；**3,211 个源码文件实例全部与对应原始 Git blob 字节相同**。
- 40 种文档/证据版本存在脱敏或发布说明差异；`REDACTIONS.json` 明示原/发布 hash、原/发布行号与替换行。原始私有路径不在变更记录中复述，原行用 hash 定位。该记录不是可反向还原私有元数据的补丁。
- `delete_from_baseline` 仅表示在**新建恢复目录**中排除原基底的这些路径，不是删除当前开发工程文件的指令。
- `storage.baseline_path` 必须从第一层稳定发布提交取内容，不能从已被第二层 WIP 修改的当前工作树取同名文件。
- 没有运行游戏代码、测试、导入、导出或恢复到任何现有项目目录。核对的是文件可恢复性，不是新一轮运行验收。

### 每个 HEAD 的源码恢复校验

下表值为 `SHA256(sorted(relative_path + NUL + git_mode + NUL + file_SHA256 + LF))`，只统计非文档源码文本。每个 HEAD 的全体文本原始/发布 hash 也记录在 `heads/*.json` 和 `VERIFICATION.json`，可明确区分文档脱敏造成的变化。

| 阶段标签 | 源码恢复 inventory SHA-256 |
|---|---|
| luanshi-appraisal | 89445280f229074379995d072cf8e04681cc5fdb623e620eb2115e40ae10da0e |
| luanshi-balance | 13e75be396a45bbeedd43a44b97ef46b64ad6d837e4276268deb01c2da8c2d2b |
| luanshi-comrades | 43f072333c0273f6b25664f828ae9ff6075ca490c6453b54955a7565a1058afa |
| luanshi-couriers | 6605b9d8f5ba095377dc4d0c027a69049995c0eec57e8d69457ebd29cf5ad02c |
| luanshi-economy | eb7e8140ae0f23bbcc0669eae5b39de1cfdf2acfdc97c32132afad577cf0e27f |
| luanshi-fatigue | ece7c2f09bbddb24ebcd39453a9de0c70e06454d72c29981c0f4f6a854715f6a |
| luanshi-game | 2fa162e9bf365253cb672f21e973f027f99135e9f59aef84db8da20f5b3e2899 |
| luanshi-hometown | 858deb0b092d924f7d2ba9f4f3d4bfd469b45497040abe0cae90169420ec76e3 |
| luanshi-hometown-audit | 7a82f7e7cf810719df2a1c84c47b38683703c815e7c87d35c055ac74ad156d23 |
| luanshi-mac-render | f5a246cf7c881226c813982fb74d38c05bdc0817e34521dc4a4815f7eccc4949 |
| luanshi-profile-integration | 1f822be1cdcf5d5976201c0577896ed0334b29d5d8f09a574a38b8c692dbb72f |
| luanshi-progression | fd4c062f5f4e8cb7e51034f602dd4b52f07538060b6e33524f163ef3201263de |
| luanshi-resume | 9521f95746a3bcdd9b69f994039a1f560e0ea399cb84fc3fe41bb5233c5daf41 |
| luanshi-save-ui | f0e501f671174146ad9ecfd3bb1295d2252b818c32e25970917113d5604f19fc |
| luanshi-saves | ee75baf05d316e5581c69caa7bdb911006cd6b8b12f3f1c5cdfefa725a9ec0aa |
| luanshi-wounds | 435f4080d98bec595c9ae85604687930993665e4dfbbbfbef6afd796a8d40f18 |
| luanshi-wounds-audit | e3cd5b228ba603b715c348a46bad184cdecc28f0d6c6e4df953fc7f27e8ed720 |
| luanshi-youth-attrition | 6d2e98ac42228956faec811b694ab8174633a52f2ee8780e0a124eb639297139 |
| luanshi-youth-core | ea7da5f5777e83b66ffd551c5d5917c8bcb810dfb15026d838a8d7777079790e |
| luanshi-youth-ui | f8db49c4820bcc30b7646a0e62045d7522ebead1aae2004ca3f8c0b0370d8b44 |

## 唯一排除的受版本管理二进制资产

`assets/fonts/LuanshiUISCR-Regular.otf` 未包含。该资产的平台确认尚未解决；无字体字节、替代编码、构建包或 bundle 被加入文本恢复材料。导入元数据、字体生成源码、许可证和覆盖清单只是文本项目记录，不等于字体文件。

该字体只在本来含它的阶段列为缺失。所有其余受版本管理 UTF-8 文本都可按清单恢复；原来不含该字体的早期阶段不会被错误添加。当前稳定/最新文本交接因此**不能称为完整可运行或可重现构建交付**。忽略缓存、原始临时日志、构建包和未引用中间提交不在本材料范围内。

## 保留的 v0.13 构建身份（只记录，不随材料提供）

- macOS ZIP SHA-256：`785120170b7ca4c20c8838d8bbfaf917ad6feeaf4bdc1a529989642e8f36f7b5`
- Linux tar.gz SHA-256：`e92e4397376ed6472e69a74160afb11b0e7a7758149392b1bca3905db708e228`
- 本地验证证据 `docs/evidence/wounds-v013-validation.log` 的原始 SHA-256：`5d11ad5311ae3e99cf4bcd16d255626f2fa4dac82bb88a64c430e3c21aa848e3`

原来在本地通过的 v0.13 验证不等于当前缺失字体的文本发布层已经重测。图形、当前版本原生 macOS、Apple M5、签名及主观可玩性仍不是本次已验收内容。
