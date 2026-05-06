# Phase 5 & 6 实现方案

> 版本：v1.0 | 日期：2026-04-12 | 基于产品设计方案 v1.0

---

## 背景

产品需求文档中列为 🔴 核心 的「进步统计图表」（75% 用户最想要）和 🟡 重要 的「教练认证」在此阶段实现。两个功能改动区域不重叠，可并行开发。

---

## Phase 5 — 进步统计图表

### 目标

在「记录」Tab 的「进步」子页面中提供有意义的数据可视化，帮助用户看到自己的进步轨迹。内容精简，保留三个最有价值的维度，避免信息过载。

### 数据维度选择（依据问卷 TOP3：进步统计图）

| 图表 | 内容 | 类型 |
|------|------|------|
| 攀爬频率 | 每周/每月完成的攀爬次数 | BarChart（柱状图） |
| 等级分布 | 各难度完成数量 + Flash 占比 | 横向进度条（复用 GradeStat） |
| 结果概览 | Flash / 完成 / 尝试 总数及占比 | 三色数字 + 彩色条 |

**时间段切换**：周（近 8 周）/ 月（近 6 个月）/ 总（全部按月分组）

---

### 后端改动

#### 新接口

```
GET /api/stats/me?period=WEEK|MONTH|ALL
Authorization: Bearer {token}
```

**响应结构**：

```json
{
  "period": "WEEK",
  "buckets": [
    {
      "label": "4/7",
      "climbCount": 5,
      "flashCount": 1,
      "sendCount": 2,
      "attemptCount": 2,
      "sessionMinutes": 90
    }
  ],
  "gradeDistribution": [
    { "difficulty": "VB", "total": 3, "sends": 2, "flashes": 0 },
    { "difficulty": "V0", "total": 8, "sends": 5, "flashes": 1 }
  ],
  "summary": {
    "totalClimbs": 47,
    "totalFlashes": 8,
    "flashRate": 17,
    "topGrade": "V5",
    "totalSessions": 12
  }
}
```

#### 新文件

| 文件 | 说明 |
|------|------|
| `dto/stats/StatsPeriodDto.java` | 顶层响应 DTO |
| `dto/stats/StatsBucketDto.java` | 单个时间桶（label + 各计数） |
| `dto/stats/StatsSummaryDto.java` | 汇总数字（总数、Flash率、最高难度） |
| `service/StatsService.java` | 接口定义 |
| `service/impl/StatsServiceImpl.java` | 实现：查询 ClimbLog + ClimbSession 计算 |
| `controller/StatsController.java` | `GET /api/stats/me` |

#### 查询逻辑

- **WEEK**：取最近 8 个完整周（`YEARWEEK(date)` 分组），label 格式 `M/d`（该周第一天）
- **MONTH**：取最近 6 个月（`DATE_FORMAT(date, '%Y-%m')` 分组），label 格式 `M月`
- **ALL**：取全部记录按月分组，label 同上
- **等级分布**：全时间，直接复用 `ClimbServiceImpl.getGradeStats()` 的逻辑
- **topGrade**：按 V 级数字排序，取 `result IN (FLASH, SEND)` 中最高难度

---

### 前端改动

#### 新依赖（pubspec.yaml）

```yaml
fl_chart: ^0.69.0
```

#### 新文件 / 修改文件

| 文件 | 改动 |
|------|------|
| `models.dart` | 新增 `ClimbStats`, `StatsBucket`, `StatsSummary` |
| `api_client.dart` | 新增 `fetchStats(String period)` |
| `record_tab.dart` | 填充「进步」子页面（现为空壳） |

#### UI 结构（进步 Tab 内容）

