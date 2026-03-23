//
//  FoodResultSheet.swift
//  RaccoonCal
//
//  Task 17.4 — 识别结果展示（食物名称/卡路里/蛋白质/脂肪/碳水）
//  Task 17.5 — 识别失败提示和手动输入食物名称的降级入口
//  Task 17.6 — 用户修改食物名称/份量/餐次的编辑表单
//  Task 17.7 — 确认保存，调用 saveFoodRecord，触发 XP 浮动动画
//

import SwiftUI
import UIKit

// MARK: - FoodResultSheet

struct FoodResultSheet: View {

    let result: FoodRecognitionResult
    var onDismiss: () -> Void
    /// Called when the user confirms a manually-entered food name.
    var onManualEntry: ((FoodRecognitionResult) -> Void)? = nil

    @StateObject private var gamificationManager = GamificationManager.shared

    // Task 17.6 — editable copy of foods so edits can be reflected in the list
    @State private var editableFoods: [RecognizedFood]
    // Task 17.6 — which food is currently being edited
    @State private var editingFood: RecognizedFood?
    // Task 17.10 — selected food indices (checked = will be saved)
    @State private var selectedFoodIndices: Set<Int>
    // Task 17.7 — selected meal type for all foods in this save
    @State private var selectedMealType: MealType = .lunch
    // Task 17.7 — save state
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil

