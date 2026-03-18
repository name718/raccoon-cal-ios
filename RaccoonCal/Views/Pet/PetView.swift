//
//  PetView.swift
//  RaccoonCal
//
//  浣熊养成页：
//  - 19.2 浣熊外观/名称/等级/饱食度进度条展示（使用静态图片）
//  - 19.3 集成 RaccoonMoodView 展示当前心情状态
//  - 19.4 点击浣熊调用 interactWithPet，显示随机文案和 scale 动画
//  - 19.5 装扮道具列表（帽子/衣服/配件三槽位）
//  - 19.6 更换装扮后调用 updatePetOutfit 保存，图片叠加预览
//  - 19.7 成长历史时间线（按 achievedAt 升序）
//  - 19.8 连续 3 天未打卡时展示"思念"状态（RaccoonLoading + 文案提示）
//

import SwiftUI

// MARK: - PetView

struct PetView: View {

    // MARK: - Dependencies

    @EnvironmentObject var gamificationManager: GamificationManager

    // MARK: - State

    /// 当前宠物状态（从 GamificationManager 同步）
    @State private var petStatus: PetStatus? = nil

    // 19.4 互动动画
    /// 是否正在执行互动（防重复点击）
    @State private var isInteracting: Bool = false
    /// 是否显示互动文案气泡
    @State private var showInteractText: Bool = false
    /// 当前互动随机文案
    @State private var interactText: String = ""
    /// 浣熊 scale 动画触发值
    @State private var raccoonScale: CGFloat = 1.0

    // 19.5 装扮槽位
    /// 当前选中的装扮槽位 Tab
    @State private var selectedOutfitSlot: OutfitSlot = .hat
    /// 已解锁的装扮 key 集合（从 API 获取）
    @State private var unlockedOutfitKeys: Set<String> = []
    /// 是否正在加载装扮列表
    @State private var isLoadingOutfits: Bool = false

    // 19.6 装扮预览
    /// 预览中的帽子 key（未保存）
    @State private var previewHat: String? = nil
    /// 预览中的衣服 key（未保存）
    @State private var previewClothes: String? = nil
    /// 预览中的配件 key（未保存）
    @State private var previewAccessory: String? = nil
    /// 是否正在保存装扮
    @State private var isSavingOutfit: Bool = false
    /// 保存失败时显示的错误提示
    @State private var outfitSaveError: String? = nil
    /// 页面级错误提示
    @State private var errorMessage: String? = nil

    // MARK: - Computed Properties

    /// 当前心情（优先使用 petStatus，否则 fallback 到 .normal）
    private var currentMood: PetMood {
        petStatus?.mood ?? .normal
    }

    /// 是否处于"思念"状态（19.8）
    private var isMissingState: Bool {
        currentMood == .missing
    }

    /// 连续未打卡天数（19.8）：从 lastCheckinAt 计算，最少返回 3
    private var missedDays: Int {
        guard let lastCheckinStr = gamificationManager.gamificationStatus?.lastCheckinAt else {
            // 从未打卡，视为 3 天
            return 3
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: lastCheckinStr)
            ?? ISO8601DateFormatter().date(from: lastCheckinStr)
        guard let lastDate = date else { return 3 }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 3
        return max(days, 3)
    }

    /// 宠物名称
    private var petName: String {
        petStatus?.name ?? "小R"
    }

    /// 宠物等级
    private var petLevel: Int {
        petStatus?.level ?? (gamificationManager.gamificationStatus?.level ?? 1)
    }

    /// 饱食度 0-100
    private var satiety: Double {
        petStatus?.satiety ?? 0
    }

