# 实现任务清单

## 概述

本任务清单基于 `requirements.md` 和 `design.md`，将 RaccoonCal 游戏化功能拆分为可执行的实现任务。任务分为两大部分：**服务端**（Express.js + Prisma + MySQL + Redis）和 **iOS App**（Swift + SwiftUI）。

> **注意**：所有涉及 3D 模型、骨骼动画、游戏引擎的任务标记为 `[DEFERRED]`，暂不实现。浣熊展示统一使用现有静态图片资源（Assets.xcassets 中已有的 PNG），心情切换通过切换图片实现，不依赖动画引擎。

---

## 第一部分：服务端任务

### 任务 1：数据库 Schema 扩展与迁移

- [x] 1.1 在 `schema.prisma` 中新增 `UserProfile` 模型（身高/体重/目标/活动水平/每日卡路里目标）
- [x] 1.2 新增 `WeightRecord` 模型（体重历史）
- [x] 1.3 新增 `FoodRecord` 模型（饮食记录，含餐次/营养素/图片URL）
- [x] 1.4 新增 `GamificationStatus` 模型（XP/等级/HP/Streak/保护盾）
- [x] 1.5 新增 `XpTransaction` 模型（XP 流水，含幂等唯一约束）
- [x] 1.6 新增 `Pet` 模型（浣熊宠物，含装扮槽位）和 `PetLevelHistory` 模型
- `[DEFERRED]` 升级解锁新外观/3D 装扮道具（等待美术资源）
- [x] 1.7 新增 `DailyTask` 模型（每日任务，含唯一约束 userId+taskKey+taskDate）
- [x] 1.8 新增 `AchievementDef` 模型（成就定义）和 `UserAchievement` 模型
- [x] 1.9 新增 `League` 模型和 `LeagueMember` 模型
- [x] 1.10 在 `User` 模型中添加所有新模型的关联关系
- [x] 1.11 执行 `prisma migrate dev` 生成迁移文件
- [x] 1.12 编写 `seed.ts`，写入 20+ 条成就定义数据和任务池数据

**属性测试**：Property 21（任务池不重复性）、Property 22（成就幂等性）

---

### 任务 2：游戏化引擎核心工具函数

- [x] 2.1 创建 `src/utils/gamificationEngine.ts`
- [x] 2.2 实现 `calcLevel(totalXp: number): number`（等级公式 100×N²，上限 50 级）
- [x] 2.3 实现 `xpToNextLevel(totalXp: number): number`
- [x] 2.4 实现 `awardXp(userId, reason, refId, amount)`（含 Redis 去重 + DB 唯一约束幂等）
- [x] 2.5 实现 `checkAndDeductHp(userId, date)`（超出目标 10% 时扣减 HP，下限 0）
- [x] 2.6 实现 `calcPetMood(params)`（6 种心情状态确定性计算）
- [x] 2.7 实现 `calcSatietyDelta(recordCalories, dailyTarget)`（饱食度增量，上限 100）
- [x] 2.8 创建 `src/utils/calorieCalculator.ts`，实现 Harris-Benedict 公式计算每日卡路里目标

**属性测试**：
- Property 13（等级公式正确性）：`fc.integer({ min: 0, max: 250000 })` 验证等级区间
- Property 18（XP 幂等性）：同一 reason+refId 重复调用 totalXp 不变
- Property 19（HP 扣减阈值）：超出 10% 才扣，下限 0
- Property 12（心情确定性）：相同输入返回相同心情
- Property 15（饱食度增量）：`min(calories/target*100, 100)`
- Property 27（卡路里目标重算）：相同输入始终相同输出

---

### 任务 3：食物识别与记录 API

- [x] 3.1 创建 `src/services/logmeal.service.ts`，封装 LogMeal API(令牌：c2c524a7ed34ad36fd4dd124eebda1f4d74321d8) 调用
- [x] 3.2 实现图片预处理（Sharp 压缩至 800px 宽，质量 80%）
- [x] 3.3 实现识别失败处理（置信度 < 0.3 或空结果返回 `{ foods: [], confidence: 0 }`）
- [x] 3.4 创建 `src/services/food.service.ts`，实现饮食记录 CRUD
- [x] 3.5 实现 `getDailyCalSummary(userId, date)` 按餐次分组汇总
- [x] 3.6 实现 `getNutritionStats(userId, days)` 获取 N 天营养统计
- [x] 3.7 创建 `src/controllers/food.controller.ts` 和 `src/routes/food.routes.ts`
- [x] 3.8 注册路由：`POST /api/food/recognize`、`POST /api/food/records`、`GET /api/food/records`、`DELETE /api/food/records/:id`、`GET /api/food/stats`
- [x] 3.9 在 `app.ts` 中挂载 food 路由
- [x] 3.10 保存饮食记录后触发：XP 授予（+10）、HP 检查、浣熊饱食度更新、打卡标记写入 Redis

