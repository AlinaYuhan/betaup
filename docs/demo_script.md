# BetaUp — Demo Script
> 中英双语演讲稿 · 口语版 · 约 5–6 分钟

---

## ① 开场 Opening
**【操作】打开软件，停在登录页面**

**EN:**
> "Hi everyone. Our project is called BetaUp — an app for rock climbers.
>
> In climbing, *beta* means tips or information that help you finish a route. So BetaUp means — level up your climbing. The logo is the Greek letter Beta, but shaped like a climber. That's where the name comes from.
>
> Right now, most climbers use three or four different apps — one to find gyms, one to log climbs, one to chat with friends. We built one app that does all of that."

**中文提示：** 开场30秒，说完就登录，不要停太久。

---

## ② 登录页 Login Screen
**【操作】指一下UI，然后登录攀岩者账号**

**EN:**
> "Before I log in — quick look at the design. Dark theme, bold font. We wanted it to feel like the sport — strong and clean.
>
> I'll log in with our climber account now."

**中文提示：** 一句话带过UI就行，快速登录。

---

## ③ Tab 1 — Explore 探索页
**【操作】登录后进入Explore，展示地图**

**EN:**
> "First tab — Explore. We used the Amap API to show climbing gyms all over China. Each pin on the map is a real gym, with phone number, address, opening hours, and how to buy tickets — all in one place. Normal map apps don't filter for climbing gyms. We do.
>
> Let me tap Locate Me."

**【操作】点击 Locate Me**

> "The list below now sorts by distance — closest first. We can see XJTLU's campus climbing wall right at the top. Let me tap it."

**【操作】点开西郊利物浦攀岩馆详情**

> "Now — one of our fun features. If you're within 2 kilometres of a gym, you can do a GPS check-in. Every check-in gives you points and shows up on the leaderboard. Think of it like the badge system in Keep, or how ski pass apps track which mountains you've been to. The idea is — the more you climb, the more you earn. It makes people want to go to new gyms and climb more."

**中文提示：** 类比Keep跑步徽章或者滑雪打卡，老师会更有画面感。

---

## ④ Tab 2 — Training Record 训练记录
**【操作】切到第二个tab，开始一个训练**

**EN:**
> "Second tab — Training. Let me start a session.
>
> We have three types of climbs you can log:
> - **Flash** — you finished it on your very first try
> - **Send** — you finished it after a few tries
> - **Attempt** — you tried hard but didn't top it this time
>
> You add the route name, grade, date, and gym. Date and gym are already filled in automatically. After your session, you can see all your past climbs here, and check the Progress tab for charts — things like how often you climb and what grades you're doing."

**【操作】添加几条记录，展示历史和进步页面**

> "One more thing here — a hardware feature. BetaUp can connect to an Apple Watch and track your heart rate in real time while you climb. Since we're on web today, I'll show the simulation mode. When the app runs on a phone, it's a live connection to the watch."

**【操作】展示心率连接/模拟界面**

**中文提示：** 心率这个快速展示就好，不用深入解释，说"we built this"就行。

---

## ⑤ Tab 3 — Community 社区
**【操作】切到第三个tab**

**EN:**
> "Third tab — Community. You can post text, photos, or videos. When you make a post, you pick a type:
> - A normal update
> - **Find a Climbing Partner** — if you want someone to climb with
> - Or a **Beta Post** — where you share how to do a specific route, to help other people
>
> Other users can like, comment, and follow you. You'll also see a coach badge next to verified coaches — I'll show that part soon."

**【操作】展示发帖界面，指出Beta和找搭子两个标签**

**中文提示：** Beta post和找搭子是区别于普通社交的功能，稍微停一下让老师看清楚这两个标签。

---

## ⑥ Tab 4 — Notifications 通知
**【操作】切到第四个tab**

**EN:**
> "Fourth tab — Notifications. When you unlock a badge, get a new follower, or someone likes your post — it shows up here. You can also tap a follower notification and follow them back directly."

**中文提示：** 快速带过，30秒内说完。

---

## ⑦ Tab 5 — Profile + Badges + Leaderboard
**【操作】切到第五个tab**

