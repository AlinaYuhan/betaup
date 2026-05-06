# BetaUp — Poster Q&A 备考文档
> Poster Presentation 问答准备 · 中英双语 · 口语版

---

## 📋 海报内容速览（先快速了解海报结构）

| 区域 | 内容要点 |
|------|---------|
| **Introduction / Motivation** | 攀岩者找馆难、记录麻烦、缺社交工具 → 做一个整合平台 |
| **Persona** | Primary: Alex（普通攀岩者，想追踪进步） / Secondary: Coach Li（教练，想远程看学生数据） |
| **Aims** | 6个目标：找馆、记录、社交、徽章激励、教练互动、整合进一个app |
| **Design & Concept** | Voice-first设计、gamification、explore地图、双用户旅程图 |
| **System Decision (HCI)** | 比较了3个方案：手动表单 / Apple Watch / AI语音助手 → 选了语音助手 |
| **Iterations** | Iteration 1: 草图 → Iteration 2: 低保真Figma → Iteration 3: 高保真 |
| **How the System Works** | Flutter前端 → Spring Boot API → JWT认证 → H2数据库 + DeepSeek AI |
| **Early Evaluation** | 问卷数据：81%用户倾向location-based badge；柱状图显示训练记录和进步追踪是最高需求 |
| **References & AI** | 引用4篇学术论文 + 使用Claude Code和DeepSeek做AI辅助开发 |

---

## 🔑 重点词汇表（提前记住这些词）

| 中文 | English |
|------|---------|
| 攀岩 | rock climbing / bouldering |
| 训练记录 | session logging / training log |
| 进步追踪 | progress tracking |
| 语音助手 | voice assistant |
| 徽章系统 | badge system |
| 排行榜 | leaderboard |
| 游戏化 | gamification |
| 低门槛 | low friction / easy to use |
| 原型 | prototype |
| 低保真 | low-fidelity (lo-fi) |
| 高保真 | high-fidelity (hi-fi) |
| 用户旅程图 | user journey map |
| 用户画像 | persona |
| 问卷 | questionnaire / survey |
| 访谈 | interview |
| 可用性测试 | usability testing |
| 出声思考 | think-aloud |
| 迭代 | iteration |
| 认证 / 验证 | verification / certification |
| 教练 | coach |
| 打卡 | check-in |
| 心率 | heart rate |
| 穿戴设备 | wearable device |
| 推送通知 | push notification |
| 后端 | backend |
| 前端 | frontend |
| 数据库 | database |

---

## Q1 — Can you introduce your project in 1 minute?

**关键词提纲：** climbers · fragmented tools · one platform · voice logging · badges · social · map · coach

**EN（口语版）：**
> "Our project is BetaUp — a climbing app that brings everything together in one place.
>
> We noticed that climbers usually juggle multiple apps: one for finding gyms, one for logging sessions, one for chatting. It's messy and most people stop recording after a while because it's too much effort.
>
> So we built BetaUp. The main features are: finding nearby gyms on a map, logging climbs with a voice assistant, earning badges based on your progress, posting in a community, and a coach verification system.
>
> Tech-wise: Flutter for the frontend, Spring Boot for the backend, and DeepSeek AI for the voice assistant. The goal was to make climbing more fun to track and easier to stick with long-term."

**中文：** 就按上面说，BetaUp是整合了找馆、记录、社交、徽章、教练的攀岩平台。发现攀岩者用太多个app，记录门槛高所以经常断掉。我们用语音助手降低记录门槛，用徽章和排行榜增加趣味性。

---

## Q2 — What is the most important user requirement?

**关键词提纲：** low-friction logging · questionnaire · tired after session · data continuity · foundation for everything else

**EN（口语版）：**
> "The most important requirement is easy session logging with visible progress.
>
> Our survey showed that users do want to track progress, but the biggest problem is that logging feels like a chore after a tiring session. So they skip it. And once the data is gone, everything else — badges, stats, coaching — loses its point.
>
> That's why we focused first on making logging as easy as possible. That's the foundation."

**中文：** 最重要需求是低门槛记录训练数据。问卷显示大家想追踪进步，但手动输入太麻烦，累了就不记了。没有数据，徽章、统计、教练功能都没有基础。

---

## Q3 — How did you design and prototype for this?

**关键词提纲：** Crazy Eights → lo-fi Figma → voice-first with form fallback → Panda assistant → more visible