**属性测试**：
- Property 6（识别失败返回空列表）：模拟低置信度响应
- Property 7（保存记录后 XP +10，幂等）
- Property 8（多食物识别结果数量一致性）
- Property 4（餐次分组求和正确性）
- Property 10（删除记录后卡路里重算）

---

### 任务 4：游戏化状态 API

- [x] 4.1 创建 `src/services/gamification.service.ts`
- [x] 4.2 实现 `getGamificationStatus(userId)`（含 Redis 缓存，TTL 5 分钟）
- [x] 4.3 实现 `getXpHistory(userId)`
- [x] 4.4 创建 `src/controllers/gamification.controller.ts` 和路由
- [x] 4.5 注册路由：`GET /api/gamification/status`、`GET /api/gamification/history`
- [x] 4.6 在 `app.ts` 中挂载 gamification 路由

---

### 任务 5：浣熊宠物 API

- [x] 5.1 创建 `src/services/pet.service.ts`
- [x] 5.2 实现 `getPetStatus(userId)`（含心情计算，Redis 缓存 10 分钟）
- [x] 5.3 实现 `interactWithPet(userId)`（+XP，幂等：每日一次）
- [x] 5.4 实现 `updatePetOutfit(userId, outfit)`（保存装扮槽位数据）
- [x] 5.5 实现 `getUnlockedOutfits(userId)`（返回已解锁装扮 key 列表）
- `[DEFERRED]` 装扮解锁与 3D 资产关联逻辑（等待美术资源）
- [x] 5.6 创建 `src/controllers/pet.controller.ts` 和路由
- [x] 5.7 注册路由：`GET /api/pet`、`POST /api/pet/interact`、`PUT /api/pet/outfit`、`GET /api/pet/outfits`
- [x] 5.8 在 `app.ts` 中挂载 pet 路由

---

### 任务 6：每日任务 API

- [x] 6.1 创建 `src/services/task.service.ts`
- [x] 6.2 定义任务池（6 种任务类型，含 taskKey/title/xpReward）
- [x] 6.3 实现 `generateDailyTasks(userId, date)`（从任务池随机抽 3 条，不重复）
- [x] 6.4 实现 `getDailyTasks(userId, date)`（若当日无任务则自动生成）
- [x] 6.5 实现 `checkAndCompleteTasks(userId, date)`（自动检查并完成满足条件的任务）
- [x] 6.6 实现全勤奖励逻辑（3 条全完成额外 +30 XP）
- [x] 6.7 创建 `src/controllers/task.controller.ts` 和路由
- [x] 6.8 注册路由：`GET /api/tasks/daily`、`POST /api/tasks/:id/complete`
- [x] 6.9 在 `app.ts` 中挂载 task 路由

**属性测试**：Property 21（每日任务生成不重复性）、Property 5（任务完成进度计算）

---

### 任务 7：成就徽章 API

- [x] 7.1 创建 `src/services/achievement.service.ts`
- [x] 7.2 实现 `getAchievements(userId)`（返回全部成就含解锁状态）
- [x] 7.3 实现 `checkAndUnlockAchievements(userId)`（检查并解锁满足条件的成就，幂等）
- [x] 7.4 创建 `src/controllers/achievement.controller.ts` 和路由
- [x] 7.5 注册路由：`GET /api/achievements`
- [x] 7.6 在 `app.ts` 中挂载 achievement 路由

**属性测试**：Property 22（成就解锁幂等性）、Property 23（成就进度百分比）

---

### 任务 8：联盟排行榜 API

- [x] 8.1 创建 `src/services/league.service.ts`
- [x] 8.2 实现联盟分配逻辑（按等级分配层级，每组上限 30 人）
- [x] 8.3 实现 `getLeagueInfo(userId)`（含 Redis Sorted Set 排行榜，Top 10）
- [x] 8.4 实现 `getLeagueSettlement(userId)`（获取上次结算结果）
- [x] 8.5 实现排行榜隐私过滤（只返回 nickname/petAvatarMood/weeklyXp，不含 email/phone）
- [x] 8.6 创建 `src/controllers/league.controller.ts` 和路由
- [x] 8.7 注册路由：`GET /api/league/current`、`GET /api/league/settlement`
- [x] 8.8 在 `app.ts` 中挂载 league 路由

