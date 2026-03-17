# 技术设计文档：RaccoonCal 游戏化功能

## 概述

RaccoonCal 是一款 iOS 原生卡路里管理应用，通过"拍照识别食物 → 记录饮食 → 养成浣熊宠物"的核心循环，将健康管理与游戏化激励深度融合。本文档描述所有待实现功能模块的技术设计，基于现有服务端（Express.js + Prisma + MySQL + Redis）和 iOS App（Swift + SwiftUI）架构进行扩展。

---

## 架构

### 整体系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS App (SwiftUI)                         │
│  HomeView │ CameraView │ RecordView │ PetView │ ProfileView  │
│  ─────────────────────────────────────────────────────────  │
│  GamificationManager │ NotificationManager │ UserManager    │
│  ─────────────────────────────────────────────────────────  │
│  APIService (URLSession + Bearer JWT)                        │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTPS / REST
┌──────────────────────▼──────────────────────────────────────┐
│                Express.js API Server                         │
│  /api/food  │ /api/gamification │ /api/pet │ /api/league    │
│  ─────────────────────────────────────────────────────────  │
│  GamificationEngine │ FoodService │ CronJobs                │
│  ─────────────────────────────────────────────────────────  │
│  Prisma ORM                                                  │
└──────┬───────────────────────────────────────┬──────────────┘
       │                                       │
┌──────▼──────┐                       ┌────────▼────────┐
│    MySQL    │                       │     Redis       │
│  (持久化)   │                       │  (缓存/排行榜)  │
└─────────────┘                       └─────────────────┘
       │
┌──────▼──────┐
│  LogMeal AI │
│  (食物识别) │
└─────────────┘
```

### 服务端模块划分

```
src/
├── controllers/
│   ├── food.controller.ts        # 食物识别与记录
│   ├── gamification.controller.ts # XP/等级/HP/Streak
│   ├── pet.controller.ts         # 浣熊宠物
│   ├── task.controller.ts        # 每日任务
│   ├── achievement.controller.ts # 成就徽章
│   ├── league.controller.ts      # 联盟排行榜
│   └── profile.controller.ts     # 个人资料
├── services/
│   ├── food.service.ts
│   ├── gamification.service.ts   # 游戏化引擎核心
│   ├── pet.service.ts
│   ├── task.service.ts
│   ├── achievement.service.ts
│   ├── league.service.ts
│   ├── profile.service.ts
│   └── logmeal.service.ts        # LogMeal API 封装
├── routes/
│   ├── food.routes.ts
│   ├── gamification.routes.ts
│   ├── pet.routes.ts
│   ├── task.routes.ts
│   ├── achievement.routes.ts
│   ├── league.routes.ts
│   └── profile.routes.ts
├── jobs/
│   ├── dailyReset.job.ts         # 每日零点重置
│   ├── leagueSettlement.job.ts   # 每周联盟结算
│   └── streakCheck.job.ts        # Streak 检查
└── utils/
    ├── gamificationEngine.ts     # XP/等级/HP 计算
    └── calorieCalculator.ts      # Harris-Benedict 公式
