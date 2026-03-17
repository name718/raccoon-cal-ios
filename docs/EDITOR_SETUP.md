# 编辑器配置：RaccoonCal iOS

## Xcode 配置

### 推荐设置

`Xcode → Settings → Text Editing`：

- 勾选 "Automatically trim trailing whitespace"
- 勾选 "Including whitespace-only lines"
- Line wrapping：80 列参考线（可选）

`Xcode → Settings → Indentation`：

- Indent using: Spaces
- Tab width: 4
- Indent width: 4

### 代码片段

常用代码片段可通过 `Cmd + Shift + L` 打开 Library 搜索。

## VS Code（辅助编辑）

如果用 VS Code 查看/编辑 Swift 文件：

- Swift for Visual Studio Code（官方插件）
- Error Lens
- GitLens

## SwiftLint（可选）

```bash
# 安装
brew install swiftlint

# 在项目根目录创建 .swiftlint.yml
# 运行检查
swiftlint lint

# 自动修复
swiftlint --fix
```

推荐 `.swiftlint.yml` 配置：

```yaml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - explicit_init
line_length: 120
type_body_length:
  warning: 300
  error: 400
```

## Git Hooks

项目使用 Conventional Commits，提交信息格式：

```
feat | fix | docs | style | refactor | perf | test | chore: 描述
```

示例：
```bash
git commit -m "feat: 实现 CameraView 拍照识别流程"
git commit -m "fix: 修复 HP 心形图标数量计算错误"
git commit -m "refactor: 提取 RaccoonMoodView 为独立组件"
```

## 常用快捷键

| 操作 | 快捷键 |
|------|--------|
| 运行 | `Cmd + R` |
| 停止 | `Cmd + .` |
| 清理构建 | `Cmd + Shift + K` |
| 重新缩进 | `Ctrl + I` |
| 跳转到定义 | `Cmd + Click` |
| 查找所有引用 | `Shift + Cmd + Option + F` |
| 重命名符号 | 右键 → Refactor → Rename |
| 打开 Preview | `Cmd + Option + Return` |
| 刷新 Preview | `Cmd + Option + P` |
| 运行测试 | `Cmd + U` |
| 运行单个测试 | 点击测试方法左侧菱形图标 |

## Simulator 技巧

```bash
# 列出可用模拟器
xcrun simctl list devices

# 重置模拟器（清除所有数据）
xcrun simctl erase all

# 截图
xcrun simctl io booted screenshot screenshot.png
```
