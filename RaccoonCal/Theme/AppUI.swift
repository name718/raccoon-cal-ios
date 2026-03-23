import SwiftUI

enum AppLayout {
    static let mainTabContentBottomInset: CGFloat = 118
}

enum AppButtonKind {
    case primary
    case secondary
    case destructive
}

enum AppDialogTone {
    case info
    case success
    case warning
    case error

    var iconName: String {
        switch self {
        case .info:
            return "sparkles"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .info:
            return AppTheme.primary
        case .success:
            return AppTheme.success
        case .warning:
            return AppTheme.warning
        case .error:
            return AppTheme.error
        }
    }
}

struct AppDialogAction {
    let title: String
    let role: ButtonRole?
    let handler: (() -> Void)?

    init(_ title: String, role: ButtonRole? = nil, handler: (() -> Void)? = nil) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}

struct AppBottomSheetActionItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemImage: String
    let tintColor: Color
    let handler: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tintColor: Color = AppTheme.primary,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tintColor = tintColor
        self.handler = handler
    }
}

struct AppRoundedButtonStyle: ButtonStyle {
    let kind: AppButtonKind
    let fullWidth: Bool

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 54)
            .padding(.horizontal, fullWidth ? 0 : 18)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: shadowColor.opacity(configuration.isPressed ? 0.12 : 0.2),
                radius: configuration.isPressed ? 6 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.58)
            .animation(.spring(response: 0.24, dampingFraction: 0.8), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary, .destructive:
            return .white
        case .secondary:
            return AppTheme.textPrimary
        }
    }

    private var shadowColor: Color {
        switch kind {
        case .primary:
            return AppTheme.primary
        case .secondary:
            return Color.black
        case .destructive:
            return AppTheme.error
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .primary:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.gradientPrimary)
        case .secondary:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.88))
        case .destructive:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.error],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private var border: some View {
        switch kind {
        case .secondary:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

private struct AppInputFieldModifier: ViewModifier {
    let isInvalid: Bool

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: isInvalid ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var borderColor: Color {
        isInvalid ? AppTheme.error.opacity(0.85) : AppTheme.primary.opacity(0.14)
    }
}

private struct AppDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let tone: AppDialogTone
    let primaryAction: AppDialogAction
    let secondaryAction: AppDialogAction?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isPresented)

            if isPresented {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(tone.tintColor.opacity(0.14))
                            .frame(width: 64, height: 64)

                        Image(systemName: tone.iconName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(tone.tintColor)
                    }

                    VStack(spacing: 10) {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    VStack(spacing: 12) {
                        if let secondaryAction {
                            Button(secondaryAction.title) {
                                dismiss()
                                secondaryAction.handler?()
                            }
                            .appButtonStyle(kind: buttonKind(for: secondaryAction), fullWidth: true)
                        }

                        Button(primaryAction.title) {
                            dismiss()
                            primaryAction.handler?()
                        }
                        .appButtonStyle(kind: buttonKind(for: primaryAction), fullWidth: true)
                    }
                }
                .padding(24)
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.16), radius: 24, x: 0, y: 12)
                .padding(.horizontal, 28)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isPresented)
    }

    private func dismiss() {
        isPresented = false
    }

    private func buttonKind(for action: AppDialogAction) -> AppButtonKind {
        switch action.role {
        case .destructive:
            return .destructive
        case .cancel:
            return .secondary
        default:
            return .primary
        }
    }
}

private struct AppDelayedLoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    let delayNanoseconds: UInt64

    @State private var shouldShowOverlay = false

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(shouldShowOverlay)

            if shouldShowOverlay {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()

                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AppTheme.primary)
                            .scaleEffect(1.15)

                        Text(message)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 40)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .task(id: isLoading) {
            shouldShowOverlay = false
            guard isLoading else { return }

            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled, isLoading else { return }
            shouldShowOverlay = true
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShowOverlay)
    }
}

private struct AppBottomSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let actions: [AppBottomSheetActionItem]
    let dismissTitle: String

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
                .disabled(isPresented)

            if isPresented {
                Color.black.opacity(0.14)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)

                VStack(spacing: 14) {
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 42, height: 5)
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        if let message, !message.isEmpty {
                            Text(message)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        ForEach(actions) { action in
                            Button {
                                dismiss()
                                action.handler()
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(action.tintColor.opacity(0.14))
                                            .frame(width: 52, height: 52)

                                        Image(systemName: action.systemImage)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(action.tintColor)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(action.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppTheme.textPrimary)

                                        if let subtitle = action.subtitle {
                                            Text(subtitle)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(AppTheme.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textDisabled)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    Button(dismissTitle) {
                        dismiss()
                    }
                    .appButtonStyle(kind: .secondary, fullWidth: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                        )
                        .ignoresSafeArea(edges: .bottom)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 22, x: 0, y: 10)
                .padding(.horizontal, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.86), value: isPresented)
    }

    private func dismiss() {
        isPresented = false
    }
}

extension View {
    func appButtonStyle(kind: AppButtonKind = .primary, fullWidth: Bool = true) -> some View {
        buttonStyle(AppRoundedButtonStyle(kind: kind, fullWidth: fullWidth))
    }

    func appInputFieldStyle(isInvalid: Bool = false) -> some View {
        modifier(AppInputFieldModifier(isInvalid: isInvalid))
    }

    func appDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        tone: AppDialogTone = .info,
        primaryAction: AppDialogAction = AppDialogAction("确定"),
        secondaryAction: AppDialogAction? = nil
    ) -> some View {
        modifier(
            AppDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                tone: tone,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction
                )
        )
    }

    func delayedLoadingOverlay(
        isLoading: Bool,
        message: String = "加载中...",
        delayNanoseconds: UInt64 = 2_000_000_000
    ) -> some View {
        modifier(
            AppDelayedLoadingOverlayModifier(
                isLoading: isLoading,
                message: message,
                delayNanoseconds: delayNanoseconds
            )
        )
    }

    func appBottomSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        actions: [AppBottomSheetActionItem],
        dismissTitle: String = "取消"
    ) -> some View {
        modifier(
            AppBottomSheetModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                actions: actions,
                dismissTitle: dismissTitle
            )
        )
    }

    func appMainTabScrollableContent() -> some View {
        padding(.bottom, AppLayout.mainTabContentBottomInset)
    }
}