```

### iOS App 模块划分

```
RaccoonCal/
├── Models/
│   ├── APIModels.swift           # 已有，扩展新模型
│   ├── GamificationModels.swift  # XP/等级/HP/Streak
│   ├── FoodModels.swift          # 食物识别/记录
│   ├── PetModels.swift           # 浣熊宠物
│   ├── TaskModels.swift          # 每日任务
│   ├── AchievementModels.swift   # 成就徽章
│   └── LeagueModels.swift        # 联盟排行榜
├── Services/
│   ├── APIService.swift          # 已有，扩展新接口
│   ├── UserManager.swift         # 已有，扩展游戏化状态
│   ├── GamificationManager.swift # 游戏化状态管理
│   └── NotificationManager.swift # 本地通知管理
├── Views/
│   ├── Home/HomeView.swift       # 今日概览（待实现）
│   ├── Camera/CameraView.swift   # 拍照识别（待实现）
│   ├── Record/RecordView.swift   # 历史记录（待实现）
│   ├── Pet/PetView.swift         # 浣熊养成（待实现）
│   ├── Profile/ProfileView.swift # 个人资料（待实现）
│   └── Components/               # 共享 UI 组件
│       ├── CalorieRingView.swift
│       ├── HPHeartView.swift
│       ├── XPFloatLabel.swift
│       └── RaccoonMoodView.swift
└── Theme/AppTheme.swift          # 已有
```

---

## 组件与接口

### 服务端 API 接口

所有接口均需 `Authorization: Bearer <token>` 请求头（除特殊说明外）。

#### 食物识别与记录

```
POST   /api/food/recognize          # 上传图片，调用 LogMeal 识别
POST   /api/food/records            # 保存饮食记录
GET    /api/food/records?date=      # 获取指定日期记录
DELETE /api/food/records/:id        # 删除饮食记录
GET    /api/food/stats?days=7       # 获取 N 天营养统计
```

#### 游戏化

```
GET    /api/gamification/status     # 获取用户游戏化状态（XP/等级/HP/Streak）
GET    /api/gamification/history    # 获取 XP 历史记录
```

#### 浣熊宠物

```
GET    /api/pet                     # 获取浣熊状态
POST   /api/pet/interact            # 触发互动（+XP）
PUT    /api/pet/outfit              # 更换装扮
GET    /api/pet/outfits             # 获取已解锁装扮列表
```

#### 每日任务

```
GET    /api/tasks/daily             # 获取今日任务列表
POST   /api/tasks/:id/complete      # 手动触发任务完成检查
```

#### 成就徽章

```
GET    /api/achievements            # 获取全部成就（含解锁状态）
```

#### 联盟排行榜

```
GET    /api/league/current          # 获取当前联盟信息和排行榜
GET    /api/league/settlement       # 获取上次结算结果
```

#### 个人资料

```
GET    /api/profile                 # 获取完整个人资料
PUT    /api/profile                 # 更新个人信息（触发卡路里目标重算）
GET    /api/profile/weight-history  # 获取体重历史（最近 30 天）
POST   /api/profile/weight          # 记录新体重
```

### iOS APIService 扩展接口

在现有 `APIService.swift` 基础上新增以下方法：

```swift
// 食物
func recognizeFood(imageData: Data) async throws -> FoodRecognitionResult
func saveFoodRecord(_ record: FoodRecordRequest) async throws -> FoodRecord
func getFoodRecords(date: String) async throws -> [MealGroup]
func deleteFoodRecord(id: Int) async throws
func getFoodStats(days: Int) async throws -> NutritionStats

// 游戏化
func getGamificationStatus() async throws -> GamificationStatus
func getPetStatus() async throws -> PetStatus
func interactWithPet() async throws -> PetInteractResult
func updatePetOutfit(_ outfit: OutfitRequest) async throws

// 任务与成就
func getDailyTasks() async throws -> [DailyTask]
func getAchievements() async throws -> [Achievement]

// 联盟
func getLeague() async throws -> LeagueInfo
func getLeagueSettlement() async throws -> LeagueSettlement?

// 个人资料
func getProfile() async throws -> UserProfile
func updateProfile(_ profile: ProfileUpdateRequest) async throws -> UserProfile
func recordWeight(_ weight: Double) async throws
func getWeightHistory() async throws -> [WeightRecord]
```

---

## 数据模型

### Prisma Schema 扩展

在现有 `User` 表基础上新增以下模型：

```prisma
// 用户健康档案（Onboarding 数据持久化）
model UserProfile {
  id              Int      @id @default(autoincrement())
  userId          Int      @unique @map("user_id")
  nickname        String   @db.VarChar(50)
  gender          String   @db.VarChar(10)
  height          Int      // cm
  weight          Float    // kg
  age             Int
  goal            String   @db.VarChar(50)  // lose_weight / maintain / gain_muscle
  activityLevel   String   @map("activity_level") @db.VarChar(20)
  dailyCalTarget  Int      @map("daily_cal_target")
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")
  user            User     @relation(fields: [userId], references: [id])
  @@map("user_profiles")
}

// 体重历史
model WeightRecord {
  id        Int      @id @default(autoincrement())
  userId    Int      @map("user_id")
  weight    Float
  recordedAt DateTime @default(now()) @map("recorded_at")
  user      User     @relation(fields: [userId], references: [id])
  @@map("weight_records")
  @@index([userId, recordedAt])
}

// 饮食记录
model FoodRecord {
  id          Int      @id @default(autoincrement())
  userId      Int      @map("user_id")
  foodName    String   @map("food_name") @db.VarChar(100)
  calories    Float
  protein     Float    @default(0)
  fat         Float    @default(0)
  carbs       Float    @default(0)
  fiber       Float    @default(0)
  servingSize Float    @map("serving_size") @default(100) // 克
  mealType    String   @map("meal_type") @db.VarChar(20) // breakfast/lunch/dinner/snack
  imageUrl    String?  @map("image_url") @db.VarChar(255)
  recordedAt  DateTime @default(now()) @map("recorded_at")
  user        User     @relation(fields: [userId], references: [id])
  @@map("food_records")
  @@index([userId, recordedAt])
}

