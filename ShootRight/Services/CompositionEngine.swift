import Foundation
import CoreGraphics

/// 一次构图评估的结果
struct CompositionResult {
    /// 当前要展示的提示（nil = 无需提示）
    let tip: GuidanceTip?
    /// 是否已对齐（无活动提示项 = 可以拍了）
    let aligned: Bool
    /// 主体框（归一化、左上角原点，nil = 未检测到）
    let subjectRect: CGRect?
}

/// 构图引导规则引擎（确定性输出，非生成式）
///
/// 规则优先级：先救"硬伤"（裁切/歪斜），再给"优化"（位置/大小/角度）。
/// 每条规则命中即返回，保证提示稳定、可解释。
enum CompositionEngine {

    static func evaluate(scene: PhotoScene,
                         detections: Detections,
                         rollDegrees: Double,
                         pitchDegrees: Double) -> CompositionResult {
        switch scene {
        case .food:
            return evaluateFood(detections, rollDegrees, pitchDegrees)
        case .couple, .single:
            return evaluatePortrait(scene: scene, detections, rollDegrees, pitchDegrees)
        case .group:
            return evaluateGroup(detections, rollDegrees)
        case .landscape:
            return evaluateLandscape(detections, rollDegrees)
        case .unknown:
            return evaluateGeneric(rollDegrees)
        }
    }

    // MARK: - 拍对象 / 单人照

    private static func evaluatePortrait(scene: PhotoScene,
                                         _ d: Detections,
                                         _ roll: Double,
                                         _ pitch: Double) -> CompositionResult {
        guard let subject = portraitSubject(d) else {
            return CompositionResult(tip: nil, aligned: false, subjectRect: nil)
        }

        // 1) 脚被裁（人框贴底）
        if let person = largestPerson(d), person.maxY > 0.97 {
            return result(tip("让脚出现在画面里", .up), subject)
        }
        // 2) 头顶留白（人脸太靠上）
        if let face = largestFace(d) {
            if face.midY < 0.22 {
                return result(tip("头顶留白，往后退一点", .farther), subject)
            }
            if face.midY > 0.50 {
                return result(tip("手机放低，人物靠上", .down), subject)
            }
        }
        // 3) 人脸三分位（横）
        if let face = largestFace(d) {
            let target = nearestThird(face.midX)
            if abs(face.midX - target) > 0.10 {
                let direction: TipDirection = face.midX < target ? .right : .left
                return result(tip("往\(direction == .right ? "右" : "左")移一点", direction), subject)
            }
        }
        // 4) 主体大小
        if subject.height < 0.40 {
            return result(tip("再近一点", .closer), subject)
        }
        if subject.height > 0.90 {
            return result(tip("再远一点", .farther), subject)
        }
        // 5) 水平
        if abs(roll) > 2 {
            return result(tip("保持水平", .none), subject)
        }
        return aligned(subject)
    }

    // MARK: - 拍美食

    private static func evaluateFood(_ d: Detections, _ roll: Double, _ pitch: Double) -> CompositionResult {
        guard let subject = d.salientRect ?? d.largestRect else {
            return CompositionResult(tip: nil, aligned: false, subjectRect: nil)
        }
        // 1) 主体过小
        if subject.width * subject.height < 0.10 {
            return result(tip("再近一点", .closer), subject)
        }
        // 2) 主体三分位
        let target = nearestThird(subject.midX)
        if abs(subject.midX - target) > 0.10 {
            let direction: TipDirection = subject.midX < target ? .right : .left
            return result(tip("把主体放到三分点上", direction), subject)
        }
        // 3) 俯拍角度（相机未向下看 → 建议放低俯拍）
        if pitch > -15 {
            return result(tip("手机放低，俯拍更显丰盛", .down), subject)
        }
        // 4) 水平
        if abs(roll) > 2 {
            return result(tip("保持水平", .none), subject)
        }
        return aligned(subject)
    }

    // MARK: - 合影

    private static func evaluateGroup(_ d: Detections, _ roll: Double) -> CompositionResult {
        let boxes = d.faceCount >= 2 ? d.faceRects : d.personRects
        guard !boxes.isEmpty, let subject = d.largestRect else {
            return CompositionResult(tip: nil, aligned: false, subjectRect: nil)
        }
        // 1) 人脸出框 / 贴边
        if boxes.contains(where: { $0.minX < 0.02 || $0.maxX > 0.98 }) {
            return result(tip("拍全所有人，往中间靠", .none), subject)
        }
        // 2) 头顶空隙
        if boxes.contains(where: { $0.minY < 0.03 }) {
            return result(tip("头顶留一点空隙", .farther), subject)
        }
        // 3) 水平
        if abs(roll) > 2 {
            return result(tip("让画面保持水平", .none), subject)
        }
        return aligned(subject)
    }

    // MARK: - 风景 / 建筑

    private static func evaluateLandscape(_ d: Detections, _ roll: Double) -> CompositionResult {
        // 1) 水平（风景的第一硬伤）
        if abs(roll) > 2 {
            return result(tip("让地平线保持水平", .none), d.salientRect ?? d.largestRect)
        }
        guard let subject = d.salientRect ?? d.largestRect else {
            return aligned(nil)
        }
        // 2) 主体过小
        if subject.width * subject.height < 0.08 {
            return result(tip("再近一点", .closer), subject)
        }
        // 3) 主体三分位
        let target = nearestThird(subject.midX)
        if abs(subject.midX - target) > 0.12 {
            let direction: TipDirection = subject.midX < target ? .right : .left
            return result(tip("把主体放到三分点上", direction), subject)
        }
        return aligned(subject)
    }

    // MARK: - 未识别场景

    private static func evaluateGeneric(_ roll: Double) -> CompositionResult {
        if abs(roll) > 2 {
            return result(tip("保持水平", .none), nil)
        }
        return aligned(nil)
    }

    // MARK: - 工具

    private static func result(_ tip: GuidanceTip?, _ subject: CGRect?) -> CompositionResult {
        CompositionResult(tip: tip, aligned: tip == nil, subjectRect: subject)
    }

    private static func aligned(_ subject: CGRect?) -> CompositionResult {
        CompositionResult(tip: nil, aligned: true, subjectRect: subject)
    }

    private static func tip(_ text: String, _ direction: TipDirection) -> GuidanceTip {
        GuidanceTip(text: text, direction: direction)
    }

    private static func portraitSubject(_ d: Detections) -> CGRect? {
        largestFace(d) ?? largestPerson(d) ?? d.salientRect
    }

    private static func largestFace(_ d: Detections) -> CGRect? {
        d.faceRects.max { $0.width * $0.height < $1.width * $1.height }
    }

    private static func largestPerson(_ d: Detections) -> CGRect? {
        d.personRects.max { $0.width * $0.height < $1.width * $1.height }
    }

    /// 最近的竖三分线位置（0.33 / 0.67）
    private static func nearestThird(_ x: CGFloat) -> CGFloat {
        abs(x - 0.33) <= abs(x - 0.67) ? 0.33 : 0.67
    }
}
