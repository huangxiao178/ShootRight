import SwiftUI
import Photos

/// 成片页：滤镜强度微调 + 拍法讲解 + 保存 / 分享
struct ResultView: View {
    let photo: CapturedPhoto
    let onClose: () -> Void

    @State private var intensity: Double = 1
    @State private var showingOriginal = false
    @State private var saved = false
    @State private var showShare = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()

                imageArea
                    .padding(.horizontal, 12)

                Spacer()

                controlArea
            }
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.12), in: Circle())
            }
            Spacer()
            Text(photo.scene.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
            Spacer()
            Button {
                showShare = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.12), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - 图片区

    private var imageArea: some View {
        Image(uiImage: displayedImage)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .onLongPressGesture(minimumDuration: 0.15, pressing: { pressing in
                showingOriginal = pressing
            }, perform: {})
    }

    /// 按强度实时重渲染
    private var displayedImage: UIImage {
        if showingOriginal { return photo.originalImage }
        guard intensity < 1, let ci = CIImage(image: photo.originalImage) else {
            return photo.image
        }
        let filtered = FilterRenderer.apply(photo.filter, to: ci, intensity: CGFloat(intensity))
        return FilterRenderer.render(filtered) ?? photo.image
    }

    // MARK: - 控制区

    private var controlArea: some View {
        VStack(spacing: 14) {
            // 强度滑杆
            HStack(spacing: 12) {
                Text("原片")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                Slider(value: $intensity, in: 0...1)
                    .tint(.white)
                Text("滤镜")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 24)

            // 讲解
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("为什么这样拍好看")
                        .font(.system(size: 13, weight: .bold))
                }
                Text(photo.explanation)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(3)
                Text("滤镜 · \(photo.filter.name)：\(photo.filter.explanation)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)

            // 保存
            Button {
                saveToAlbum()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    Text(saved ? "已保存到相册" : "保存到相册")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(saved ? Color.green : Color.white, in: RoundedRectangle(cornerRadius: 24))
            }
            .disabled(saved)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [displayedImage])
        }
    }

    private func saveToAlbum() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    saved = false
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: displayedImage)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    saved = success
                }
            }
        }
    }
}

/// 系统分享面板桥接
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
