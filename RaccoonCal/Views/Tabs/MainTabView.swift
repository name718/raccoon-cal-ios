//
//  MainTabView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI
import UIKit

private enum AddEntryErrorContext {
    case imageRecognition
    case imageProcessing
}

struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @State private var showCameraCapture = false
    @State private var isRecognizingImage = false
    @State private var addEntryErrorMessage: String? = nil
    @State private var addEntryErrorTitle = "识别失败"
    @State private var addEntryErrorContext: AddEntryErrorContext? = nil
    @State private var manualDraft: ManualFoodDraft? = nil
    @State private var pendingRecognitionFallbackDraft: ManualFoodDraft? = nil
    @State private var loadedTabs: Set<Int> = [AppState.shared.selectedTab]

    private var addSheetActions: [AppBottomSheetActionItem] {
        [
            AppBottomSheetActionItem(
                title: "手动记录",
                subtitle: "直接填写食物、餐次、份量和营养信息",
                systemImage: "square.and.pencil",
                tintColor: AppTheme.primary
            ) {
                manualDraft = ManualFoodDraft.blank()
            },
            AppBottomSheetActionItem(
                title: "拍照识别",
                subtitle: "拍一张食物照片，识别后自动进入手动填写页",
                systemImage: "camera.fill",
                tintColor: AppTheme.secondary
            ) {
                showCameraCapture = true
            }
        ]
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            tabContainer
        }
        .environmentObject(appState)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .onAppear {
            ensureTabLoaded(appState.selectedTab)
        }
        .onChange(of: appState.selectedTab) { newValue in
            ensureTabLoaded(newValue)
        }
        .appBottomSheet(
            isPresented: $appState.showAddEntryOptions,
            title: "添加记录",
            message: "选择手动填写或直接拍照识别，识别后会自动回填到表单。",
            actions: addSheetActions
        )
        .fullScreenCover(isPresented: $showCameraCapture) {
            AddRecordCameraCaptureView(
                onClose: {
                    showCameraCapture = false
                },
                onCaptured: { rawData in
                    showCameraCapture = false
                    Task {
                        await recognizeImageAndOpenForm(rawData)
                    }
                }
            )
        }
        .fullScreenCover(item: $manualDraft) { draft in
            ManualFoodEntrySheet(
                initialMealType: draft.mealType,
                initialFood: draft.food,
                initialPhotoData: draft.photoData,
                onSaved: { _ in
                    manualDraft = nil
                }
            )
        }
        .delayedLoadingOverlay(
            isLoading: isRecognizingImage,
            message: "正在分析图片并整理为可编辑表单...",
            delayNanoseconds: 450_000_000
        )
        .appDialog(
            isPresented: Binding(
                get: { addEntryErrorMessage != nil },
                set: { newValue in
                    if !newValue {
                        addEntryErrorMessage = nil
                        addEntryErrorContext = nil
                    }
                }
            ),
            title: addEntryErrorTitle,
            message: addEntryErrorMessage ?? "请稍后重试",
            tone: .error,
            primaryAction: AppDialogAction(pendingRecognitionFallbackDraft == nil ? "重新拍照" : "继续手动填写") {
                if let fallback = pendingRecognitionFallbackDraft {
                    manualDraft = fallback
                } else {
                    showCameraCapture = true
                }
                addEntryErrorMessage = nil
                pendingRecognitionFallbackDraft = nil
                addEntryErrorContext = nil
            },
            secondaryAction: AppDialogAction(pendingRecognitionFallbackDraft == nil ? "稍后再试" : "重新拍照") {
                if pendingRecognitionFallbackDraft != nil {
                    showCameraCapture = true
                }
                addEntryErrorMessage = nil
                pendingRecognitionFallbackDraft = nil
                addEntryErrorContext = nil
            }
        )
    }

    @ViewBuilder
    private var tabContainer: some View {
        ZStack {
            tabPage(tag: 0) {
                HomeView()
            }

            tabPage(tag: 1) {
                RecordView()
            }

            tabPage(tag: 3) {
                PetView()
            }

            tabPage(tag: 4) {
                ProfileView()
            }
        }
    }

    @ViewBuilder
    private func tabPage<Content: View>(tag: Int, @ViewBuilder content: () -> Content) -> some View {
        if loadedTabs.contains(tag) {
            content()
                .opacity(appState.selectedTab == tag ? 1 : 0)
                .allowsHitTesting(appState.selectedTab == tag)
                .accessibilityHidden(appState.selectedTab != tag)
                .zIndex(appState.selectedTab == tag ? 1 : 0)
        }
    }

    @MainActor
    private func recognizeImageAndOpenForm(_ rawData: Data) async {
        isRecognizingImage = true
        addEntryErrorMessage = nil
        addEntryErrorContext = nil
        defer { isRecognizingImage = false }

        guard let imageData = resizedJpegData(from: rawData, maxWidth: 800, compressionQuality: 0.8) else {
            addEntryErrorTitle = "图片处理失败"
            addEntryErrorContext = .imageProcessing
            addEntryErrorMessage = "这张照片暂时无法处理，请重新拍一张，或稍后再试。"
            return
        }

        do {
            let result = try await APIService.shared.recognizeFood(imageData: imageData)
            manualDraft = ManualFoodDraft.fromRecognition(result, photoData: imageData)
        } catch {
            addEntryErrorTitle = "识别暂时不可用"
            addEntryErrorContext = .imageRecognition
            pendingRecognitionFallbackDraft = ManualFoodDraft.blank().copy(photoData: imageData)
            addEntryErrorMessage = "图片已经拍好，但暂时无法完成识别。你可以继续手动填写，稍后再试识别。\n\n\(error.localizedDescription)"
        }
    }

    private func resizedJpegData(from data: Data, maxWidth: CGFloat, compressionQuality: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let originalSize = image.size
        guard originalSize.width > maxWidth else {
            return image.jpegData(compressionQuality: compressionQuality)
        }

        let scale = maxWidth / originalSize.width
        let newSize = CGSize(width: maxWidth, height: originalSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    private func ensureTabLoaded(_ tag: Int) {
        guard tag != 2 else { return }
        loadedTabs.insert(tag)
    }

    private var customTabBar: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            let effectiveBottomInset = max(bottomInset, 6)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 0.5)

                    HStack(spacing: 8) {
                        tabBarItem(
                            title: "首页",
                            systemImage: "house.fill",
                            tag: 0
                        )

                        tabBarItem(
                            title: "记录",
                            systemImage: "list.clipboard.fill",
                            tag: 1
                        )

                        Spacer(minLength: 78)

                        tabBarItem(
                            title: "浣熊",
                            systemImage: "pawprint.fill",
                            tag: 3
                        )

                        tabBarItem(
                            title: "我的",
                            systemImage: "person.fill",
                            tag: 4
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, effectiveBottomInset)
                    .frame(height: 56 + effectiveBottomInset, alignment: .top)
                }
                .background(tabBarBaseColor)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -1)
                .ignoresSafeArea(edges: .bottom)

                ZStack {
                    Capsule(style: .continuous)
                        .fill(tabBarBaseColor)
                        .frame(width: 92, height: 26)
                        .offset(y: 12)

                    Circle()
                        .fill(tabBarBaseColor)
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                        )

                    Button(action: {
                        appState.presentAddEntryOptions()
                    }) {
                        Circle()
                            .fill(AppTheme.gradientPrimary)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("添加记录")
                }
                .shadow(color: AppTheme.primary.opacity(0.16), radius: 10, x: 0, y: 5)
                .offset(y: -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 82)
        .ignoresSafeArea(.keyboard)
    }

    private var tabBarBaseColor: Color {
        Color(
            uiColor: UIColor(
                red: 255 / 255,
                green: 251 / 255,
                blue: 245 / 255,
                alpha: 1
            )
        )
    }

    private func tabBarItem(title: String, systemImage: String, tag: Int) -> some View {
        let isSelected = appState.selectedTab == tag

        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                appState.selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.textDisabled)

                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AppTheme.primary.opacity(0.10) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
