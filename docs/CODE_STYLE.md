# 代码风格指南

## 概述

本项目使用 ESLint + Prettier +
TypeScript 确保代码质量和一致性。所有代码必须通过 lint 检查才能提交。

## 快速开始

### 1. 安装开发环境

```bash
# 运行设置脚本
./scripts/setup-dev.sh

# 或手动安装
pnpm install
pnpm prepare
```

### 2. VSCode 配置

打开项目后，VSCode 会提示安装推荐插件，点击 "Install All" 即可。

必需插件：

- ESLint
- Prettier - Code formatter
- React Native Tools

详细配置请查看 [编辑器配置指南](./EDITOR_SETUP.md)。

### 3. 验证配置

```bash
# 检查代码风格
pnpm lint

# 自动修复问题
pnpm lint:fix

# 格式化代码
pnpm format
```

## 代码规范

### TypeScript 规范

#### 类型定义

```typescript
// ✅ 推荐：使用 interface 定义对象类型
interface User {
  id: string;
  name: string;
  email: string;
}

// ✅ 推荐：使用 type 定义联合类型
type Status = 'active' | 'inactive' | 'pending';

// ❌ 避免：使用 any
const data: any = fetchData(); // 不推荐

// ✅ 推荐：使用具体类型或 unknown
const data: User = fetchData();
const data: unknown = fetchData();
```

#### 类型导入

```typescript
// ✅ 推荐：使用 type 关键字导入类型
import type { User, Status } from './types';
import { fetchUser } from './api';

// ❌ 避免：混合导入
import { User, fetchUser } from './api';
```

#### 函数类型

```typescript
// ✅ 推荐：明确参数和返回值类型
function calculateCalories(food: Food): number {
  return food.protein * 4 + food.carbs * 4 + food.fat * 9;
}

// ✅ 推荐：箭头函数
const formatCalories = (calories: number): string => {
  return `${calories} kcal`;
};

// ✅ 推荐：异步函数
async function fetchFoodData(id: string): Promise<Food> {
  const response = await api.get(`/food/${id}`);
  return response.data;
}
```

### React / React Native 规范

#### 组件定义

```typescript
// ✅ 推荐：函数组件 + TypeScript
interface FoodCardProps {
  food: Food;
  onPress?: () => void;
}

export const FoodCard: React.FC<FoodCardProps> = ({ food, onPress }) => {
  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{food.name}</Text>
      <Text>{food.calories} kcal</Text>
    </TouchableOpacity>
  );
};

// ❌ 避免：类组件（除非必要）
class FoodCard extends React.Component<FoodCardProps> {
  render() {
    return <View>...</View>;
  }
}
```

#### Hooks 使用

```typescript
// ✅ 推荐：正确使用 Hooks
export const FoodList: React.FC = () => {
  // 1. 所有 Hooks 在顶层调用
  const [foods, setFoods] = useState<Food[]>([]);
  const [loading, setLoading] = useState(false);

  // 2. useEffect 依赖项完整
  useEffect(() => {
    fetchFoods();
  }, []); // 空数组表示只在挂载时执行

  // 3. useCallback 优化回调
  const handlePress = useCallback((food: Food) => {
    console.log('Selected:', food.name);
  }, []);

  // 4. useMemo 优化计算
  const totalCalories = useMemo(() => {
    return foods.reduce((sum, food) => sum + food.calories, 0);
  }, [foods]);

  return <View>...</View>;
};

// ❌ 避免：条件调用 Hooks
if (condition) {
  const [state, setState] = useState(); // 错误！
}
```

#### 样式定义

```typescript
// ✅ 推荐：使用 StyleSheet.create
const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#FFF9F0',
  },
  title: {
    fontSize: 24,
    fontWeight: '600',
    color: '#2E2E2E',
  },
});

// ❌ 避免：内联样式（性能差）
<View style={{ flex: 1, padding: 16 }}>

// ⚠️ 警告：使用主题常量
import { colors, spacing } from '@/theme';

const styles = StyleSheet.create({
  container: {
    padding: spacing.md,
    backgroundColor: colors.background,
  },
});
```

### Express / Node.js 规范

#### 控制器