// 游戏化状态（每用户一条）
model GamificationStatus {
  id            Int      @id @default(autoincrement())
  userId        Int      @unique @map("user_id")
  totalXp       Int      @default(0) @map("total_xp")
  level         Int      @default(1)
  weeklyXp      Int      @default(0) @map("weekly_xp")
  currentHp     Int      @default(5) @map("current_hp")
  streakDays    Int      @default(0) @map("streak_days")
  streakShields Int      @default(0) @map("streak_shields") // 最多 2
  lastCheckinAt DateTime? @map("last_checkin_at")
  hpResetAt     DateTime? @map("hp_reset_at")
  updatedAt     DateTime @updatedAt @map("updated_at")
  user          User     @relation(fields: [userId], references: [id])
  @@map("gamification_status")
}

// XP 流水记录
model XpTransaction {
  id        Int      @id @default(autoincrement())
  userId    Int      @map("user_id")
  amount    Int
  reason    String   @db.VarChar(50) // food_record / daily_goal / task / streak / achievement
  refId     String?  @map("ref_id") @db.VarChar(50) // 关联业务 ID，用于幂等
  earnedAt  DateTime @default(now()) @map("earned_at")
  user      User     @relation(fields: [userId], references: [id])
  @@map("xp_transactions")
  @@unique([userId, reason, refId]) // 幂等约束
  @@index([userId, earnedAt])
}

// 浣熊宠物
model Pet {
  id          Int      @id @default(autoincrement())
  userId      Int      @unique @map("user_id")
  name        String   @default("小R") @db.VarChar(50)
  satiety     Float    @default(0) // 0-100 饱食度
  hatSlot     String?  @map("hat_slot") @db.VarChar(50)
  clothSlot   String?  @map("cloth_slot") @db.VarChar(50)
  accessSlot  String?  @map("access_slot") @db.VarChar(50)
  updatedAt   DateTime @updatedAt @map("updated_at")
  user        User     @relation(fields: [userId], references: [id])
  levelHistory PetLevelHistory[]
  @@map("pets")
}

// 浣熊升级历史
model PetLevelHistory {
  id          Int      @id @default(autoincrement())
  petId       Int      @map("pet_id")
  level       Int
  unlockedItem String? @map("unlocked_item") @db.VarChar(100)
  achievedAt  DateTime @default(now()) @map("achieved_at")
  pet         Pet      @relation(fields: [petId], references: [id])
  @@map("pet_level_history")
}

// 每日任务
model DailyTask {
  id          Int      @id @default(autoincrement())
  userId      Int      @map("user_id")
  taskKey     String   @map("task_key") @db.VarChar(50) // 任务类型标识
  title       String   @db.VarChar(100)
  xpReward    Int      @map("xp_reward")
  completed   Boolean  @default(false)
  completedAt DateTime? @map("completed_at")
  taskDate    String   @map("task_date") @db.VarChar(10) // YYYY-MM-DD
  user        User     @relation(fields: [userId], references: [id])
  @@map("daily_tasks")
  @@unique([userId, taskKey, taskDate])
  @@index([userId, taskDate])
}

// 成就徽章定义（静态数据，seed 写入）
model AchievementDef {
  id          Int      @id @default(autoincrement())
  key         String   @unique @db.VarChar(50)
  title       String   @db.VarChar(100)
  description String   @db.VarChar(255)
  xpReward    Int      @map("xp_reward")
  iconName    String   @map("icon_name") @db.VarChar(50)
  userAchievements UserAchievement[]
  @@map("achievement_defs")
}

// 用户已解锁成就
model UserAchievement {
  id              Int      @id @default(autoincrement())
  userId          Int      @map("user_id")
  achievementKey  String   @map("achievement_key") @db.VarChar(50)
  unlockedAt      DateTime @default(now()) @map("unlocked_at")
  user            User     @relation(fields: [userId], references: [id])
  achievementDef  AchievementDef @relation(fields: [achievementKey], references: [key])
  @@unique([userId, achievementKey])
  @@map("user_achievements")
}

// 联盟分组
model League {
  id        Int      @id @default(autoincrement())
  tier      String   @db.VarChar(20) // bronze/silver/gold/platinum/diamond
  weekStart String   @map("week_start") @db.VarChar(10) // YYYY-MM-DD
  members   LeagueMember[]
  @@map("leagues")
  @@index([tier, weekStart])
}

