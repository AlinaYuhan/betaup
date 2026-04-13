# BetaUp 开发日志

## Phase 2 — 社交功能开发（2026-04-10）

### 功能目标
- 社区动态（发帖、点赞、评论）
- 关注/粉丝系统
- 排行榜（徽章榜 / 打卡榜）
- 个人资料编辑

---

### 遇到的问题与解决办法

#### 1. BottomSheet 内 `SessionScope.of(context)` 失效
**现象**：发帖、写评论、编辑资料时，操作无响应或静默失败。  
**原因**：`showModalBottomSheet` 创建了新的 Route，其 `BuildContext` 不在 `SessionScope`（InheritedWidget）的树上，`SessionScope.of(context)` 会 assert 失败或拿到 null，导致 token 取不到，请求返回 401。  
**解决**：在调用 `showModalBottomSheet` **之前**（在有效的父级 context 中）读取 session，构建好 `ApiClient` 后通过构造函数传入 sheet。Sheet 内部只用 `widget.client`，不再调用 `SessionScope.of(context)`。

```dart
// ✅ 正确写法
Future<void> _showCreatePost() async {
  final session = SessionScope.of(context); // 在有效 context 里读
  final client = ApiClient(readToken: () => session.token);
  await showModalBottomSheet(
    builder: (_) => _CreatePostSheet(client: client), // 传进去
  );
}

// ❌ 错误写法（sheet 内部调用）
class _CreatePostSheetState extends State<_CreatePostSheet> {
  Future<void> _submit() async {
    final session = SessionScope.of(context); // 这里 context 不在树上
  }
}
```

---

#### 2. `initState` 中不能调用 InheritedWidget
**现象**：`ProfileHeader` 加载 dashboard 数据时崩溃。  
**原因**：`initState()` 阶段 widget 还未挂载到树上，不能调用 `SessionScope.of(context)`。  
**解决**：改为在 `didChangeDependencies()` 中加载，用 `_loaded` 布尔值防止重复执行。

```dart
bool _loaded = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_loaded) {
    _loaded = true;
    _loadData();
  }
}
```

---

#### 3. 错误信息被 BottomSheet 遮挡（SnackBar 不可见）
**现象**：发帖失败时 SnackBar 出现在底部弹窗后面，用户看不到任何反馈。  
**解决**：把错误信息改为在 sheet 内部用红色 `Text` 显示，并用 `debugPrint` 同步输出到终端。

```dart
String? _errorMsg;

// 发布失败时
setState(() { _errorMsg = e.toString(); _submitting = false; });

// build 里直接展示
if (_errorMsg != null)
  Text("发布失败：$_errorMsg", style: TextStyle(color: Colors.red)),
```

---

#### 4. Hibernate 懒加载异常（LazyInitializationException）
**现象**：GET /api/posts 返回 500，错误信息为 `Could not initialize proxy [com.betaup.entity.User#1] - no session`。评论列表同样报错。  
**原因**：`Post.user` 和 `Comment.user` 均为 `FetchType.LAZY`，而 `application.yml` 中 `open-in-view: false`，Controller 的 `toDto()` 调用 `post.getUser().getName()` 时 JPA session 已关闭。  
**解决**：在 Repository 的查询方法上加 `@EntityGraph(attributePaths = {"user"})`，让 JPA 在查询时自动 JOIN FETCH user，避免 session 关闭后再访问懒代理。

```java
// PostRepository
@EntityGraph(attributePaths = {"user"})
Page<Post> findAllByOrderByCreatedAtDesc(Pageable pageable);

// CommentRepository
@EntityGraph(attributePaths = {"user"})
List<Comment> findByPostIdOrderByCreatedAtAsc(Long postId);
```

---

#### 5. 评论后帖子评论数不刷新
**现象**：评论成功后，帖子列表中评论数仍显示 0。  
**原因**：`_openComments()` 调用 `showModalBottomSheet` 时没有 `await`，sheet 关闭后不会触发帖子列表刷新。  
**解决**：将 `_openComments()` 改为 `async`，`await` modal 关闭后调用 `_load()` 刷新列表。

```dart
Future<void> _openComments(Post post) async {
  ...
  await showModalBottomSheet(...);
  _load(); // 关闭后刷新，拿到最新 commentCount
}
```

---

#### 6. 排行榜只显示一个用户
**现象**：排行榜只显示当前登录用户，其他注册用户不出现。  
**原因**：原代码用 `userRepository.findByRoleOrderByCreatedAtDesc(UserRole.CLIMBER)` 只查 CLIMBER 角色，Coach 用户不包含在内。  
**解决**：改为 `userRepository.findAll()` 查所有用户。

---

### 技术栈
- **后端**：Spring Boot 3 + Java 21 + MySQL 8 + JPA/Hibernate + JWT
- **前端**：Flutter (Windows Desktop) + Dart
- **认证**：Bearer JWT，过期时间 24 小时

