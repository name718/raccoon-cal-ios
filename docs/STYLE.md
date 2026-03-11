# 浣熊卡路里 UI 设计规范

## 1. 整体设计风格定位

在开始前，先明确统一的设计语言，让所有页面保持一致的品牌感：

### 设计风格关键词
- **温暖可爱（Warm & Cute）** - 营造亲和力，降低用户对卡路里管理的焦虑
- **圆润柔和（Soft & Rounded）** - 所有元素采用圆角设计，传达友好感
- **森林系配色（Forest-inspired colors）** - 呼应浣熊的自然栖息地
- **现代极简（Modern Minimalist）** - 避免复杂界面，专注核心功能
- **游戏化元素（Gamification elements）** - 通过视觉反馈增强互动乐趣

## 2. 色彩系统

### 2.1 主色盘
```css
/* 主色 - 温暖的琥珀橙 */
--primary-color: #FFB347;
--primary-light: #FFD4A3;
--primary-dark: #E6A042;

/* 辅色 - 清新草绿 */
--secondary-color: #7CB342;
--secondary-light: #A5D6A7;
--secondary-dark: #689F38;

/* 背景色 - 奶油白 */
--background-primary: #FFF9F0;
--background-secondary: #F5F5F0;

/* 点缀色 - 珊瑚粉 */
--accent-color: #FF6B6B;
--accent-light: #FF9999;
```

### 2.2 功能色彩
```css
/* 成功状态 */
--success-color: #4CAF50;
--success-light: #C8E6C9;

/* 警告状态 */
--warning-color: #FF9800;
--warning-light: #FFE0B2;

/* 错误状态 */
--error-color: #F44336;
--error-light: #FFCDD2;

/* 信息状态 */
--info-color: #2196F3;
--info-light: #BBDEFB;

/* 文字颜色 */
--text-primary: #2E2E2E;
--text-secondary: #757575;
--text-disabled: #BDBDBD;
--text-white: #FFFFFF;
```

### 2.3 渐变色
```css
/* 主要渐变 - 用于按钮和重要元素 */
--gradient-primary: linear-gradient(135deg, #FFB347 0%, #FF8A65 100%);

/* 次要渐变 - 用于卡片背景 */
--gradient-secondary: linear-gradient(135deg, #7CB342 0%, #8BC34A 100%);

/* 背景渐变 - 用于页面背景 */
--gradient-background: linear-gradient(180deg, #FFF9F0 0%, #F0F8E8 100%);
```

## 3. 字体系统

### 3.1 字体族
```css
/* 主字体 - 系统字体优先 */
--font-family-primary: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif;

/* 数字字体 - 用于卡路里显示 */
--font-family-numeric: 'SF Pro Display', -apple-system, BlinkMacSystemFont, sans-serif;

/* 装饰字体 - 用于标题和特殊文案 */
--font-family-display: 'Nunito', -apple-system, BlinkMacSystemFont, sans-serif;
```

### 3.2 字体大小
```css
/* 标题字体 */
--font-size-h1: 28px;    /* 页面主标题 */
--font-size-h2: 24px;    /* 区块标题 */
--font-size-h3: 20px;    /* 卡片标题 */
--font-size-h4: 18px;    /* 小标题 */

/* 正文字体 */
--font-size-body-large: 16px;   /* 重要正文 */
--font-size-body: 14px;         /* 普通正文 */
--font-size-body-small: 12px;   /* 辅助信息 */

/* 特殊字体 */
--font-size-caption: 10px;      /* 说明文字 */
--font-size-button: 16px;       /* 按钮文字 */
--font-size-numeric-large: 32px; /* 大数字显示 */
--font-size-numeric: 24px;      /* 普通数字 */
```

### 3.3 字重
```css
--font-weight-light: 300;
--font-weight-regular: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;
```

## 4. 间距系统

### 4.1 基础间距
```css
/* 基础单位 4px */
--spacing-xs: 4px;
--spacing-sm: 8px;
--spacing-md: 16px;
--spacing-lg: 24px;
--spacing-xl: 32px;
--spacing-xxl: 48px;

/* 页面级间距 */
--spacing-page-horizontal: 20px;
--spacing-page-vertical: 24px;

/* 组件间距 */
--spacing-component: 16px;
--spacing-section: 32px;
```

### 4.2 圆角系统
```css
--border-radius-xs: 4px;    /* 小元素 */
--border-radius-sm: 8px;    /* 按钮、输入框 */
--border-radius-md: 12px;   /* 卡片 */
--border-radius-lg: 16px;   /* 大卡片 */
--border-radius-xl: 24px;   /* 模态框 */
--border-radius-full: 50%;  /* 圆形元素 */
```

## 5. 组件设计规范

