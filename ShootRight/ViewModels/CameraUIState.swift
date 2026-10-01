import SwiftUI
import Combine

/// 引导强度
enum GuideMode: Int, CaseIterable {
    case newbie = 0   // 新手：完整引导（箭头 + 文案 + 网格 + 水平仪）
    case light = 1    // 轻引导：仅网格 + 水平仪 + 主体框
    case off = 2      // 关闭
}

/// 相机 UI 状态：ViewController 分析管线写入，SwiftUI 叠加层读取
final class CameraUIState: ObservableObject {

    // MARK: - 分析结果
    @Published var scene: PhotoScene = .unknown
    @Published var sceneOverride: PhotoScene?    // 用户手动选择的场景（nil = 自动）
    @Published var tip: GuidanceTip?
    @Published var aligned = false               // 对齐 = 可以拍了
    @Published var subjectRect: CGRect?          // 主体框（视图坐标）
    @Published var rollDegrees: Double = 0       // 水平仪实时横滚角

    // MARK: - 滤镜
    @Published var filters: [FilterPreset] = []
    @Published var selectedFilter: FilterPreset?
    @Published var filterThumbs: [String: UIImage] = [:]   // filter.id -> 缩略图

    // MARK: - 引导偏好
    @Published var guideMode: GuideMode = .newbie
    @Published var showGrid = true
    @Published var showLevel = true

    // MARK: - 流程状态
    @Published var isCapturing = false
    @Published var errorMessage: String?
    @Published var showScenePicker = false
    @Published var showGuideCards = false
    @Published var showSettings = false

    // MARK: - 回调（由 CameraViewController 注入）
    var onCapture: (() -> Void)?
    var onToggleCamera: (() -> Void)?
    var onSwitchScene: ((PhotoScene?) -> Void)?
    var onCapturedPhoto: ((CapturedPhoto) -> Void)?

    /// 当前生效场景（手动优先）
    var effectiveScene: PhotoScene { sceneOverride ?? scene }

    // MARK: - 动作（叠加层按钮调用）
    func selectFilter(_ filter: FilterPreset) {
        selectedFilter = filter
    }

    func capture() {
        onCapture?()
    }

    func toggleCamera() {
        onToggleCamera?()
    }

    func clearSceneOverride() {
        onSwitchScene?(nil)
    }
}