### 注意事项
- Windows 上用 PowerShell 的 `curl.exe` 发 JSON 请求时，反引号换行会导致 JSON 解析失败，改用 `Invoke-RestMethod` 代替
- 后端修改 Java 文件后必须重启（`Ctrl+C` → `mvn spring-boot:run`），热重载对 Spring Boot 无效
- Flutter 用 `r` 热重载，`R` 完全重启

---

## Phase 2.5 — 社交功能深化（2026-04-11）

### 功能目标
- 评论交互重新设计（点按回复、长按菜单）
- 抽取公共 Widget：`UserProfileSheet`、`FollowListSheet`、`PostDetailSheet`
- 个人资料页"关注"/"粉丝"数字可点击，弹出关注列表
- 通知 Tab 点击跳转：FOLLOW → 我的粉丝列表；LIKE/COMMENT → 帖子详情

### 新增/修改文件
| 文件 | 说明 |
|------|------|
| `user_profile_sheet.dart` | 提取为公共 Widget，展示他人资料+关注/取关 |
| `follow_list_sheet.dart` | 关注/粉丝列表，每行可点击查看对方资料 |
| `post_detail_sheet.dart` | 帖子全文+评论，支持通知导航 |
| `community_tab.dart` | 评论列表去掉"回复"按钮，改为点按→回复模式，长按→操作菜单 |
| `profile_tab.dart` | "关注"/"粉丝"加 GestureDetector |
| `notification_tab.dart` | `_NotificationTile` 增加 `onTap` 回调 |
| `FollowController.java` | 新增 GET /api/users/{id}/followers、/following |
| `PostController.java` | 新增 GET /api/posts/{id} 单帖查询 |

### 遇到的问题与解决办法

#### 7. 评论复制功能报错（Clipboard 未导入）
**现象**：长按评论选"复制"后程序崩溃，`Clipboard` 类找不到。  
**原因**：`Clipboard.setData()` 在 `package:flutter/services.dart` 中，而不是 `package:flutter/material.dart`。  
**解决**：在文件顶部加 `import 'package:flutter/services.dart';`。

---

#### 8. FocusNode 跨 Widget 传递
**现象**：点按评论进入回复模式后，键盘没有自动弹出，需要用户再点一次输入框。  
**原因**：`_setReply()` 里调用 `_focusNode.requestFocus()` 时 FocusNode 没有绑定到 TextField。  
**解决**：在 `_CommentsSheetState` 中声明 `final FocusNode _focusNode = FocusNode()`，并通过 `focusNode: _focusNode` 传给 `TextField`，`dispose()` 里记得释放。

```dart
@override
void dispose() {
  _controller.dispose();
  _focusNode.dispose(); // 必须释放，否则内存泄漏
  super.dispose();
}
```

---

#### 9. `if` 语句未用大括号引发 linter 报错
**现象**：CI lint 阶段报 `if` 语句 body 应在 block 中。  
**原因**：setState 回调里直接写 `if (mounted) setState(...)`，没有花括号。  
**解决**：一律改为 `if (mounted) { setState(...); }`。

---

## Phase 2.5-Merge — 合入同学地图功能（2026-04-11）

### 背景
同学 czx6365 在 `6e268c3` 提交中完成了岩馆地图功能（`geolocator` 依赖 + `explore_tab.dart` 改动），需要合入主分支。

### 操作流程
```bash
git fetch origin
git merge 6e268c3
# 解决冲突后
git add .
git commit  # merge commit 373b152
git push origin main
```

### 遇到的问题与解决办法

#### 10. Flutter API 版本冲突：`withAlpha` vs `withValues`
**现象**：merge 时 `profile_tab.dart` 出现冲突，我方用 `withAlpha(102)`，对方用 `withValues(alpha: 0.4)`。  
**原因**：Flutter 3.x 新增了 `withValues(alpha:)` 替代旧版 `withAlpha(int 0-255)`，两种写法功能等价但 API 不同。  
**解决**：采用对方更新的写法 `withValues(alpha: x.x)`，保持与新版 Flutter API 一致。

| 旧写法 | 新写法 |
|--------|--------|
| `color.withAlpha(102)` | `color.withValues(alpha: 0.4)` |
| `color.withAlpha(20)` | `color.withValues(alpha: 0.08)` |

---

#### 11. `pubspec.lock` 镜像源冲突
**现象**：对方的 `pubspec.lock` 写的是 `pub.flutter-io.cn`（中国镜像），本地是 `pub.dev`（官方源）。  
**原因**：两人网络环境不同，生成的 lock 文件镜像域名不同，git 把这也当做冲突。  
**解决**：保留本地 `pub.dev` 的版本，不把中国镜像源写入版本库，避免其他成员在非中国网络下拉取失败。