```
┌─────────────────────────────────────┐
│  [周]  [月]  [总]    ← SegmentedButton
├─────────────────────────────────────┤
│  总攀爬 47   Flash率 17%  场次 12   ← 概览数字条
├─────────────────────────────────────┤
│                                     │
│  攀爬频率                           │
│  ████ ██ ████ ██ ███ ██ ████ ██    │ ← BarChart（8 柱）
│  3/10 3/17 ...                      │
├─────────────────────────────────────┤
│  等级分布                           │
│  VB  ████████░░  8/10               │
│  V0  ████████████  12/12            │
│  V3  █████░░░░░  5/9                │
│  ... （仅展示有记录的等级）         │
├─────────────────────────────────────┤
│  Flash ⚡ 8   完成 ✅ 31   尝试 💪 8 │ ← 彩色三色条
└─────────────────────────────────────┘
```

#### BarChart 关键配置

- X轴：bucket.label（周/月标签）
- Y轴：climbCount
- 触摸 tooltip 显示：次数 / Flash / 完成 / 尝试
- 颜色：primary（ember）实色，高度不超过可见区域
- 无数据时显示友好占位（「还没有记录，去爬一条吧」）

---

## Phase 6 — 教练认证系统

### 目标

- 用户在「我的」页面提交教练认证申请（上传证书图片 + 简历文字）
- 管理员在 App 内审核（通过 / 拒绝 + 填写原因）
- 审核通过后，名字旁全社区可见「教练」蓝色标签（帖子、评论、排行榜）

### 设计原则（来自产品方案）

> 登录注册只有一个统一入口，Coach 是后续认证获得的身份标签，不是注册时的选项。

---

### 后端改动

#### 数据模型

**新实体：`CoachCertification.java`**

```java
id          BIGINT PK
user        ManyToOne → users (LAZY)
status      ENUM(PENDING, APPROVED, REJECTED)
certificateImagePath  VARCHAR(500)   // 本地文件路径，对外映射为 URL
resumeText  VARCHAR(2000) nullable
rejectReason VARCHAR(500) nullable
appliedAt   DATETIME
reviewedAt  DATETIME nullable
```

**新枚举：`CertificationStatus.java`**

```java
PENDING, APPROVED, REJECTED
```

**`UserRole.java` 增加**

```java
CLIMBER, COACH, ADMIN
```

**`User.java` 无需改字段**（`isCoachCertified` 和 `role` 已有）

#### 文件存储

```yaml
# application.yml
upload:
  dir: ${user.home}/.betaup-uploads/certificates
```

```java
// WebMvcConfig.java — 静态资源映射
registry.addResourceHandler("/uploads/**")
        .addResourceLocations("file:" + uploadDir + "/");
```

图片通过 `POST /api/coach/apply`（multipart）上传，服务端随机生成文件名存储，返回相对路径，前端拼接 `baseUrl + /uploads/certificates/xxx.jpg` 展示。

#### 新接口

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| `POST` | `/api/coach/apply` | CLIMBER | 提交认证申请（multipart：image + resumeText） |
| `GET` | `/api/coach/status` | CLIMBER | 查询当前认证状态及申请详情 |
| `GET` | `/api/admin/certifications` | ADMIN | 查询申请列表（?status=PENDING） |
| `POST` | `/api/admin/certifications/{id}/approve` | ADMIN | 审核通过 |
| `POST` | `/api/admin/certifications/{id}/reject` | ADMIN | 拒绝（body：rejectReason） |

审核通过时的副作用（在 Service 层同步执行）：
```java
user.setIsCoachCertified(true);
user.setRole(UserRole.COACH);
certification.setStatus(CertificationStatus.APPROVED);
certification.setReviewedAt(LocalDateTime.now());
// 发通知给申请人
```

#### DTO 改动（「教练」标签传播）

需要在以下 DTO 增加 `authorIsCoach: boolean` 字段，从 `user.isCoachCertified` 填充：

| DTO | 新字段 |
|-----|--------|
| `PostDto.java` | `authorIsCoach` |
| `CommentDto.java` | `authorIsCoach` |
| 排行榜用户项（`LeaderboardEntryDto` 或内联 Map） | `isCoach` |

