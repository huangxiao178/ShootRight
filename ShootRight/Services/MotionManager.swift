import CoreMotion
import Combine

/// 设备姿态（水平仪数据源）：陀螺仪 + 加速度计，无需用户授权
final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()

    /// 横滚角（度）：左右倾斜，用于水平仪
    @Published var rollDegrees: Double = 0
    /// 俯仰角（度）：相机看向下方为负，用于俯拍建议
    @Published var pitchDegrees: Double = 0

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.05 // 20fps，水平仪顺滑
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.rollDegrees = motion.attitude.roll * 180 / .pi
            self.pitchDegrees = motion.attitude.pitch * 180 / .pi
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
