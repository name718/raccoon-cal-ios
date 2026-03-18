//
//  CameraView.swift
//  RaccoonCal
//

import SwiftUI
import AVFoundation
import PhotosUI

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

    init(continuation: CheckedContinuation<Data?, Never>) {
        self.continuation = continuation
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            continuation.resume(returning: nil)
        } else {
            continuation.resume(returning: photo.fileDataRepresentation())
        }
    }
}

// MARK: - CameraView

struct CameraView: View {

    @EnvironmentObject var gamificationManager: GamificationManager

    // MARK: - State

    @State private var capturedImage: UIImage? = nil
    @State private var recognitionResult: FoodRecognitionResult? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedMealType: String = MealType.lunch.rawValue
    @State private var showPhotoPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // 17.9 — 相机权限状态
    @State private var cameraPermissionStatus: AVAuthorizationStatus =
        AVCaptureDevice.authorizationStatus(for: .video)
    @State private var showPermissionAlert: Bool = false

    // MARK: - Camera Session

    private let captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        return session
    }()

    private let photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()

    @State private var captureDelegate: PhotoCaptureDelegate? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview (only shown when authorized)
            if cameraPermissionStatus == .authorized {
                CameraPreviewView(session: captureSession)
                    .ignoresSafeArea()
            } else {
                // 17.9 — 未授权时展示引导占位视图
                Color.black.ignoresSafeArea()
                permissionPlaceholderView
            }

            // Controls overlay (only when authorized)
            if cameraPermissionStatus == .authorized {
                VStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.bottom, 48)
                    } else {
                        HStack(spacing: 40) {
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
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

                            Color.clear.frame(width: 52, height: 52)
                        }
                        .padding(.bottom, 48)
                    }
                }
            }
        }
        .sheet(item: $recognitionResult) { result in
            FoodResultSheet(
                result: result,
                onDismiss: { recognitionResult = nil },
                onManualEntry: { syntheticResult in
                    recognitionResult = syntheticResult
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        // 17.9 — 权限引导弹窗
        .alert("需要相机权限", isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("RaccoonCal 需要访问您的相机来拍摄食物照片，请在设置中允许相机访问。")
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            stopSession()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadAndUploadPickedPhoto(newItem) }
        }
    }

    // MARK: - 17.9 Permission Placeholder View

    private var permissionPlaceholderView: some View {
        VStack(spacing: 24) {
            Image("RaccoonThinking")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text("需要相机权限")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("RaccoonCal 需要访问您的相机\n来拍摄食物照片")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("去设置")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 160, height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
            }
        }
        .padding(32)
    }

    // MARK: - Session Lifecycle (17.9 — permission-aware)

    private func startSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionStatus = status

        switch status {
        case .authorized:
            setupAndStartSession()

        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                await MainActor.run {
                    cameraPermissionStatus = granted ? .authorized : .denied
                    if granted {
                        setupAndStartSession()
                    } else {
                        showPermissionAlert = true
                    }
                }
            }

        case .denied, .restricted:
            showPermissionAlert = true

        @unknown default:
            showPermissionAlert = true
        }
    }

    private func setupAndStartSession() {
        guard !captureSession.isRunning else { return }

        if captureSession.inputs.isEmpty,
           let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    private func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.stopRunning()
        }
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
        return await withCheckedContinuation { continuation in
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            DispatchQueue.main.async { self.captureDelegate = delegate }
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: delegate)
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
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    // MARK: - Photo Library

    @MainActor
    private func loadAndUploadPickedPhoto(_ item: PhotosPickerItem) async {
        isLoading = true
        errorMessage = nil
        defer { selectedPhotoItem = nil }

        guard let rawData = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = "无法读取所选图片，请重试"
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
}

// MARK: - Preview

#Preview {
    CameraView()
        .environmentObject(GamificationManager.shared)
}