// 联盟成员
model LeagueMember {
  id        Int      @id @default(autoincrement())
  leagueId  Int      @map("league_id")
  userId    Int      @map("user_id")
  weeklyXp  Int      @default(0) @map("weekly_xp")
  rank      Int?
  promoted  Boolean? // 结算后晋升/降级标记
  league    League   @relation(fields: [leagueId], references: [id])
  user      User     @relation(fields: [userId], references: [id])
  @@unique([leagueId, userId])
  @@map("league_members")
}
```

### iOS 数据模型

```swift
// GamificationModels.swift
struct GamificationStatus: Codable {
    let totalXp: Int
    let level: Int
    let weeklyXp: Int
    let currentHp: Int
    let streakDays: Int
    let streakShields: Int
    let xpToNextLevel: Int
    let levelProgress: Double // 0.0-1.0
}

// FoodModels.swift
struct FoodRecognitionResult: Codable {
    let foods: [RecognizedFood]
    let confidence: Double
}
struct RecognizedFood: Codable {
    let name: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let servingSize: Double
}
struct FoodRecord: Codable {
    let id: Int
    let foodName: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let servingSize: Double
    let mealType: String
    let recordedAt: String
}
struct MealGroup: Codable {
    let mealType: String
    let totalCalories: Double
    let records: [FoodRecord]
}
struct NutritionStats: Codable {
    let dailyCalories: [DailyCalories]
    let avgProtein: Double
    let avgFat: Double
    let avgCarbs: Double
}
struct DailyCalories: Codable {
    let date: String
    let calories: Double
}

// PetModels.swift
enum PetMood: String, Codable {
    case happy, satisfied, normal, hungry, sad, missing
}
struct PetStatus: Codable {
    let name: String
    let level: Int
    let satiety: Double
    let mood: PetMood
    let hatSlot: String?
    let clothSlot: String?
    let accessSlot: String?
    let unlockedOutfits: [String]
    let levelHistory: [PetLevelEvent]
}
struct PetLevelEvent: Codable {
    let level: Int
    let unlockedItem: String?
    let achievedAt: String
}

// TaskModels.swift
struct DailyTask: Codable {
    let id: Int
    let taskKey: String
    let title: String
    let xpReward: Int
    let completed: Bool
}

// AchievementModels.swift
struct Achievement: Codable {
    let key: String
    let title: String
    let description: String
    let xpReward: Int
    let iconName: String
    let unlocked: Bool
    let unlockedAt: String?
}

// LeagueModels.swift
struct LeagueInfo: Codable {
    let tier: String
    let weeklyXp: Int
    let rank: Int
    let topMembers: [LeagueMember]
}
struct LeagueMember: Codable {
    let nickname: String
    let petAvatarMood: String
    let weeklyXp: Int
    let rank: Int
}
struct LeagueSettlement: Codable {
    let promoted: Bool?
    let demoted: Bool?
    let newTier: String
    let finalRank: Int
}
```

---

## Redis 缓存设计

### 键命名规范与 TTL 策略

| 键模式 | 用途 | TTL |
|--------|------|-----|
| `user:gamification:{userId}` | 游戏化状态缓存 | 5 分钟 |
| `user:daily_cal:{userId}:{date}` | 当日卡路里汇总 | 至次日零点 |
| `user:daily_tasks:{userId}:{date}` | 当日任务列表 | 至次日零点 |
| `league:ranking:{tier}:{weekStart}` | 联盟排行榜（Sorted Set） | 7 天 |
| `user:xp_dedup:{userId}:{reason}:{refId}` | XP 幂等去重 | 24 小时 |
| `pet:status:{userId}` | 浣熊状态缓存 | 10 分钟 |
| `checkin:flag:{userId}:{date}` | 当日打卡标记 | 至次日零点 |

### 联盟排行榜实现

使用 Redis Sorted Set，`ZADD league:ranking:{tier}:{weekStart} {weeklyXp} {userId}`，`ZREVRANGE` 获取 Top 10。每次用户获得 XP 时通过 `ZINCRBY` 实时更新。

---

## 游戏化引擎设计

### XP 授予规则

```typescript
// gamificationEngine.ts
const XP_RULES = {
  food_record: 10,          // 每次饮食记录
  daily_goal: 30,           // 达成当日卡路里目标
  task_complete: (xp: number) => xp, // 任务奖励（20-50 XP）
  streak_bonus: (streak: number) => Math.min(5 * streak, 50),
  achievement: (xp: number) => xp,  // 成就奖励
};

