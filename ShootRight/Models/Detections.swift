import Foundation

/// 单帧检测结果（坐标为归一化、左上角原点、竖屏直立空间）
struct Detections {
    var personRects: [CGRect] = []
    var faceRects: [CGRect] = []
    var salientRect: CGRect?

    var personCount: Int { personRects.count }
    var faceCount: Int { faceRects.count }

    /// 最大的一个矩形（用于画主体框兜底）
    var largestRect: CGRect? {
        let all = personRects + faceRects
        return all.max { $0.width * $0.height < $1.width * $1.height } ?? salientRect
    }
}
