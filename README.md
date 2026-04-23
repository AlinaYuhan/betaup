# BetaUp

> **"Beta"** is climber slang for route information — tips, sequences, and moves that help others send a problem. BetaUp is where climbers share that knowledge, track every send, and level up together.

BetaUp 是一款面向攀岩者与教练的全栈训练社交应用，融合游戏化成就系统、AI 语音助手与实时社区互动，让每次训练都变成有意义的进步记录。

---

## ✨ 核心功能 / Key Features

### 🧗 训练记录 / Climb Logging
- 记录每次攀爬：线路难度、攀爬类型（Flash / Redpoint / Attempt）、训练时长
- 语音输入——对 Panda 说"记录一个 V5 完成"即可免手操作
- 自动生成会话总结与进度图表

### 🏅 游戏化成就 / Gamification
- 20+ 成就徽章：首次完成、连续打卡、解锁新难度等
- XP 经验值系统，徽章解锁触发庆祝动画（Confetti）
- 个人主页徽章墙，进度一目了然

### 🤖 AI 语音助手 Panda / AI Voice Assistant
- 可拖动熊猫头像，点击激活语音界面
- 基于 DeepSeek NLP + Web Speech API，自然语言理解攀岩指令
- 支持：记录攀爬、查询统计、开始/结束训练、问天气等
- TTS 语音回复，全程免触屏操作

### 👥 社区 / Community
- 发布动态、上传攀爬照片/视频（最多 6 张）
- **Beta 分享区**：发布线路 Beta（过线技巧），标记线路名称与难度，帮助其他人突破难关
- 点赞、评论、关注其他攀岩者
- 实时排行榜：按次数、最高级别、XP 排名

### 🗺️ 探索地图 / Explore
- 基于 GPS 定位附近岩馆
- 岩馆地图 + 打卡签到（积累地点徽章）
- 心率监测（蓝牙 BLE 设备连接）

### 🏫 教练系统 / Coach Connect
- 教练认证申请 → 管理员审核 → 激活教练权限
- 教练可查看学员训练数据、发布反馈与训练计划
- 学员可在 App 内直接接收并回复教练反馈

### 🛠️ 管理后台 / Admin Dashboard
- 用户管理与内容审核
- 教练申请审批
- 全站数据统计

---

## 🏗️ 技术架构 / Tech Stack

```
┌────────────────────────────────────────────────┐
│         Flutter Client (Web / Mobile)           │
│  Auth · Record · Profile · Community · Explore  │
│  Voice Assistant (Web Speech API + flutter_tts) │
└──────────────────┬─────────────────────────────┘
                   │ HTTPS REST API (JSON)
┌──────────────────▼─────────────────────────────┐
│      Spring Boot 3.x Backend (Port 8080)        │
│  JWT Auth · JPA/Hibernate · Achievement Engine  │
└──────────┬──────────────┬───────────────────────┘
           │              │
    ┌──────▼──────┐  ┌────▼────────────┐
    │  H2 / MySQL │  │  DeepSeek API   │
    └─────────────┘  └─────────────────┘
```

| 层 | 技术 |
|----|------|
| 移动/Web 前端 | Flutter 3.x · Dart |
| 后端 API | Spring Boot 3.2 · Java 21 |
| 数据库 | H2 In-Memory (Dev) · MySQL (Prod) |
| 认证 | JWT (Bearer Token) · 角色权限 CLIMBER / COACH / ADMIN |
| AI 语音 | DeepSeek Chat API · Web Speech API · flutter_tts |
| 地图 | Geolocator · flutter_map |
| 硬件 | flutter_blue_plus (BLE 心率) |
| 图表 | fl_chart |
| Portfolio | GitHub Pages |

---

## 🚀 本地运行 / Running Locally

### 后端 Backend

```bash
cd backend
./mvnw spring-boot:run
# API 运行在 http://localhost:8080
```

### Flutter 前端 Frontend

```bash
cd mobile_flutter
flutter pub get
flutter run -d chrome   # Web 演示
# 或
flutter run             # 连接 Android / iOS 设备
```

> Flutter Web 需要 Chrome，后端默认使用 H2 内存数据库，无需额外配置 MySQL 即可启动演示。

---

## 👥 团队 / Team — CPT208 · Group C2-6

| 成员 | 角色 | 主要贡献 |
|------|------|---------|
| **Cao Yuhan 曹雨涵** | Lead Developer | 全栈开发：Spring Boot REST API（70+ 端点）、Flutter 全部页面（15+ 屏）、JWT 认证、游戏化引擎、AI 语音助手、社区模块、教练系统、管理后台、地图集成、数据库设计 |
| **Yang Renyu 杨仁雨** | User Research | 用户访谈、问卷设计、Persona 建立、用户旅程地图 |
| **Chen Zixi 陈子熹** | UI/UX Design | Figma 原型（低保真 + 高保真）、视觉风格指南、探索页前端、数据库 Schema 审查 |
| **Yang Mengxi 杨梦溪** | Evaluation | 可用性测试、SUS 问卷、项目海报设计、演示视频制作 |

---

## 🔗 Links

- **Portfolio**: [alinayuhan.github.io/betaup](https://alinayuhan.github.io/betaup)
- **GitHub**: [github.com/AlinaYuhan/betaup](https://github.com/AlinaYuhan/betaup)
- **CPT208** · University of Liverpool / XJTLU · 2025–2026
