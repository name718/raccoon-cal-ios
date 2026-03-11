# API 接口文档

## 基础信息

- **Base URL**: `https://api.raccooncal.com/v1`
- **认证方式**: Bearer Token (JWT)
- **请求格式**: JSON
- **响应格式**: JSON

## 通用响应格式

```typescript
interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
  timestamp: string;
}
```

## 错误码说明

| 错误码 | HTTP状态码 | 说明 |
|--------|------------|------|
| `AUTH_REQUIRED` | 401 | 需要登录认证 |
| `INVALID_TOKEN` | 401 | Token无效或过期 |
| `PERMISSION_DENIED` | 403 | 权限不足 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `VALIDATION_ERROR` | 400 | 请求参数验证失败 |
| `RATE_LIMIT_EXCEEDED` | 429 | 请求频率超限 |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |

## API 接口列表

具体的 API 接口将在开发过程中逐步添加和完善。

## 1. 认证接口

待开发...

## 2. 用户接口

待开发...

## 3. 食物识别接口

待开发...

## 4. 浣熊养成接口

待开发...

## 5. 社交功能接口

待开发...

## 6. 数据统计接口

待开发...

## 7. 通知接口

待开发...

## 8. 系统接口

待开发...