**EN:**
> "Fifth tab — Profile. You can see your followers, who you follow, and edit your name.
>
> The main highlight here is the **Badge Wall** and **Leaderboard**. You earn badges based on:
> - How many climbs you've done, and what grades
> - How many different gyms you've checked in to
> - How active you are in the community
>
> Everyone is ranked on the leaderboard by badge count and check-ins. This is the core of our gamification — we want every session to feel like you're making progress, not just going to the gym."

**【操作】展示徽章墙和排行榜**

**中文提示：** 停一下，让老师看徽章的视觉效果，这是亮点。

---

## ⑧ 语音助手 Panda 🐼（最大亮点）
**【操作】点开右下角熊猫按钮**

**EN:**
> "Now — our biggest feature. This is **Panda**, our AI voice assistant for climbers. It uses the DeepSeek API and Web Speech recognition, and it works in both Chinese and English.
>
> Let me try in Chinese first."

**【操作】对麦克风说（中文）：**
> *"帮我推荐附近的攀岩馆"*

> "Panda says the XJTLU gym is nearby — great, let's go there.
>
> Now in English:"

**【操作】说：**
> *"Start a climbing session."*

> "Session started. Now let me log a climb:"

**【操作】说：**
> *"Log a V4 flash."*

> "Done. Panda logged it — no tapping at all. This is really useful when you're mid-climb and your hands are full of chalk. You just talk to it.
>
> Let me go to the Training tab to confirm it's there."

**【操作】切到训练记录，展示刚刚语音添加的V4**

> "There it is. Logged by voice."

**中文提示：** 这段节奏放慢，让老师看清楚"说一句话→记录出现"这个过程。这是我们技术含量最高的部分，要给足时间。

---

## ⑨ 教练认证 + 管理员后台
**【操作】在Profile页找到申请教练认证的入口，展示一下**

**EN:**
> "BetaUp has two user types — regular climbers and coaches. Any user can apply to be a verified coach by uploading their certificate and a short bio.
>
> Let me switch to our Admin account to show how that works."

**【操作】登出，登录管理员账号**

> "The admin has an extra panel — all the coach applications are listed here. I can read the bio, check the certificate, and approve or reject."

**【操作】展示一个申请，点击批准或拒绝**

> "Once approved, the user gets a notification, and the coach badge shows up next to their name in the community. So when you're reading posts, you know who's a real coach."

**中文提示：** 快速展示审批动作就好，说完就结束这段。

---

## ⑩ 新账户 — 徽章弹窗效果（可选，时间够再做）
**【操作】注册一个新账户，完成第一次登录或添加第一条攀岩记录**

**EN:**
> "One last thing — when a new user logs their first climb, they get a badge unlock right away."

**【操作】展示徽章弹窗动画**

> "Small detail, but it makes the first session feel good immediately."

**中文提示：** 如果时间紧就跳过这步。

---

## ⑪ 结尾 Closing
**【操作】面向老师**

**EN:**
> "So that's BetaUp. It's a climbing app that puts everything in one place — finding gyms, logging climbs, social community, badges and leaderboards, heart rate from your watch, coach verification, and a voice assistant.
>
> Our goal was to make climbing feel more fun and more connected. Thank you."

---

## ⏱ 时间参考

| 段落 | 时长 |
|------|------|
| 开场 + 登录 | ~40s |
| Explore + GPS打卡 | ~60s |
| 训练记录 + 心率 | ~60s |
| 社区 | ~30s |
| 通知 + Profile + 徽章 | ~45s |
| **语音助手 Panda** | **~75s（核心，不要压缩）** |
| 教练 + Admin | ~45s |
| 结尾 | ~20s |
| **合计** | **~约6分钟** |

> 如果只有4分钟：跳过心率模拟和新账户注册，语音助手保留完整演示。

---

## 💡 亮点一句话总结备忘

| 亮点 | 说法 |
|------|------|
| GPS打卡排行榜 | "like a badge system for gyms — the more you visit, the higher you rank" |
| 语音助手 Panda | "just talk to it, hands-free, works in Chinese and English" |
| 心率穿戴互联 | "connects to Apple Watch to track heart rate while you climb" |
| 教练认证 | "verified coach badge — so you know who's a real coach in the community" |
| Beta / 找搭子标签 | "post types for sharing route tips or finding a climbing partner" |
| 徽章系统 | "like Keep's running badges, but for climbing" |