// 幂等 XP 授予：通过 XpTransaction 的 unique(userId, reason, refId) 约束
async function awardXp(userId: number, reason: string, refId: string, amount: number) {
  // 先查 Redis 去重缓存，命中则跳过
  // 未命中则写入 XpTransaction（DB 唯一约束兜底）
  // 更新 GamificationStatus.totalXp 和 weeklyXp
  // 检查是否升级，若升级则写 PetLevelHistory
  // 更新 Redis Sorted Set
}
```

### 等级公式

```typescript
// Level N 所需累计 XP = 100 * N^2
function calcLevel(totalXp: number): number {
  return Math.min(Math.floor(Math.sqrt(totalXp / 100)), 50);
}
function xpToNextLevel(totalXp: number): number {
  const level = calcLevel(totalXp);
  if (level >= 50) return 0;
  return 100 * (level + 1) ** 2 - totalXp;
}
```

### HP 扣减逻辑

```typescript
// 每次保存饮食记录后触发
async function checkAndDeductHp(userId: number, date: string) {
  const { totalCalories, dailyTarget } = await getDailyCalSummary(userId, date);
  const status = await getGamificationStatus(userId);
  // 超出目标 10% 且 HP > 0 时扣减
  if (totalCalories > dailyTarget * 1.1 && status.currentHp > 0) {
    await deductHp(userId, 1);
  }
}
```

### Streak 计算逻辑

```typescript
// 每日零点 cron 检查
async function updateStreak(userId: number) {
  const yesterday = getDateString(-1);
  const checkedIn = await hasCheckinOnDate(userId, yesterday);
  if (!checkedIn) {
    const status = await getGamificationStatus(userId);
    if (status.streakShields > 0) {
      await consumeShield(userId); // 消耗保护
    } else {
      await resetStreak(userId);   // 重置为 0
    }
  }
}
```

### 浣熊心情计算

```typescript
function calcPetMood(params: {
  totalCalories: number;
  dailyTarget: number;
  mealCount: number;
  streakDays: number;
}): PetMood {
  const { totalCalories, dailyTarget, mealCount, streakDays } = params;
  if (streakDays === 0 && mealCount === 0) return 'missing'; // 连续 3 天未打卡
  if (totalCalories > dailyTarget * 1.2) return 'sad';
  if (totalCalories >= dailyTarget * 0.9 && totalCalories <= dailyTarget * 1.1) return 'happy';
  if (mealCount >= 2) return 'satisfied';
  if (mealCount === 1) return 'normal';
  return 'hungry';
}
```

### 饱食度计算

```typescript
// 每次记录饮食后更新
function calcSatietyDelta(recordCalories: number, dailyTarget: number): number {
  return Math.min((recordCalories / dailyTarget) * 100, 100);
}
// 每日零点重置为 0
```

---

## AI 食物识别集成方案

### LogMeal API 调用流程

```
iOS App                    Express Server              LogMeal API
   │                            │                           │
   │── POST /api/food/recognize ─►                          │
   │   (multipart/form-data)    │                           │
   │                            │── POST /v2/image/segmentation/complete/v1.0
   │                            │   Authorization: Bearer AI_API_KEY
   │                            │   (image file)            │
   │                            │◄── { results: [...] } ────│
   │                            │                           │
   │                            │ [解析结果，提取营养数据]
   │                            │ [用 Sharp 压缩图片后上传 S3]
   │◄── { foods: [...] } ───────│
```

### 服务端实现

```typescript
// logmeal.service.ts
async function recognizeFood(imageBuffer: Buffer): Promise<RecognizedFood[]> {
  const formData = new FormData();
  formData.append('image', imageBuffer, { filename: 'food.jpg', contentType: 'image/jpeg' });

  const response = await axios.post(
    `${config.ai.apiUrl}/v2/image/segmentation/complete/v1.0`,
    formData,
    { headers: { Authorization: `Bearer ${config.ai.apiKey}`, ...formData.getHeaders() } }
  );

  return parseLogMealResponse(response.data);
}

// 图片预处理（Sharp）：压缩至 800px 宽，质量 80%，减少 API 传输量
async function preprocessImage(buffer: Buffer): Promise<Buffer> {
  return sharp(buffer).resize({ width: 800 }).jpeg({ quality: 80 }).toBuffer();
}
```

### 识别失败处理

- LogMeal 返回空结果或 confidence < 0.3 → 返回 `{ foods: [], confidence: 0 }`
- 网络超时（10s）→ 返回 503 错误，App 显示"识别失败"提示
- App 提供手动输入食物名称的降级入口

---

## 定时任务设计

使用 `node-cron` 实现，在 `app.ts` 启动时注册。

```typescript
// jobs/dailyReset.job.ts - 每日零点执行
cron.schedule('0 0 * * *', async () => {
  // 1. 重置所有用户 HP 为 5
  // 2. 重置所有用户浣熊饱食度为 0
  // 3. 为所有活跃用户生成新的每日任务（从任务池随机抽 3 条）
  // 4. 检查 Streak（调用 updateStreak）
  // 5. 清理过期 Redis 缓存
});

