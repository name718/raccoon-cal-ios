//
//  CameraView.swift
//  RaccoonCal
//

import SwiftUI
import AVFoundation
import PhotosUI

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

struct CameraView: View {

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @StateObject private var cameraController = CameraSessionController()
    @State private var capturedImage: UIImage? = nil
    @State private var recognitionResult: FoodRecognitionResult? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedMealType: String = MealType.lunch.rawValue
    @State private var showPhotoPicker: Bool = false
    @State private var showManualEntryEditor: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview (only shown when authorized)
            if shouldShowLiveCameraPreview, let session = cameraController.session {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                // 17.9 — 未授权时展示引导占位视图
                Color.black.ignoresSafeArea()
                permissionPlaceholderView
            }

            // Controls overlay (only when authorized)
            if shouldShowLiveCameraPreview {
                VStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.bottom, 48)
                    } else {
                        HStack(spacing: 40) {
                            Button(action: { showPhotoPicker = true }) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .frame(width: 52, height: 52)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("从相册选取")

                            Button(action: captureAndUpload) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 4)
                                        .frame(width: 72, height: 72)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 58, height: 58)
                                }
                            }
                            .accessibilityLabel("拍照")

                            Button(action: { showManualEntryEditor = true }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                                    .frame(width: 52, height: 52)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("手动记录")
                        }
                        .padding(.bottom, 48)
                    }
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker { rawData in
                Task {
                    await loadAndUploadPickedPhoto(rawData)
                }
            }
        }
        .sheet(isPresented: $showManualEntryEditor) {
            ManualFoodEntrySheet(
                initialMealType: MealType(rawValue: selectedMealType) ?? .lunch,
                onSaved: { _ in
                    showManualEntryEditor = false
                }
            )
        }
        .sheet(item: $recognitionResult) { result in
            resultSheetView(for: result)
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
            title: "操作失败",
            message: errorMessage ?? "请稍后重试",
            tone: .error,
            primaryAction: AppDialogAction("确定") {
                errorMessage = nil
            }
        )
    }

    // MARK: - 17.9 Permission Placeholder View

    private var permissionPlaceholderView: some View {
        VStack(spacing: 24) {
            Image("RaccoonThinking")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text(simulatorCameraUnavailable ? "模拟器不支持实时相机" : "需要相机权限")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(permissionDescriptionText)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: {
                    showPhotoPicker = true
                }) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                }
                .appButtonStyle(kind: .primary, fullWidth: false)

                Button(action: {
                    showManualEntryEditor = true
                }) {
                    Label("手动记录", systemImage: "square.and.pencil")
                }
                .appButtonStyle(kind: .secondary, fullWidth: false)

                if !simulatorCameraUnavailable {
                    Button(action: {
                        openAppSettings()
                    }) {
                        Text("去设置")
                    }
                    .appButtonStyle(kind: .secondary, fullWidth: false)
                }
            }
        }
        .padding(32)
    }

    // MARK: - Session Lifecycle (17.9 — permission-aware)

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

    // MARK: - Capture & Upload

    private func captureAndUpload() {
        Task { await performCaptureAndUpload() }
    }

    @MainActor
    private func performCaptureAndUpload() async {
        isLoading = true
        errorMessage = nil

        guard let rawData = await capturePhoto() else {
            errorMessage = "拍照失败，请重试"
            isLoading = false
            return
        }

        guard let imageData = resizedJpegData(from: rawData, maxWidth: 800, compressionQuality: 0.8) else {
            errorMessage = "图片处理失败，请重试"
            isLoading = false
            return
        }

        do {
            let result = try await APIService.shared.recognizeFood(imageData: imageData)
            recognitionResult = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func capturePhoto() async -> Data? {
        await cameraController.capturePhoto()
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
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    // MARK: - Photo Library

    @MainActor
    private func loadAndUploadPickedPhoto(_ rawData: Data) async {
        isLoading = true
        errorMessage = nil

        guard let imageData = resizedJpegData(from: rawData, maxWidth: 800, compressionQuality: 0.8) else {
            errorMessage = "图片处理失败，请重试"
            isLoading = false
            return
        }

        do {
            let result = try await APIService.shared.recognizeFood(imageData: imageData)
            recognitionResult = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @ViewBuilder
    private func resultSheetView(for result: FoodRecognitionResult) -> some View {
        let sheet = FoodResultSheet(
            result: result,
            onDismiss: { recognitionResult = nil },
            onManualEntry: { syntheticResult in
                recognitionResult = syntheticResult
            }
        )

        if #available(iOS 16.0, *) {
            sheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        } else {
            sheet
        }
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
            return "当前在 iPhone 模拟器中运行，实时相机能力不可用。\n你可以直接从相册选择图片继续测试。"
        }
        return "RaccoonCal 需要访问您的相机\n来拍摄食物照片"
    }
}

// MARK: - Preview

#Preview {
    CameraView()
}
