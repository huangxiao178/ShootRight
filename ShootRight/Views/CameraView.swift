import SwiftUI

/// SwiftUI 桥接：把 UIKit 相机控制器包成 SwiftUI 视图
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedPhoto: CapturedPhoto?
    @StateObject private var state = CameraUIState()

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController(state: state)
        state.onCapturedPhoto = { photo in
            self.capturedPhoto = photo
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