---

## Phase A — 攀爬记录系统重设计（2026-04-11）

### 功能目标
根据竞品分析（磕磕、TopLogger、Crux）和用户体验痛点，对记录流程进行改造：
- 难度选择改为横向滑动的 Chip 选择器（VB、V0–V12）
- 结果由下拉框改为三按钮选择：⚡ Flash / ✅ 完成 / 💪 试了
- 新增尝试次数 +/− 计数器（Flash 时隐藏）
- 路线名改为选填
- 统计页新增各V级完成率进度条

### 数据模型变更
**后端（ClimbLog 表）**：
```sql
-- 新增两列
ALTER TABLE climb_logs
    ADD COLUMN result ENUM('FLASH','SEND','ATTEMPT') DEFAULT NULL,
    ADD COLUMN attempts INT NOT NULL DEFAULT 1;
-- route_name 改为允许 NULL
ALTER TABLE climb_logs MODIFY COLUMN route_name VARCHAR(160) NULL;
```
旧字段 `status`（COMPLETED/ATTEMPTED）保留，由 `result` 自动推导（FLASH/SEND → COMPLETED，ATTEMPT → ATTEMPTED），确保已有徽章统计逻辑不受影响。

### 新增/修改文件
| 文件 | 说明 |
|------|------|
| `ClimbResult.java` | 新枚举：FLASH / SEND / ATTEMPT |
| `ClimbLog.java` | 新增 `result`、`attempts` 字段；`routeName` 改可空 |
| `ClimbLogRequest.java` | 用 `ClimbResult result` 替换旧 `ClimbStatus status`；加 `attempts` |
| `ClimbLogResponse.java` | 返回体加 `result`、`attempts` |
| `GradeStatDto.java` | 新 DTO：`difficulty` / `total` / `sends` / `flashes` |
| `ClimbServiceImpl.java` | 创建/更新时自动推导 `status`；新增 `getGradeStats()` 带 V 级排序 |
| `ClimbController.java` | 新增 `GET /api/climbs/grade-stats` |
| `models.dart` | 新增 `ClimbResult` 枚举（含 emoji 标签）；更新 `ClimbLog`；新增 `GradeStat` |
| `api_client.dart` | 新增 `fetchGradeStats()` |
| `common.dart` | 新增 `resultColor()` 辅助函数（金/绿/橙） |
| `climber_pages.dart` | 重设计 `ClimbEditorPage`；更新日志卡片；`ClimberDashboardTab` 加难度统计卡 |

### 遇到的问题与解决办法

#### 12. `@NotBlank` 注解孤立导致编译失败
**现象**：移除 `routeName` 的 `@NotBlank` 后，同文件 `venue` 字段仍有 `@NotBlank`，但 import 行被一并删除，编译报 `cannot find symbol`。  
**解决**：改为直接把 `venue` 的 `@NotBlank` 也删除（venue 验证下沉到 Service 层），同时移除已无用的 import。

---

#### 13. `_loadGradeStats` 方法缺少关闭大括号
**现象**：IDE 报大量"class in class"错误，实际原因是方法体少了一个 `}`，导致后续类被误解析为嵌套类。  
**解决**：补全缺失的 `}` 即可；这类错误优先看第一个报错行的上文，而不是报错行本身。

---

#### 14. `@Builder.Default` 与 `@AllArgsConstructor` 的配合
**现象**：`ClimbLog` 加了 `@Builder.Default` 给 `attempts` 赋默认值 1，但 `@AllArgsConstructor` 生成的全参构造器会忽略默认值。  
**说明**：这在生产中无影响，因为 Hibernate 通过 `@NoArgsConstructor` 实例化，Builder 走 `@Builder.Default`，`@AllArgsConstructor` 只在测试/手动构建时使用。只需确保 Service 层手动传入 `attempts` 即可。

---

### 设计决策记录
- **为什么保留旧 `status` 字段**：badge 计数（`countByUserIdAndStatus`）依赖此字段，直接删除会破坏徽章系统。通过 `deriveStatus(result)` 桥接，做到新旧兼容。
- **为什么 `result` 允许 NULL**：Hibernate DDL update 新增列时默认 nullable，已有行 `result` 为 NULL，`toResponse()` 里从 `status` 反推兜底，不影响展示。
- **Flash 时隐藏次数计数器**：Flash 定义就是第一次就完成，次数固定为 1，不需要用户输入，UI 上隐藏减少干扰。

---

## Phase B — 训练场次系统（2026-04-11）

### 功能目标
参考主流运动 App（Nike Run Club、Strava）的"开始训练 → 计时 → 结束 → 战报"流程，为攀岩日志引入"场次"概念：
- 「开始攀岩」→ 输入场馆 → 进入全屏计时页
- 计时页可边训练边记录日志（自动关联场次）
- 结束时生成「训练战报」：时长、Flash/完成/尝试统计、最高完成难度、各难度分布进度条

