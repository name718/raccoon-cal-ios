//
//  CameraView.swift
//  RaccoonCal
//

import SwiftUI
import AVFoundation
import PhotosUI
import UIKit

// MARK: - CameraSessionController

final class CameraSessionController: ObservableObject {
    @Published private(set) var permissionStatus: AVAuthorizationStatus =
        CameraSessionController.currentPermissionStatus()

    let session: AVCaptureSession?
    private let photoOutput: AVCapturePhotoOutput?
    private let sessionQueue = DispatchQueue(
        label: "com.raccooncal.camera.session",
        qos: .userInitiated
    )

    private var isConfigured = false
    private var captureDelegate: PhotoCaptureDelegate?

    init() {
        #if targetEnvironment(simulator)
        self.session = nil
        self.photoOutput = nil
        #else
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        self.session = session
        self.photoOutput = AVCapturePhotoOutput()
        #endif
    }

    @MainActor
    func refreshPermissionStatus() {
        permissionStatus = Self.currentPermissionStatus()
    }

    func ensureSessionRunning() {
        guard let session else { return }
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        Task { @MainActor in
            permissionStatus = status
        }

        switch status {
        case .authorized:
            sessionQueue.async { [weak self] in
                self?.configureSessionIfNeeded()
                guard let self, !session.isRunning else { return }
                session.startRunning()
            }

        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                await MainActor.run {
                    self.permissionStatus = granted ? .authorized : .denied
                }

                guard granted else { return }
                self.ensureSessionRunning()
            }

        case .denied, .restricted:
            break

        @unknown default:
            break
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, let session = self.session, session.isRunning else { return }
            session.stopRunning()
        }
    }

    func capturePhoto() async -> Data? {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self,
                      let session = self.session,
                      let photoOutput = self.photoOutput,
                      session.isRunning else {
                    continuation.resume(returning: nil)
                    return
                }

                let delegate = PhotoCaptureDelegate(continuation: continuation) { [weak self] in
                    self?.captureDelegate = nil
                }
                self.captureDelegate = delegate

                let settings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured, let session, let photoOutput else { return }

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        if session.inputs.isEmpty,
           let device = AVCaptureDevice.default(
               .builtInWideAngleCamera,
               for: .video,
               position: .back
           ),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        if !session.outputs.contains(photoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }

    private static func currentPermissionStatus() -> AVAuthorizationStatus {
        #if targetEnvironment(simulator)
        return .denied
        #else
        return AVCaptureDevice.authorizationStatus(for: .video)
        #endif
    }
}

// MARK: - CameraPreviewView (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }
}

// MARK: - PhotoCaptureDelegate

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: CheckedContinuation<Data?, Never>
    private let onFinish: (() -> Void)?

    init(
        continuation: CheckedContinuation<Data?, Never>,
        onFinish: (() -> Void)? = nil
    ) {
        self.continuation = continuation
        self.onFinish = onFinish
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            continuation.resume(returning: nil)
        } else {
            continuation.resume(returning: photo.fileDataRepresentation())
        }
        onFinish?()
    }
}

// MARK: - PhotoLibraryPicker (iOS 15 compatible)

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onPick: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onPick: (Data) -> Void

        init(onPick: @escaping (Data) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let itemProvider = results.first?.itemProvider,
                  itemProvider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.95) else {
                    return
                }

                DispatchQueue.main.async {
                    self.onPick(data)
                }
            }
        }
    }
}

// MARK: - CameraView

struct ManualFoodDraft: Identifiable {
    let id = UUID()
    let mealType: MealType
    let food: RecognizedFood
    let photoData: Data?

    static func blank(mealType: MealType = .lunch) -> ManualFoodDraft {
        ManualFoodDraft(
            mealType: mealType,
            food: RecognizedFood(
                name: "",
                calories: 0,
                protein: 0,
                fat: 0,
                carbs: 0,
                servingSize: 100,
                mealType: mealType.rawValue
            ),
            photoData: nil
        )
    }

    static func fromRecognition(
        _ result: FoodRecognitionResult,
        photoData: Data?,
        fallbackMealType: MealType = .lunch
    ) -> ManualFoodDraft {
        guard let firstFood = result.foods.first else {
            return blank(mealType: fallbackMealType).copy(photoData: photoData)
        }

        let resolvedMealType =
            MealType(rawValue: firstFood.mealType ?? fallbackMealType.rawValue) ??
            fallbackMealType

        let normalizedFood = RecognizedFood(
            name: firstFood.name,
            calories: firstFood.calories,
            protein: firstFood.protein,
            fat: firstFood.fat,
            carbs: firstFood.carbs,
            servingSize: firstFood.servingSize,
            mealType: resolvedMealType.rawValue
        )

        return ManualFoodDraft(
            mealType: resolvedMealType,
            food: normalizedFood,
            photoData: photoData
        )
    }

    func copy(photoData: Data?) -> ManualFoodDraft {
        ManualFoodDraft(
            mealType: mealType,
            food: food,
            photoData: photoData
        )
    }
}

