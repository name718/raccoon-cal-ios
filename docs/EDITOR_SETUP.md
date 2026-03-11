# 编辑器配置指南

## VSCode 设置

### 必需插件

项目已配置推荐插件列表（`.vscode/extensions.json`），打开项目时 VSCode 会提示安装：

1. **ESLint** - 代码检查
2. **Prettier** - 代码格式化
3. **TypeScript** - TypeScript 支持
4. **React Native Tools** - React Native 开发工具
5. **ES7+ React/Redux/React-Native snippets** - 代码片段
6. **MongoDB for VS Code** - MongoDB 数据库管理
7. **Error Lens** - 行内错误提示
8. **Path Intellisense** - 路径智能提示
9. **IntelliCode** - AI 辅助代码补全
10. **GitLens** - Git 增强工具
11. **Todo Tree** - TODO 注释高亮

### 自动安装插件

打开项目后，VSCode 右下角会弹出提示：

```
This workspace has extension recommendations.
```

点击 "Install All" 即可自动安装所有推荐插件。

或者手动安装：

1. 按 `Cmd+Shift+P` (macOS) 或 `Ctrl+Shift+P` (Windows/Linux)
2. 输入 "Extensions: Show Recommended Extensions"
3. 点击安装按钮

## 自动格式化配置

### 保存时自动格式化

项目已配置保存时自动格式化（`.vscode/settings.json`）：

```json
{
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  }
}
```

### 工作原理

1. **保存文件时**：
   - Prettier 自动格式化代码
   - ESLint 自动修复可修复的问题

2. **粘贴代码时**：
   - 自动格式化粘贴的代码

3. **手动格式化**：
   - macOS: `Shift+Option+F`
   - Windows/Linux: `Shift+Alt+F`

## 代码检查配置

### ESLint 规则

项目使用 ESLint 进行代码检查（`.eslintrc.js`）：

- **TypeScript 规则**：类型检查、未使用变量检查
- **React 规则**：Hooks 规则、组件规范
- **React Native 规则**：样式规范、性能优化
- **Prettier 集成**：格式化规则

### 运行 Lint

```bash
# 检查所有代码
pnpm lint

# 自动修复问题
pnpm lint:fix

# 只检查特定包
pnpm --filter server lint
pnpm --filter mobile lint
```

### VSCode 中的 Lint

- 错误和警告会在编辑器中实时显示
- 红色波浪线：错误
- 黄色波浪线：警告
- 蓝色波浪线：信息提示

## Prettier 配置

### 格式化规则

项目使用 Prettier 统一代码风格（`.prettierrc`）：

```json
{
  "semi": true, // 使用分号
  "trailingComma": "es5", // ES5 兼容的尾逗号
  "singleQuote": true, // 使用单引号
  "printWidth": 80, // 每行最大 80 字符
  "tabWidth": 2, // 缩进 2 空格
  "arrowParens": "avoid" // 箭头函数参数省略括号
}
```

### 手动格式化

```bash
# 格式化所有文件
pnpm format

# 检查格式（不修改）
pnpm prettier --check "**/*.{js,jsx,ts,tsx,json,md}"
```

## Git Hooks

### Pre-commit Hook

提交代码前自动运行：

1. **Lint-staged**：只检查暂存的文件
2. **ESLint**：修复代码问题
3. **Prettier**：格式化代码

如果检查失败，提交会被阻止。

### Commit Message Hook

提交信息必须符合 Conventional Commits 规范：

```bash
# 正确的提交信息
git commit -m "feat: 添加食物识别功能"
git commit -m "fix: 修复浣熊动画卡顿"
git commit -m "docs: 更新 API 文档"

# 错误的提交信息（会被拒绝）
git commit -m "update code"
git commit -m "fix bug"
```

### 提交类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建工具或辅助工具的变动

### 跳过 Hooks（不推荐）

```bash
# 跳过 pre-commit hook
git commit --no-verify -m "message"

# 跳过 commit-msg hook
git commit --no-verify -m "message"
```

## EditorConfig

项目使用 EditorConfig 统一编辑器配置（`.editorconfig`）：

- 字符集：UTF-8
- 换行符：LF (Unix 风格)
- 缩进：2 空格
- 文件末尾：自动添加空行
- 行尾空格：自动删除

大多数编辑器会自动识别 EditorConfig 配置。

## TypeScript 配置

### 路径别名

项目配置了路径别名，可以使用 `@/` 导入：

```typescript
// 不推荐
import { FoodCard } from '../../../components/food/FoodCard';

// 推荐
import { FoodCard } from '@/components/food/FoodCard';
```

### 自动导入

VSCode 会自动建议导入：

1. 输入组件或函数名
2. 选择自动导入建议
3. VSCode 自动添加 import 语句

