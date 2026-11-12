# 河关原生画面实测

生产提交 `a6bd5043e75721f9db0888db790f1c32d55e9da5` 只改动战场画质设置。默认档以实际窗口像素绘制，4× MSAA 处理模型边缘。图像没有启用 FXAA 或 TAA。第三个旧索引 2 保留性能档；新增索引 3 可直接选择同样 100% 分辨率、相同阴影、关闭 MSAA。

## 普通游玩机位

同一台 GitHub Ubuntu 24.04、Mesa llvmpipe 软件 Vulkan、Godot 4.6.3 Mobile，运行真实 `scenes/game.tscn`。骑乘镜头高度 14，混战为 18，使用战场正常镜头控制器。摄像机以相同轨迹平移，角色随 20 Hz 战斗逻辑和呈现插值推进。每格有 512+512 普通兵。骑乘画面第 1 帧可见 145 名存活战斗角色，包含 9 名骑兵，混战为 109 名与 3 名骑兵。每组画面均核对可见战斗角色身份、武器数量、时刻、指挥官、骑乘状态、攻击和镜头中心。

每种分辨率和模式为两个机位各输出 5 张连续完整无损 PNG和 30 个计时样本，计时前各预热 12 帧。时间包含真实模拟/视图更新和 Vulkan 提交，不包含截图读回及保存。固定采样与运动测量都与 3840×2400 同镜头 4× 参照图的面积采样比较。额外的隐藏角色帧只用于找出人物轮廓覆盖，在正常截图及计时之外。表中为轮廓与运动误差减少比例，以及单采样到 4× 的真实软件渲染耗时。

| 窗口和机位 | 轮廓误差 | 运动误差 | P50 毫秒 | P95 毫秒 |
| --- | ---: | ---: | ---: | ---: |
| 1280×800 骑乘 | −30.6% | −32.4% | 237.5 → 549.9 | 252.2 → 569.3 |
| 1280×800 混战 | −26.7% | −27.3% | 177.9 → 364.3 | 193.1 → 381.5 |
| 1920×1200 骑乘 | −30.1% | −31.8% | 389.3 → 857.5 | 408.4 → 881.0 |
| 1920×1200 混战 | −28.6% | −28.8% | 304.3 → 586.0 | 319.8 → 607.0 |

llvmpipe 只公布 1× 和 4× 颜色样本能力。请求 2× 后四个机位留存的 PNG 各与单采样同 SHA，各项运动指标亦相同。真机 Apple GPU、Retina 合成、持续帧率及热限制留待真机核验。

[骑乘原始 PNG，1920×1200 单采样](mounted-1920-msaa0.png) · [骑乘原始 PNG，4×](mounted-1920-msaa4.png) · [混战原始 PNG，单采样](contact-1920-msaa0.png) · [混战原始 PNG，4×](contact-1920-msaa4.png)

[逐帧状态、帧时间及完整数值](measurements.json) · [原始文件 SHA-256](SHA256SUMS) · [原始 Vulkan 测量与完整帧序列](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43297303797) · [生产源原生窗口缩放、四档设置和存档回归](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43299463298)

## 复现

在含有本试验脚本的证据分支检出此目录，使用同版 Linux Godot、已导入的字体和 Vulkan 驱动。以下命令保存某个机位组合的全部无损原图和原始帧时。完整组合、软件 Vulkan 设置、下载校验和及 Python 对比脚本见 [云端工作流](../../../.github/workflows/river-native-clarity.yml)。

```sh
./tools/prepare-font.sh
godot --headless --editor --import --path .
xvfb-run -a -s '-screen 0 3896x2448x24' godot --path . --resolution 1920x1200 \
  --rendering-method mobile --rendering-driver vulkan --audio-driver Dummy --disable-vsync --fixed-fps 60 \
  --script tests/river_native_clarity.gd -- --raw=/tmp/river-native-raw/1920-4 --width=1920 --samples=4
```

最初原始工件的命中与伤亡两个数组延迟序列化，各帧读到的都是末时刻数值。这里的 JSON 用同种子生产源独立重放补录每个采样 tick 的整数副本。tick 65、66 的双方命中分别为 179/88、183/91，伤亡为 13/42、14/42。截图、帧耗时及图像误差来自首轮同机试验。
