# BetaUp UI Redesign Plan — v2

> 更新：2026-05-04  
> 方向：大刀阔斧重构，参考冥想 app（大氛围插画）+ TODU（超强对比+大数字）

---

## 一、审美方向（已定）

**Athletic Dark — 运动深色系**

- 不是"深色模式"，是有**大气感**的沉浸式深色
- 数字是主角（V6、50%、22次 用超大压缩字体占据视觉中心）
- 每个页面有一个明确的"hero"区域，其他元素服务于它
- 攀岩专属视觉语言：岩石纹理、路线颜色、hold 形态
- 参考：冥想 app（插画主视觉 + 浮动卡片）× TODU（超强对比 + 几何感）

---

## 二、设计系统（Design Tokens）

### 2.1 色彩

```
背景层级（深度通过层级区分，不是纯色）：
  Base          #09111F   页面底色
  Surface       #111D2E   卡片、容器
  Surface+      #162338   输入框、次级卡片
  Glow          rgba(255,122,24,0.08)   橙色微光（用于 hero 区域背景）

文字：
  Primary       #FFFFFF   主内容
  Secondary     #6B8299   标签、时间戳、辅助
  Muted         #3A5070   禁用/最弱

品牌：
  Orange        #FF7A18   唯一 accent（保持克制）
  Orange Glow   rgba(255,122,24,0.35)  用于发光阴影

V 等级颜色系统（攀岩专属）：
  V0–V2   #4ADE80  绿（入门）
  V3–V4   #60A5FA  蓝（中级）
  V5–V6   #FF7A18  橙（进阶）← 与品牌色统一
  V7–V8   #E879F9  紫（高级）
  V9+     #F43F5E  红（精英）
```

### 2.2 字体（已在 index.html + ThemeData 配置）

| 用途 | 字体 | 粗细 | 场景 |
|------|------|------|------|
| 品牌/大标题 | Oswald | 700 | 页面标题、Tab label、底部导航 |
| **等级/数字** | **Barlow Condensed** | **800** | **V6、50%、22次 ← 最重要** |
| 正文 | DM Sans | 400/500 | 帖子内容、说明文字 |
| 辅助 | DM Sans | 400 | 时间戳、小标签 |

### 2.3 背景质感（所有页面通用）

**方案：三层叠加**
```
Layer 1: Base 深色 #09111F（纯色底）
Layer 2: 角落橙色光晕（右上角 + 左下角，radial gradient，opacity 0.06）
Layer 3: 噪点纹理（noise PNG，opacity 0.03，tile）
```
实现方式：在全局 `Scaffold` 外套一个 `Stack`，底层放 `CustomPaint` 画渐变光晕。

### 2.4 动效规范

| 类型 | 实现 | 时长 | 使用场景 |
|------|------|------|----------|
| 数字计数跳动 | `TweenAnimationBuilder` | 800ms | 进步页统计数字加载 |
| Go Climb 呼吸光圈 | `AnimationController` + `ScaleTransition` | 2s loop | 记录页主 CTA |
| 卡片淡入 | `FadeTransition` + stagger delay | 300ms | 列表加载 |
| 徽章发光解锁 | `AnimatedContainer` + BoxShadow | 600ms | 微章页 |
| 页面切换 | `SlideTransition` | 200ms | Tab 切换 |
| Lottie 动画 | `lottie` 包 | — | 空状态、成就解锁庆祝 |

---

## 三、素材计划

### 3.1 可以加入的素材类型

| 素材 | 来源 | 用在哪里 |
|------|------|----------|
| 攀岩 SVG 插画 | unDraw.co（免费，可换色）| 空状态页、通知空页 |
| Lottie 动画 | LottieFiles.com（免费） | 徽章解锁庆祝、空状态动画 |
| 噪点纹理 PNG | 生成一次放入 assets | 全局背景叠加 |
| Hold 形态图案 | 自绘 SVG（简单圆/多边形）| 卡片背景装饰 |
| 路线颜色 icon | 自绘 SVG（彩色圆点）| V 等级标签 |

### 3.2 需要添加的包

```yaml
# pubspec.yaml 追加
lottie: ^3.1.0   # Lottie 动画支持
```

### 3.3 素材目录结构

