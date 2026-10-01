import Foundation

/// 引导箭头方向（叠加层箭头用）
enum TipDirection: Equatable {
    case left
    case right
    case up
    case down
    case closer
    case farther
    case none
}

/// 一条引导提示（文案 ≤ 12 字 + 方向）
struct GuidanceTip: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let direction: TipDirection

    static func == (lhs: GuidanceTip, rhs: GuidanceTip) -> Bool {
        lhs.text == rhs.text && lhs.direction == rhs.direction
    }
}