    init(result: FoodRecognitionResult,
         onDismiss: @escaping () -> Void,
         onManualEntry: ((FoodRecognitionResult) -> Void)? = nil) {
        self.result = result
        self.onDismiss = onDismiss
        self.onManualEntry = onManualEntry
        self._editableFoods = State(initialValue: result.foods)
        // Task 17.10 — all foods selected by default
        self._selectedFoodIndices = State(initialValue: Set(result.foods.indices))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Header
            HStack {
                Text("识别结果")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Confidence badge
                if result.confidence > 0 {
                    Text("\(Int(result.confidence * 100))% 置信度")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(confidenceColor)
                        .clipShape(Capsule())
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Divider()

            if editableFoods.isEmpty || result.confidence == 0 {
                // Task 17.5 — Recognition failed: show failure prompt + manual entry fallback
                RecognitionFailedView(onManualEntry: onManualEntry, onDismiss: onDismiss)
            } else {
                // Task 17.10 — Food items list with per-item checkboxes
                ScrollView {
                    VStack(spacing: 12) {
                        // Select all / deselect all toggle (only shown for multiple foods)
                        if editableFoods.count > 1 {
                            HStack {
                                let allSelected = selectedFoodIndices.count == editableFoods.count
                                Button(action: {
                                    if allSelected {
                                        selectedFoodIndices.removeAll()
                                    } else {
                                        selectedFoodIndices = Set(editableFoods.indices)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: allSelected ? "checkmark.square.fill" : "square")
                                            .foregroundColor(allSelected ? AppTheme.primary : AppTheme.textSecondary)
                                        Text(allSelected ? "取消全选" : "全选")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                Spacer()
                                Text("已选 \(selectedFoodIndices.count)/\(editableFoods.count)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }

                        ForEach(editableFoods.indices, id: \.self) { idx in
                            let food = editableFoods[idx]
                            let isSelected = selectedFoodIndices.contains(idx)
                            FoodItemCard(
                                food: food,
                                isSelected: isSelected,
                                onToggleSelect: {
                                    if isSelected {
                                        selectedFoodIndices.remove(idx)
                                    } else {
                                        selectedFoodIndices.insert(idx)
                                    }
                                },
                                onEdit: { editingFood = food }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                // Task 17.7 — Meal type picker + save button
                VStack(spacing: 12) {
                    Divider()

                    // Meal type picker
                    HStack {
                        Text("餐次")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Picker("餐次", selection: $selectedMealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.chineseDisplayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 260)
                    }
                    .padding(.horizontal, 16)

                    // Error message
                    if let saveError = saveError {
                        Text(saveError)
                            .font(.caption)
                            .foregroundColor(AppTheme.error)
                            .padding(.horizontal, 16)
                    }

                    // Save button
                    Button(action: saveAllFoods) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            // Task 17.10 — show selected count when multiple foods
                            let label: String = {
                                if isSaving { return "保存中…" }
                                if editableFoods.count > 1 {
                                    return "保存已选 \(selectedFoodIndices.count) 项"
                                }
                                return "确认保存"
                            }()
                            Text(label)
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background((isSaving || selectedFoodIndices.isEmpty) ? AppTheme.primary.opacity(0.6) : AppTheme.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isSaving || selectedFoodIndices.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    // Task 17.7 — XP float overlay on the save button
                    .xpFloatOverlay(manager: gamificationManager)
                }
            }
        }
        .background(AppTheme.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        // Task 17.6 — edit form sheet
        .sheet(item: $editingFood) { food in
            FoodEditFormView(food: food) { updatedFood in
                // Replace the edited food in the editable list
                if let idx = editableFoods.firstIndex(where: { $0.id == food.id }) {
                    editableFoods[idx] = updatedFood
                }
                editingFood = nil
            } onCancel: {
                editingFood = nil
            }
        }
    }

    // MARK: - Save (Task 17.7)

    private func saveAllFoods() {
        Task {
            await performSave()
        }
    }

    @MainActor
    private func performSave() async {
        isSaving = true
        saveError = nil

        // Task 17.10 — only save foods that are checked
        let foodsToSave = editableFoods.indices
            .filter { selectedFoodIndices.contains($0) }
            .map { editableFoods[$0] }

        do {
            for food in foodsToSave {
                let req = SaveFoodRecordRequest(
                    foodName: food.name,
                    calories: food.calories,
                    protein: food.protein,
                    fat: food.fat,
                    carbs: food.carbs,
                    fiber: 0,
                    servingSize: food.servingSize,
                    mealType: food.mealType ?? selectedMealType.rawValue,
                    imageUrl: nil,
                    recordedAt: nil
                )
                _ = try await APIService.shared.saveFoodRecord(req)
            }
            // Trigger XP float animation (+10 XP per save, as defined in task 3.10)
            gamificationManager.showXpFloat(amount: 10)
            // Refresh gamification status and pet satiety in background
            Task { await gamificationManager.refreshStatus() }
            Task { await gamificationManager.loadPetStatus() }
            onDismiss()
        } catch {
            saveError = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Confidence Color

    private var confidenceColor: Color {
        switch result.confidence {
        case 0.8...: return AppTheme.success
        case 0.5..<0.8: return AppTheme.warning
        default: return AppTheme.error
        }
    }
}

// MARK: - FoodEditFormView (Task 17.6)

/// Edit form that lets the user modify food name, meal type, serving size and nutrition data.
struct FoodEditFormView: View {

    let attachmentImage: UIImage?
    var onSelectPhoto: (() -> Void)?
    var onRemovePhoto: (() -> Void)?
    var onConfirm: (RecognizedFood) -> Void
    var onCancel: () -> Void

    @State private var foodName: String
    @State private var servingSize: Double
    @State private var mealType: MealType
    @State private var calories: Double
    @State private var protein: Double
    @State private var fat: Double
    @State private var carbs: Double

    init(food: RecognizedFood,
         attachmentImage: UIImage? = nil,
         onSelectPhoto: (() -> Void)? = nil,
         onRemovePhoto: (() -> Void)? = nil,
         onConfirm: @escaping (RecognizedFood) -> Void,
         onCancel: @escaping () -> Void) {
        self.attachmentImage = attachmentImage
        self.onSelectPhoto = onSelectPhoto
        self.onRemovePhoto = onRemovePhoto
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self._foodName = State(initialValue: food.name)
        self._servingSize = State(initialValue: food.servingSize > 0 ? food.servingSize : 100)
        self._mealType = State(initialValue: MealType(rawValue: food.mealType ?? MealType.lunch.rawValue) ?? .lunch)
        self._calories = State(initialValue: max(0, food.calories))
        self._protein = State(initialValue: max(0, food.protein))
        self._fat = State(initialValue: max(0, food.fat))
        self._carbs = State(initialValue: max(0, food.carbs))
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: Food name
                Section(header: Text("食物名称")) {
                    TextField("食物名称", text: $foodName)
                        .appInputFieldStyle()
                }

                // MARK: Meal type
                Section(header: Text("餐次")) {
                    Picker("餐次", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.chineseDisplayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                if attachmentImage != nil || onSelectPhoto != nil {
                    Section(header: Text("记录照片")) {
                        VStack(alignment: .leading, spacing: 12) {
                            if let attachmentImage {
                                Image(uiImage: attachmentImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }

                            Text(attachmentImage == nil ? "可选，上传一张照片方便后续核对记录。" : "已附加照片，保存后会和这条饮食记录一起上传。")
                                .font(.footnote)
                                .foregroundColor(AppTheme.textSecondary)

                            HStack(spacing: 12) {
                                if let onSelectPhoto {
                                    Button(action: onSelectPhoto) {
                                        Label(attachmentImage == nil ? "上传照片" : "更换照片", systemImage: "photo.on.rectangle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .appButtonStyle(kind: .secondary, fullWidth: true)
                                }

                                if attachmentImage != nil, let onRemovePhoto {
                                    Button(role: .destructive, action: onRemovePhoto) {
                                        Label("移除", systemImage: "trash")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .appButtonStyle(kind: .secondary, fullWidth: true)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: Serving size
                Section(header: Text("份量 (g)")) {
                    HStack {
                        // Decrement
                        Button {
                            if servingSize > 1 { servingSize = max(1, servingSize - 10) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(servingSize <= 1 ? AppTheme.textDisabled : AppTheme.primary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Editable value
                        TextField("份量", value: $servingSize, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.title3.bold())
                            .frame(width: 80)
                            .appInputFieldStyle()
                            .onChange(of: servingSize) { newVal in
                                servingSize = min(9999, max(1, newVal))
                            }

                        Text("g")
                            .foregroundColor(AppTheme.textSecondary)

                        Spacer()

                        // Increment
                        Button {
                            if servingSize < 9999 { servingSize = min(9999, servingSize + 10) }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(servingSize >= 9999 ? AppTheme.textDisabled : AppTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Nutrition
                Section(header: Text("营养信息")) {
                    NutritionInputRow(label: "热量", unit: "kcal", value: $calories, color: AppTheme.primary)
                    NutritionInputRow(label: "蛋白质", unit: "g", value: $protein, color: AppTheme.info)
                    NutritionInputRow(label: "脂肪", unit: "g", value: $fat, color: AppTheme.accent)
                    NutritionInputRow(label: "碳水", unit: "g", value: $carbs, color: AppTheme.secondary)
                }
            }
            .navigationTitle("编辑食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { confirmEdit() }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(foodName.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? AppTheme.textDisabled
                                         : AppTheme.primary)
                        .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    private func confirmEdit() {
        let trimmed = foodName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let clamped = min(9999, max(1, servingSize))
        let updated = RecognizedFood(
            name: trimmed,
            calories: max(0, calories),
            protein:  max(0, protein),
            fat:      max(0, fat),
            carbs:    max(0, carbs),
            servingSize: clamped,
            mealType: mealType.rawValue
        )
        onConfirm(updated)
    }
}

// MARK: - NutritionRow

private struct NutritionInputRow: View {
    let label: String
    let unit: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            TextField(label, value: $value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 88)
                .appInputFieldStyle()
                .onChange(of: value) { newValue in
                    value = max(0, min(9999, newValue))
                }
            Text(unit)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - MealType + Chinese display name

extension MealType {
    var chineseDisplayName: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch:     return "午餐"
        case .dinner:    return "晚餐"
        case .snack:     return "加餐"
        }
    }
}

private enum ManualRecognitionState {
    case idle
    case recognizing
    case recognized
    case noFoodDetected
    case failed
}

private enum ManualAutofillField: CaseIterable, Hashable {
    case foodName
    case mealType
    case servingSize
    case calories
    case protein
    case fat
    case carbs
}

private enum ManualEntryErrorContext {
    case imageProcessing
    case recognitionFailed
    case noFoodDetected
    case saveFailed
}

// MARK: - ManualFoodEntrySheet

struct ManualFoodEntrySheet: View {

    let initialMealType: MealType
    let initialFood: RecognizedFood
    var onSaved: ((RecognizedFood) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var foodName: String
    @State private var selectedMealType: MealType
    @State private var servingSize: Double
    @State private var calories: Double
    @State private var protein: Double
    @State private var fat: Double
    @State private var carbs: Double
    @State private var selectedPhotoData: Data?
    @State private var isSaving = false
    @State private var isRecognizing = false
    @State private var errorMessage: String? = nil
    @State private var errorTitle = "保存失败"
    @State private var errorContext: ManualEntryErrorContext? = nil
    @State private var showPhotoPicker = false
    @State private var progressMessage = "正在保存记录..."
    @State private var recognitionBannerMessage = "上传图片后会自动调用 AI 识别，并把结果回填到下面的表单。"
    @State private var recognitionState: ManualRecognitionState = .idle
    @State private var autofilledFields: Set<ManualAutofillField> = []
    @State private var showSaveSuccessToast = false

    init(
        initialMealType: MealType,
        initialFood: RecognizedFood? = nil,
        initialPhotoData: Data? = nil,
        onSaved: ((RecognizedFood) -> Void)? = nil
    ) {
        self.initialMealType = initialMealType
        self.initialFood = initialFood ?? RecognizedFood(
            name: "",
            calories: 0,
            protein: 0,
            fat: 0,
            carbs: 0,
            servingSize: 100,
            mealType: initialMealType.rawValue
        )
        self.onSaved = onSaved
        self._foodName = State(initialValue: self.initialFood.name)
        self._selectedMealType = State(
            initialValue: MealType(rawValue: self.initialFood.mealType ?? initialMealType.rawValue) ?? initialMealType
        )
        self._servingSize = State(initialValue: self.initialFood.servingSize > 0 ? self.initialFood.servingSize : 100)
        self._calories = State(initialValue: max(0, self.initialFood.calories))
        self._protein = State(initialValue: max(0, self.initialFood.protein))
        self._fat = State(initialValue: max(0, self.initialFood.fat))
        self._carbs = State(initialValue: max(0, self.initialFood.carbs))
        self._selectedPhotoData = State(initialValue: initialPhotoData)
        let initialAutofilledFields: Set<ManualAutofillField> =
            initialPhotoData != nil && !self.initialFood.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Set(ManualAutofillField.allCases)
            : []
        self._autofilledFields = State(initialValue: initialAutofilledFields)
        if initialPhotoData != nil {
            if self.initialFood.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self._recognitionBannerMessage = State(
                    initialValue: "图片已带入当前表单，但暂未识别到可直接回填的菜品，请你继续手动完善。"
                )
                self._recognitionState = State(initialValue: .noFoodDetected)
            } else {
                self._recognitionBannerMessage = State(
                    initialValue: "已根据图片识别结果回填当前表单，你可以继续修改后再保存。"
                )
                self._recognitionState = State(initialValue: .recognized)
            }
        }
    }

    private var selectedPhotoImage: UIImage? {
        guard let selectedPhotoData else { return nil }
        return UIImage(data: selectedPhotoData)
    }

    private var canSave: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var draftFood: RecognizedFood {
        RecognizedFood(
            name: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: max(0, calories),
            protein: max(0, protein),
            fat: max(0, fat),
            carbs: max(0, carbs),
            servingSize: min(9999, max(1, servingSize)),
            mealType: selectedMealType.rawValue
        )
    }

    private var recognitionStatusTint: Color {
        switch recognitionState {
        case .idle:
            return AppTheme.info
        case .recognizing:
            return AppTheme.primary
        case .recognized:
            return AppTheme.success
        case .noFoodDetected:
            return AppTheme.warning
        case .failed:
            return AppTheme.error
        }
    }

    private var recognitionStatusIcon: String {
        switch recognitionState {
        case .idle:
            return "wand.and.stars"
        case .recognizing:
            return "sparkles"
        case .recognized:
            return "checkmark.circle.fill"
        case .noFoodDetected:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.octagon.fill"
        }
    }

    private var recognitionStatusTitle: String {
        switch recognitionState {
        case .idle:
            return "等待识别"
        case .recognizing:
            return "AI 识别中"
        case .recognized:
            return "已回填表单"
        case .noFoodDetected:
            return "未识别到菜品"
        case .failed:
            return "识别失败"
        }
    }

    private var recognitionActionTitle: String {
        selectedPhotoData == nil ? "上传图片并识别" : "重新上传并再次识别"
    }

    private var recognitionActionSubtitle: String {
        selectedPhotoData == nil
        ? "选择一张食物照片，系统会自动识别并回填表单"
        : "重新上传会覆盖当前图片，并用新结果更新表单"
    }

    private var recognitionHelperText: String {
        switch recognitionState {
        case .idle:
            return "识别后会优先回填食物名称、热量和三大营养素，你仍可继续手动修改。"
        case .recognizing:
            return "正在分析图片中的菜品和营养信息，通常只需片刻。"
        case .recognized:
            return "AI 已完成回填，保存前建议你再核对一次份量和餐次。"
        case .noFoodDetected:
            return "当前图片未识别到明确菜品，请继续手动填写，或换一张更清晰的照片。"
        case .failed:
            return "图片已保留，但本次识别未成功。你可以重试，或直接继续手动填写。"
        }
    }

    private var hasAutofilledFields: Bool {
        !autofilledFields.isEmpty
    }

    private var autofilledSummaryText: String {
        "本次已自动回填 \(autofilledFields.count) 项，你修改后会自动取消对应标记。"
    }

    private var draftSummaryItems: [(String, String, Color)] {
        [
            ("餐次", selectedMealType.chineseDisplayName, AppTheme.primary),
            ("份量", "\(Int(max(1, servingSize)))g", AppTheme.info),
            ("热量", calories > 0 ? "\(Int(calories)) kcal" : "待补充", AppTheme.accent)
        ]
    }

    private var errorPrimaryAction: AppDialogAction {
        switch errorContext {
        case .imageProcessing:
            return AppDialogAction("重新选择图片") {
                errorMessage = nil
                showPhotoPicker = true
            }
        case .recognitionFailed:
            return AppDialogAction("重新识别") {
                retryRecognition()
            }
        case .noFoodDetected:
            return AppDialogAction("继续手动填写") {
                errorMessage = nil
            }
        case .saveFailed:
            return AppDialogAction("重试保存") {
                retrySaveDraft()
            }
        case .none:
            return AppDialogAction("确定") {
                errorMessage = nil
            }
        }
    }

    private var errorSecondaryAction: AppDialogAction? {
        switch errorContext {
        case .imageProcessing:
            return AppDialogAction("继续手动填写") {
                errorMessage = nil
            }
        case .recognitionFailed:
            return AppDialogAction("继续手动填写") {
                errorMessage = nil
            }
        case .noFoodDetected:
            return AppDialogAction("重新选择图片") {
                errorMessage = nil
                showPhotoPicker = true
            }
        case .saveFailed:
            return AppDialogAction("稍后再试") {
                errorMessage = nil
            }
        case .none:
            return nil
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.gradientBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        manualHeaderCard
                        photoCapabilityCard
                        draftSummaryCard
                        basicInfoCard
                        nutritionCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 140)
                }
            }
            .navigationTitle("手动填写")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveBar
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker { rawData in
                handlePickedPhoto(rawData)
            }
        }
        .delayedLoadingOverlay(
            isLoading: isSaving || isRecognizing,
            message: progressMessage,
            delayNanoseconds: 450_000_000
        )
        .appDialog(
            isPresented: Binding(
                get: { errorMessage != nil },
                set: {
                    if !$0 {
                        errorMessage = nil
                        errorContext = nil
                    }
                }
            ),
            title: errorTitle,
            message: errorMessage ?? "",
            tone: .error,
            primaryAction: errorPrimaryAction,
            secondaryAction: errorSecondaryAction
        )
        .overlay(alignment: .top) {
            if showSaveSuccessToast {
                saveSuccessToast
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var manualHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.16))
                        .frame(width: 48, height: 48)

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("手动记录饮食")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("支持直接填写，也支持上传食物照片后自动识别并回填，你确认后再保存。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: recognitionStatusIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(recognitionStatusTint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recognitionStatusTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(recognitionBannerMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(recognitionStatusTint.opacity(0.09))
            )

            if hasAutofilledFields {
                HStack(alignment: .top, spacing: 8) {
                    autofillBadge(text: "AI 已填充")

                    Text(autofilledSummaryText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(manualCardBackground)
    }

    private var photoCapabilityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("图片识别辅助")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("上传食物照片后自动识别，并把结果回填到当前表单")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    if isRecognizing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(recognitionStatusTint)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: recognitionStatusIcon)
                            .font(.system(size: 12, weight: .semibold))
                    }

                    Text(recognitionStatusTitle)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(recognitionStatusTint)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(recognitionStatusTint.opacity(0.10))
                )
            }

            if let selectedPhotoImage {
                Image(uiImage: selectedPhotoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 188)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            selectedPhotoData = nil
                            recognitionState = .idle
                            recognitionBannerMessage = "上传图片后会自动调用 AI 识别，并把结果回填到下面的表单。"
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                        }
                        .padding(10)
                    }
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 6) {
                            Image(systemName: isRecognizing ? "sparkles" : recognitionStatusIcon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(isRecognizing ? "正在识别" : recognitionStatusTitle)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.45), in: Capsule(style: .continuous))
                        .padding(12)
                    }
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.primary.opacity(0.10),
                                Color.white.opacity(0.82),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 168)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(AppTheme.primary)
                            Text("上传一张食物照片")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("选择照片后会自动调用 AI 识别，并回填食物名称、热量和营养信息。")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)

                            Text("支持 JPG / PNG / WEBP")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.textDisabled)
                        }
                    }
            }

            Button {
                showPhotoPicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 40, height: 40)

                        if isRecognizing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(recognitionActionTitle)
                            .font(.system(size: 16, weight: .bold))
                            .multilineTextAlignment(.leading)

                        Text(recognitionActionSubtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.84))
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.92))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(isSaving || isRecognizing)
            .appButtonStyle(kind: .primary, fullWidth: true)

            if selectedPhotoData != nil {
                manualActionButton(
                    title: "移除当前图片",
                    systemImage: "trash",
                    tint: AppTheme.textSecondary
                ) {
                    selectedPhotoData = nil
                    recognitionState = .idle
                    recognitionBannerMessage = "已移除图片，你可以继续手动填写，或重新上传图片触发 AI 识别。"
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(recognitionStatusTint)

                Text(recognitionHelperText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isRecognizing {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppTheme.primary)
                            .scaleEffect(0.85)

                        Text("正在识别图片并回填表单")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Text("系统会先识别菜品，再整理为当前表单可编辑的数据。识别完成后你仍可继续修改。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.08))
                )
            }
        }
        .padding(18)
        .background(manualCardBackground)
    }

    private var draftSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                "当前记录摘要",
                iconName: "sparkles.rectangle.stack.fill",
                subtitle: "这里会随着你的修改和 AI 回填实时更新。"
            )

            HStack(spacing: 10) {
                ForEach(Array(draftSummaryItems.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        Text(item.1)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(item.2.opacity(0.10))
                    )
                }
            }
        }
        .padding(18)
        .background(manualCardBackground)
    }

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                "基础信息",
                iconName: "list.bullet.clipboard.fill",
                subtitle: hasAutofilledFields ? "以下带有标记的内容来自图片识别，保存前可继续调整。" : nil
            )

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("食物名称", field: .foodName)

                TextField("例如：米饭、鸡胸肉、酸奶水果碗", text: $foodName)
                    .appInputFieldStyle(isInvalid: !canSave)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(autofilledFields.contains(.foodName) ? AppTheme.success.opacity(0.28) : .clear, lineWidth: 1.5)
                    )
                    .onChange(of: foodName) { _ in
                        clearAutofill(.foodName)
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("餐次", field: .mealType)

                HStack(spacing: 8) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Button {
                            selectedMealType = mealType
                            clearAutofill(.mealType)
                        } label: {
                            Text(mealType.chineseDisplayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedMealType == mealType ? .white : AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(selectedMealType == mealType ? AppTheme.primary : Color.white.opacity(0.8))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(autofilledFields.contains(.mealType) ? AppTheme.success.opacity(0.08) : Color.clear)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("份量", field: .servingSize)

                HStack(spacing: 12) {
                    quantityAdjustButton(systemImage: "minus", isEnabled: servingSize > 1) {
                        servingSize = max(1, servingSize - 10)
                        clearAutofill(.servingSize)
                    }

                    TextField("份量", value: $servingSize, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .bold))
                        .appInputFieldStyle()
                        .onChange(of: servingSize) { newValue in
                            servingSize = min(9999, max(1, newValue))
                            clearAutofill(.servingSize)
                        }

                    Text("g")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)

                    quantityAdjustButton(systemImage: "plus", isEnabled: servingSize < 9999) {
                        servingSize = min(9999, servingSize + 10)
                        clearAutofill(.servingSize)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(autofilledFields.contains(.servingSize) ? AppTheme.success.opacity(0.08) : Color.clear)
                )
            }
        }
        .padding(18)
        .background(manualCardBackground)
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                "营养信息",
                iconName: "bolt.heart.fill",
                subtitle: hasAutofilledFields ? "营养数据为识别建议值，你可以按包装或实际份量修正。" : nil
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                manualMetricField(title: "热量", value: $calories, unit: "kcal", tint: AppTheme.primary, field: .calories)
                manualMetricField(title: "蛋白质", value: $protein, unit: "g", tint: AppTheme.info, field: .protein)
                manualMetricField(title: "脂肪", value: $fat, unit: "g", tint: AppTheme.accent, field: .fat)
                manualMetricField(title: "碳水", value: $carbs, unit: "g", tint: AppTheme.secondary, field: .carbs)
            }
        }
        .padding(18)
        .background(manualCardBackground)
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 0.5)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(canSave ? draftFood.name : "请先填写食物名称")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canSave ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        compactSaveBadge(text: "\(Int(draftFood.servingSize))g", tint: AppTheme.info)
                        compactSaveBadge(text: selectedMealType.chineseDisplayName, tint: AppTheme.primary)
                        if draftFood.calories > 0 {
                            compactSaveBadge(text: "\(Int(draftFood.calories)) kcal", tint: AppTheme.accent)
                        }
                    }
                }

                Spacer()

                Button {
                    Task { await save(draftFood) }
                } label: {
                    Text("保存记录")
                        .frame(minWidth: 108)
                }
                .disabled(!canSave || isSaving || isRecognizing)
                .appButtonStyle(kind: .primary, fullWidth: false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(tabSafeBackground)
        }
    }

    @MainActor
    private func save(_ food: RecognizedFood) async {
        isSaving = true
        showSaveSuccessToast = false
        errorTitle = "保存失败"
        errorContext = nil
        errorMessage = nil
        progressMessage = "正在保存记录..."
        defer { isSaving = false }

        do {
            let imageUrl: String?
            if let selectedPhotoData {
                progressMessage = "正在上传照片..."
                imageUrl = try await APIService.shared.uploadFoodRecordImage(
                    imageData: selectedPhotoData
                )
            } else {
                imageUrl = nil
            }

            progressMessage = "正在保存记录..."
            let request = SaveFoodRecordRequest(
                foodName: food.name,
                calories: food.calories,
                protein: food.protein,
                fat: food.fat,
                carbs: food.carbs,
                fiber: 0,
                servingSize: food.servingSize,
                mealType: food.mealType ?? initialMealType.rawValue,
                imageUrl: imageUrl,
                recordedAt: nil
            )

            _ = try await APIService.shared.saveFoodRecord(request)
            gamificationManager.showXpFloat(amount: 10)
            Task { await gamificationManager.refreshStatus() }
            Task { await gamificationManager.loadPetStatus() }
            onSaved?(food)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                showSaveSuccessToast = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        } catch {
            errorContext = .saveFailed
            errorMessage = "这条饮食记录还没有保存成功，你可以立即重试，已填写的内容会保留。\n\n\(error.localizedDescription)"
        }
    }

    private func handlePickedPhoto(_ rawData: Data) {
        guard let normalizedData = normalizedUploadImageData(from: rawData) else {
            errorTitle = "图片处理失败"
            errorContext = .imageProcessing
            errorMessage = "图片处理失败，请重新选择"
            recognitionState = .failed
            return
        }

        selectedPhotoData = normalizedData
        recognitionBannerMessage = "图片已上传，正在调用 AI 识别并准备回填表单。"

        Task {
            await recognizeAndPrefill(from: normalizedData, source: "上传图片")
        }
    }

    @MainActor
    private func recognizeAndPrefill(from photoData: Data, source: String) async {
        isRecognizing = true
        recognitionState = .recognizing
        errorTitle = "识别失败"
        errorContext = nil
        errorMessage = nil
        progressMessage = "AI 正在识别图片并回填表单..."
        defer { isRecognizing = false }

        do {
            let result = try await APIService.shared.recognizeFood(imageData: photoData)
            guard !result.foods.isEmpty else {
                recognitionState = .noFoodDetected
                recognitionBannerMessage = "图片已上传，但 AI 没有识别到明确菜品，请你继续手动填写。"
                errorTitle = "未识别到菜品"
                errorContext = .noFoodDetected
                errorMessage = "这张图片里没有识别到足够明确的菜品信息。你可以直接继续手动填写，或者换一张更清晰的图片。"
                return
            }
            applyRecognizedFood(result)
            recognitionState = .recognized
            recognitionBannerMessage = "已根据\(source)完成 AI 识别并回填表单，请在保存前核对名称、份量和营养信息。"
        } catch {
            recognitionState = .failed
            recognitionBannerMessage = "图片已上传，但这次 AI 识别没有成功，你可以重试或继续手动填写。"
            errorContext = .recognitionFailed
            errorMessage = "暂时无法完成图片识别，请检查网络后重试，或继续手动填写。\n\n\(error.localizedDescription)"
        }
    }

    private func applyRecognizedFood(_ result: FoodRecognitionResult) {
        guard let recognized = result.foods.first else { return }

        foodName = recognized.name
        servingSize = max(1, recognized.servingSize)
        calories = max(0, recognized.calories)
        protein = max(0, recognized.protein)
        fat = max(0, recognized.fat)
        carbs = max(0, recognized.carbs)
        selectedMealType = MealType(rawValue: recognized.mealType ?? selectedMealType.rawValue) ?? selectedMealType
        autofilledFields = Set(ManualAutofillField.allCases)
    }

    private func normalizedUploadImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxWidth: CGFloat = 1600
        let originalSize = image.size

        guard originalSize.width > maxWidth else {
            return image.jpegData(compressionQuality: 0.85)
        }

        let scale = maxWidth / originalSize.width
        let newSize = CGSize(width: maxWidth, height: originalSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resizedImage.jpegData(compressionQuality: 0.85)
    }

    @ViewBuilder
    private func manualActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(isDisabled ? AppTheme.textDisabled : tint)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isDisabled ? Color.white.opacity(0.5) : tint.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isDisabled ? Color.white.opacity(0.6) : tint.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    @ViewBuilder
    private func quantityAdjustButton(
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isEnabled ? AppTheme.primary.opacity(0.12) : Color.white.opacity(0.6))
                    .frame(width: 38, height: 38)

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isEnabled ? AppTheme.primary : AppTheme.textDisabled)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private func manualMetricField(
        title: String,
        value: Binding<Double>,
        unit: String,
        tint: Color,
        field: ManualAutofillField
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    if autofilledFields.contains(field) {
                        autofillBadge(text: "AI")
                    }
                }

                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(tint)
            }

            TextField(title, value: value, format: .number.precision(.fractionLength(1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .appInputFieldStyle()
                .onChange(of: value.wrappedValue) { newValue in
                    value.wrappedValue = max(0, min(9999, newValue))
                    clearAutofill(field)
                }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(autofilledFields.contains(field) ? tint.opacity(0.10) : Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(autofilledFields.contains(field) ? tint.opacity(0.18) : Color.clear, lineWidth: 1)
        )
    }

    private func clearAutofill(_ field: ManualAutofillField) {
        guard !isRecognizing else { return }
        autofilledFields.remove(field)
    }

    private func retryRecognition() {
        guard let selectedPhotoData else {
            errorMessage = nil
            showPhotoPicker = true
            return
        }
        errorMessage = nil
        Task {
            await recognizeAndPrefill(from: selectedPhotoData, source: "重新识别")
        }
    }

    private func retrySaveDraft() {
        errorMessage = nil
        Task {
            await save(draftFood)
        }
    }

    private func sectionTitle(_ title: String, iconName: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 6) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.primary)

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                if hasAutofilledFields {
                    autofillBadge(text: "AI 辅助")
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func fieldLabel(_ title: String, field: ManualAutofillField) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)

            if autofilledFields.contains(field) {
                autofillBadge(text: "AI 已填充")
            }
        }
    }

    private func autofillBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppTheme.success)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.success.opacity(0.12))
            )
    }

    private func compactSaveBadge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.10))
            )
    }

    private var saveSuccessToast: some View {
        HStack(spacing: 12) {
            Image("RaccoonSuccess")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text("记录已保存")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("饮食数据已更新，稍后会自动返回。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.success)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.95), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
    }

    private var manualCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
    }

    private var tabSafeBackground: Color {
        Color(
            uiColor: UIColor(
                red: 255 / 255,
                green: 251 / 255,
                blue: 245 / 255,
                alpha: 0.98
            )
        )
    }
}

