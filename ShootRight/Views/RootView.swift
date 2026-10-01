import SwiftUI

/// 根视图：相机 + 成片页路由
struct RootView: View {
    @State private var capturedPhoto: CapturedPhoto?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraView(capturedPhoto: $capturedPhoto)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $capturedPhoto) { photo in
            ResultView(photo: photo) {
                capturedPhoto = nil
            }
        }
    }
}