**属性测试**：Property 24（联盟分配规则）、Property 25（晋升/降级比例）、Property 26（隐私保护）

---

### 任务 9：个人资料 API

- [x] 9.1 创建 `src/services/profile.service.ts`
- [x] 9.2 实现 `getProfile(userId)`
- [x] 9.3 实现 `updateProfile(userId, data)`（触发卡路里目标重算）
- [x] 9.4 实现 `recordWeight(userId, weight)` 和 `getWeightHistory(userId)`
- [x] 9.5 创建 `src/controllers/profile.controller.ts` 和路由
- [x] 9.6 注册路由：`GET /api/profile`、`PUT /api/profile`、`GET /api/profile/weight-history`、`POST /api/profile/weight`
- [x] 9.7 在 `app.ts` 中挂载 profile 路由

**属性测试**：Property 27（卡路里目标重算确定性）

---

### 任务 10：定时任务（Cron Jobs）

- [x] 10.1 创建 `src/jobs/dailyReset.job.ts`（每日零点：重置 HP/饱食度/生成任务/检查 Streak）
- [x] 10.2 创建 `src/jobs/leagueSettlement.job.ts`（每周日 23:59：联盟结算晋升/降级）
- [x] 10.3 创建 `src/jobs/streakCheck.job.ts`（每日 19:00：查询未打卡用户，记录风险状态）
- [x] 10.4 在 `app.ts` 的 `startServer()` 中注册所有 cron jobs

**属性测试**：Property 16（Streak 连续性计算）、Property 25（联盟结算比例）

---

## 第二部分：iOS App 任务

### 任务 11：数据模型层

- [x] 11.1 创建 `Models/GamificationModels.swift`（GamificationStatus/XpTransaction）
- [x] 11.2 创建 `Models/FoodModels.swift`（FoodRecognitionResult/FoodRecord/MealGroup/NutritionStats）
- [x] 11.3 创建 `Models/PetModels.swift`（PetStatus/PetMood/PetLevelEvent）
- [x] 11.4 创建 `Models/TaskModels.swift`（DailyTask）
- [x] 11.5 创建 `Models/AchievementModels.swift`（Achievement）
- [x] 11.6 创建 `Models/LeagueModels.swift`（LeagueInfo/LeagueMember/LeagueSettlement）
- [x] 11.7 在 `Models/APIModels.swift` 中新增 UserProfile/WeightRecord/ProfileUpdateRequest

---

### 任务 12：APIService 扩展

- [x] 12.1 在 `APIService.swift` 中新增食物相关接口（recognizeFood/saveFoodRecord/getFoodRecords/deleteFoodRecord/getFoodStats）
- [x] 12.2 新增游戏化接口（getGamificationStatus/getPetStatus/interactWithPet/updatePetOutfit）
- [x] 12.3 新增任务与成就接口（getDailyTasks/getAchievements）
- [x] 12.4 新增联盟接口（getLeague/getLeagueSettlement）
- [x] 12.5 新增个人资料接口（getProfile/updateProfile/recordWeight/getWeightHistory）
- [x] 12.6 实现 multipart/form-data 图片上传支持（用于 recognizeFood）

---

### 任务 13：GamificationManager

- [x] 13.1 创建 `Services/GamificationManager.swift`（ObservableObject）
- [x] 13.2 实现 `@Published` 属性：gamificationStatus/dailyTasks/achievements/leagueInfo
- [x] 13.3 实现 `refreshStatus()` 拉取游戏化状态
- [x] 13.4 实现 `showXpFloat(amount: Int)` 触发浮动 XP 动画
- [x] 13.5 实现 `calcPetMood(calories:target:mealCount:streakDays:) -> PetMood`（本地计算）
- [x] 13.6 实现 `calcLevel(totalXp:) -> Int` 和 `xpToNextLevel(totalXp:) -> Int`（本地计算）
- [x] 13.7 实现 `calcSatietyDelta(recordCalories:dailyTarget:) -> Double`（本地计算）

**属性测试（SwiftCheck）**：
- Property 12（心情确定性）
- Property 13（等级公式正确性）
- Property 15（饱食度增量）

