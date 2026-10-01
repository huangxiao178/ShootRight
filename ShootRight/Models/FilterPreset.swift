import CoreImage
import UIKit

/// 滤镜预设：参数化 CIFilter 链，intensity 0-1 线性插值（0 = 原片）
struct FilterPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let scene: PhotoScene
    let explanation: String
    let apply: (CIImage, CGFloat) -> CIImage

    static func == (lhs: FilterPreset, rhs: FilterPreset) -> Bool {
        lhs.id == rhs.id
    }

    var isOriginal: Bool { id == "original" }
}

/// 滤镜库：场景 → 精选滤镜
enum FilterLibrary {

    static func filters(for scene: PhotoScene) -> [FilterPreset] {
        let original = FilterPreset(
            id: "original",
            name: "原片",
            scene: scene,
            explanation: "不过度修饰，保留真实。",
            apply: { image, _ in image }
        )

        switch scene {
        case .food:
            return [
                chain("food.warm", "暖食", scene,
                      "暖调提升食欲，突出食物本身。") { img, i in
                    img.exposure(0.15 * i).vibrance(1.15 * i).temperature(target: 6500 + 800 * i)
                },
                chain("food.fresh", "清新", scene,
                      "降低色温更干净，适合浅色餐具。") { img, i in
                    img.exposure(0.12 * i).saturation(1.08 * i).temperature(target: 6500 - 700 * i)
                },
                chain("food.rich", "浓郁", scene,
                      "提高对比与饱和，让菜品更立体。") { img, i in
                    img.contrast(1 + 0.12 * i).saturation(1 + 0.25 * i).vibrance(1 + 0.2 * i)
                },
                original
            ]

        case .couple, .single:
            return [
                chain("portrait.cream", "奶油肌", scene,
                      "轻微提亮肤色，画面柔和干净。") { img, i in
                    img.exposure(0.18 * i).vibrance(1.1 * i).temperature(target: 6500 + 400 * i)
                },
                chain("portrait.film", "胶片", scene,
                      "低对比低饱和，复古耐看。") { img, i in
                    img.contrast(1 - 0.08 * i).saturation(1 - 0.15 * i)
                        .gamma(1 + 0.08 * i).vignette(0.35 * i)
                },
                chain("portrait.japan", "日系", scene,
                      "提亮偏冷，清爽通透。") { img, i in
                    img.exposure(0.2 * i).saturation(1 - 0.08 * i)
                        .temperature(target: 6500 - 600 * i).gamma(1 + 0.05 * i)
                },
                original
            ]

        case .group:
            return [
                chain("group.bright", "明亮", scene,
                      "提亮肤色与场景，合照更有精神。") { img, i in
                    img.exposure(0.2 * i).saturation(1.08 * i)
                },
                chain("group.natural", "自然", scene,
                      "轻微校正，保留真实色彩。") { img, i in
                    img.contrast(1 + 0.05 * i).vibrance(1.08 * i)
                },
                chain("group.warm", "暖调", scene,
                      "暖色让合照更亲切。") { img, i in
                    img.temperature(target: 6500 + 500 * i).exposure(0.1 * i)
                },
                original
            ]

        case .landscape:
            return [
                chain("land.clear", "通透", scene,
                      "提饱和降色温，天空更蓝更透。") { img, i in
                    img.saturation(1 + 0.18 * i).contrast(1 + 0.06 * i)
                        .temperature(target: 6500 - 400 * i)
                },
                chain("land.teal", "青橙", scene,
                      "冷暖对比，风光大片感。") { img, i in
                    img.saturation(1 + 0.15 * i).contrast(1 + 0.08 * i)
                        .temperature(target: 6500 + 500 * i)
                },
                chain("land.bw", "黑白", scene,
                      "去色提对比，突出结构与光影。") { img, i in
                    img.saturation(1 - i).contrast(1 + 0.1 * i)
                },
                original
            ]

        case .unknown:
            return [
                chain("base.light", "提亮", scene,
                      "光线不足时轻微提亮。") { img, i in
                    img.exposure(0.15 * i)
                },
                original
            ]
        }
    }

    private static func chain(_ id: String,
                              _ name: String,
                              _ scene: PhotoScene,
                              _ explanation: String,
                              _ body: @escaping (CIImage, CGFloat) -> CIImage) -> FilterPreset {
        FilterPreset(id: id, name: name, scene: scene, explanation: explanation, apply: body)
    }
}

// MARK: - CIImage 滤镜链便捷方法（全部为连续参数滤镜，强度可线性插值）

private extension CIImage {
    func exposure(_ value: CGFloat) -> CIImage {
        applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: value])
    }

    func saturation(_ value: CGFloat) -> CIImage {
        applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: value])
    }

    func contrast(_ value: CGFloat) -> CIImage {
        applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: value])
    }

    func vibrance(_ value: CGFloat) -> CIImage {
        applyingFilter("CIVibrance", parameters: [kCIInputAmountKey: value])
    }

    func temperature(target: CGFloat) -> CIImage {
        applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: target, y: 0)
        ])
    }

    func gamma(_ value: CGFloat) -> CIImage {
        applyingFilter("CIGammaAdjust", parameters: ["inputPower": value])
    }

    func vignette(_ value: CGFloat) -> CIImage {
        let radius = min(extent.width, extent.height) * 0.75
        return applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: value,
            kCIInputRadiusKey: radius
        ])
    }
}
