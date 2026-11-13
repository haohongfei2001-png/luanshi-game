# 河关 RC16 · 实机美术验收

| 项目 | 观察与证据 |
|---|---|
| ARTREF-01 镜头 | 22 米正常摄像机、同一种子、同一次起枪与命中。6.4 米到 51 米之间可切换。留存 1920×1200 窗口原帧。[两版正常截图](normal-camera-before-after/) |
| ARTREF-02 普通兵 | 三套真实衣片用于两军的枪刀、盾/长刀和弓弩手。能在原生图看见与身体相连的袖口、腰系、护臂和握弓手。重装军士之间面相重复，局部有深斑。[枪](garrison/final-spear.jpg) · [盾](garrison/final-shield.jpg) · [弓](garrison/archer/fingers-pair.jpg) |
| ARTREF-03 身份 | 主角的绛色短披与枪臂保留，主将和近身护卫仍在战役中独立行动。阵中同色衣料与近似面孔让部分精锐和普通兵易混。[近镜](close.png) · [军官与队形记录](measurements.json) |
| ARTREF-04 重心、接战 | 植入三段原作身体曲线并限制负重摇摆。实走中脚掌与兵器握点连续，#94 弓手有真实弹药、出箭和目标。仍有急停姿态较硬、邻兵武器互遮的片段。[等速推进](march/march-pair.mp4) · [侧面放箭](garrison/archer/fingers-side-pair.jpg) |
| ARTREF-05 千人军阵 | 1024 名普通兵、32 名军官和玩家。近中远档实际行进、放箭、受击、冲门、撤出并改变战果。移动镜头仍有命中与伤亡。[远阵](wide.png) · [导出游戏分段记录](export-recording.json) |
| ARTREF-06 环境 | 关门、河岸、营地、桥和树林位于一张地图。树的底层网格已共享，四个窗口保留原像素及交锋。关内建筑、营地器具和重复树冠仍有改进空间。[关门](groves/gate-pair.jpg) · [岸线](groves/river-pair.jpg) |
| ARTREF-07 清晰度 | 原像素按 100% 内部尺寸绘制，默认 4× MSAA。未裁剪图供判断正常人物大小，穿插的杆兵器与五米人物面部杂色如实保留。[近战原帧](normal-camera-before-after/after.png) · [Metal 原始窗口](metal-window.png) |
| ARTREF-08 连续实战 | 从正式 Linux 游戏可执行文件采集键鼠、音频、兵员状态和 960 帧；另有从军议至驻营的完整带声流程。[40 秒正常游玩](combat-normal-speed.mp4) · [战役原片](playthrough-full.mp4) |
| ARTREF-09 同类参考 | 针对三种军服辨识、上身负重行进和环境清晰度有实际改动与退回试作。动作、轮廓和人物身份仍有可见差距。[对应作品和实际镜位](reference-gap-analysis.md) |
| ARTREF-10 来源 | 成衣、手、头、步态、树、地面与其他项目自制内容有分别署名。转换脚本和源版本可复建，安装包附带第三方授权。[资产与许可](assets-and-licenses.md) · [发行包清单](shipping-packages.json) |
| ARTREF-11 目标设备 | `DEVICE_NOT_RUN`。真实 MacBook Air M5、内屏及外接屏 20 分钟热稳态待实测。托管 Apple Silicon 的包体与图形验证另列。[原生实测](PLAYTEST.md) |
| ARTREF-12 商业美术完成度 | `ART_REVIEW_REQUIRED`。普通兵衣甲与持械动作已有实机变化，部分近景脸部仍有深色斑点，军阵中有武器交错与动作雷同。美术尚未通过。 |