// jobs/leagueSettlement.job.ts - 每周日 23:59 执行
cron.schedule('59 23 * * 0', async () => {
  // 1. 查询所有联盟的本周排名
  // 2. 前 20% 用户标记晋升，后 20% 标记降级
  // 3. 写入 LeagueMember.promoted 字段
  // 4. 下周一零点创建新联盟分组，重置 weeklyXp
});

// jobs/streakCheck.job.ts - 每日 19:00 执行（Streak 断裂风险提醒）
cron.schedule('0 19 * * *', async () => {
  // 查询今日未打卡且 streakDays > 0 的用户
  // 写入通知队列（App 端本地通知，服务端仅记录状态）
});
```

---

## 本地通知设计（iOS）

### NotificationManager

```swift
// NotificationManager.swift
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    // 通知标识符常量
    enum NotificationID {
        static let dailyCheckin = "daily_checkin"
        static let taskRefresh = "task_refresh"
        static let streakRisk = "streak_risk"
        static let petMissing = "pet_missing"
    }

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // 注册每日打卡提醒（默认 20:00）
    func scheduleDailyCheckin(hour: Int = 20, minute: Int = 0) {
        cancelNotification(id: NotificationID.dailyCheckin)
        let content = UNMutableNotificationContent()
        content.title = "小R 在等你 🦝"
        content.body = "别忘了记录今天的饮食，保持你的 Streak！"
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: NotificationID.dailyCheckin, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // 注册任务刷新提醒（默认 09:00）
    func scheduleTaskRefresh(hour: Int = 9, minute: Int = 0) { ... }

    // 注册 Streak 断裂风险提醒（当日 19:00，非重复）
    func scheduleStreakRisk() { ... }

    // 注册宠物思念提醒（连续 3 天未打卡后触发，延迟 1 秒）
    func schedulePetMissing() { ... }

    // 取消当日打卡提醒（完成打卡后调用）
    func cancelDailyCheckin() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [NotificationID.dailyCheckin]
        )
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
```

### 通知幂等保证

每次注册通知前先取消同 ID 的旧通知，确保同类通知每天最多一条。利用 `UNNotificationRequest` 的 `identifier` 唯一性，重复 `add` 会自动覆盖。

---

## 正确性属性

*属性（Property）是在系统所有有效执行中都应成立的特征或行为——本质上是对系统应做什么的形式化陈述。属性是人类可读规范与机器可验证正确性保证之间的桥梁。*

### Property 1：卡路里进度比例有界性

*对任意* 已摄入卡路里值和卡路里目标值，计算出的进度比例应在 [0.0, 1.0] 范围内（超出时 clamp 到 1.0，不足时不低于 0.0）。

**Validates: Requirements 1.2**

### Property 2：超标警告色切换

*对任意* 已摄入卡路里和卡路里目标，当摄入 > 目标时进度条颜色应为 `AppTheme.warning`，否则应为 `AppTheme.primary`。

**Validates: Requirements 1.3**

### Property 3：HP 展示数量有界性

*对任意* HP 值（整数），展示的心形图标数量应等于 `max(0, min(hp, 5))`。

**Validates: Requirements 1.4, 7.1, 7.4**

### Property 4：餐次卡路里分组求和正确性

*对任意* 饮食记录列表，按餐次分组后各组的卡路里之和应等于该餐次所有记录的卡路里之和，且所有餐次之和等于当日总卡路里。

**Validates: Requirements 1.6, 3.3**

### Property 5：任务完成进度计算正确性

*对任意* 每日任务列表，完成进度 = 已完成任务数 / 总任务数，且结果在 [0, 1] 范围内。

**Validates: Requirements 1.10, 8.3**

### Property 6：识别失败时返回错误状态

*对任意* LogMeal API 返回置信度低于阈值（0.3）或空结果的响应，食物识别服务应返回空食物列表而非抛出未处理异常。

**Validates: Requirements 2.4**

### Property 7：保存记录后 XP 增加

*对任意* 有效饮食记录，保存后用户的 totalXp 应增加恰好 10（food_record 奖励），且同一记录 ID 重复保存不再增加 XP（幂等性）。

**Validates: Requirements 2.6, 6.1, 6.6**

### Property 8：多食物识别结果数量一致性

*对任意* 包含 N 种食物的 LogMeal 识别响应，解析后返回的食物列表长度应等于 N。

**Validates: Requirements 2.10**

### Property 9：日历打卡状态与记录一致性

*对任意* 饮食记录集合，日历中每天的打卡状态（已打卡/未打卡）应与该日是否存在至少一条饮食记录严格一致。

**Validates: Requirements 3.1**

### Property 10：删除记录后卡路里重新计算正确性

*对任意* 饮食记录列表，删除其中一条记录后，当日卡路里总量应等于原总量减去被删除记录的卡路里值。

**Validates: Requirements 3.4**

### Property 11：图表数据聚合正确性

*对任意* N 天饮食记录，折线图中每天的数据点值应等于该日所有记录的卡路里之和；营养素平均值应等于 N 天各营养素总量之和除以 N。

**Validates: Requirements 3.5, 3.6**

### Property 12：浣熊心情状态确定性

*对任意* 用户当日行为数据（摄入卡路里、目标卡路里、餐次数量、连续未打卡天数），`calcPetMood` 函数应返回唯一确定的心情状态，且满足：超出目标 20% → sad，达标 90%-110% → happy，记录 ≥ 2 餐 → satisfied，记录 1 餐 → normal，无记录 → hungry，连续 3 天无记录 → missing。

**Validates: Requirements 4.2, 1.5**

### Property 13：等级公式正确性

*对任意* 累计 XP 值，计算出的等级 N 应满足 `100*(N-1)^2 <= XP < 100*N^2`（N 在 [1, 50] 范围内），且 `xpToNextLevel` 应等于 `100*N^2 - XP`。

**Validates: Requirements 4.3, 6.2**

### Property 14：成长历史时间线有序性

*对任意* 浣熊升级历史记录，时间线中的事件应按 `achievedAt` 升序排列，且等级值单调递增。

**Validates: Requirements 4.6**

### Property 15：饱食度增量计算正确性

*对任意* 饮食记录卡路里和每日目标，饱食度增量应等于 `min(calories / dailyTarget * 100, 100)`，且累计饱食度不超过 100%。

**Validates: Requirements 4.8**

### Property 16：Streak 连续性计算正确性

*对任意* 打卡历史记录集合，Streak 值应等于从今天往前连续有打卡记录的天数；若昨日无记录且无保护盾，Streak 应重置为 0；若有保护盾，Streak 保持不变且保护盾数量减 1。

**Validates: Requirements 5.1, 5.2, 5.6**

### Property 17：Streak 里程碑 XP 奖励正确性

*对任意* Streak 值，当达到 7/30/100 天时，授予的 XP 奖励应分别为 50/200/1000，且同一里程碑不重复授予。

**Validates: Requirements 5.4**

### Property 18：XP 授予幂等性

*对任意* 行为类型和关联业务 ID，同一用户在同一天内对同一行为的 XP 授予应只发生一次，重复触发不改变 totalXp。

**Validates: Requirements 6.6, 9.4**

### Property 19：HP 扣减阈值正确性

*对任意* 卡路里记录序列，当且仅当累计摄入超出目标 10% 时扣减 1 点 HP，且 HP 下限为 0（不会变为负数）。

**Validates: Requirements 7.2, 7.4**

### Property 20：HP 恢复上限正确性

*对任意* 当前 HP 值（0-5），完成恢复任务后 HP 应增加 1，但不超过 5。

**Validates: Requirements 7.5**

### Property 21：每日任务生成不重复性

*对任意* 任务池，每日生成的 3 条任务应互不重复（taskKey 唯一），且均来自任务池中的有效任务。

**Validates: Requirements 8.1**

### Property 22：成就解锁幂等性

*对任意* 成就 key，用户满足解锁条件后成就状态变为已解锁，重复触发不再授予 XP，`UserAchievement` 表中该用户该成就只有一条记录。

**Validates: Requirements 9.2, 9.4**

### Property 23：成就进度百分比正确性

*对任意* 用户成就数据，进度百分比应等于已解锁成就数 / 总成就数，且在 [0, 1] 范围内。

**Validates: Requirements 9.6**

### Property 24：联盟分配规则正确性

*对任意* 用户等级，分配到的联盟层级应符合等级区间规则（1-10 级→青铜，11-20→白银，21-30→黄金，31-40→铂金，41-50→钻石），且同一联盟同一周的成员数不超过 30。

**Validates: Requirements 10.1**

### Property 25：联盟结算晋升/降级比例正确性

*对任意* 联盟排名列表（N 人），结算后排名前 ceil(N*0.2) 的用户应标记为晋升，排名后 ceil(N*0.2) 的用户应标记为降级，中间用户保持不变。

**Validates: Requirements 10.4**

### Property 26：排行榜隐私保护

*对任意* 联盟排行榜渲染结果，每条记录不应包含用户的 email 或 phone 字段，只包含 nickname、petAvatarMood 和 weeklyXp。

**Validates: Requirements 10.6**

### Property 27：卡路里目标重算正确性

*对任意* 用户健康数据（性别、身高、体重、年龄、活动水平、目标），每日卡路里目标应由 Harris-Benedict 公式确定性计算，相同输入始终产生相同输出。

**Validates: Requirements 11.3**

### Property 28：通知修改后旧通知被取消

*对任意* 新通知时间设置，调用 `scheduleXxx` 后，旧的同类通知应不再存在于待发送队列中，新通知应按新时间注册。

**Validates: Requirements 12.4**

### Property 29：同类通知每天最多一次

*对任意* 通知触发序列，同一 `NotificationID` 在待发送队列中最多存在一条（后注册覆盖前注册）。

**Validates: Requirements 12.5**

### Property 30：完成打卡后取消打卡提醒

*对任意* 打卡完成事件，调用 `cancelDailyCheckin()` 后，`daily_checkin` 通知应从待发送队列中移除。

**Validates: Requirements 12.6**

---

## 错误处理

### 服务端错误处理

| 场景 | HTTP 状态码 | 错误码 | 处理方式 |
|------|------------|--------|---------|
| LogMeal API 超时 | 503 | `AI_TIMEOUT` | 返回空识别结果，App 显示降级入口 |
| LogMeal API 识别失败 | 200 | - | 返回 `{ foods: [], confidence: 0 }` |
| 图片格式不支持 | 400 | `INVALID_IMAGE` | 返回错误提示 |
| XP 幂等冲突（DB unique 约束） | 200 | - | 静默忽略，不报错 |
| 联盟已满（30人） | 200 | - | 自动创建新联盟分组 |
| 用户档案不存在 | 404 | `PROFILE_NOT_FOUND` | 引导用户完成 Onboarding |

### iOS 错误处理

- 网络请求失败：显示 Toast 提示，提供重试按钮
- 相机权限被拒：展示权限说明弹窗，提供跳转系统设置的按钮
- 识别失败：显示"识别失败"提示，展示手动输入入口
- Token 过期（401）：`UserManager` 自动调用 `logout()`，跳转登录页

---

## 测试策略

### 双轨测试方法

单元测试和属性测试互补，共同保证系统正确性：
- **单元测试**：验证具体示例、边界条件和集成点
- **属性测试**：通过随机输入验证普遍性规律

### 服务端测试

**属性测试库**：`fast-check`（TypeScript）

```typescript
// 示例：等级公式属性测试
import fc from 'fast-check';
import { calcLevel, xpToNextLevel } from '@/utils/gamificationEngine';