// MARK: - RecognitionFailedView (Task 17.5)

/// Shown when food recognition returns empty foods or confidence == 0.
struct RecognitionFailedView: View {

    var onManualEntry: ((FoodRecognitionResult) -> Void)?
    var onDismiss: () -> Void

    @State private var foodName: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Failure illustration + message
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.warning)

                Text("未能识别食物")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text("请手动输入食物名称，继续记录")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Manual entry input
            VStack(alignment: .leading, spacing: 8) {
                Text("食物名称")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 10) {
                    TextField("例如：米饭、鸡胸肉…", text: $foodName)
                        .focused($isTextFieldFocused)
                        .font(.body)
                        .appInputFieldStyle()
                        .submitLabel(.done)
                        .onSubmit { confirmManualEntry() }

                    Button(action: confirmManualEntry) {
                        Text("确认")
                    }
                    .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .appButtonStyle(kind: .primary, fullWidth: false)
                    .accessibilityLabel("确认手动输入食物名称")
                }
            }
            .padding(.horizontal, 20)

            // Retake photo option
            Button(action: onDismiss) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.caption)
                    Text("重新选择图片")
                        .font(.subheadline)
                }
                .foregroundColor(AppTheme.primary)
            }
            .accessibilityLabel("关闭并重新选择图片")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTextFieldFocused = true
            }
        }
    }

    private func confirmManualEntry() {
        let trimmed = foodName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let manualFood = RecognizedFood(
            name: trimmed,
            calories: 0,
            protein: 0,
            fat: 0,
            carbs: 0,
            servingSize: 100,
            mealType: MealType.lunch.rawValue
        )
        let syntheticResult = FoodRecognitionResult(foods: [manualFood], confidence: 1.0)
        onManualEntry?(syntheticResult)
    }
}

