# 开发指南

## 环境要求

### 系统要求
- Node.js >= 18.0.0
- pnpm >= 8.0.0
- React Native CLI
- Android Studio (Android 开发)
- Xcode (iOS 开发)

### 数据库要求
- MongoDB >= 5.0
- Redis >= 6.0

## 项目设置

### 1. 克隆项目
```bash
git clone https://github.com/your-org/raccoon-cal.git
cd raccoon-cal
```

### 2. 安装依赖
```bash
# 安装所有包的依赖
pnpm install
```

### 3. 环境配置

#### 服务端环境变量
创建 `packages/server/.env` 文件：
```env
# 服务配置
NODE_ENV=development
PORT=3000
API_VERSION=v1

# 数据库配置
MONGODB_URI=mongodb://localhost:27017/raccooncal
REDIS_URL=redis://localhost:6379

# JWT配置
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# 外部API配置
LOGMEAL_API_KEY=your-logmeal-api-key
LOGMEAL_API_URL=https://api.logmeal.es

# 文件上传配置
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_S3_BUCKET=raccoon-cal-images
AWS_REGION=us-east-1

# 推送通知
FCM_SERVER_KEY=your-fcm-server-key

# 日志配置
LOG_LEVEL=debug
```

#### 移动端环境变量
创建 `packages/mobile/.env` 文件：
```env
# API配置
API_BASE_URL=http://localhost:3000/api/v1
WS_BASE_URL=ws://localhost:3000/v1/ws

# 第三方服务
SENTRY_DSN=your-sentry-dsn
ANALYTICS_KEY=your-analytics-key

# 构建配置
BUNDLE_ID=com.raccooncal.app
APP_NAME=RaccoonCal
```

### 4. 数据库设置

#### MongoDB 初始化
```bash
# 启动 MongoDB
mongod

# 创建数据库和初始数据
cd packages/server
pnpm run db:seed
```

#### Redis 启动
```bash
# macOS (使用 Homebrew)
brew services start redis

# Linux
sudo systemctl start redis

# Docker
docker run -d -p 6379:6379 redis:alpine
```

## 开发流程

### 1. 启动开发环境

#### 启动所有服务
```bash
# 根目录执行，会同时启动服务端和移动端
pnpm dev
```

#### 单独启动服务
```bash
# 只启动服务端
pnpm dev:server

# 只启动移动端
pnpm dev:mobile

# 启动 iOS 模拟器
pnpm dev:ios

# 启动 Android 模拟器
pnpm dev:android
```

### 2. 代码结构说明

#### 服务端结构 (`packages/server/`)
```
src/
├── controllers/        # 控制器层
│   ├── auth.controller.js
│   ├── food.controller.js
│   ├── raccoon.controller.js
│   └── social.controller.js
├── models/            # 数据模型
│   ├── User.js
│   ├── FoodRecord.js
│   └── RaccoonState.js
├── routes/            # 路由定义
│   ├── auth.routes.js
│   ├── food.routes.js
│   └── index.js
├── services/          # 业务逻辑层
│   ├── aiRecognition.service.js
│   ├── gamification.service.js
│   └── notification.service.js
├── middleware/        # 中间件
│   ├── auth.middleware.js
│   ├── validation.middleware.js
│   └── rateLimit.middleware.js
├── utils/            # 工具函数
│   ├── logger.js
│   ├── response.js
│   └── constants.js
└── app.js            # 应用入口
```

#### 移动端结构 (`packages/mobile/`)
```
src/
├── components/        # 通用组件
│   ├── common/       # 基础组件
│   ├── raccoon/      # 浣熊相关组件
│   └── food/         # 食物相关组件
├── screens/          # 页面组件
│   ├── auth/         # 认证页面
│   ├── home/         # 首页
│   ├── camera/       # 拍照页面
│   ├── raccoon/      # 浣熊养成页面
│   └── profile/      # 个人中心
├── services/         # API服务
│   ├── api.js        # API客户端
│   ├── auth.service.js
│   └── food.service.js
├── store/            # 状态管理
│   ├── slices/       # Redux slices
│   └── store.js      # Store配置
├── navigation/       # 导航配置
├── utils/           # 工具函数
├── types/           # TypeScript类型
└── App.tsx          # 应用入口
```

### 3. 开发规范

#### 代码风格
项目使用 ESLint + Prettier 进行代码格式化：
```bash
# 检查代码风格
pnpm lint

# 自动修复
pnpm lint:fix

# 格式化代码
pnpm format
```

#### Git 提交规范
使用 Conventional Commits 规范：
```bash
# 功能开发
git commit -m "feat: 添加食物识别功能"

# Bug修复
git commit -m "fix: 修复浣熊动画卡顿问题"

# 文档更新
git commit -m "docs: 更新API文档"

# 样式调整
git commit -m "style: 调整首页布局"

# 重构代码
git commit -m "refactor: 重构用户认证逻辑"

# 性能优化
git commit -m "perf: 优化图片加载性能"

# 测试相关
git commit -m "test: 添加食物识别单元测试"
```

#### TypeScript 使用
项目全面使用 TypeScript，确保类型安全：
```typescript
// 定义接口
interface FoodRecord {
  id: string;
  foodName: string;
  calories: number;
  nutrition: NutritionInfo;
  recordedAt: Date;
}

// 使用泛型
interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: APIError;
}

// 组件Props类型
interface CameraScreenProps {
  navigation: NavigationProp<RootStackParamList>;
  onPhotoTaken: (photo: PhotoResult) => void;
}
```

