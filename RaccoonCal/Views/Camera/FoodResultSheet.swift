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

// MARK: - ManualFoodEntrySheet

struct ManualFoodEntrySheet: View {

    let initialMealType: MealType
    let initialFood: RecognizedFood
    var onSaved: ((RecognizedFood) -> Void)? = nil
    @State private var seedFood: RecognizedFood
    @State private var selectedPhotoData: Data?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showPhotoPicker = false
    @State private var progressMessage = "正在保存记录..."

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
        self._seedFood = State(initialValue: self.initialFood)
        self._selectedPhotoData = State(initialValue: initialPhotoData)
    }

    private var selectedPhotoImage: UIImage? {
        guard let selectedPhotoData else { return nil }
        return UIImage(data: selectedPhotoData)
    }

    var body: some View {
        ZStack {
            FoodEditFormView(
                food: seedFood,
                attachmentImage: selectedPhotoImage,
                onSelectPhoto: {
                    showPhotoPicker = true
                },
                onRemovePhoto: {
                    selectedPhotoData = nil
                },
                onConfirm: { updatedFood in
                    seedFood = updatedFood
                    Task { await save(updatedFood) }
                },
                onCancel: {
                    dismiss()
                }
            )

            if isSaving {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()

                ProgressView(progressMessage)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker { rawData in
                if let normalizedData = normalizedUploadImageData(from: rawData) {
                    selectedPhotoData = normalizedData
                } else {
                    errorMessage = "图片处理失败，请重新选择"
                }
            }
        }
        .appDialog(
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            title: "保存失败",
            message: errorMessage ?? "",
            tone: .error,
            primaryAction: AppDialogAction("确定") {
                errorMessage = nil
            }
        )
    }

    @MainActor
    private func save(_ food: RecognizedFood) async {
        isSaving = true
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
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
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
