# 原生包的画面

同一只 [RC7 内部 .app](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000466949)，实际在 Apple M1 (Virtual)/Apple5 上起进程、部署 512v512 后由 Godot 截取。并非 Linux 截图调色。以下 JPEG 保留原尺寸，无 AI 增强或插帧。[PNG 原件及逐帧数据](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43341234060/artifacts/14000910119) · [从已有附件读取的独立核对](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43343869369)。

| 实机样本 | 实际附件 | 原 PNG SHA-256 |
|---|---:|---|
| [兼容后端](native-compat-1.jpg) | 960×600 | `8ce91a597684f2c63315861689eb91b89911f478ccd997cdfc49f0aeeda3a23a` |
| [默认 Metal](native-default-metal-1.jpg) | 960×600 | `f02d5aec8ac611ba7e1de9056e3c9d82e7e82a768e0f56b70b5262466111bca2` |
| [默认 Metal 移镜到城门](native-shipping-metal.jpg) | 1024×640 | `b23cc2d8fd03495d43ec48660109113a7e58903ab8a5458f547b0f7e80427fe6` |

兼容与移动渲染的首轮经过相近但不完全相同的实时时钟（窗口命中 400 与 398），只能肉眼对照衣甲和草泥的色值，不可逐像素相减。默认移动渲染的道路、布袍明显较暗；低分辨率的前排武器边线明显。后一张为 24 秒移镜取样，战斗区域不同。真实 MacBook Air M5 未测。