struct CameraView: View {
    var body: some View {
        Color.clear
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

struct AddRecordCameraCaptureView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    let onClose: () -> Void
    let onCaptured: (Data) -> Void

    @StateObject private var cameraController = CameraSessionController()
    @State private var isCapturing = false
    @State private var errorMessage: String? = nil

    private var cameraBottomCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: isCapturing ? "sparkles" : "camera.aperture")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(isCapturing ? "正在处理照片" : "拍照识别")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(isCapturing
                         ? "拍照完成后会先进行识别，再自动带入手动填写页。"
                         : "拍一张食物照片，识别成功后自动回填；即使识别失败，也能继续手动填写。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                statusChip(
                    icon: isCapturing ? "bolt.badge.clock.fill" : "wand.and.stars",
                    title: isCapturing ? "处理中" : "自动回填"
                )

                statusChip(
                    icon: "slider.horizontal.3",
                    title: "可继续修改"
                )
            }

            if isCapturing {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.95)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("正在保存照片并准备识别")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("通常只需要几秒钟，请保持当前页面。")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
            } else {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("对准食物主体拍摄")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("画面清晰、光线充足时识别会更稳定。")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                    }

                    Spacer()

                    Button(action: capturePhotoAndContinue) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.92), lineWidth: 4)
                                .frame(width: 78, height: 78)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 62, height: 62)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppTheme.primary)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("拍照并继续")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 26, x: 0, y: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    var body: some View {
        ZStack {
            if shouldShowLiveCameraPreview, let session = cameraController.session {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.88), AppTheme.textPrimary.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                permissionPlaceholderView
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.56),
                    .clear,
                    Color.black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                if shouldShowLiveCameraPreview {
                    cameraBottomCard
                }
            }
        }
        .onAppear {
            startSession()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                cameraController.refreshPermissionStatus()
                startSession()
            case .background, .inactive:
                stopSession()
            @unknown default:
                break
            }
        }
        .onDisappear {
            stopSession()
        }
        .appDialog(
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        errorMessage = nil
                    }
                }
            ),
            title: "拍照失败",
            message: errorMessage ?? "请稍后重试",
            tone: .error,
            primaryAction: AppDialogAction("重新拍照") {
                errorMessage = nil
                capturePhotoAndContinue()
            },
            secondaryAction: AppDialogAction("返回") {
                errorMessage = nil
            }
        )
    }

    private var permissionPlaceholderView: some View {
        VStack {
            Spacer()

            VStack(spacing: 22) {
                Image("RaccoonThinking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                VStack(spacing: 8) {
                    Text(simulatorCameraUnavailable ? "当前设备不支持实时相机" : "需要开启相机权限")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text(permissionDescriptionText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    statusChip(
                        icon: simulatorCameraUnavailable ? "iphone.slash" : "camera.fill",
                        title: simulatorCameraUnavailable ? "真机可用" : "需要授权"
                    )

                    statusChip(icon: "square.and.pencil", title: "可继续手填")
                }

                VStack(spacing: 12) {
                    if !simulatorCameraUnavailable {
                        Button(action: openAppSettings) {
                            Text("去设置开启权限")
                                .frame(maxWidth: .infinity)
                        }
                        .appButtonStyle(kind: .primary, fullWidth: true)
                    }

                    Button(action: onClose) {
                        Text("先返回")
                            .frame(maxWidth: .infinity)
                    }
                    .appButtonStyle(kind: .secondary, fullWidth: true)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func startSession() {
        guard !simulatorCameraUnavailable else {
            cameraController.refreshPermissionStatus()
            return
        }
        cameraController.ensureSessionRunning()
    }

    private func stopSession() {
        cameraController.stopSession()
    }

    private func openAppSettings() {
        guard !simulatorCameraUnavailable else { return }
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(url)
    }

    private func capturePhotoAndContinue() {
        Task { await performCapture() }
    }

    @MainActor
    private func performCapture() async {
        isCapturing = true
        errorMessage = nil
        defer { isCapturing = false }

        guard let rawData = await cameraController.capturePhoto() else {
            errorMessage = "拍照失败，请重试"
            return
        }

        onCaptured(rawData)
    }

    private var simulatorCameraUnavailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private var shouldShowLiveCameraPreview: Bool {
        !simulatorCameraUnavailable
            && cameraController.session != nil
            && cameraController.permissionStatus == .authorized
    }

    private var permissionDescriptionText: String {
        if simulatorCameraUnavailable {
            return "模拟器里不支持实时拍照，请在真机上使用拍照识别；你也可以先返回，直接进入手动填写。"
        }
        return "开启后即可直接拍照识别；识别完成后会自动进入可编辑的手动填写页。"
    }

    private func statusChip(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
    }
}

// MARK: - Preview

#Preview {
    AddRecordCameraCaptureView(onClose: {}, onCaptured: { _ in })
}
