import Vision
import CoreGraphics

/// 主体检测：人体框 + 人脸框 + 显著性区域（全本地）
final class SubjectDetector {
    private let queue = DispatchQueue(label: "com.shootright.subject")

    /// 基于不可变 CGImage 检测（调用方负责传入直立图）
    func detect(cgImage: CGImage, completion: @escaping (Detections) -> Void) {
        queue.async {
            let person = VNDetectHumanRectanglesRequest()
            let face = VNDetectFaceRectanglesRequest()
            let saliency = VNGenerateAttentionBasedSaliencyImageRequest()

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([person, face, saliency])

                var detections = Detections()
                detections.personRects = (person.results ?? []).map { Self.topLeftOrigin($0.boundingBox) }
                detections.faceRects = (face.results ?? []).map { Self.topLeftOrigin($0.boundingBox) }
                if let salient = saliency.results?.first,
                   let objects = salient.salientObjects,
                   let first = objects.first {
                    detections.salientRect = Self.topLeftOrigin(first.boundingBox)
                }

                DispatchQueue.main.async {
                    completion(detections)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(Detections())
                }
            }
        }
    }

    /// Vision 归一化坐标（左下角原点）→ 左上角原点（SwiftUI 直接可用）
    static func topLeftOrigin(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
    }
}
