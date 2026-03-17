# 开发指南：RaccoonCal iOS

## 环境要求

- macOS 13+
- Xcode 15+
- iOS 15.0+ 部署目标
- Swift 5.9+

## 初始化

```bash
git clone https://github.com/name718/raccoon-cal.git
cd raccoon-cal/raccoon-cal-app
open RaccoonCal.xcodeproj
```

在 `APIService.swift` 中配置服务端地址：

```swift
private let baseURL = "http://localhost:3000/api"  // 开发环境
```

确保 `raccoon-cal-server` 已启动（参考服务端开发指南）。

## 运行

- 选择模拟器或真机
- `Cmd + R` 运行
- `Cmd + Shift + K` 清理构建缓存

## 项目配置

### Info.plist 权限声明

```xml
<!-- 相机 -->
<key>NSCameraUsageDescription</key>
<string>用于拍照识别食物卡路里</string>

<!-- 相册 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>用于从相册选取食物图片</string>
```

### 本地通知

首次进入主界面时请求通知权限：

```swift
await NotificationManager.shared.requestPermission()
```

## 开发规范

### 新增 View

1. 在对应目录创建 `XxxView.swift`
2. 通过 `@EnvironmentObject` 获取 `UserManager` / `GamificationManager`
3. 在 `onAppear` 中拉取数据，`task {}` 处理 async 调用
4. 错误状态用 `@State var errorMessage: String?` + `.alert` 展示

```swift
struct HomeView: View {
    @EnvironmentObject var gamificationManager: GamificationManager
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            // ...
        }
        .task {
            do {
                try await gamificationManager.refreshStatus()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .alert("错误", isPresented: .constant(errorMessage != nil)) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
```

### 新增 API 接口

在 `APIService.swift` 中添加方法：

```swift
func getFoodRecords(date: String) async throws -> [MealGroup] {
    return try await request("/food/records?date=\(date)")
}
```

### 新增数据模型

在对应 `Models/XxxModels.swift` 中添加 `Codable` 结构体，字段名使用 `camelCase`，与服务端 JSON 保持一致（服务端已配置 `camelCase` 序列化）。

## 调试

### 网络请求

在 `APIService.swift` 的 `request` 方法中已有 `print` 日志，Xcode Console 可查看请求/响应详情。

真机调试时用 Charles 或 Proxyman 抓包，需在设备安装证书并配置代理。

### 通知调试

```swift
// 查看待发送通知
UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    print(requests.map { $0.identifier })
}
```

### 模拟器限制

- 相机：模拟器无法使用真实相机，测试时用相册选图替代
- 通知：模拟器支持本地通知，但需要 App 在后台才能收到

## 测试

```bash
# 在 Xcode 中运行测试
Cmd + U

# 命令行运行
xcodebuild test -project RaccoonCal.xcodeproj -scheme RaccoonCal -destination 'platform=iOS Simulator,name=iPhone 15'
```

测试文件结构：

```
RaccoonCalTests/
├── Properties/          # 属性测试（SwiftCheck）
│   ├── GamificationPropertyTests.swift
│   └── NotificationPropertyTests.swift
└── Unit/
    ├── GamificationManagerTests.swift
    └── APIServiceTests.swift
```

## Git 提交规范

使用 Conventional Commits：

```bash
git commit -m "feat: 实现 HomeView 卡路里进度条"
git commit -m "fix: 修复相机权限弹窗重复显示"
git commit -m "refactor: 提取 CalorieRingView 为独立组件"
git commit -m "docs: 更新开发指南"
```

## 构建与发布

```bash
# Archive（需配置签名证书）
xcodebuild archive \
  -project RaccoonCal.xcodeproj \
  -scheme RaccoonCal \
  -configuration Release \
  -archivePath RaccoonCal.xcarchive

# 导出 IPA
xcodebuild -exportArchive \
  -archivePath RaccoonCal.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## 常见问题

**模拟器无法连接本地服务端**

确保 `baseURL` 使用 `http://localhost:3000`（模拟器与 Mac 共享网络），真机调试需改为 Mac 的局域网 IP，如 `http://192.168.1.x:3000`。

**Xcode 构建缓存问题**

```
Product → Clean Build Folder（Cmd + Shift + K）
```

**Swift Package 依赖拉取失败**

```
File → Packages → Reset Package Caches
```