// Feature: raccoon-cal-gamification-plan, Property 13: 等级公式正确性
test('level formula correctness', () => {
  fc.assert(fc.property(
    fc.integer({ min: 0, max: 250000 }),
    (totalXp) => {
      const level = calcLevel(totalXp);
      expect(level).toBeGreaterThanOrEqual(1);
      expect(level).toBeLessThanOrEqual(50);
      if (level < 50) {
        expect(totalXp).toBeGreaterThanOrEqual(100 * (level - 1) ** 2);
        expect(totalXp).toBeLessThan(100 * level ** 2);
      }
    }
  ), { numRuns: 1000 });
});
```

**单元测试**：
- 成就池数量 ≥ 20（Requirements 9.1）
- 四种通知类型均已注册（Requirements 12.3）
- HP 初始值为 5（Requirements 7.1）

### iOS 测试

**属性测试库**：`SwiftCheck`

```swift
// Feature: raccoon-cal-gamification-plan, Property 12: 浣熊心情状态确定性
property("pet mood is deterministic") <- forAll { (calories: Double, target: Double, meals: Int) in
    let mood1 = calcPetMood(calories: abs(calories), target: max(abs(target), 1), meals: abs(meals) % 5)
    let mood2 = calcPetMood(calories: abs(calories), target: max(abs(target), 1), meals: abs(meals) % 5)
    return mood1 == mood2
}
```

**每个属性测试最少运行 100 次迭代。**

**单元测试重点**：
- `calcLevel` 边界值（XP=0, XP=100, XP=250000）
- `calcSatietyDelta` 上限 clamp（calories > dailyTarget）
- `NotificationManager` 幂等覆盖行为
- 联盟结算晋升/降级边界（N=1, N=2 时的比例计算）