## 测试

### 1. 单元测试
```bash
# 运行所有测试
pnpm test

# 运行服务端测试
pnpm test:server

# 运行移动端测试
pnpm test:mobile

# 监听模式
pnpm test:watch

# 生成覆盖率报告
pnpm test:coverage
```

### 2. 集成测试
```bash
# 运行集成测试
pnpm test:integration

# 运行E2E测试
pnpm test:e2e
```

### 3. 测试文件结构
```
packages/server/tests/
├── unit/              # 单元测试
│   ├── controllers/
│   ├── services/
│   └── utils/
├── integration/       # 集成测试
│   ├── auth.test.js
│   └── food.test.js
└── fixtures/          # 测试数据

packages/mobile/__tests__/
├── components/        # 组件测试
├── screens/          # 页面测试
├── services/         # 服务测试
└── utils/            # 工具测试
```

## 调试

### 1. 服务端调试
```bash
# 使用 Node.js 调试器
pnpm debug:server

# 使用 VS Code 调试
# 在 .vscode/launch.json 中配置调试选项
```

### 2. 移动端调试

#### React Native Debugger
```bash
# 安装 React Native Debugger
brew install --cask react-native-debugger

# 启动调试器
open "rndebugger://set-debugger-loc?host=localhost&port=8081"
```

#### Flipper 调试
```bash
# 安装 Flipper
brew install --cask flipper

# 在应用中启用 Flipper
# 已在项目中配置，直接使用即可
```

### 3. 日志查看
```bash
# 查看服务端日志
pnpm logs:server

# 查看移动端日志
# iOS
pnpm logs:ios

# Android
pnpm logs:android
```

## 构建和部署

### 1. 构建项目
```bash
# 构建所有包
pnpm build

# 构建服务端
pnpm build:server

# 构建移动端
pnpm build:mobile
```

### 2. 移动端打包

#### Android 打包
```bash
# 生成 APK
cd packages/mobile/android
./gradlew assembleRelease

# 生成 AAB (Google Play)
./gradlew bundleRelease
```

#### iOS 打包
```bash
# 使用 Xcode 或命令行
cd packages/mobile/ios
xcodebuild -workspace RaccoonCal.xcworkspace -scheme RaccoonCal -configuration Release archive
```

### 3. 服务端部署

#### Docker 部署
```bash
# 构建镜像
docker build -t raccoon-cal-server .

# 运行容器
docker run -d -p 3000:3000 --env-file .env raccoon-cal-server
```

#### 使用 Docker Compose
```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 性能优化

### 1. 服务端优化
- 使用 Redis 缓存频繁查询的数据
- 数据库查询优化和索引建立
- API 响应压缩
- 图片 CDN 加速

### 2. 移动端优化
- 图片懒加载和压缩
- 列表虚拟化
- 状态管理优化
- Bundle 分包

### 3. 监控指标
```bash
# 性能监控
pnpm monitor

# 内存使用分析
pnpm analyze:memory

# Bundle 大小分析
pnpm analyze:bundle
```

## 常见问题

### 1. 环境问题

#### Node.js 版本不匹配
```bash
# 使用 nvm 管理 Node.js 版本
nvm install 18
nvm use 18
```

#### pnpm 安装失败
```bash
# 清除缓存
pnpm store prune

# 重新安装
rm -rf node_modules
pnpm install
```

### 2. 移动端问题

#### Metro 缓存问题
```bash
# 清除 Metro 缓存
pnpm start --reset-cache

# 清除所有缓存
pnpm clean
```

#### Android 构建失败
```bash
# 清理 Android 构建
cd packages/mobile/android
./gradlew clean

# 重新构建
./gradlew assembleDebug
```

#### iOS 构建失败
```bash
# 清理 iOS 构建
cd packages/mobile/ios
xcodebuild clean

# 重新安装 Pods
cd ..
npx pod-install
```

### 3. 数据库问题

#### MongoDB 连接失败
```bash
# 检查 MongoDB 状态
brew services list | grep mongodb

# 重启 MongoDB
brew services restart mongodb-community
```

#### Redis 连接失败
```bash
# 检查 Redis 状态
redis-cli ping

# 重启 Redis
brew services restart redis
```

## 开发工具推荐

### 1. VS Code 插件
- ES7+ React/Redux/React-Native snippets
- Prettier - Code formatter
- ESLint
- TypeScript Importer
- React Native Tools
- MongoDB for VS Code

### 2. Chrome 插件
- React Developer Tools
- Redux DevTools
- JSON Viewer

### 3. 移动端工具
- React Native Debugger
- Flipper
- Android Studio
- Xcode

## 贡献指南

### 1. 分支管理
- `main`: 主分支，用于生产环境
- `develop`: 开发分支，用于集成功能
- `feature/*`: 功能分支
- `hotfix/*`: 热修复分支

### 2. Pull Request 流程
1. 从 `develop` 创建功能分支
2. 完成开发并通过测试
3. 提交 Pull Request 到 `develop`
4. 代码审查通过后合并
5. 定期将 `develop` 合并到 `main`

### 3. 代码审查清单
- [ ] 代码符合项目规范
- [ ] 包含必要的测试
- [ ] 文档已更新
- [ ] 性能影响评估
- [ ] 安全性检查

这个开发指南为浣熊卡路里项目提供了完整的开发环境设置和工作流程说明。