```typescript
// ✅ 推荐：清晰的控制器结构
export class FoodController {
  /**
   * 获取食物列表
   */
  static async getFoods(req: Request, res: Response, next: NextFunction) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const userId = req.user.id;

      const foods = await FoodService.getFoods(userId, { page, limit });

      return ApiResponse.success(res, foods);
    } catch (error) {
      next(error);
    }
  }
}
```

#### 服务层

```typescript
// ✅ 推荐：业务逻辑在服务层
export class FoodService {
  /**
   * 获取用户的食物记录
   */
  static async getFoods(
    userId: string,
    options: PaginationOptions
  ): Promise<PaginatedResult<Food>> {
    const { page, limit } = options;
    const skip = (page - 1) * limit;

    const [foods, total] = await Promise.all([
      FoodRecord.find({ userId })
        .sort({ recordedAt: -1 })
        .skip(skip)
        .limit(limit),
      FoodRecord.countDocuments({ userId }),
    ]);

    return {
      data: foods,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
```

#### 错误处理

```typescript
// ✅ 推荐：自定义错误类
export class NotFoundError extends AppError {
  constructor(resource: string) {
    super('NOT_FOUND', `${resource} not found`, 404);
  }
}

// ✅ 推荐：在服务层抛出错误
if (!food) {
  throw new NotFoundError('Food');
}

// ✅ 推荐：在控制器中捕获错误
try {
  const food = await FoodService.getFood(id);
  return ApiResponse.success(res, food);
} catch (error) {
  next(error); // 传递给错误处理中间件
}
```

### 命名规范

#### 文件命名

```
✅ 推荐：
- FoodCard.tsx          (React 组件)
- FoodCard.styles.ts    (样式文件)
- food.service.ts       (服务)
- food.controller.ts    (控制器)
- food.types.ts         (类型定义)
- formatCalories.ts     (工具函数)
- API_CONSTANTS.ts      (常量)

❌ 避免：
- foodcard.tsx
- Food-Card.tsx
- food_card.tsx
```

#### 变量命名

```typescript
// ✅ 推荐：camelCase
const userName = 'John';
const isLoading = false;
const totalCalories = 1500;

// ✅ 推荐：PascalCase（类、组件、类型）
class FoodService {}
interface UserProfile {}
type Status = 'active' | 'inactive';

// ✅ 推荐：UPPER_SNAKE_CASE（常量）
const MAX_UPLOAD_SIZE = 5 * 1024 * 1024;
const API_BASE_URL = 'https://api.example.com';

// ❌ 避免：不清晰的命名
const data = fetchData();
const temp = calculate();
const x = getValue();
```

#### 函数命名

```typescript
// ✅ 推荐：动词开头，描述性强
function fetchUserData() {}
function calculateTotalCalories() {}
function validateEmail() {}
function handleSubmit() {}

// ✅ 推荐：布尔值用 is/has/can 开头
function isValidEmail() {}
function hasPermission() {}
function canEdit() {}

// ❌ 避免：不清晰的命名
function process() {}
function doIt() {}
function func1() {}
```

### 注释规范

#### JSDoc 注释

```typescript
/**
 * 计算食物的总卡路里
 * @param food - 食物对象
 * @returns 总卡路里数
 */
function calculateCalories(food: Food): number {
  return food.protein * 4 + food.carbs * 4 + food.fat * 9;
}

/**
 * 食物服务类
 * 处理食物相关的业务逻辑
 */
export class FoodService {
  /**
   * 识别食物并保存记录
   * @param imageData - Base64 编码的图片数据
   * @param userId - 用户 ID
   * @returns 食物记录和浣熊点评
   * @throws {ValidationError} 当图片数据无效时
   */
  static async recognizeFood(
    imageData: string,
    userId: string
  ): Promise<FoodRecognitionResult> {
    // 实现...
  }
}
```

#### 行内注释

```typescript
// ✅ 推荐：解释为什么，而不是做什么
// 使用 setTimeout 避免阻塞 UI 线程
setTimeout(() => processLargeData(), 0);

// 临时禁用规则需要说明原因
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const legacyData: any = oldApi.getData(); // 旧 API 返回类型不明确

// ❌ 避免：显而易见的注释
// 设置 loading 为 true
setLoading(true);
```

### 导入顺序

