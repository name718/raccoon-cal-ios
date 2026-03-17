# RaccoonCal iOS

浣熊卡路里 iOS 原生应用。拍照识别食物卡路里，结合游戏化宠物养成系统。

## 技术栈

- Swift 5.9+ / SwiftUI / iOS 15+
- AVFoundation（相机）
- PHPickerViewController（相册）
- UNUserNotificationCenter（本地通知）
- URLSession + Bearer JWT（网络请求）

## 项目结构

```
RaccoonCal/
├── App/
│   └── RaccoonCalApp.swift        # 应用入口
├── Models/
│   ├── APIModels.swift            # 基础 API 模型
│   ├── GamificationModels.swift   # XP/等级/HP/Streak
│   ├── FoodModels.swift           # 食物识别/记录
│   ├── PetModels.swift            # 浣熊宠物
│   ├── TaskModels.swift           # 每日任务
│   ├── AchievementModels.swift    # 成就徽章
│   └── LeagueModels.swift         # 联盟排行榜
├── Services/
│   ├── APIService.swift           # 网络请求封装
│   ├── UserManager.swift          # 用户状态管理
│   ├── GamificationManager.swift  # 游戏化状态管理
│   └── NotificationManager.swift  # 本地通知管理
├── Views/
│   ├── Auth/                      # 登录/注册/Onboarding
│   ├── Tabs/                      # 主 Tab 框架
│   ├── Home/                      # 首页今日概览
│   ├── Camera/                    # 拍照识别
│   ├── Record/                    # 饮食历史
│   ├── Pet/                       # 浣熊养成
│   ├── Profile/                   # 个人资料
│   └── Components/                # 共享 UI 组件
├── Theme/
│   └── AppTheme.swift             # 颜色/字体/间距常量
└── Assets.xcassets/               # 图片资源
```

## 快速开始

```bash
git clone https://github.com/name718/raccoon-cal.git
cd raccoon-cal/raccoon-cal-app
open RaccoonCal.xcodeproj
```

选择模拟器或真机，`Cmd + R` 运行。

## 环境要求

- Xcode 15+
- iOS 15.0+ 部署目标
- Swift 5.9+

## 服务端

本 App 依赖 `raccoon-cal-server`，确保服务端已启动并在 `APIService.swift` 中配置正确的 `baseURL`。

## 文档

- [技术设计文档](docs/TECH_DESIGN.md)
- [开发指南](docs/DEVELOPMENT.md)
- [代码规范](docs/CODE_STYLE.md)
- [编辑器配置](docs/EDITOR_SETUP.md)
- [API 接口文档](../raccoon-cal-server/docs/API.md)
