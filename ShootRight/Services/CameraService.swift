import AVFoundation
import UIKit
import CoreImage

/// AVFoundation 相机封装：取景、分析帧、拍照
final class CameraService: NSObject {

    enum CameraError: LocalizedError {
        case noCamera
        case denied
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .noCamera: return "未找到可用摄像头"
            case .denied: return "需要相机权限，请在 设置 > 隐私 > 相机 中开启"
            case .captureFailed: return "拍照失败，请重试"
            }
        }
    }

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.shootright.camera.session")
    private let videoQueue = DispatchQueue(label: "com.shootright.camera.video")

    private var deviceInput: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoCompletion: ((Result<UIImage, Error>) -> Void)?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var frameCounter = 0
    private(set) var isConfigured = false

    /// 分析帧回调（视频输出队列线程），参数：(像素缓冲, 竖屏直立尺寸)
    var onAnalysisFrame: ((CVPixelBuffer, CGSize) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - 配置

    func configure() async throws {
        let authorized = await withCheckedContinuation { cont in
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                cont.resume(returning: true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            default:
                cont.resume(returning: false)
            }
        }
        guard authorized else { throw CameraError.denied }

        try sessionQueue.sync {
            session.beginConfiguration()
            session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else {
                throw CameraError.noCamera
            }
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                deviceInput = input
            }

            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }

            photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            videoOutput.connection(with: .video)?.videoOrientation = .portrait
            photoOutput.connection(with: .video)?.videoOrientation = .portrait

            session.commitConfiguration()
            isConfigured = true
        }
    }

    func start() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - 切换摄像头

    func switchCamera() {
        sessionQueue.async {
            guard let input = self.deviceInput else { return }
            let newPosition: AVCaptureDevice.Position = (input.device.position == .back) ? .front : .back
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: device) else { return }

            self.session.beginConfiguration()
            self.session.removeInput(input)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.deviceInput = newInput
                self.currentPosition = newPosition
            } else {
                self.session.addInput(input)
            }
            self.videoOutput.connection(with: .video)?.videoOrientation = .portrait
            self.photoOutput.connection(with: .video)?.videoOrientation = .portrait
            self.session.commitConfiguration()
        }
    }

    // MARK: - 拍照

    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        sessionQueue.async {
            guard self.photoOutput.connection(with: .video) != nil else {
                completion(.failure(CameraError.captureFailed))
                return
            }
            self.photoCompletion = completion
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - 分析帧输出

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        frameCounter += 1
        // 每 8 帧抽 1 帧做 AI 分析（约 3-4fps）
        if frameCounter % 8 == 0 {
            // 竖屏直立后的尺寸（宽高对调）
            let uprightSize = CGSize(width: CVPixelBufferGetHeight(buffer),
                                     height: CVPixelBufferGetWidth(buffer))
            onAnalysisFrame?(buffer, uprightSize)
        }
    }
}

// MARK: - 照片输出

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            photoCompletion?(.failure(error))
            photoCompletion = nil
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            photoCompletion?(.failure(CameraError.captureFailed))
            photoCompletion = nil
            return
        }
        photoCompletion?(.success(image))
        photoCompletion = nil
    }
}