    /// 成长历史（按 achievedAt 升序，19.7）
    private var sortedLevelHistory: [PetLevelEvent] {
        gamificationManager.petLevelHistory
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.gradientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: 19.2 浣熊外观/名称/等级/饱食度
                        petInfoSection

                        // MARK: 19.3 + 19.4 浣熊心情展示 & 点击互动
                        raccoonInteractSection

                        // MARK: 19.8 思念状态提示（仅 missing 时显示）
                        if isMissingState {
                            missingStateBanner
                        }

                        // MARK: 19.5 + 19.6 装扮道具列表
                        outfitSection

                        // MARK: 19.7 成长历史时间线
                        levelHistorySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await loadPetData()
                }
            }
            .navigationTitle("浣熊")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("请求失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await loadPetData()
        }
    }

    // MARK: - 19.2 宠物信息区

    private var petInfoSection: some View {
        HStack(spacing: 16) {
            // 浣熊外观（静态图片，根据心情切换）
            ZStack {
                Circle()
                    .fill(AppTheme.primaryLight.opacity(0.4))
                    .frame(width: 88, height: 88)
                RaccoonMoodView(mood: currentMood, size: 72)
            }

            // 名称 / 等级 / 饱食度
            VStack(alignment: .leading, spacing: 8) {
                // 名称 + 等级徽章
                HStack(spacing: 8) {
                    Text(petName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.primary)
                        Text("Lv.\(petLevel)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppTheme.primary.opacity(0.12)))
                }

                // 心情标签
                Text(currentMood.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)

                // 饱食度进度条
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.secondary)
                            Text("饱食度")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text("\(Int(satiety))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(satiety >= 80 ? AppTheme.secondary : AppTheme.textSecondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.secondary.opacity(0.15))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.secondaryLight, AppTheme.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(satiety / 100, 1.0), height: 8)
                                .animation(.easeInOut(duration: 0.4), value: satiety)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - 19.3 + 19.4 浣熊心情 & 互动区

    private var raccoonInteractSection: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))

            VStack(spacing: 12) {
                // 19.3 RaccoonMoodView
                // 19.4 点击触发互动
                // 19.6 ZStack 叠加装扮图片
                Button(action: handleRaccoonTap) {
                    ZStack {
                        RaccoonMoodView(mood: currentMood, size: 150)

                        // 19.6 — 衣服图层（底层）
                        if let clothKey = previewClothes,
                           let _ = OutfitCatalog.all.first(where: { $0.id == clothKey }) {
                            OutfitOverlayImage(outfitKey: clothKey, size: 150)
                        }

                        // 19.6 — 配件图层（中层）
                        if let accKey = previewAccessory,
                           let _ = OutfitCatalog.all.first(where: { $0.id == accKey }) {
                            OutfitOverlayImage(outfitKey: accKey, size: 150)
                        }

                        // 19.6 — 帽子图层（顶层）
                        if let hatKey = previewHat,
                           let _ = OutfitCatalog.all.first(where: { $0.id == hatKey }) {
                            OutfitOverlayImage(outfitKey: hatKey, size: 150)
                        }
                    }
                    .scaleEffect(raccoonScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: raccoonScale)
                }
                .buttonStyle(.plain)
                .disabled(isInteracting)

                // 互动文案气泡（19.4）
                if showInteractText {
                    Text(interactText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.primaryLight.opacity(0.5))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                // 19.6 — 保存失败提示
                if let error = outfitSaveError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 19.8 思念状态横幅

    private var missingStateBanner: some View {
        VStack(spacing: 12) {
            // RaccoonLoading 图片
            Image("RaccoonLoading")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            // 文案提示：浣熊好想你...已经 X 天没见到你了
            VStack(spacing: 4) {
                Text("浣熊好想你...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                Text("已经 \(missedDays) 天没见到你了")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - 19.5 + 19.6 装扮区

    private var outfitSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("装扮")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                // 19.6 — 保存按钮（仅当预览与已保存状态不同时显示）
                if hasUnsavedOutfitChanges {
                    Button(action: { Task { await saveOutfit() } }) {
                        HStack(spacing: 4) {
                            if isSavingOutfit {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                            }
                            Text("保存")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppTheme.primary.opacity(0.12)))
                    }
                    .disabled(isSavingOutfit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // 19.5 三槽位 Tab（帽子/衣服/配件）
            Picker("装扮槽位", selection: $selectedOutfitSlot) {
                ForEach(OutfitSlot.allCases, id: \.self) { slot in
                    Text(slot.rawValue).tag(slot)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            if isLoadingOutfits {
                ProgressView()
                    .padding(.vertical, 24)
            } else {
                outfitItemGrid(for: selectedOutfitSlot)
            }

            Spacer(minLength: 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    /// 当前槽位对应的已选 key
    private func selectedKey(for slot: OutfitSlot) -> String? {
        switch slot {
        case .hat:       return previewHat
        case .clothes:   return previewClothes
        case .accessory: return previewAccessory
        }
    }

    /// 更新预览选中 key（19.6 保存时使用）
    private func setSelectedKey(_ key: String?, for slot: OutfitSlot) {
        switch slot {
        case .hat:       previewHat = key
        case .clothes:   previewClothes = key
        case .accessory: previewAccessory = key
        }
    }

    /// 19.6 — 预览状态与已保存状态是否有差异
    private var hasUnsavedOutfitChanges: Bool {
        guard let status = petStatus else { return false }
        return previewHat != status.hatSlot
            || previewClothes != status.clothSlot
            || previewAccessory != status.accessSlot
    }

    /// 19.6 — 保存装扮：乐观更新 → 调用 API → 失败时回滚预览
    private func saveOutfit() async {
        guard hasUnsavedOutfitChanges else { return }
        isSavingOutfit = true
        outfitSaveError = nil

        // 记录保存前的预览值，用于回滚
        let savedHat = previewHat
        let savedClothes = previewClothes
        let savedAccessory = previewAccessory

        let request = PetOutfitRequest(
            hat: previewHat,
            clothes: previewClothes,
            accessory: previewAccessory
        )

        let result = await gamificationManager.updatePetOutfit(request)
        if let updated = result {
            // 同步最新服务端状态到预览
            petStatus = updated
            previewHat = updated.hatSlot
            previewClothes = updated.clothSlot
            previewAccessory = updated.accessSlot
        } else {
            // 回滚预览到保存前的值
            previewHat = savedHat
            previewClothes = savedClothes
            previewAccessory = savedAccessory
            withAnimation {
                outfitSaveError = "保存失败，请重试"
            }
            // 3 秒后清除错误提示
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation { outfitSaveError = nil }
            }
        }

        isSavingOutfit = false
    }

    @ViewBuilder
    private func outfitItemGrid(for slot: OutfitSlot) -> some View {
        let items = OutfitCatalog.items(for: slot)
        let currentSelected = selectedKey(for: slot)

        if items.isEmpty {
            Text("暂无可用装扮")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textDisabled)
                .padding(.vertical, 20)
        } else {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(items) { item in
                    let isUnlocked = unlockedOutfitKeys.contains(item.id)
                    let isSelected = currentSelected == item.id
                    OutfitItemCell(
                        item: item,
                        isUnlocked: isUnlocked,
                        isSelected: isSelected
                    )
                    .onTapGesture {
                        guard isUnlocked else { return }
                        // 再次点击已选中项则取消选中
                        if isSelected {
                            setSelectedKey(nil, for: slot)
                        } else {
                            setSelectedKey(item.id, for: slot)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
    }

    // MARK: - 19.7 成长历史时间线

    private var levelHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("成长历史")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if sortedLevelHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.textDisabled)
                        Text("升级后这里会记录成长足迹")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textDisabled)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sortedLevelHistory.enumerated()), id: \.element.id) { index, event in
                        levelHistoryRow(event: event, isLast: index == sortedLevelHistory.count - 1)
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer(minLength: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
    }

    private func levelHistoryRow(event: PetLevelEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线轴：圆点 + 竖线
            VStack(spacing: 0) {
                Circle()
                    .fill(levelDotColor(for: event.level))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .padding(.top, 4)
                if !isLast {
                    Rectangle()
                        .fill(AppTheme.primary.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            // 内容区
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 等级徽章
                    Text("Lv.\(event.level)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(levelBadgeColor(for: event.level))
                        )

                    // 解锁道具（若有）
                    if let itemKey = event.unlockedItem,
                       let outfitItem = OutfitCatalog.all.first(where: { $0.id == itemKey }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.secondary)
                            Text("解锁 \(outfitItem.displayName)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondary)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(AppTheme.secondary.opacity(0.12))
                        )
                    }
                }

                // 时间
                Text(formattedDate(event.achievedAt))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textDisabled)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
        .padding(.top, 4)
    }

    /// 根据等级返回时间线圆点颜色
    private func levelDotColor(for level: Int) -> Color {
        switch level {
        case 1..<10:  return AppTheme.primary
        case 10..<20: return AppTheme.secondary
        case 20..<30: return .orange
        case 30..<40: return .pink
        default:      return .yellow
        }
    }

    /// 根据等级返回徽章背景色
    private func levelBadgeColor(for level: Int) -> Color {
        switch level {
        case 1..<10:  return AppTheme.primary
        case 10..<20: return AppTheme.secondary
        case 20..<30: return .orange
        case 30..<40: return .pink
        default:      return Color(red: 0.85, green: 0.65, blue: 0.1)
        }
    }

    /// 将 ISO 8601 字符串格式化为本地可读日期
    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.locale = Locale(identifier: "zh_CN")
            display.dateFormat = "yyyy年M月d日"
            return display.string(from: date)
        }
        // fallback: 截取前 10 字符 YYYY-MM-DD
        return String(isoString.prefix(10))
    }

    // MARK: - Data Loading

    private func loadPetData() async {
        errorMessage = nil
        await gamificationManager.refreshStatus()
        await gamificationManager.loadPetStatus()
        await gamificationManager.loadPetLevelHistory()
        petStatus = gamificationManager.petStatus
        if errorMessage == nil {
            errorMessage = gamificationManager.errorMessage
        }

        // 19.5 — 同步已保存的装扮槽位到预览状态
        if let status = petStatus {
            previewHat = status.hatSlot
            previewClothes = status.clothSlot
            previewAccessory = status.accessSlot
        }

        // 19.5 — 加载已解锁装扮列表
        await loadUnlockedOutfits()
    }

    private func loadUnlockedOutfits() async {
        isLoadingOutfits = true
        do {
            let keys = try await APIService.shared.getUnlockedOutfits()
            unlockedOutfitKeys = Set(keys)
        } catch {
            print("[PetView] loadUnlockedOutfits error: \(error.localizedDescription)")
            if errorMessage == nil { errorMessage = error.localizedDescription }
            // 加载失败时 fallback：将等级 1 的道具视为已解锁
            let level = petLevel
            let fallbackKeys = OutfitCatalog.all
                .filter { $0.requiredLevel <= level }
                .map { $0.id }
            unlockedOutfitKeys = Set(fallbackKeys)
        }
        isLoadingOutfits = false
    }

    // MARK: - 19.4 浣熊互动

    private func handleRaccoonTap() {
        guard !isInteracting else { return }
        isInteracting = true

        // Scale 动画：弹跳放大再回弹
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            raccoonScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                raccoonScale = 1.0
            }
        }

        Task {
            // 调用 interactWithPet API
            let result = await gamificationManager.interactWithPet()
            if result == nil, let managerError = gamificationManager.errorMessage {
                errorMessage = managerError
            }

            // 根据 API 结果决定显示文案
            let phrase: String
            if result != nil {
                // 互动成功，显示鼓励文案
                phrase = randomInteractPhrase()
            } else {
                // 今日已互动
                phrase = alreadyInteractedPhrase()
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                interactText = phrase
                showInteractText = true
            }

            // 2 秒后隐藏文案气泡
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                showInteractText = false
            }
            isInteracting = false
        }
    }

    // MARK: - Helpers

    private func randomInteractPhrase() -> String {
        let phrases: [String]
        switch currentMood {
        case .happy:
            phrases = ["今天状态超棒！继续保持 🎉", "你做到了！浣熊为你骄傲 ⭐️"]
        case .satisfied:
            phrases = ["不错哦，继续记录吧 😊", "浣熊很满足，继续努力 🦝"]
        case .normal:
            phrases = ["今天才刚开始，加油！", "浣熊在等你的下一餐 🦝"]
        case .hungry:
            phrases = ["快去记录今天的第一餐吧！", "浣熊饿了，快去吃点东西 🍜"]
        case .sad:
            phrases = ["今天超标了，明天继续加油 💪", "没关系，明天会更好 🌟"]
        case .missing:
            phrases = ["好久不见！浣熊很想你 🦝", "欢迎回来，一起继续健康之旅 🌿"]
        }
        return phrases.randomElement() ?? "加油！浣熊为你加油 🦝"
    }

    private func alreadyInteractedPhrase() -> String {
        let phrases = [
            "今天已经互动过啦，明天再来 🦝",
            "浣熊今天有点害羞，明天见 😊",
            "今天的爱已经收到了，明天再来 💕"
        ]
        return phrases.randomElement() ?? "今天已经互动过啦，明天再来 🦝"
    }
}

// MARK: - OutfitItemCell

/// 单件装扮道具格子（19.5）
private struct OutfitItemCell: View {
    let item: OutfitItem
    let isUnlocked: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(cellBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .frame(height: 64)

                if isUnlocked {
                    Image(systemName: item.icon)
                        .font(.system(size: 28))
                        .foregroundColor(item.color)
                } else {
                    ZStack {
                        Image(systemName: item.icon)
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.textDisabled)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textDisabled)
                            .offset(x: 12, y: 12)
                    }
                }
            }

            Text(item.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isUnlocked ? AppTheme.textPrimary : AppTheme.textDisabled)
                .lineLimit(1)

            if !isUnlocked {
                Text("Lv.\(item.requiredLevel)")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textDisabled)
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var cellBackground: Color {
        if isSelected {
            return AppTheme.primary.opacity(0.15)
        } else if isUnlocked {
            return Color.white.opacity(0.8)
        } else {
            return AppTheme.backgroundSecondary.opacity(0.5)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return AppTheme.primary
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - OutfitOverlayImage

/// 19.6 — 装扮图片叠加层（静态图片覆盖，无 3D 预览）
///
/// 优先从 Assets.xcassets 加载与 outfitKey 同名的图片；
/// 若图片不存在，则 fallback 到对应道具的 SF Symbol 图标（半透明占位）。
private struct OutfitOverlayImage: View {
    let outfitKey: String
    let size: CGFloat

    private var item: OutfitItem? {
        OutfitCatalog.all.first { $0.id == outfitKey }
    }

    var body: some View {
        if UIImage(named: outfitKey) != nil {
            // 资产中存在对应图片，直接叠加
            Image(outfitKey)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .allowsHitTesting(false)
        } else if let item = item {
            // Fallback：SF Symbol 占位（半透明，右上角偏移）
            Image(systemName: item.icon)
                .font(.system(size: size * 0.28))
                .foregroundColor(item.color.opacity(0.85))
                .frame(width: size, height: size, alignment: .topTrailing)
                .padding(.trailing, size * 0.05)
                .padding(.top, size * 0.04)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Preview

#Preview {
    PetView()
        .environmentObject(GamificationManager.shared)
}