**EN（口语版）：**
> "We started with Crazy Eights sketches to explore different ideas — pure forms, step-by-step input, voice-first. Then we made a lo-fi Figma prototype to connect the main flow: open app → start session → log by voice → see badges.
>
> We compared the options and chose voice-first with a form as backup. Voice is faster mid-session, and the form is there if you need to correct something.
>
> Then we turned the voice entry into the Panda assistant character to make it more obvious and fun to use."

**中文：** Crazy Eights探索多个方案 → Figma低保真串联核心流程 → 选了语音优先+表单兜底 → 把语音入口做成熊猫助手，让用户更容易发现。

---

## Q4 — Have you evaluated your prototype with users?

**关键词提纲：** two rounds · lo-fi click test · think-aloud · voice entry not visible · badge feedback weak · iterated

**EN（口语版）：**
> "Yes, two rounds. First with the lo-fi Figma prototype, we checked if users understood the main flow — especially logging and seeing feedback.
>
> Then after the Alpha build, we did think-aloud sessions. Users tried: signing up, logging a climb, viewing badges, posting in the community, and using the voice assistant.
>
> We found two main issues: users didn't immediately notice the voice button, and badge feedback wasn't strong enough visually. So we made the voice assistant more visible and improved badge animations."

**中文：** 两轮评估。第一轮Figma低保真点击测试，第二轮Alpha版think-aloud。发现语音入口不明显、徽章反馈视觉太弱。对应迭代了语音助手入口和徽章动效。

---

## Q5 — Can you describe your vibe coding process?

**关键词提纲：** not copy-paste · define first · AI scaffold · human review · test edge cases · prototype → reliable system

**EN（口语版）：**
> "Vibe coding for us wasn't just copy-pasting AI output. It was more like: we define the feature clearly first — inputs, outputs, edge cases — then use AI to generate the scaffold, then we review it, fix issues, and test.
>
> For the backend, we tested every endpoint manually. For the frontend, we used Flutter hot reload to check everything. Complex things like the voice assistant were tested for edge cases — network failure, empty voice input, wrong commands.
>
> So AI helped us move fast, but we always verified before shipping."

**中文：** 不是直接复制AI代码。流程是：先定义清楚功能（输入输出边界） → AI生成脚手架 → 人工检查修正 → 测试异常场景。AI帮我们快速出原型，但每个接口和页面都自己验证过。

---

## Q6 — Why did you choose Flutter and Spring Boot? *(常问)*

**关键词提纲：** cross-platform · single codebase · web + mobile · Spring Boot mature · JWT · team familiarity

**EN：**
> "We chose Flutter because it runs on both web and mobile from one codebase. That was important for us — we wanted to demo on Chrome but also be ready to deploy to phones later.
>
> Spring Boot was the natural backend choice for us because the team had experience with Java, and it handles REST APIs, JWT authentication, and database connections cleanly out of the box."

**中文：** Flutter一套代码跑web和手机，演示方便也方便后续部署。Spring Boot团队熟悉Java，处理REST API和JWT认证很顺手。

---

## Q7 — How is BetaUp different from existing apps like 27crags or Strava? *(常问)*

**关键词提纲：** 27crags = database only, no social · Strava = no climbing grades · we combine all + voice + gamification

**EN：**
> "27crags has a big route database but no gamification or real social layer. Strava is great for social but has no climbing-specific grading or indoor support. Crimpd does training plans but no community.
>
> BetaUp combines all of that — and adds things none of them have: a voice assistant for hands-free logging, a gym check-in leaderboard, and coach certification."

**中文：** 27crags只有数据库没有社交；Strava没有攀岩分级；Crimpd只有训练计划没有社区。BetaUp整合了以上所有，还加了语音助手、打卡排行榜、教练认证——这些是现有app没有的。

---

## Q8 — What challenges did you face? *(常问)*

**关键词提纲：** voice accuracy · Lombok field naming · Chip layout bug · merge conflict · balancing features

**EN：**
> "A few technical ones. The voice assistant was tricky — we had to engineer the system prompt carefully so it could parse natural language into structured actions like 'log a V4 flash'.
>
> We also hit a Lombok naming issue where a boolean field 'isBeta' generated a setter called 'setBeta' — so our form binding was broken until we found that.
>
> On the design side, balancing how many features to include without making the app feel overwhelming was the main challenge."

