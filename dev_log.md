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