// MARK: - FoodItemCard

private struct FoodItemCard: View {

    let food: RecognizedFood
    // Task 17.10 — selection support
    var isSelected: Bool = true
    var onToggleSelect: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Task 17.10 — checkbox toggle
            Button(action: { onToggleSelect?() }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.primary : Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .accessibilityLabel(isSelected ? "取消选择 \(food.name)" : "选择 \(food.name)")

            VStack(alignment: .leading, spacing: 10) {
                // Food name + serving size + edit button
                HStack {
                    Text(food.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(food.servingSize))g")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    if let mealType = food.mealType,
                       let meal = MealType(rawValue: mealType) {
                        Text(meal.chineseDisplayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.backgroundSecondary)
                            .clipShape(Capsule())
                    }

                    // Task 17.6 — edit button
                    Button(action: { onEdit?() }) {
                        Text("编辑")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.primaryLight.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("编辑 \(food.name)")
                }

                // Calories highlight
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(isSelected ? AppTheme.primary : AppTheme.textSecondary)
                    Text("\(Int(food.calories)) kcal")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isSelected ? AppTheme.primary : AppTheme.textSecondary)
                }

                // Macros row
                HStack(spacing: 0) {
                    MacroLabel(label: "蛋白质", value: food.protein, unit: "g", color: isSelected ? AppTheme.info : AppTheme.textSecondary)
                    Spacer()
                    MacroLabel(label: "脂肪", value: food.fat, unit: "g", color: isSelected ? AppTheme.accent : AppTheme.textSecondary)
                    Spacer()
                    MacroLabel(label: "碳水", value: food.carbs, unit: "g", color: isSelected ? AppTheme.secondary : AppTheme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(isSelected ? Color.white : Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: isSelected ? Color.black.opacity(0.06) : .clear, radius: 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - MacroLabel

private struct MacroLabel: View {

    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
            Text(String(format: "%.1f%@", value, unit))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
