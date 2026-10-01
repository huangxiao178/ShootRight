import Foundation

/// 拍摄场景（对应产品方案 V1 的 5 个场景 + 未识别）
enum PhotoScene: String, CaseIterable, Identifiable {
    case food       // 拍美食
    case couple     // 拍对象
    case single     // 单人照
    case group      // 合影
    case landscape  // 风景 / 建筑
    case unknown    // 未识别（仅基础网格 + 水平仪）

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food: return "拍美食"
        case .couple: return "拍对象"
        case .single: return "单人照"
        case .group: return "合影"
        case .landscape: return "风景"
        case .unknown: return "未识别"
        }
    }

    /// 成片页"为什么这样拍好看"的一句话讲解
    var explanation: String {
        switch self {
        case .food:
            return "俯拍 45° 能展现食物的丰盛层次，主体放在三分点上更有食欲，暖色调让画面更诱人。"
        case .couple:
            return "机位放低让人更显高挑，头顶留白、人脸放上三分线，画面立刻有呼吸感。"
        case .single:
            return "机位放在胸口高度最自然，主体靠三分线，背景留白多一点更高级。"
        case .group:
            return "所有人脸完整入框、画面保持水平，边缘留一点空隙，合照才不挤。"
        case .landscape:
            return "地平线保持水平，天空与地面按三分分配，画面稳定又耐看。"
        case .unknown:
            return "先稳住画面、保持水平，对准主体再按快门。"
        }
    }

    /// 拍法卡（场景库内容）
    var guideCards: [GuideCard] {
        switch self {
        case .food:
            return [
                GuideCard(
                    title: "俯拍 45°，丰盛感翻倍",
                    steps: ["手机放低，与桌面约呈 45°", "让主体落在三分点上", "背景留白，避开杂物"],
                    mistake: "平拍 + 居中 + 杂物入镜，画面又平又乱"
                ),
                GuideCard(
                    title: "突出主角",
                    steps: ["靠近主体，让它占画面一半", "借窗户光或一盏灯", "滤镜选暖食更诱人"],
                    mistake: "主体太小，看不出吃的是什么"
                )
            ]
        case .couple:
            return [
                GuideCard(
                    title: "拍出大长腿",
                    steps: ["蹲低一点，机位到腰部高度", "人物头顶留一格空白", "脚部完整入画"],
                    mistake: "站着平拍 + 裁脚，又矮又憋屈"
                ),
                GuideCard(
                    title: "氛围感",
                    steps: ["人脸放在三分线上", "背景留白或自然虚化", "暖色滤镜提升氛围"],
                    mistake: "人脸贴边，画面失衡"
                )
            ]
        case .single:
            return [
                GuideCard(
                    title: "自然半身照",
                    steps: ["机位举到胸口高度", "人物靠三分线，别居中", "背景留白多一点"],
                    mistake: "仰拍鼻孔视角 + 主体居中，呆板又显矮"
                ),
                GuideCard(
                    title: "全身照",
                    steps: ["脚底贴画框下沿", "头顶留一格", "保持画面水平"],
                    mistake: "裁到膝盖/手腕，构图断裂"
                )
            ]
        case .group:
            return [
                GuideCard(
                    title: "拍全所有人",
                    steps: ["所有人脸完整入框", "边缘留一点空隙", "喊大家往中间靠"],
                    mistake: "边缘人脸被裁一半"
                ),
                GuideCard(
                    title: "保持水平",
                    steps: ["以地平线/背景线为准", "跟水平仪对齐", "连拍两张选最好的"],
                    mistake: "背景歪斜，再好的表情也白搭"
                )
            ]
        case .landscape:
            return [
                GuideCard(
                    title: "水平优先",
                    steps: ["地平线对齐水平仪", "天空与地面按三分分配", "主体放三分点上"],
                    mistake: "地平线歪斜，画面立即失衡"
                ),
                GuideCard(
                    title: "找主体",
                    steps: ["画面里留一个视觉中心", "靠近或变焦让它变大", "前景后景拉开层次"],
                    mistake: "空荡荡一片，没有焦点"
                )
            ]
        case .unknown:
            return [
                GuideCard(
                    title: "先稳住",
                    steps: ["拿稳手机", "保持水平", "对准你想拍的主体"],
                    mistake: "手抖 + 歪斜，神仙滤镜也救不回"
                )
            ]
        }
    }
}

/// 拍法卡模型
struct GuideCard: Identifiable {
    let id = UUID()
    let title: String
    let steps: [String]
    let mistake: String
}