### 类型检查

```bash
# 检查类型错误
pnpm --filter server tsc --noEmit
pnpm --filter mobile tsc --noEmit
```

## 调试配置

### 调试服务端

1. 按 `F5` 或点击调试面板的 "Debug Server"
2. 在代码中设置断点
3. 请求 API 触发断点

### 调试移动端

1. 启动 Metro bundler: `pnpm dev:mobile`
2. 启动模拟器或真机
3. 按 `F5` 选择 "Run iOS" 或 "Run Android"
4. 在代码中设置断点

### 调试测试

1. 按 `F5` 选择 "Debug Jest Tests"
2. 在测试文件中设置断点
3. 测试运行时会在断点处暂停

## 常用快捷键

### 代码编辑

- `Cmd+Shift+P` / `Ctrl+Shift+P`: 命令面板
- `Shift+Option+F` / `Shift+Alt+F`: 格式化文档
- `Cmd+.` / `Ctrl+.`: 快速修复
- `F2`: 重命名符号
- `Cmd+D` / `Ctrl+D`: 选择下一个匹配项

### 导航

- `Cmd+P` / `Ctrl+P`: 快速打开文件
- `Cmd+Shift+O` / `Ctrl+Shift+O`: 跳转到符号
- `F12`: 跳转到定义
- `Shift+F12`: 查找所有引用
- `Cmd+Click` / `Ctrl+Click`: 跳转到定义

### 调试

- `F5`: 开始调试
- `F9`: 切换断点
- `F10`: 单步跳过
- `F11`: 单步进入
- `Shift+F11`: 单步跳出

## 任务运行

### 运行任务

1. 按 `Cmd+Shift+P` / `Ctrl+Shift+P`
2. 输入 "Tasks: Run Task"
3. 选择要运行的任务：
   - Install Dependencies
   - Lint / Lint Fix
   - Format Code
   - Run Tests
   - Build All
   - Start Server
   - Start Mobile
   - Clean

### 快捷运行

- `Cmd+Shift+B` / `Ctrl+Shift+B`: 运行默认构建任务
- `Cmd+Shift+T` / `Ctrl+Shift+T`: 运行默认测试任务

## 问题排查

### ESLint 不工作

1. 检查是否安装了 ESLint 插件
2. 重启 ESLint 服务器：
   - `Cmd+Shift+P` / `Ctrl+Shift+P`
   - 输入 "ESLint: Restart ESLint Server"

### Prettier 不工作

1. 检查是否安装了 Prettier 插件
2. 确认 Prettier 是默认格式化工具：
   - 右键点击文件
   - "Format Document With..."
   - 选择 "Prettier - Code formatter"
   - 勾选 "Configure Default Formatter"

### 自动格式化不生效

1. 检查 `.vscode/settings.json` 配置
2. 确认 `editor.formatOnSave` 为 `true`
3. 重启 VSCode

### Git Hooks 不工作

```bash
# 重新安装 Husky
pnpm prepare

# 检查 hooks 权限
chmod +x .husky/pre-commit
chmod +x .husky/commit-msg
```

### TypeScript 类型错误

```bash
# 清除缓存
rm -rf node_modules
rm -rf packages/*/node_modules
pnpm install

# 重启 TypeScript 服务器
# Cmd+Shift+P / Ctrl+Shift+P
# "TypeScript: Restart TS Server"
```

## 团队协作建议

1. **统一编辑器配置**：所有团队成员使用相同的 VSCode 配置
2. **安装推荐插件**：确保所有必需插件已安装
3. **遵循代码规范**：不要禁用 ESLint 规则或跳过 Git Hooks
4. **定期更新依赖**：保持工具链版本一致
5. **代码审查**：关注代码风格和规范

## 其他编辑器

### WebStorm / IntelliJ IDEA

1. 启用 ESLint：
   - Settings → Languages & Frameworks → JavaScript → Code Quality Tools →
     ESLint
   - 勾选 "Automatic ESLint configuration"

2. 启用 Prettier：
   - Settings → Languages & Frameworks → JavaScript → Prettier
   - 勾选 "On save"

3. 导入 EditorConfig：
   - 自动识别 `.editorconfig` 文件

### Vim / Neovim

安装插件：

- `dense-analysis/ale` - ESLint 集成
- `prettier/vim-prettier` - Prettier 集成
- `editorconfig/editorconfig-vim` - EditorConfig 支持

### Sublime Text

安装插件：

- `SublimeLinter-eslint` - ESLint 集成
- `JsPrettier` - Prettier 集成
- `EditorConfig` - EditorConfig 支持

这个配置确保了团队成员使用统一的代码风格和开发环境，提高代码质量和协作效率。
