# 代码规范：RaccoonCal iOS

## 语言与工具

- Swift 5.9+，SwiftUI
- SwiftLint（可选，`.swiftlint.yml` 配置）
- Xcode 内置格式化（`Ctrl + I` 重新缩进）

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类型（struct/class/enum/protocol） | PascalCase | `FoodRecord`, `PetMood` |
| 变量/函数/属性 | camelCase | `totalCalories`, `refreshStatus()` |
| 常量 | camelCase（Swift 惯例） | `maxHp`, `baseURL` |
| 文件 | PascalCase，与主类型同名 | `HomeView.swift`, `GamificationManager.swift` |

## 数据模型

```swift
// ✅ 用 struct + Codable，字段名与服务端 JSON 一致（camelCase）
struct FoodRecord: Codable, Identifiable {
    let id: Int
    let foodName: String
    let calories: Double
    let mealType: String
    let recordedAt: String
}

// ✅ 枚举用 String rawValue，方便 Codable
enum PetMood: String, Codable {
    case happy, satisfied, normal, hungry, sad, missing
}
```

## View 规范

```swift
// ✅ 小 View 拆分为独立组件，避免单个 View 超过 150 行
struct CalorieRingView: View {
    let current: Double
    let target: Double

    private var progress: Double {
        min(current / max(target, 1), 1.0)  // clamp 到 [0, 1]
    }

    var body: some View {
        ZStack {
            Circle().stroke(AppTheme.Colors.surface, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress >= 1 ? AppTheme.Colors.warning : AppTheme.Colors.primary, lineWidth: 12)
                .rotationEffect(.degrees(-90))
        }
    }
}

// ✅ 复杂 body 用 @ViewBuilder 拆分子方法
private var headerSection: some View { ... }
private var mealListSection: some View { ... }
```

## Service 规范

```swift
// ✅ ObservableObject + @Published，@MainActor 保证主线程更新
@MainActor
class GamificationManager: ObservableObject {
    @Published var status: GamificationStatus?

    func refreshStatus() async throws {
        status = try await APIService.shared.getGamificationStatus()
    }
}

// ✅ 单例用 static let shared
class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
}
```

## 异步规范

```swift
// ✅ 用 async/await，不用 completion handler
func recognizeFood(imageData: Data) async throws -> FoodRecognitionResult {
    return try await APIService.shared.recognizeFood(imageData: imageData)
}

// ✅ View 中用 .task {} 处理异步，自动绑定 View 生命周期
.task {
    try? await viewModel.load()
}

// ✅ 并发请求用 async let
async let status = APIService.shared.getGamificationStatus()
async let tasks = APIService.shared.getDailyTasks()
let (s, t) = try await (status, tasks)
```

## 错误处理

```swift
// ✅ 定义统一错误类型
enum APIError: LocalizedError {
    case unauthorized
    case networkError(Error)
    case decodingError(Error)
    case serverError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "登录已过期，请重新登录"
        case .networkError: return "网络连接失败，请检查网络"
        case .serverError(_, let msg): return msg
        default: return "请求失败，请稍后重试"
        }
    }
}

// ✅ 401 自动登出
if case .unauthorized = error {
    UserManager.shared.logout()
}
```

## AppTheme 使用

```swift
// ✅ 所有颜色/字体/间距通过 AppTheme 引用，不硬编码
Text("今日卡路里")
    .font(AppTheme.Fonts.body)
    .foregroundColor(AppTheme.Colors.textSecondary)

// ❌ 不硬编码
Text("今日卡路里")
    .font(.system(size: 14))
    .foregroundColor(Color(hex: "#757575"))
```

## 注释规范

```swift
/// 计算浣熊心情，与服务端 calcPetMood 逻辑保持一致
/// - Parameters:
///   - calories: 当日已摄入卡路里
///   - target: 每日卡路里目标
///   - mealCount: 当日已记录餐次数
///   - streakDays: 当前连续打卡天数（0 表示今日未打卡）
func calcPetMood(calories: Double, target: Double, mealCount: Int, streakDays: Int) -> PetMood

// 解释为什么，不解释做什么
// 注册前先取消旧通知，确保同类通知每天最多一条
cancelNotification(id: NotificationID.dailyCheckin)
```

## 导入顺序

```swift
// 1. Swift 标准库（通常不需要显式导入）
// 2. Apple 框架
import SwiftUI
import AVFoundation
import UserNotifications

// 3. 第三方库（如有）
import SwiftCheck
```
