import UIKit

/// 一张成片：原图 + 应用滤镜后的图 + 场景信息
struct CapturedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage        // 已应用推荐滤镜
    let originalImage: UIImage
    let scene: PhotoScene
    let filter: FilterPreset
    let explanation: String
}
