import UIKit
import SwiftUI
import AVFoundation
import CoreImage

/// 相机控制器：总装相机 / 识别 / 规则引擎 / 叠加层
final class CameraViewController: UIViewController {

    private let state: CameraUIState
    private let camera = CameraService()
    private let classifier = SceneClassifier()
    private let detector = SubjectDetector()
    private let motion = MotionManager()

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private var analysisCounter = 0
    private var lastClassifiedScene: PhotoScene = .unknown

    init(state: CameraUIState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPreviewLayer()
        setupOverlay()
        wireCallbacks()
        startPipeline()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override var prefersStatusBarHidden: Bool { true }

    deinit {
        camera.stop()
        motion.stop()
    }

    // MARK: - 初始化

    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: camera.session)
        layer.videoGravity = .resizeAspectFill
        layer.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    private func setupOverlay() {
        let host = UIHostingController(rootView: CameraOverlayView(state: state, motion: motion))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func wireCallbacks() {
        state.onCapture = { [weak self] in self?.capturePhoto() }
        state.onToggleCamera = { [weak self] in self?.camera.switchCamera() }
        state.onSwitchScene = { [weak self] scene in
            guard let self else { return }
            self.state.sceneOverride = scene
            self.refreshFilters()
        }
    }

    private func startPipeline() {
        Task {
            do {
                try await camera.configure()
                previewLayer?.connection?.videoOrientation = .portrait
                camera.start()
                motion.start()
                camera.onAnalysisFrame = { [weak self] buffer, size in
                    self?.handleAnalysisFrame(buffer, uprightSize: size)
                }
                camera.onError = { [weak self] error in
                    DispatchQueue.main.async {
                        self?.state.errorMessage = error.localizedDescription
                    }
                }
                refreshFilters()
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 分析管线（视频输出队列线程）

    private func handleAnalysisFrame(_ buffer: CVPixelBuffer, uprightSize: CGSize) {
        autoreleasepool {
            analysisCounter += 1

            detector.detect(pixelBuffer: buffer) { [weak self] detections in
                guard let self else { return }
                if self.state.sceneOverride == nil {
                    self.classifier.classify(pixelBuffer: buffer, personCount: detections.personCount) { scene, _ in
                        if self.state.sceneOverride == nil {
                            self.updateScene(scene)
                        }
                    }
                }

                let scene = self.state.effectiveScene
                let result = CompositionEngine.evaluate(scene: scene,
                                                        detections: detections,
                                                        rollDegrees: self.motion.rollDegrees,
                                                        pitchDegrees: self.motion.pitchDegrees)

                DispatchQueue.main.async {
                    self.state.subjectRect = result.subjectRect.map {
                        self.mapRect($0, videoSize: uprightSize)
                    }
                    if self.state.guideMode == .newbie {
                        if result.aligned && !self.state.aligned {
                            self.haptic.impactOccurred()
                        }
                        self.state.tip = result.tip
                        self.state.aligned = result.aligned
                    } else {
                        self.state.tip = nil
                        self.state.aligned = false
                    }
                }
            }

            // 每 ~8 次分析（约 2 秒）刷新滤镜缩略图
            if analysisCounter % 8 == 0 {
                refreshThumbnails(buffer: buffer)
            }
        }
    }

    private func updateScene(_ scene: PhotoScene) {
        guard scene != lastClassifiedScene else { return }
        lastClassifiedScene = scene
        state.scene = scene
        refreshFilters()
    }

    private func refreshFilters() {
        let list = FilterLibrary.filters(for: state.effectiveScene)
        state.filters = list
        if !list.contains(where: { $0.id == state.selectedFilter?.id }) {
            state.selectedFilter = list.first
        }
    }

    private func refreshThumbnails(buffer: CVPixelBuffer) {
        let filters = state.filters
        guard !filters.isEmpty else { return }
        var thumbs: [String: UIImage] = [:]
        for filter in filters {
            if let thumb = FilterRenderer.thumbnail(from: buffer, filter: filter, size: 64) {
                thumbs[filter.id] = thumb
            }
        }
        DispatchQueue.main.async {
            self.state.filterThumbs = thumbs
        }
    }

    // MARK: - 拍照

    private func capturePhoto() {
        guard !state.isCapturing else { return }
        state.isCapturing = true

        camera.capturePhoto { [weak self] result in
            guard let self else { return }
            self.state.isCapturing = false
            switch result {
            case .success(let image):
                let scene = self.state.effectiveScene
                let filter = self.state.selectedFilter
                    ?? FilterLibrary.filters(for: scene).first
                    ?? FilterLibrary.filters(for: .unknown).first!

                let ciImage = CIImage(image: image) ?? CIImage.empty()
                let filteredImage = FilterRenderer.apply(filter, to: ciImage, intensity: 1)
                let output = FilterRenderer.render(filteredImage) ?? image

                let photo = CapturedPhoto(image: output,
                                          originalImage: image,
                                          scene: scene,
                                          filter: filter,
                                          explanation: scene.explanation)
                self.state.onCapturedPhoto?(photo)
            case .failure(let error):
                self.state.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 坐标映射（Vision 归一化 → 视图坐标，resizeAspectFill）

    private func mapRect(_ normalized: CGRect, videoSize: CGSize) -> CGRect {
        let viewSize = view.bounds.size
        guard videoSize.width > 0, videoSize.height > 0, viewSize.width > 0 else { return .zero }
        let scale = max(viewSize.width / videoSize.width, viewSize.height / videoSize.height)
        let drawWidth = videoSize.width * scale
        let drawHeight = videoSize.height * scale
        let xOffset = (viewSize.width - drawWidth) / 2
        let yOffset = (viewSize.height - drawHeight) / 2
        return CGRect(x: normalized.minX * videoSize.width * scale + xOffset,
                      y: normalized.minY * videoSize.height * scale + yOffset,
                      width: normalized.width * videoSize.width * scale,
                      height: normalized.height * videoSize.height * scale)
    }
}
