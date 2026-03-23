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

    var body: some View {
        ZStack {
            if shouldShowLiveCameraPreview, let session = cameraController.session {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                permissionPlaceholderView
            }

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
                    VStack(spacing: 14) {
                        Text("拍照后会自动进入手动填写页")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        if isCapturing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                                .padding(.bottom, 48)
                        } else {
                            Button(action: capturePhotoAndContinue) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 4)
                                        .frame(width: 72, height: 72)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 58, height: 58)
                                }
                            }
                            .accessibilityLabel("拍照并继续")
                            .padding(.bottom, 48)
                        }
                    }
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
            primaryAction: AppDialogAction("确定") {
                errorMessage = nil
            }
        )
    }

    private var permissionPlaceholderView: some View {
        VStack(spacing: 24) {
            Image("RaccoonThinking")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text(simulatorCameraUnavailable ? "当前设备不支持实时相机" : "需要相机权限")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(permissionDescriptionText)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                if !simulatorCameraUnavailable {
                    Button(action: openAppSettings) {
                        Text("去设置")
                    }
                    .appButtonStyle(kind: .primary, fullWidth: false)
                }

                Button(action: onClose) {
                    Text("返回")
                }
                .appButtonStyle(kind: .secondary, fullWidth: false)
            }
        }
        .padding(32)
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
            return "模拟器里不支持拍照。\n请返回后选择“从相册选择”继续。"
        }
        return "请开启相机权限，拍照后会自动进入手动填写页。"
    }
}

// MARK: - Preview

#Preview {
    AddRecordCameraCaptureView(onClose: {}, onCaptured: { _ in })
}
