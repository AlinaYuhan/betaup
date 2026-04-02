# BetaUp

BetaUp 是一个面向攀岩者（Climber）和教练（Coach）的全栈 Web 应用。

当前项目采用：

- 后端：Java 21、Spring Boot 3、Spring Security、Spring Data JPA、MySQL、JWT、Maven
- 前端：React、Vite、React Router、Axios、Tailwind CSS

## 当前已实现功能

### 1. 用户认证与安全

- 用户注册
- 用户登录
- 基于 JWT 的接口鉴权
- 获取当前登录用户信息
- 基于角色的页面与接口访问控制
  - `CLIMBER`
  - `COACH`

### 2. Climber 功能

- 创建 climb log
- 查看自己的 climb log 列表
- 查看单条 climb log
- 编辑 climb log
- 删除未被 feedback 关联的 climb log
- climb log 列表支持：
  - 分页
  - 排序

### 3. Coach 功能

- 查看 climber roster
- 按姓名或邮箱搜索 climber
- 查看单个 climber 详情
- 查看 climber 的 recent climbs 和 feedback 历史
- 创建 feedback
- 编辑自己创建的 feedback
- 删除自己创建的 feedback
- feedback 列表支持：
  - 按 climber 筛选
  - 按 rating 筛选
  - 分页
  - 排序
- climber roster 支持：
  - 分页
  - 排序

### 4. Badge 系统

- 系统启动时自动补充默认 badge 规则
- 根据用户行为自动授予 badge
  - 总日志数
  - 完成攀爬数
  - 收到 feedback 数
- 查看我的 badge
- 查看 badge progress
- Coach 可管理 badge 规则
  - 创建规则
  - 编辑规则
  - 删除规则
- badge 规则变更后会自动重新同步 climber badge 状态

### 5. Dashboard

- Climber dashboard
  - metrics
  - breakdown
  - recent activity
  - chart 数据
- Coach dashboard
  - metrics
  - roster breakdown
  - recent coaching activity
  - chart 数据
- dashboard 支持时间范围筛选
  - `LAST_30_DAYS`
  - `LAST_90_DAYS`
  - `LAST_180_DAYS`
  - `ALL_TIME`
- dashboard 支持导出 CSV

### 6. 前端页面与交互

- 登录页
- 注册页
- Climber 页面
  - Dashboard
  - Climb Logs
  - New Log
  - Badges
  - Feedback
- Coach 页面
  - Dashboard
  - Climbers
  - Climber Detail
  - Feedback
  - New Feedback
  - Badge Rules
- 所有核心页面已完成基础 UI、导航和后端联调

### 7. 后端基础能力

- 统一响应结构 `ApiResponse`
- 全局异常处理
- JPA 实体与关系建模
- MySQL 持久化
- 通用分页返回 `PageResponse`
- 分页与排序参数统一抽象

## 当前项目状态

目前 BetaUp 已经不是纯脚手架，已经具备可以本地运行和演示的 MVP 主链路：

- 注册 / 登录
- Climber 记录训练
- Coach 写反馈
- Badge 自动计算
- Dashboard 展示与导出

## 暂未完成

以下内容还没有做完，或者只做了基础版本：

- 更细粒度的权限模型（例如 Admin）
- 更完整的 badge 规则治理
- 更复杂的 dashboard 统计分析
- 更完整的 CRUD 覆盖和批量操作
- 集成测试与更系统的自动化测试
- seed data / 初始化演示数据
- 生产环境部署配置
