# BetaUp Demo 本地运行指南

> 给录制视频的同学：按照以下步骤在自己电脑上运行 demo 页面。

---

## 你需要准备

- **Python 3**（验证：终端输入 `python --version`，显示 3.x 即可）
- **Git**（已 clone 过仓库就不用再装）
- **Chrome 浏览器**
- **Spring Boot 后端**（需要有人开着，否则 App 打开是白屏登录页）

---

## 第一步：拉取最新代码

```bash
git pull origin main
```

如果还没 clone：

```bash
git clone https://github.com/AlinaYuhan/betaup.git
cd betaup
```

---

## 第二步：启动后端

> **谁的电脑上有后端环境（Java + Maven），由他/她来启动。其他人连同一个 WiFi 就能用。**

有后端环境的人，在 `betaup/backend/` 目录下运行：

```bash
./mvnw spring-boot:run
```

或者用 IntelliJ IDEA 直接点运行按钮。

后端默认跑在 `http://localhost:8080`。

> 如果你们没有人运行后端，App 只会显示白屏登录页，无法正常演示。
> 建议让 Alina 那边开着后端，其他人连同一个网络。

---

## 第三步：启动 Demo 服务器

在 `betaup/` 根目录下运行：

```bash
python serve.py
```

终端会显示：

```
  BetaUp demo server → http://localhost:8000/demo.html
  Portfolio          → http://localhost:8000/index.html
  Press Ctrl+C to stop.
```

> **为什么不能直接双击 HTML 打开？**
> Flutter 的渲染引擎（CanvasKit）需要特定的 HTTP 响应头，直接用文件路径或
> VS Code Live Server 打开会白屏。serve.py 自动加了这些头。

---

## 第四步：打开 Chrome

访问：

```
http://localhost:8000/demo.html
```

页面左侧会显示自动切换的场景文字，右侧是可以点击操作的完整 App。

---

## 控制方式

| 操作 | 效果 |
|------|------|
| `Space` 或 `→` | 切到下一个场景 |
| `←` | 回到上一个场景 |
| `P` | 暂停 / 恢复自动切换 |
| 点底部小圆点 | 直接跳转到任意场景 |
| `⏸ Pause` 按钮 | 暂停，文字停留当前 |

---

## 录制建议

1. Chrome 全屏（F11），OBS 或系统录屏录全屏
2. 先点 `⏸ Pause` 暂停自动切换，自己手动控制节奏
3. 右侧 App 可以正常点击登录、操作
4. 测试账号联系 Alina 获取（需要后端上有数据）

---

## 常见问题

**Q: 右侧 App 白屏**
- 确认 serve.py 在运行
- 确认访问的是 `localhost:8000`，不是 `file://` 或其他端口
- 确认后端在运行（`localhost:8080`）

**Q: serve.py 报 `Address already in use`**
- 端口 8000 被占用，改 serve.py 最后一行的 `port = 8000` 为 `8001`，然后访问 `localhost:8001`

**Q: `python` 命令找不到**
- 试试 `python3 serve.py`

**Q: App 能加载但登录失败**
- 后端没有运行，或者后端 IP/端口 配置不对
