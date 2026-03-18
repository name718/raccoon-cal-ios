//
//  ProfileEditView.swift
//  RaccoonCal
//
//  任务 20.3：个人信息编辑页，保存后触发卡路里目标重算
//

import SwiftUI

struct ProfileEditView: View {

    // MARK: - Input

    let profile: UserProfile
    var onSaved: ((UserProfile) -> Void)?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var nickname: String
    @State private var height: Double
    @State private var weight: Double
    @State private var age: Int
    @State private var goal: GoalOption
    @State private var activityLevel: ActivityLevelOption

    // MARK: - UI State

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    // MARK: - Goal Options

    enum GoalOption: String, CaseIterable, Identifiable {
        case weightLoss  = "lose_weight"
        case maintain    = "maintain"
        case muscleGain  = "gain_muscle"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .weightLoss: return "减脂"
            case .maintain:   return "维持体重"
            case .muscleGain: return "增肌"
            }
        }

        static func from(_ raw: String) -> GoalOption {
            GoalOption(rawValue: raw.lowercased()) ?? .maintain
        }
    }

    // MARK: - Activity Level Options

    enum ActivityLevelOption: String, CaseIterable, Identifiable {
        case sedentary  = "sedentary"
        case light      = "light"
        case moderate   = "moderate"
        case active     = "active"
        case veryActive = "very_active"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sedentary:  return "久坐（几乎不运动）"
            case .light:      return "轻度（每周 1-3 天）"
            case .moderate:   return "中度（每周 3-5 天）"
            case .active:     return "高度（每周 6-7 天）"
            case .veryActive: return "极高（体力劳动/运动员）"
            }
        }

        static func from(_ raw: String) -> ActivityLevelOption {
            ActivityLevelOption(rawValue: raw.lowercased()) ?? .moderate
        }
    }

    // MARK: - Init

    init(profile: UserProfile, onSaved: ((UserProfile) -> Void)? = nil) {
        self.profile = profile
        self.onSaved = onSaved
        _nickname      = State(initialValue: profile.nickname)
        _height        = State(initialValue: profile.height)
        _weight        = State(initialValue: profile.weight)
        _age           = State(initialValue: profile.age)
        _goal          = State(initialValue: GoalOption.from(profile.goal))
        _activityLevel = State(initialValue: ActivityLevelOption.from(profile.activityLevel))
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.gradientBackground.ignoresSafeArea()

                formContent

                // 成功提示 Toast
                if showSuccess {
                    VStack {
                        Spacer()
                        successToast
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button("保存") { Task { await save() } }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                            .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .alert("保存失败", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        let form = Form {
                    // 基本信息
                    Section {
                        HStack {
                            Label("昵称", systemImage: "person.fill")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                            Spacer()
                            TextField("请输入昵称", text: $nickname)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    } header: {
                        sectionHeader("基本信息")
                    }

                    // 身体数据
                    Section {
                        // 身高
                        VStack(alignment: .leading, spacing: 6) {
                            Label("身高", systemImage: "ruler")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                            HStack {
                                Slider(value: $height, in: 100...250, step: 1)
                                    .accentColor(AppTheme.primary)
                                Text("\(Int(height)) cm")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 4)

                        // 体重
                        VStack(alignment: .leading, spacing: 6) {
                            Label("体重", systemImage: "scalemass")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                            HStack {
                                Slider(value: $weight, in: 30...200, step: 0.5)
                                    .accentColor(AppTheme.secondary)
                                Text(String(format: "%.1f kg", weight))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 4)

                        // 年龄
                        HStack {
                            Label("年龄", systemImage: "calendar.badge.clock")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                            Spacer()
                            Stepper("\(age) 岁", value: $age, in: 10...100)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    } header: {
                        sectionHeader("身体数据")
                    }

                    // 目标设置
                    Section {
                        Picker(selection: $goal) {
                            ForEach(GoalOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        } label: {
                            Label("健身目标", systemImage: "target")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                        }

                        Picker(selection: $activityLevel) {
                            ForEach(ActivityLevelOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        } label: {
                            Label("活动水平", systemImage: "figure.walk")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                        }
                    } header: {
                        sectionHeader("目标设置")
                    } footer: {
                        Text("保存后将根据您的身体数据和目标自动重新计算每日卡路里目标。")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textDisabled)
                    }
                }

        if #available(iOS 16.0, *) {
            form.scrollContentBackground(.hidden)
        } else {
            form
        }
    }

    // MARK: - Success Toast

    private var successToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.success)
                .font(.system(size: 18))
            Text("保存成功，卡路里目标已更新")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppTheme.textSecondary)
            .textCase(nil)
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        let updateRequest = ProfileUpdateRequest(
            nickname: nickname.trimmingCharacters(in: .whitespaces),
            gender: nil,
            height: height,
            weight: weight,
            age: age,
            goal: goal.rawValue,
            activityLevel: activityLevel.rawValue
        )

        do {
            let updatedProfile = try await APIService.shared.updateProfile(updateRequest)
            isSaving = false
            withAnimation(.spring()) { showSuccess = true }
            onSaved?(updatedProfile)
            // 短暂显示成功提示后关闭
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dismiss()
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileEditView(profile: UserProfile(
        id: 1,
        userId: 1,
        nickname: "浣熊用户",
        gender: "male",
        height: 170,
        weight: 65,
        age: 25,
        goal: "maintain",
        activityLevel: "moderate",
        dailyCalTarget: 2000,
        createdAt: "",
        updatedAt: ""
    ))
}
