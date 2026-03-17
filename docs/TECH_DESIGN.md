# 技术设计文档：RaccoonCal iOS

## 架构概览

```
SwiftUI Views
    │
ObservableObject Services（UserManager / GamificationManager / NotificationManager）
    │
APIService（URLSession + Bearer JWT）
    │ HTTPS / REST
RaccoonCal Server（raccoon-cal-server）
```

## 技术栈

| 层级 | 选型 |
|------|------|
| 语言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 最低部署目标 | iOS 15.0 |
| 相机 | AVFoundation |
| 相册 | PHPickerViewController |
| 本地通知 | UNUserNotificationCenter |
| 网络 | URLSession（原生，无第三方依赖） |
| 包管理 | Swift Package Manager |

## 项目结构

```
RaccoonCal/
├── App/
│   └── RaccoonCalApp.swift            # @main 入口，注入 UserManager
├── Models/
│   ├── APIModels.swift                # 基础 API 响应模型
│   ├── GamificationModels.swift       # GamificationStatus / XpTransaction
│   ├── FoodModels.swift               # FoodRecognitionResult / FoodRecord / MealGroup / NutritionStats
│   ├── PetModels.swift                # PetStatus / PetMood / PetLevelEvent
│   ├── TaskModels.swift               # DailyTask
│   ├── AchievementModels.swift        # Achievement
│   └── LeagueModels.swift             # LeagueInfo / LeagueMember / LeagueSettlement
├── Services/
│   ├── APIService.swift               # 所有网络请求封装（async/await）
│   ├── UserManager.swift              # 用户登录状态（@Published token/user）
│   ├── GamificationManager.swift      # 游戏化状态（@Published status/tasks/achievements）
│   └── NotificationManager.swift      # 本地通知注册/取消
├── Views/
│   ├── Auth/
│   │   ├── WelcomeView.swift
│   │   ├── LoginView.swift
│   │   ├── RegisterView.swift
│   │   ├── OnboardingView.swift
│   │   └── OnboardingSteps/           # Step1～Step9
│   ├── Tabs/
│   │   └── MainTabView.swift          # 5 Tab 框架
│   ├── Home/
│   │   └── HomeView.swift             # 今日概览
│   ├── Camera/
│   │   └── CameraView.swift           # 拍照识别
│   ├── Record/
│   │   └── RecordView.swift           # 饮食历史
│   ├── Pet/
│   │   └── PetView.swift              # 浣熊养成
│   ├── Profile/
│   │   └── ProfileView.swift          # 个人资料
│   └── Components/
│       ├── CalorieRingView.swift       # 环形进度条
│       ├── HPHeartView.swift           # 生命值心形图标
│       ├── XPFloatLabel.swift          # 浮动 +N XP 动画
│       └── RaccoonMoodView.swift       # 浣熊静态图片（按心情切换）
└── Theme/
    └── AppTheme.swift                  # 颜色/字体/间距常量
```

## 数据流

```
View → 调用 Service 方法（async/await）
Service → 调用 APIService → 解析响应 → 更新 @Published 属性
View → 通过 @StateObject / @EnvironmentObject 响应更新
```

## APIService 设计

所有请求统一封装，自动附加 Bearer Token：

```swift
func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) async throws -> T
```

错误处理：
- 401 → `UserManager.shared.logout()`，跳转登录页
- 网络失败 → 抛出 `APIError`，View 层显示 Toast + 重试按钮

## GamificationManager

```swift
@MainActor
class GamificationManager: ObservableObject {
    @Published var status: GamificationStatus?
    @Published var dailyTasks: [DailyTask] = []
    @Published var achievements: [Achievement] = []
    @Published var leagueInfo: LeagueInfo?
    @Published var showXpFloat: Bool = false
    @Published var xpFloatAmount: Int = 0

    // 本地计算（与服务端公式保持一致）
    func calcLevel(_ totalXp: Int) -> Int
    func xpToNextLevel(_ totalXp: Int) -> Int
    func calcPetMood(calories: Double, target: Double, mealCount: Int, streakDays: Int) -> PetMood
    func calcSatietyDelta(recordCalories: Double, dailyTarget: Double) -> Double
}
```

## NotificationManager

```swift
class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() async -> Bool
    func scheduleDailyCheckin(hour: Int = 20, minute: Int = 0)   // 每日打卡提醒
    func scheduleTaskRefresh(hour: Int = 9, minute: Int = 0)     // 任务刷新提醒
    func scheduleStreakRisk()                                      // 当日 19:00 Streak 风险
    func schedulePetMissing()                                      // 连续 3 天未打卡
    func cancelDailyCheckin()                                      // 完成打卡后取消
}
```

通知幂等：注册前先取消同 ID 的旧通知，`UNNotificationRequest` 相同 identifier 自动覆盖。

## 浣熊展示方案

当前阶段使用静态图片（Assets.xcassets 中已有 PNG），按心情切换：

| PetMood | 图片资源 |
|---------|---------|
| happy | RaccoonHappy |
| satisfied | RaccoonExcited |
| normal | RaccoonGreeting |
| hungry | RaccoonThinking |
| sad | RaccoonLoading |
| missing | RaccoonLoading |

3D 动画/骨骼动画待美术资源就绪后接入，接口设计已预留。

## 相机集成

```swift
// 拍照：AVCaptureSession + AVCapturePhotoOutput
// 相册：PHPickerViewController（iOS 14+）
// 图片压缩：UIImage → JPEG，quality 0.8，上传前压缩至 800px 宽
// 上传：multipart/form-data，字段名 image
```

## 本地数据

当前不使用 Core Data，所有数据从服务端拉取，关键状态缓存在 `@Published` 属性中，App 重启后重新拉取。

## 安全

- Token 存储：`UserDefaults`（开发阶段），生产环境迁移至 Keychain
- 图片上传：仅上传压缩后的 JPEG，不保留原图
- 排行榜：只展示 nickname 和 petAvatarMood，不展示真实姓名/邮箱