### 数据模型变更
**后端新建表**（手动执行，Hibernate DDL update 对 NOT NULL 列有限制）：
```sql
CREATE TABLE climb_sessions (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  start_time DATETIME(6) NOT NULL,
  end_time DATETIME(6) NULL,
  venue VARCHAR(120) NULL,
  notes VARCHAR(500) NULL,
  created_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_sessions_user (user_id),
  CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(id)
);
ALTER TABLE climb_logs ADD COLUMN session_id BIGINT NULL;
```

### 新增/修改文件
| 文件 | 说明 |
|------|------|
| `ClimbSession.java` | 新实体：id / user / startTime / endTime / venue / notes |
| `ClimbSessionRepository.java` | 按 userId 查活跃场次、按 id+userId 查单场次 |
| `SessionStartRequest.java` | 请求体：venue |
| `SessionDto.java` | 响应：id / userId / venue / startTime / endTime / active |
| `SessionSummaryDto.java` | 战报响应：时长 / Flash / 完成 / 尝试 / 最高难度 / 难度分布列表 |
| `GradeStatDto.java` | 难度统计：difficulty / total / sends / flashes |
| `SessionServiceImpl.java` | startSession / getActiveSession / endSession（含 buildSummary） |
| `SessionController.java` | POST /sessions、GET /sessions/active、POST /sessions/{id}/end |
| `ClimbLog.java` | 新增 `session_id` 字段（Long，可空） |
| `models.dart` | 新增 `ClimbSession`、`SessionSummary`、`GradeStat` 模型 |
| `api_client.dart` | 新增 startSession / fetchActiveSession / endSession |
| `session_page.dart` | 新文件：全屏计时页 + 战报 BottomSheet（_WarReportSheet） |
| `record_tab.dart` | 新增场次状态管理；FAB 改为 Go Climb / 继续训练双态；AppBar 显示训练中指示器 |

### 遇到的问题与解决办法

#### 15. Hibernate DDL update 无法新增 NOT NULL 列
**现象**：后端重启后报 `Column 'attempts' not found`，Hibernate 未能自动添加该列。  
**原因**：MySQL 对非空表新增 NOT NULL 列需要 DEFAULT 值；Hibernate `ddl-auto: update` 的 ALTER 语句不带 DEFAULT，被 MySQL 拒绝。  
**解决**：
1. 在 `@Column` 加 `columnDefinition = "INT NOT NULL DEFAULT 1"`
2. 手动执行 `ALTER TABLE climb_logs ADD COLUMN attempts INT NOT NULL DEFAULT 1`

---

#### 16. routeName 存 NULL 导致 Hibernate 校验失败
**现象**：保存日志时报 `NULL not allowed for column 'route_name'`，即使数据库列已改为 nullable。  
**原因**：Hibernate 在执行 SQL 之前做内存校验，`@Column(nullable=false)` 仍生效；此外 Service 层将空字符串转成了 null 传入。  
**解决**：Service 层保存时统一用 `""` 替代 `null`（`routeName == null ? "" : routeName`），不存 null。

---

#### 17. Difficulty Chip 在 Windows 桌面无法横向滚动
**现象**：`SingleChildScrollView(scrollDirection: Axis.horizontal)` 包裹 Chip 行，鼠标拖拽无响应。  
**原因**：Flutter Windows 桌面端 `SingleChildScrollView` 默认不响应鼠标拖拽手势。  
**方案一**：改用 `Wrap` —— 但 VB~V12 共 14 个 Chip 会自动换行到 3 行，移动端体验差，放弃。  
**方案二（采用）**：改用 `Slider` —— 单行、任意设备均可操作；`_selectedDifficulty` 从 `String?` 改为 `String`，初始值为 `_kGrades[0]`（VB）。

---

### 设计决策记录
- **`session_id` 用 Long 而非 JPA 关系**：避免懒加载复杂度，反范式存 ID 即可，查询时不需要 JOIN。
- **战报在 BottomSheet 展示**：用 `DraggableScrollableSheet` 实现可拖拽的战报面板，关闭后自动 pop SessionPage 并刷新日志列表。
- **`didChangeDependencies` 代替 `initState` 加载数据**：`initState` 阶段无法安全调用 `SessionScope.of(context)`（InheritedWidget），改用 `didChangeDependencies` + `_sessionChecked` 布尔防重复。

---

## Phase B BugFix — 战报 Flash/完成 重复计数（2026-04-11）

### 问题
训练结束后战报显示：Flash=1、完成=1、尝试=1，但实际只记录了 2 条（V4 Flash + V10 尝试）。  
**根因**：`SessionServiceImpl.buildSummary()` 里 `sends` 的计数逻辑包含了 FLASH：
```java
// 错误写法
int sends = logs.stream()
    .filter(l -> l.getResult() == ClimbResult.FLASH || l.getResult() == ClimbResult.SEND ...)
    .count();
```
Flash 被同时计入 `flashes` 和 `sends`，导致三个统计数字加起来比实际条数多。