```
assets/
  icons/        ← 已有
  map/          ← 已有
  illustrations/ ← 新增：SVG 插画
    empty_community.svg
    empty_notifications.svg
    achievement_unlock.svg
  lottie/       ← 新增：Lottie JSON
    confetti.json        ← 成就解锁庆祝
    empty_state.json     ← 空状态动画
  textures/     ← 新增
    noise.png            ← 背景噪点纹理
```

---

## 四、各页面重构方案

### 📊 记录/训练页 — **优先级 1，先改这个**

**当前问题：** 两个小灰方块统计、普通按钮、emoji 图标

**重构后布局：**
```
┌──────────────────────────────────┐
│ 记录                             │  ← Oswald 700
│ [训练] [进步] [微章]              │  ← Tab bar Oswald
├──────────────────────────────────┤
│ ┌────────────────────────────┐   │
│ │  ░░░ 橙色光晕 hero 卡片 ░░░ │   │  ← 渐变卡片
│ │  本月最高                   │   │
│ │      V6                    │   │  ← Barlow Condensed 72px!
│ │  2次训练  ·  Campus Wall   │   │  ← 小字辅助信息
│ └────────────────────────────┘   │
│                                  │
│ ▓▓▓▓▓▓  GO CLIMB  ▓▓▓▓▓▓ ◉    │  ← 全宽橙色按钮 + 呼吸光圈
│ + 单条记录                        │
│                                  │
│ RECENT SESSIONS ────────  2×     │  ← Oswald 大写
│                                  │
│ ┌─╸ V6 ╺──────────────────────┐ │  ← 左侧橙色等级竖条
│ │ APR 21                  1m23s│ │  ← 日期 Oswald + 时长
│ │ ⚡ Flash·0  ✓ Send·1  💪·0   │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

**动效：** Go Climb 按钮有持续缓慢的脉冲光圈，暗示"随时可以出发"

---

### 📈 记录/进步页 — 优先级 2

**重构后：**
- 4 个统计格子改为 2×2 大卡片，每个数字用 Barlow Condensed 64px
- 数字加载时有计数跳动动画（从 0 跳到实际值）
- 图表标题用 Oswald，坐标轴字体更小更轻
- 等级分布的进度条更粗（8px），颜色用 V 等级颜色系统

---

### 🏅 记录/微章页 — 优先级 3

**重构后：**
- 徽章形状换六边形（clip path），比圆形更有攀岩赛事感
- 已解锁：橙色光晕（BoxShadow spread 8px）
- 锁定：半透明模糊处理（不是灰色），配一个小锁图标
- 解锁动画：scale + glow 同时出现（Lottie 金色粒子可选）
- 空白区域：放一个 SVG 插画 + "继续努力解锁更多" 文案

---

### 🔔 通知页 — 优先级 4（最快做）

**重构后：**
- 分组标题：TODAY / THIS WEEK / EARLIER（Oswald 大写）
- 通知行：左侧放对应徽章图标（不是 emoji），右侧标题+描述两行
- 未读：左侧橙色细竖条（2px）
- 空状态：SVG 插画 + "你的通知会出现在这里"

---

### 🌍 社区页 — 优先级 5

**重构后：**
- 去掉全宽分隔线，改为卡片之间 8px 空隙，卡片有轻微阴影
- 恢复哈希头像颜色（6色）
- 帖子左侧加 2px 竖条（普通=透明/找搭子=橙/Beta=蓝）
- "找搭子" tag 改为更有设计感的 pill（填色不是描边）

---

### 👤 我的页 — 优先级 6

**重构后：**
- Profile header：头像周围加橙色渐变圆环（类似运动 app 的活动环）
- 数字（2/2/0/0）改用 Barlow Condensed 32px
- 排行榜：第1名整行橙色 tint 背景，奖牌换成对应颜色实心圆

---

## 五、实施顺序

```
Step 1 (今天): 记录/训练页完整重构
  - Hero 统计卡片
  - Go Climb 脉冲动画
  - Session 卡片样式

Step 2: 进步页数字大改 + 计数动画

Step 3: 微章页六边形 + 发光效果

Step 4 (最快): 通知页分组 + 空状态

Step 5: 社区页卡片改版

Step 6: 我的页 Profile header

Step 7 (最后): 全局背景质感叠加
```

---

## 六、不改的东西

- 登录页：已经是最好的页面，保持
- 所有业务逻辑：不动任何 API 调用、state 管理
- 探索页地图：受地图 SDK 限制，只能微调周边 UI