---

### 任务 14：NotificationManager

- [x] 14.1 创建 `Services/NotificationManager.swift`
- [x] 14.2 实现 `requestPermission() async -> Bool`
- [x] 14.3 实现 `scheduleDailyCheckin(hour:minute:)`（默认 20:00，注册前先取消旧通知）
- [x] 14.4 实现 `scheduleTaskRefresh(hour:minute:)`（默认 09:00）
- [x] 14.5 实现 `scheduleStreakRisk()`（当日 19:00，非重复）
- [x] 14.6 实现 `schedulePetMissing()`（连续 3 天未打卡后触发）
- [x] 14.7 实现 `cancelDailyCheckin()`（完成打卡后调用）
- [x] 14.8 在 `MainTabView` 或 `RaccoonCalApp` 中初始化时请求通知权限

**属性测试（SwiftCheck）**：
- Property 28（修改通知后旧通知被取消）
- Property 29（同类通知每天最多一次）
- Property 30（完成打卡后取消打卡提醒）

---

### 任务 15：共享 UI 组件

- [x] 15.1 创建 `Views/Components/CalorieRingView.swift`（环形进度条，超标时切换警告色）
- [x] 15.2 创建 `Views/Components/HPHeartView.swift`（心形图标列表，最多 5 颗）
- [x] 15.3 创建 `Views/Components/XPFloatLabel.swift`（浮动 "+N XP" 动画标签）
- [x] 15.4 创建 `Views/Components/RaccoonMoodView.swift`（根据 PetMood 切换对应静态图片，使用 Assets 中已有 PNG：RaccoonHappy/RaccoonLoading/RaccoonThinking 等）

**属性测试（SwiftCheck）**：
- Property 1（卡路里进度比例有界性：输入任意值，进度 clamp 到 [0,1]）
- Property 2（超标时颜色切换）
- Property 3（HP 心形数量有界性：`max(0, min(hp, 5))`）

---

### 任务 16：HomeView

- [ ] 16.1 创建 `Views/Home/HomeView.swift`
- [ ] 16.2 实现顶部信息栏（昵称/Streak 火焰图标/等级）
- [ ] 16.3 集成 `CalorieRingView` 展示当日卡路里进度
- [ ] 16.4 集成 `HPHeartView` 展示当日生命值
- [ ] 16.5 实现三餐 + 加餐卡路里小计列表，点击跳转 RecordView
- [ ] 16.6 集成 `RaccoonMoodView` 展示浣熊主场景（静态图片，根据心情切换）；点击浣熊调用 `interactWithPet` 并显示随机鼓励文案
- `[DEFERRED]` 浣熊互动 3D 动画（摇尾巴/眨眼/跳跃）
- [ ] 16.7 实现每日任务进度区域（已完成数/总数），点击展开任务详情列表
- [ ] 16.8 实现 `onAppear` 时拉取游戏化状态和今日饮食记录
- [ ] 16.9 实现超标时浣熊切换难过状态和"今日已超标"提示

**属性测试**：Property 4（餐次分组求和）、Property 5（任务进度计算）

---

### 任务 17：CameraView

- [ ] 17.1 创建 `Views/Camera/CameraView.swift`
- [ ] 17.2 集成 `AVFoundation` 实现相机取景框实时预览
- [ ] 17.3 实现拍照按钮，捕获图像并上传至 `/api/food/recognize`
- [ ] 17.4 实现识别结果展示（食物名称/卡路里/蛋白质/脂肪/碳水）
- [ ] 17.5 实现识别失败提示和手动输入食物名称的降级入口
- [ ] 17.6 实现用户修改食物名称/份量/餐次的编辑表单
- [ ] 17.7 实现确认保存，调用 `saveFoodRecord`，触发 XP 浮动动画
- [ ] 17.8 实现从相册选取图片（`PHPickerViewController`）
- [ ] 17.9 实现相机权限检查，未授权时展示引导弹窗
- [ ] 17.10 实现多食物识别结果列表，支持单独勾选
- [ ] 17.11 保存成功后刷新浣熊饱食度数据（静态图片更新）
- `[DEFERRED]` 浣熊进食 3D 动画

---

### 任务 18：RecordView