### 修复
`sends` 只计 SEND 结果，Flash 独立：
```java
// 修复后
int sends = logs.stream()
    .filter(l -> l.getResult() == ClimbResult.SEND
        || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
    .count();
```
难度分布进度条（`gSends`）仍保留 FLASH+SEND，因为进度条语义是"完成比例"，与顶部统计数字语义不同。

---

## Phase C — 记录 Tab 重构 + GPS 场馆识别（2026-04-11）

### 功能目标
参考 滑呗、磕磕 等主流运动 App 的交互模式，对「记录」Tab 的训练首页进行全面重构：
- 大号 **Go Climb** 橙色按钮作为核心操作入口
- GPS 自动识别附近岩馆（500m 地理围栏），开始训练时自动填入场馆名
- 顶部展示本月训练次数和累计时长
- 下方展示历史训练场次卡片（按场次组织，不再是原始日志列表）
- 有进行中的训练时，按钮切换为「继续训练」+ 实时计时器

### 新增/修改文件
| 文件 | 说明 |
|------|------|
| `ClimbSessionRepository.java` | 新增分页查询已结束场次 |
| `ClimbLogRepository.java` | 新增 `findBySessionIdIn` 批量查询（避免 N+1） |
| `SessionService.java` / `Impl` | 新增 `getUserSessions()`；`buildLightSummary()` 不含难度分布，减少数据量 |
| `SessionController.java` | 新增 `GET /api/sessions`（分页） |
| `api_client.dart` | 新增 `fetchSessions()` |
| `record_tab.dart` | **完全重写**：TrainingHomeTab（GPS + Go Climb + 场次历史）；Tab 2/3 保留进步/徽章 |

### 架构说明
**GPS 识别流程**（复用 explore_tab 已有的 geolocator 逻辑）：
```
geolocator.getCurrentPosition()
    → GET /api/gyms（已有接口）
    → Geolocator.distanceBetween() 逐一计算
    → 500m 内最近岩馆 → 绿色显示 + 自动填入场馆名
    → 超出范围 → 显示"最近：X岩馆（X.Xkm）"
    → GPS 失败 → 提示手动输入，不阻断流程
```

**批量查询优化**：`getUserSessions()` 先拿一页 ClimbSession，再用 `findBySessionIdIn` 一次性拉取所有关联日志，避免对每个场次单独查询（N+1 问题）。

### 遇到的问题与解决办法

#### 18. `ClimbLogsTab` 加载不稳定（已通过重构规避）
**现象**：切换 Tab 后日志列表有时不加载，需要手动下拉刷新。  
**根因**：`ClimbLogsTabState.initState()` 直接调用 `SessionScope.of(context)`，在 `IndexedStack` 中首次渲染时 InheritedWidget 树可能未稳定，导致数据加载失败且没有自动重试。  
**解决**：Phase C 重构彻底移除了 `ClimbLogsTab`，训练首页改用 `didChangeDependencies` + `_initialized` 布尔保护，确保只在 context 完全就绪后加载数据。

---

### 设计决策记录
- **不引入高德 API Key**：GPS 定位用系统 `geolocator`，岩馆坐标来自自有数据库 `/api/gyms`，两者结合即可实现"识别附近岩馆"，无需第三方地图 SDK。
- **GPS 失败不阻断流程**：定位权限拒绝或超时时，卡片显示"定位不可用"，用户仍可手动输入场馆名开始训练。
- **本月统计从前端计算**：直接对 `fetchSessions` 返回列表按月份过滤，避免新增专用统计接口。
- **Tab 1 改名「训练」**：原「攀爬日志」强调结果列表，新名强调行动入口，与大按钮设计意图一致。

---

## Phase 4 — 徽章系统升级（2026-04-12）

### 功能目标
- 徽章目录初始化（18 枚，四大类：等级/挑战/场馆/社交）
- 自动化徽章判定引擎（`BadgeAutomationService`）
- 解锁弹窗（confetti 彩带动画）
- 通知 Tab 支持 BADGE 类型（金色样式）
- 刷新数据时效：切换 Tab 时主动 reload 通知/徽章/排行榜

