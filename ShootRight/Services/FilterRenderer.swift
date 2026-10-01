import CoreImage
import UIKit

/// Core Image 渲染与滤镜缩略图
enum FilterRenderer {
    static let context = CIContext(options: [.cacheIntermediates: false])

    /// 按强度应用滤镜（0 = 原片，1 = 全效果）
    static func apply(_ filter: FilterPreset, to image: CIImage, intensity: CGFloat) -> CIImage {
        filter.apply(image, max(0, min(1, intensity)))
    }

    /// 渲染成 UIImage
    static func render(_ image: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// 分析帧 → 直立小图（最长边 720，同步生成）
    ///
    /// 在视频输出队列上同步调用；产出不可变 CGImage，交给异步识别/缩略图
    /// 使用，彻底避免「像素缓冲在异步处理期间被相机回收」导致的偶发崩溃。
    static func analysisImage(from buffer: CVPixelBuffer) -> CGImage? {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        guard width > 0, height > 0 else { return nil }

        // 输出缓冲可能已是竖屏（1080x1920），也可能是传感器横屏（1920x1080），
        // 按宽高比判断是否需要旋转，保证分析图始终直立。
        let ci = CIImage(cvPixelBuffer: buffer)
            .oriented(height > width ? .up : .right)
        let maxSide = max(ci.extent.width, ci.extent.height)
        guard maxSide > 0 else { return nil }
        let scale = 720 / maxSide
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return context.createCGImage(scaled, from: scaled.extent)
    }

    /// 从直立分析图生成滤镜缩略图（小尺寸，快速）
    static func thumbnail(from cgImage: CGImage, filter: FilterPreset, size: CGFloat) -> UIImage? {
        let ci = CIImage(cgImage: cgImage)
        let scale = size / max(ci.extent.width, ci.extent.height)
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let filtered = apply(filter, to: scaled, intensity: 1)
        guard let cg = context.createCGImage(filtered, from: filtered.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
