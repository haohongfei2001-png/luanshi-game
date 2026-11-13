# 两台云端宿主的长帧与查询 A/B

[原生逐帧回看](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43353402439)不重新跑游戏，从两次 24 秒、512v512、100% 分辨率、4× MSAA、阴影开启的 RC7 导出包取逐帧时间。每次相机切换后的 250 ms 单列；此分组只能显示相关性。RC7 本包 2,333 帧中 355 帧超过 16.67 ms，37 帧超过 33.33 ms；只有 2 个超 33.33 ms 样本落在上述移镜窗口。另一台新宿主 2,338 帧，338 帧超过 16.67 ms，20 帧超过 33.33 ms，其中 2 帧落在窗口。两份样本都不支持把绝大多数长帧归咎于瞬时移镜。GPU 时间戳在虚拟驱动中不可用。CPU 累计平均也不能定位某一个长帧。[原始窗口数据](raw/prior-wall-tail.json)。

[RC8 源码的普通兵空间查询试验](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43354074427)在一台 Linux 云主机交错运行 A/B/B/A，分别测试 512+512 和 2,500+2,500 名普通兵。按相同顺序只枚举邻接环的两端、跳过重复扫描的内部坐标；五次决策的目标、浮点分离向量、最终存档散列、伤亡与命中一致。512 方时全集查敌中位 21.55→19.83 ms，但**实际整步**中位 18.69→18.65 ms、P95 20.84→21.12 ms；2,500 方亦无整步 P95 改善。**不合入**。这不是跑分过关，也不是以缩小每方数量换取 FPS。[数字与存档指纹](raw/grid-ab.json)。

复核长帧：解压原生验证附件，运行 `python3 docs/evidence/river-gate-v1-rc8/measure_tail.py /path/to/verification`。复核网格需要原测试分支的 `.github/workflows/rc8-grid-ab.yml`，其中含完整同 CPU 命令和原始逐样本时长。