### 新增/修改文件
| 文件 | 说明 |
|------|------|
| `BadgeCatalogInitializer.java` | 应用启动时批量写入默认徽章（幂等） |
| `BadgeAutomationServiceImpl.java` | `evaluateUserBadges` + `buildProgressByCriteria` |
| `PostController.java` | `createPost` / `likePost` 后触发徽章判定 |
| `CommentController.java` | `addComment` 后触发徽章判定 |
| `PostDto.java` | 新增 `newlyUnlockedBadges` 字段，随 createPost 响应返回 |
| `common.dart` | 新增 `showBadgeUnlockDialog` + `_BadgeUnlockDialog` + `formatDuration` |
| `notification_tab.dart` | `NotificationTabState` 改为 public + `reload()` + BADGE 样式 |
| `main_shell.dart` | GlobalKey 挂载 NotificationTab / ProfileTab，Tab 切换时 reload |
| `profile_tab.dart` | `ProfileTabState` 改为 public + `reloadLeaderboard()` + `_leaderboardReloadKey` |
| `climber_pages.dart` | `ClimbEditorPage._save()` 创建日志后弹徽章解锁窗 |
| `session_page.dart` | `_endSession()` 结束训练后弹徽章解锁窗 |
| `community_tab.dart` | `_submit()` 发帖后弹徽章解锁窗 |
| `record_tab.dart` | `formatDuration` 接入，时长精确到秒 |

### 遇到的问题与解决办法

#### 19. H2 file-DB 不自动添加新列（category 找不到）
**现象**：后端启动报 `Column "b1_0.category" not found`，迁移脚本未生效。  
**原因**：H2 使用 file 模式时（`.mv.db` 文件），`ddl-auto: update` 对已有表不会可靠地新增列；旧数据文件的 schema 早于 `category` 字段被添加的时间点。  
**解决**：删除 `.betaup-dev/betaup.mv.db` 和 `.trace.db`，重启后 Hibernate 重建所有表。  
**经验**：H2 file-DB 的 `ddl-auto: update` 对已有非空表新增列不可靠；开发期间遇到 schema 不同步，直接删文件重建是最快的解决方式（生产环境需用 Liquibase/Flyway）。

---

#### 20. 端口 8080 冲突（后台进程未退出）
**现象**：`mvn spring-boot:run` 报 `Web server failed to start. Port 8080 was already in use`。  
**原因**：之前在后台启动的 Maven 进程仍在运行，用户再次手动启动产生冲突。  
**解决**：`netstat -ano | findstr :8080` 找到占用进程的 PID（47916），`taskkill /PID 47916 /F` 杀掉后重新启动。

---

#### 21. 社交类徽章从未触发
**现象**：在社区发帖或评论后，`FIRST_POST`、`COMMENT_10` 等徽章始终不解锁。  
**原因**：`PostController` 和 `CommentController` 直接操作 Repository，没有调用 `BadgeAutomationService.evaluateUserBadges()`。  
**解决**：两个 Controller 注入 `BadgeAutomationService`，在 `createPost`、`likePost`（评估帖子作者的 `LIKES_RECEIVED`）、`addComment` 后各加一次徽章判定调用。

```java
try { badgeAutomationService.evaluateUserBadges(user); }
catch (Exception ignored) { /* badge eval must not fail the main operation */ }
```

---

#### 22. 徽章判定抛异常导致 API 返回 500
**现象**：帖子/评论已保存成功，但 API 返回 500。  
**原因**：`evaluateUserBadges` 标注了 `@Transactional`；当帖子/评论的事务已提交后，徽章判定内部抛出异常，Spring 事务拦截器将异常向上传播，Controller 没有处理导致 500。  
**解决**：在所有调用 `evaluateUserBadges` 的 Controller 方法里用 `try-catch(Exception ignored)` 包裹，确保徽章判定失败不影响主流程。

---

#### 23. IndexedStack 缓存导致数据过时
**现象**：切换到通知 Tab 后，新徽章通知不出现，红点在登录后也不消失；排行榜徽章数需要手动下拉刷新。  
**原因**：`IndexedStack` 会保持所有 Tab 的 Widget 状态；`_loaded`/`_initialized` 布尔守卫让数据只加载一次，切回 Tab 时不会重新请求。  
**解决**：
1. 通知 Tab、Profile Tab 的 State 类改为 **public**，暴露 `reload()` 和 `reloadLeaderboard()` 方法。
2. `MainShell` 中用 `GlobalKey` 持有这两个 Tab 的 State 引用。
3. `onDestinationSelected` 切换到通知 Tab 时调用 `_notifKey.currentState?.reload()`；切换到 Profile Tab 时调用 `_profileKey.currentState?.reloadLeaderboard()`。
4. 排行榜用 `ValueKey("badges_$_leaderboardReloadKey")` 强制 Widget 在 key 变化时完全重建。

```dart
// main_shell.dart — Tab 切换时主动刷新
case 3: // 通知
  setState(() => _unreadCount = 0);
  _notifKey.currentState?.reload();
case 4: // 我的
  _profileKey.currentState?.reloadLeaderboard();
```

---