**中文：** 技术挑战：语音助手的系统提示词需要反复调整才能准确解析自然语言；遇到Lombok boolean字段命名bug；Flutter web的Chip组件首次渲染有布局问题。设计上，功能很多，如何不让用户觉得太复杂是主要挑战。

---

## Q9 — What would you improve if you had more time? *(常问)*

**关键词提纲：** real Apple Watch integration · AI coach feedback · offline mode · iOS deployment

**EN：**
> "A few things. First, the Apple Watch heart rate is in demo mode right now — with more time we'd implement the real BLE connection on a physical device.
>
> Second, we'd want the AI to give personalised coaching feedback based on your training history, not just log commands.
>
> And we'd want to deploy it properly to iOS and Android, not just web."

**中文：** 1. 心率现在是模拟，想实现真实手表BLE连接；2. AI助手目前只能执行指令，希望能根据历史数据给出个性化训练建议；3. 正式部署到iOS和Android真机。

---

## Q10 — How does the badge system work exactly? *(可能问)*

**关键词提纲：** milestone triggers · streak · grade · check-in count · social activity · leaderboard ranking

**EN：**
> "Badges are triggered by specific milestones. For example: first send, 10 sessions completed, first V5, a 7-day streak, or checking in at 5 different gyms. When you hit a milestone, you get a badge unlock animation and a notification.
>
> Your badge count and gym check-in count together determine your rank on the leaderboard. The idea is to reward both climbing skill and how active you are in the community."

**中文：** 徽章由特定里程碑触发，比如第一次完成线路、连续打卡7天、首次完成V5、打卡5个不同岩馆等。徽章数量和打卡数决定排行榜排名，同时奖励技术进步和社区活跃度。

---

## Q11 — How did you handle the voice assistant technically? *(可能问)*

**关键词提纲：** Web Speech API → STT transcript → DeepSeek API → structured JSON action → Flutter executes

**EN：**
> "We used the Web Speech API for speech-to-text — that converts what the user says into a text transcript. Then we send that transcript to the DeepSeek API with a custom system prompt. DeepSeek returns a structured JSON action — like 'log a V4 flash' or 'start session'. Then Flutter reads that JSON and executes the action in the app.
>
> We tested it with edge cases like empty transcripts, ambiguous commands, and network failures."

**中文：** Web Speech API做语音转文字 → 发给DeepSeek API加上系统提示词 → DeepSeek返回结构化JSON指令 → Flutter解析并执行。测试了空语音、模糊指令、网络失败等边界情况。

---

## Q12 — What did your research / survey find? *(可能问)*

**关键词提纲：** 81% prefer location-based badges · training log = highest demand · progress tracking · community interaction

**EN：**
> "Our questionnaire showed that training log and progress tracking were the top user needs. In terms of gamification, 81% of users preferred location-based badge rewards — meaning badges tied to visiting specific gyms. That directly influenced our gym check-in leaderboard design.
>
> We also found that users wanted community interaction, but only as a secondary feature — the primary need was always reliable, easy logging."

**中文：** 问卷显示训练记录和进步追踪是最高需求；81%用户倾向基于位置的徽章奖励（去岩馆打卡得徽章），这直接影响了我们打卡排行榜的设计。社区互动是次要需求，首要还是可靠好用的记录功能。

---

## Q13 — Who is your target user? *(可能问)*

**关键词提纲：** recreational gym climbers · 18–35 · competitive mindset · coaches as secondary

**EN：**
> "Primary users are recreational gym climbers, roughly 18 to 35 years old, who climb regularly and want to see their own progress. They're competitive enough to care about grades and streaks, but not professional athletes.
>
> Secondary users are coaches who want to monitor student progress and give feedback without chasing people on WeChat."

**中文：** 主要用户是18-35岁的健身房攀岩者，定期攀岩、想追踪进步。次要用户是教练，想远程查看学生数据、提供反馈，而不是每次都微信追问。

---

## ⚡ 应急万能句（如果问题答不上来）

| 情况 | 说法 |
|------|------|
| 数据记不住 | "I'd need to check the exact number, but the general finding was..." |
| 技术细节不确定 | "That part was mainly handled by our lead developer, but the overall idea is..." |
| 问题没理解 | "Could you rephrase that? I want to make sure I answer the right thing." |
| 给时间想一下 | "That's a good question — let me think for a second." |
