import CoreImage
import UIKit

/// Core Image 渲染与滤镜缩略图
enum FilterRenderer {
    private static let context = CIContext(options: [.cacheIntermediates: false])

    /// 按强度应用滤镜（0 = 原片，1 = 全效果）
    static func apply(_ filter: FilterPreset, to image: CIImage, intensity: CGFloat) -> CIImage {
        filter.apply(image, max(0, min(1, intensity)))
    }

    /// 渲染成 UIImage
    static func render(_ image: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// 从分析帧生成滤镜缩略图（小尺寸，快速）
    static func thumbnail(from buffer: CVPixelBuffer, filter: FilterPreset, size: CGFloat) -> UIImage? {
        let ci = CIImage(cvPixelBuffer: buffer).oriented(.right)
        let scale = size / max(ci.extent.width, ci.extent.height)
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let filtered = apply(filter, to: scaled, intensity: 1)
        guard let cgImage = context.createCGImage(filtered, from: filtered.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