### 5.1 按钮设计
```css
/* 主要按钮 */
.button-primary {
  background: var(--gradient-primary);
  color: var(--text-white);
  border-radius: var(--border-radius-sm);
  padding: 12px 24px;
  font-size: var(--font-size-button);
  font-weight: var(--font-weight-medium);
  box-shadow: 0 2px 8px rgba(255, 179, 71, 0.3);
}

/* 次要按钮 */
.button-secondary {
  background: transparent;
  color: var(--primary-color);
  border: 2px solid var(--primary-color);
  border-radius: var(--border-radius-sm);
  padding: 10px 22px;
}

/* 浮动操作按钮 */
.fab {
  width: 56px;
  height: 56px;
  border-radius: var(--border-radius-full);
  background: var(--gradient-primary);
  box-shadow: 0 4px 16px rgba(255, 179, 71, 0.4);
}
```

### 5.2 卡片设计
```css
.card {
  background: var(--background-primary);
  border-radius: var(--border-radius-md);
  padding: var(--spacing-md);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  border: 1px solid rgba(255, 179, 71, 0.1);
}

.card-elevated {
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
  transform: translateY(-2px);
}
```

### 5.3 输入框设计
```css
.input {
  background: var(--background-primary);
  border: 2px solid rgba(124, 179, 66, 0.2);
  border-radius: var(--border-radius-sm);
  padding: 12px 16px;
  font-size: var(--font-size-body);
  color: var(--text-primary);
}

.input:focus {
  border-color: var(--secondary-color);
  box-shadow: 0 0 0 3px rgba(124, 179, 66, 0.1);
}
```

## 6. 图标系统

### 6.1 图标风格
- **风格**：线性图标为主，填充图标为辅
- **粗细**：2px 线宽，保持一致性
- **尺寸**：16px、20px、24px、32px 四个标准尺寸
- **颜色**：跟随文字颜色，重要操作使用主色

### 6.2 常用图标
```
相机：camera
食物：restaurant
浣熊：pets（自定义）
任务：assignment
排行榜：leaderboard
设置：settings
分享：share
收藏：favorite
```

## 7. 动画与交互

### 7.1 动画原则
- **缓动函数**：`cubic-bezier(0.4, 0.0, 0.2, 1)` - Material Design 标准
- **持续时间**：
  - 微交互：150ms
  - 页面切换：300ms
  - 复杂动画：500ms
- **浣熊动画**：使用 Lottie 实现，保持 60fps 流畅度

### 7.2 交互反馈
```css
/* 点击反馈 */
.touchable {
  transition: transform 150ms ease, opacity 150ms ease;
}

.touchable:active {
  transform: scale(0.95);
  opacity: 0.8;
}

/* 悬浮效果 */
.hoverable:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
}
```

## 8. 布局规范

### 8.1 网格系统
- **容器最大宽度**：414px（iPhone 12 Pro 标准）
- **列数**：12列网格系统
- **间距**：16px 列间距
- **边距**：20px 页面边距

### 8.2 响应式断点
```css
/* 小屏手机 */
@media (max-width: 375px) { }

/* 标准手机 */
@media (min-width: 376px) and (max-width: 414px) { }

/* 大屏手机 */
@media (min-width: 415px) { }
```

## 9. 特殊元素设计

### 9.1 浣熊角色展示
- **尺寸**：主页 120x120px，详情页 200x200px
- **背景**：圆形渐变背景，使用主色渐变
- **阴影**：柔和阴影增强立体感
- **动画**：待机、开心、困惑、睡觉等状态动画

### 9.2 卡路里数字显示
```css
.calorie-display {
  font-family: var(--font-family-numeric);
  font-size: var(--font-size-numeric-large);
  font-weight: var(--font-weight-bold);
  color: var(--primary-color);
  text-shadow: 0 2px 4px rgba(255, 179, 71, 0.2);
}
```

### 9.3 进度条设计
```css
.progress-bar {
  height: 8px;
  background: rgba(124, 179, 66, 0.2);
  border-radius: var(--border-radius-full);
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: var(--gradient-secondary);
  border-radius: var(--border-radius-full);
  transition: width 300ms ease;
}
```

## 10. 深色模式适配

### 10.1 深色模式色彩
```css
@media (prefers-color-scheme: dark) {
  :root {
    --background-primary: #1A1A1A;
    --background-secondary: #2D2D2D;
    --text-primary: #FFFFFF;
    --text-secondary: #B3B3B3;
    --primary-color: #FFD4A3;
    --secondary-color: #A5D6A7;
  }
}
```

## 11. 无障碍设计

### 11.1 对比度要求
- 普通文字：至少 4.5:1
- 大文字（18px+）：至少 3:1
- 图标和按钮：至少 3:1

### 11.2 触摸目标
- 最小触摸区域：44x44px
- 重要按钮推荐：48x48px 或更大

这套 UI 规范确保了浣熊卡路里应用的视觉一致性和用户体验，体现了温暖可爱的品牌特色，同时保持了现代应用的专业性。