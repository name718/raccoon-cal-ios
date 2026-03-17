# API 接口文档

iOS App 使用的 API 接口由 `raccoon-cal-server` 提供。

完整接口文档请查看：[raccoon-cal-server/docs/API.md](../../raccoon-cal-server/docs/API.md)

## iOS 端快速参考

- Base URL（开发）：`http://localhost:3000/api`
- 认证：`Authorization: Bearer <token>`（登录/注册后获取，存储在 `UserManager.shared.token`）
- 所有请求/响应均为 JSON

## APIService 方法列表

```swift
// 认证
func register(username:password:email:phone:) async throws -> AuthResponse
func login(identifier:password:) async throws -> AuthResponse
func getMe() async throws -> User

// 食物
func recognizeFood(imageData: Data) async throws -> FoodRecognitionResult
func saveFoodRecord(_ record: FoodRecordRequest) async throws -> FoodRecord
func getFoodRecords(date: String) async throws -> [MealGroup]
func deleteFoodRecord(id: Int) async throws
func getFoodStats(days: Int) async throws -> NutritionStats

// 游戏化
func getGamificationStatus() async throws -> GamificationStatus
func getPetStatus() async throws -> PetStatus
func interactWithPet() async throws
func updatePetOutfit(_ outfit: OutfitRequest) async throws

// 任务与成就
func getDailyTasks() async throws -> [DailyTask]
func getAchievements() async throws -> [Achievement]

// 联盟
func getLeague() async throws -> LeagueInfo
func getLeagueSettlement() async throws -> LeagueSettlement?

// 个人资料
func getProfile() async throws -> UserProfile
func updateProfile(_ profile: ProfileUpdateRequest) async throws -> UserProfile
func recordWeight(_ weight: Double) async throws
func getWeightHistory() async throws -> [WeightRecord]
```