- [ ] 18.1 创建 `Views/Record/RecordView.swift`
- [ ] 18.2 实现日历视图（过去 30 天打卡状态，已打卡用主色标记）
- [ ] 18.3 实现点击日期展示该日饮食记录列表（按餐次分组）
- [ ] 18.4 实现长按记录弹出删除确认，删除后重新计算当日卡路里
- [ ] 18.5 实现过去 7 天卡路里折线图（含目标虚线）
- [ ] 18.6 实现过去 7 天三大营养素柱状图
- [ ] 18.7 实现下拉刷新重新拉取数据
- [ ] 18.8 实现无记录时的引导文案和跳转 CameraView 按钮

**属性测试**：Property 9（日历打卡状态一致性）、Property 10（删除后卡路里重算）、Property 11（图表数据聚合）

---

### 任务 19：PetView

- [ ] 19.1 创建 `Views/Pet/PetView.swift`
- [ ] 19.2 实现浣熊外观/名称/等级/饱食度进度条展示（使用静态图片）
- [ ] 19.3 集成 `RaccoonMoodView` 展示当前心情状态
- [ ] 19.4 实现点击浣熊调用 `interactWithPet`，显示随机文案和简单 scale 动画
- `[DEFERRED]` 浣熊互动 3D 动画（骨骼动画/游戏引擎）
- [ ] 19.5 实现装扮道具列表（帽子/衣服/配件三槽位）
- [ ] 19.6 实现更换装扮后调用 `updatePetOutfit` 保存，图片叠加预览
- `[DEFERRED]` 装扮实时 3D 预览
- [ ] 19.7 实现成长历史时间线（按 achievedAt 升序）
- [ ] 19.8 连续 3 天未打卡时展示"思念"状态（切换至 RaccoonLoading 图片 + 文案提示）
- `[DEFERRED]` 思念状态 3D 等待动画

**属性测试**：Property 14（成长历史时间线有序性）

---

### 任务 20：ProfileView

- [ ] 20.1 完善 `Views/Profile/ProfileView.swift`（当前为占位符）
- [ ] 20.2 实现用户信息展示（昵称/头像/身高/体重/年龄/目标/活动水平）
- [ ] 20.3 实现个人信息编辑页，保存后触发卡路里目标重算
- [ ] 20.4 实现健康数据摘要（累计记录天数/食物次数/平均卡路里）
- [ ] 20.5 实现等级/XP/等级进度条展示
- [ ] 20.6 实现成就徽章网格（已解锁/未解锁，含进度百分比）
- [ ] 20.7 实现联盟信息（当前联盟/本周排名/Top 10 排行榜）
- [ ] 20.8 实现体重历史折线图（最近 30 天）
- [ ] 20.9 实现通知设置（打卡提醒/任务刷新/联盟结算，可修改时间）
- [ ] 20.10 实现联盟结算结果弹窗（晋升/降级提示）

**属性测试**：Property 23（成就进度百分比）、Property 24（联盟分配规则）

---

## 第三部分：集成与测试

### 任务 21：属性测试套件

- [ ] 21.1 服务端：安装 `fast-check`，创建 `src/__tests__/properties/` 目录
- [ ] 21.2 实现 Property 13（等级公式）、Property 18（XP 幂等）、Property 19（HP 扣减）的属性测试
- [ ] 21.3 实现 Property 12（心情确定性）、Property 15（饱食度）、Property 27（卡路里目标）的属性测试
- [ ] 21.4 实现 Property 21（任务不重复）、Property 22（成就幂等）、Property 25（联盟结算比例）的属性测试
- [ ] 21.5 iOS：集成 `SwiftCheck`，创建 `RaccoonCalTests/Properties/` 目录
- [ ] 21.6 实现 Property 1/2/3（进度条/颜色/HP 有界性）的属性测试
- [ ] 21.7 实现 Property 12/13/15（心情/等级/饱食度）的属性测试
- [ ] 21.8 实现 Property 28/29/30（通知幂等性）的属性测试
- [ ] 21.9 每个属性测试最少运行 100 次迭代

---

### 任务 22：端到端集成验证

- [ ] 22.1 验证完整拍照识别 → 保存记录 → XP 授予 → 浣熊饱食度更新流程
- [ ] 22.2 验证 Streak 连续打卡 → 里程碑奖励 → 成就解锁流程
- [ ] 22.3 验证每日任务生成 → 自动完成检查 → 全勤奖励流程
- [ ] 22.4 验证联盟 XP 实时更新（Redis Sorted Set）→ 周结算晋降级流程
- [ ] 22.5 验证通知注册 → 打卡完成取消通知流程