#### 新文件

| 文件 | 说明 |
|------|------|
| `entity/CoachCertification.java` | 认证申请实体 |
| `entity/CertificationStatus.java` | 状态枚举 |
| `repository/CoachCertificationRepository.java` | findByUserId, findByStatus |
| `dto/coach/CoachStatusDto.java` | 当前状态 + 申请详情（含拒绝原因） |
| `dto/coach/CoachApplicationRequest.java` | resumeText（图片单独 multipart） |
| `dto/admin/CertificationReviewDto.java` | 管理员列表项 |
| `service/CoachCertificationService.java` | 接口 |
| `service/impl/CoachCertificationServiceImpl.java` | 实现 |
| `controller/CoachController.java` | 用户侧接口 |
| `controller/AdminController.java` | 管理员侧接口 |

---

### 前端改动

#### 新依赖（pubspec.yaml）

```yaml
image_picker: ^1.1.2
```

#### 修改文件 / 新文件

| 文件 | 改动 |
|------|------|
| `models.dart` | Post/Comment 新增 `authorIsCoach`；新增 `CoachStatus`, `CertificationStatus` 枚举 |
| `api_client.dart` | `fetchCoachStatus()`, `applyForCoach(image, resumeText)`, `fetchPendingCertifications()`, `approveCertification(id)`, `rejectCertification(id, reason)` |
| `profile_tab.dart` | 个人主页 header 显示「教练」Chip；认证状态区域 |
| `community_tab.dart` | 帖子卡片作者名后显示「教练」Chip |
| `post_detail_sheet.dart` | 评论作者名后显示「教练」Chip |
| `user_profile_sheet.dart` | 他人主页显示教练标签 |
| 新建 `coach_apply_sheet.dart` | 申请表单（图片选择 + 简介文本 + 提交） |
| 新建 `admin_review_sheet.dart` | 管理员审核页（仅 ADMIN 角色可进入） |

#### 「教练」标签组件

在 `common.dart` 抽取一个小组件：

```dart
// 用法：Row(children: [Text(authorName), if (isCoach) CoachChip()])
class CoachChip extends StatelessWidget {
  // 蓝色小 Chip：「教练」
  // 尺寸很小，不影响布局
}
```

#### 认证状态在 profile_tab.dart 的展示

```
状态: NONE      → [申请教练认证] 按钮（outlined style）
状态: PENDING   → 🕐 审核中...（灰色提示 + 提交时间）
状态: APPROVED  → ✅ 已认证教练（不可再申请）
状态: REJECTED  → ❌ 审核未通过：{拒绝原因} + [重新申请] 按钮
```

#### Admin 入口

- `MainShell` 检测 `user.role == ADMIN` 时，在底部导航栏额外显示「管理」Tab（或在「我的」页面底部加入口）
- 管理 Tab 内容：待审核列表 → 每项展示申请人信息 + 证书图片 + 简历 + 通过/拒绝按钮

---

## 实现顺序建议

```
Week 1（可并行）:
  ├─ [后端] StatsController + StatsServiceImpl + 3个DTO
  └─ [后端] CoachCertification 实体 + Repository + 文件上传

Week 1 后半:
  ├─ [前端] fl_chart 集成 + 进步 Tab 图表
  └─ [后端] CoachController + AdminController + DTO改动（authorIsCoach）

Week 2:
  ├─ [前端] coach_apply_sheet + profile_tab 认证状态区域
  ├─ [前端] 帖子/评论「教练」Chip 传播
  └─ [前端] admin_review_sheet
```

---

## 不做的部分（明确排除）

- 图片 CDN / 云存储（本地文件系统够用，演示不需要云端）
- 教练约课功能（产品文档阶段三，超出本阶段范围）
- 城市分榜（现有排行榜已够，演示不需要）
- 统计图表的实时刷新（切换时间段重新请求即可，无需 WebSocket）
