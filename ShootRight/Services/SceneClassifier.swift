import Vision
import AVFoundation

/// 场景识别：Vision 内置分类器（全本地，零模型文件）
final class SceneClassifier {
    private let queue = DispatchQueue(label: "com.shootright.classifier")

    func classify(pixelBuffer: CVPixelBuffer,
                  personCount: Int,
                  completion: @escaping (PhotoScene, Float) -> Void) {
        queue.async {
            let request = VNClassifyImageRequest()
            request.usesCPUOnly = false

            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                    orientation: .right,
                                                    options: [:])
                try handler.perform([request])
                let labels = request.results ?? []
                let scene = Self.map(labels: labels, personCount: personCount)
                let confidence = labels.first?.confidence ?? 0
                DispatchQueue.main.async {
                    completion(scene, confidence)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.unknown, 0)
                }
            }
        }
    }

    /// 标签关键词 → 场景（人数优先，是最可靠信号）
    private static func map(labels: [VNClassificationObservation], personCount: Int) -> PhotoScene {
        if personCount >= 2 { return .group }
        if personCount == 1 { return .single }

        let text = labels.prefix(6).map { $0.identifier.lowercased() }.joined(separator: " ")

        if text.contains("food") || text.contains("cuisine") || text.contains("meal")
            || text.contains("dessert") || text.contains("dish") || text.contains("pastry") {
            return .food
        }
        if text.contains("crowd") || text.contains("people") || text.contains("person") {
            return .group
        }
        if text.contains("building") || text.contains("architecture") || text.contains("tower")
            || text.contains("sky") || text.contains("water") || text.contains("mountain")
            || text.contains("landscape") || text.contains("nature") || text.contains("vegetation")
            || text.contains("tree") || text.contains("beach") || text.contains("city")
            || text.contains("bridge") || text.contains("street") {
            return .landscape
        }
        return .unknown
    }
}