```typescript
// 1. React 相关
import React, { useState, useEffect } from 'react';

// 2. React Native 组件
import { View, Text, StyleSheet } from 'react-native';

// 3. 第三方库
import axios from 'axios';
import { useNavigation } from '@react-navigation/native';

// 4. 项目内部模块（按路径深度排序）
import { FoodCard } from '@/components/food';
import { formatCalories } from '@/utils';
import { colors, spacing } from '@/theme';

// 5. 类型定义
import type { Food, NutritionInfo } from '@/types';

// 6. 样式（如果单独文件）
import styles from './Component.styles';
```

### 代码组织

#### React 组件结构

```typescript
import React, { useState, useEffect, useCallback } from 'react';
import { View, Text } from 'react-native';
import type { ComponentProps } from './types';

/**
 * 组件描述
 */
export const ComponentName: React.FC<ComponentProps> = ({ prop1, prop2 }) => {
  // 1. Hooks
  const [state, setState] = useState<StateType>(initialValue);
  const navigation = useNavigation();

  // 2. 副作用
  useEffect(() => {
    // 副作用逻辑
  }, [dependencies]);

  // 3. 事件处理函数
  const handlePress = useCallback(() => {
    // 处理逻辑
  }, [dependencies]);

  // 4. 计算值
  const computedValue = useMemo(() => {
    return expensiveCalculation(state);
  }, [state]);

  // 5. 条件渲染
  if (loading) {
    return <LoadingSpinner />;
  }

  // 6. 主渲染
  return (
    <View style={styles.container}>
      <Text style={styles.text}>{prop1}</Text>
    </View>
  );
};

// 7. 样式定义
const styles = StyleSheet.create({
  container: {
    padding: 16,
  },
  text: {
    fontSize: 14,
  },
});
```

### 性能优化

```typescript
// ✅ 推荐：使用 React.memo 避免不必要的重渲染
export const FoodCard = React.memo<FoodCardProps>(({ food }) => {
  return <View>...</View>;
});

// ✅ 推荐：使用 useCallback 缓存回调
const handlePress = useCallback(() => {
  navigation.navigate('Detail', { id: food.id });
}, [food.id, navigation]);

// ✅ 推荐：使用 useMemo 缓存计算结果
const totalCalories = useMemo(() => {
  return foods.reduce((sum, food) => sum + food.calories, 0);
}, [foods]);

// ✅ 推荐：FlatList 优化
<FlatList
  data={foods}
  renderItem={renderItem}
  keyExtractor={keyExtractor}
  removeClippedSubviews
  maxToRenderPerBatch={10}
  windowSize={5}
/>
```

## 常见问题

### 如何禁用 ESLint 规则？

```typescript
// 单行禁用
// eslint-disable-next-line rule-name
const value = dangerousOperation();

// 整个文件禁用（不推荐）
/* eslint-disable rule-name */

// 必须说明原因
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const legacyData: any = oldApi.getData(); // 旧 API 类型不明确
```

### 如何格式化特定文件？

```bash
# 格式化单个文件
pnpm prettier --write src/components/FoodCard.tsx

# 格式化目录
pnpm prettier --write "src/components/**/*.tsx"
```

### 提交时 lint 失败怎么办？

```bash
# 1. 查看具体错误
pnpm lint

# 2. 自动修复
pnpm lint:fix

# 3. 手动修复无法自动修复的问题

# 4. 重新提交
git add .
git commit -m "fix: 修复 lint 错误"
```

## 最佳实践

1. **保存时自动格式化**：启用 VSCode 的 `formatOnSave`
2. **提交前检查**：确保代码通过 lint 检查
3. **遵循规范**：不要随意禁用 ESLint 规则
4. **类型安全**：避免使用 `any`，使用具体类型
5. **代码复用**：提取公共逻辑到工具函数或 Hooks
6. **性能优化**：使用 `memo`、`useCallback`、`useMemo`
7. **错误处理**：所有异步操作都要有错误处理
8. **测试覆盖**：为关键功能编写测试

## 参考资源

- [TypeScript 官方文档](https://www.typescriptlang.org/docs/)
- [React 官方文档](https://react.dev/)
- [React Native 官方文档](https://reactnative.dev/)
- [ESLint 规则](https://eslint.org/docs/rules/)
- [Prettier 配置](https://prettier.io/docs/en/options.html)
- [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