#### 24. GlobalKey 无法引用私有 State 类
**现象**：`GlobalKey<_ProfileTabState>` 编译报错，`_ProfileTabState` 在 `profile_tab.dart` 之外不可见。  
**解决**：将 `_ProfileTabState` → `ProfileTabState`（去掉下划线改为 public），`createState()` 同步更新，同样操作用于 `NotificationTabState`。  
**经验**：需要从外部持有 GlobalKey 并调用 State 方法的类，State 类必须是 public 的。

---

#### 25. `_LeaderboardView` 缺少 `super.key`
**现象**：改为 `const _LeaderboardView({required this.type})` 后，IDE 报 `The parameter 'key' is required`。  
**解决**：改为 `const _LeaderboardView({super.key, required this.type})`，const 构造函数必须通过 `super.key` 传递 key 参数。

---

#### 26. `_buildStatsStrip` 签名修改后调用处未同步
**现象**：修改了 `_buildStatsStrip(int count, Duration total)` 的签名（原为三参数），编译报参数数量不匹配。  
**解决**：搜索所有调用处，一并更新为新签名。改公共方法签名时需检查所有调用点。

---

#### 27. 字符串模板不必要的大括号（Linter 警告）
**现象**：`"${h}h ${m}分"` 报 linter 警告 `Unnecessary use of curly braces`。  
**原因**：`$h` 后跟字母 `h` 不会产生歧义（`h` 不是变量名的合法延续字符时，`$h` 安全），Flutter linter 建议去掉多余大括号。  
**规则**：只有当变量后紧跟字母/数字可能造成歧义时才需要 `${}`，否则用 `$variable` 即可。

---

#### 28. `BadgeCatalogInitializer` N+1 查询
**现象**：18 枚徽章初始化时，每枚徽章执行一次 `findByBadgeKey`，启动时发 18 条 SQL。  
**解决**：改为先 `findAll()` 拿到所有已存在的 key 集合，再 `filter` 出缺失的批量 save，从 N 条查询降到 1 条。

---

#### 29. 时长最小单位需精确到秒
**现象**：`formatDuration` 初版最小单位是 10 秒，用户明确要求最小单位 1 秒。  
**解决**：`Duration` 直接用 `d.inSeconds`，不做 10 秒舍入。分钟以下统一显示 `"${d.inSeconds}秒"`。

---

### 设计决策记录
- **`evaluateUserBadges` 包在 try-catch 里**：徽章是锦上添花，绝不能因为徽章判定失败让主操作（发帖/评论/记录）失败。与其在 Service 层处理所有异常，不如在调用处统一兜底。
- **State 类改 public vs 用 callback 传递**：callback 方案需要在 Widget 树中层层传递函数引用，GlobalKey 方案更直接；对于这类跨 Shell 的"刷新"操作，GlobalKey 是 Flutter 官方推荐方式。
- **排行榜用 ValueKey 强制重建**：排行榜是 StatefulWidget，setState 不会重新触发其 `initState`；改变 Key 后 Flutter 框架会销毁旧实例、创建新实例，从而触发重新加载。

---

## Phase 5 & 6 — 统计图表 + 教练认证（2026-04-13）

### 功能目标
- Phase 5：「进步」tab 新增统计图表页（攀岩频率 BarChart、难度分布横条、结果分类）
- Phase 6：教练认证申请/审核全流程、CoachChip 标识、Admin 后台 tab

---

### 遇到的问题与解决办法

#### 30. Spring Boot YAML 重复 key 导致启动失败
**现象**：启动时报 `SnakeYAML: found duplicate key spring`，应用无法启动。  
**原因**：`application.yml` 中存在两个顶级 `spring:` 块（新增 `servlet.multipart` 配置时未合并到原有 `spring:` 下）。  
**解决**：将 `servlet.multipart` 设置合并到唯一的 `spring:` 块中。  
**经验**：YAML 不允许同级重复 key，任何新增的 `spring.*` 配置必须写在同一个 `spring:` 块内。

---

#### 31. Multipart 上传字段名不匹配
**现象**：上传教练认证图片时后端报 `Required part 'image' is not present`。  
**原因**：Flutter 的 `http.MultipartRequest` 发送时字段名用的是 `"certificate"`，但后端 `@RequestParam("image")` 期望 `"image"`。  
**解决**：将 `request.files.add(... "certificate" ...)` 改为 `"image"`，与后端保持一致。  
**经验**：multipart 字段名是纯字符串约定，前后端必须完全一致，不会有编译期报错。

---

#### 32. H2 ENUM 列约束导致新增枚举值失败
**现象**：为 `UserRole` 新增 `ADMIN` 枚举值后，启动时报 `Value 'ADMIN' is not in the list of allowed values` 或约束违反异常。  
**原因**：H2 存储 ENUM 列时会记录允许值列表，`ddl-auto: update` 只能新增列/表，**无法修改已有列的约束**（如扩展 ENUM 可选值）。  
**解决**：删除本地 H2 数据库文件（`~/.betaup-dev/betaup.mv.db` 和 `.trace.db`），让 Hibernate 从零重建 schema。  
**经验**：H2 开发库改 ENUM 枚举值 → 直接删库重建；生产环境需写 migration SQL 手动 ALTER 列。

---

#### 33. `getPendingApplications()` 触发 LazyInitializationException
**现象**：Admin 拉取待审核列表时后端报 `LazyInitializationException: could not initialize proxy`。  
**原因**：`CoachCertification.user` 是 LAZY 关联，`getPendingApplications()` 方法没有加 `@Transactional`，在方法返回后 JPA Session 已关闭，stream 映射到 `cert.getUser()` 时无法再懒加载。  
**配置背景**：`application.yml` 设置了 `open-in-view: false`，Session 严格在 Service 层关闭。  
**解决**：在 `getPendingApplications()` 和 `getStatus()` 上加 `@Transactional(readOnly = true)`，保证方法执行期间 Session 不关闭。

---

#### 34. Admin Tab 静默吞掉异常导致显示空列表
**现象**：Admin 看到"暂无待审核申请"，实际上后端已有数据，问题是请求失败（403/500）被忽略了。  
**原因**：原 catch 块写的是 `catch (_) {}`，任何错误都被丢弃，UI 直接展示空列表状态。  
**解决**：改为将错误存入 `_error` 状态，在 UI 中显示红色错误信息 + 重试按钮，便于排查问题。  
**经验**：`catch (_) {}` 在调试阶段极其危险，至少应 `if (mounted) setState(() => _error = e.toString())`。

---

#### 35. 认证图片 URL 缺少 host 无法加载
**现象**：Admin 审核页中教练认证图片显示为破碎图标（broken image）。  
**原因**：后端返回相对路径 `/uploads/certificates/xxx.png`，`Image.network()` 需要完整 URL，而 `ApiClient.baseUrl` 是 `http://host/api`，直接拼接会变成 `http://host/api/uploads/...`（错误路径）。  
**解决**：在 `AdminTabState.didChangeDependencies()` 中，将 `baseUrl` 的 `/api` 后缀去掉得到 `serverRoot`（`http://host`），再与图片相对路径拼接为完整 URL。

```dart
final base = SessionScope.of(context).api.baseUrl;
_serverRoot = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
// 使用：serverRoot + review.certificateImageUrl
```

---

#### 36. 认证通过后 Session 未刷新，教练标识不出现
**现象**：Admin 通过认证后，用户热重启 App，个人页仍无"教练"标识，认证申请区块也还在显示。  
**原因（一）**：`UserProfile.fromJson` 中读取键名为 `"isCoachCertified"`，但 Java 中 `boolean isXxx` 字段经 Lombok/Jackson 处理后序列化 JSON key 会**去掉 `is` 前缀**，实际 key 是 `"coachCertified"`。读到 `null`，`isCoachCertified` 恒为 `false`。  
**解决（一）**：改为同时接受两个 key：

```dart
isCoachCertified: json["coachCertified"] == true || json["isCoachCertified"] == true,
```

**原因（二）**：`_CertificationSection._load()` 拿到 API 返回 `isCoachCertified: true` 后，未通知 Session 刷新，父级 `ProfileTab` 持有的 `user` 对象仍是旧数据，导致 AppBar 和 `_CertificationSection` 的判断仍基于旧值。  
**解决（二）**：在 `_load()` 中检测到服务端认证状态与本地 Session 不一致时，主动调用 `session.refreshUser()`，触发 `notifyListeners()` 驱动全局重建。

```dart
if (s.isCoachCertified && !widget.user.isCoachCertified) {
  await session.refreshUser();
}
```

**经验**：Java `boolean isXxx` → JSON key 是 `"xxx"`（去 is）；Flutter 端要用 `"xxx"` 而非 `"isXxx"`。

---

### 设计决策记录
- **Admin 账号通过 `AdminAccountInitializer` 种子化**：实现 `ApplicationRunner`，加 `@Order(1)` 确保最先执行，用 `existsByEmailIgnoreCase` 保证幂等，不会重复插入。
- **CoachChip 抽成独立 Widget**：教练标识在社区帖子、评论、排行榜、个人资料页、他人主页多处复用，统一封装为 `CoachChip`，样式改动只需修改一处。
- **StatsTab 统计图表**：频率图用 `fl_chart` `BarChart`（渐变填充）；难度分布用 `Stack + FractionallySizedBox` 实现横向进度条，不依赖额外图表库，更轻量。
- **`_CertificationSection` 隐藏逻辑**：先检查 `widget.user.isCoachCertified`（本地即时判断），再检查 `_status?.isCoachCertified`（API 数据），两者任一为 true 即隐藏，避免用户看到"一闪而过"的申请入口。
