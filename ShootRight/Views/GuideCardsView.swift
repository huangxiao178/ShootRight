import SwiftUI

/// 拍法卡：当前场景的图文拍法教学
struct GuideCardsView: View {
    let scene: PhotoScene
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(scene.guideCards) { card in
                        cardView(card)
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(scene.displayName + " · 拍法卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func cardView(_ card: GuideCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .foregroundStyle(.blue)
                Text(card.title)
                    .font(.system(size: 16, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(card.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(.blue, in: Circle())
                        Text(step)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                    }
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("常见错误：\(card.mistake)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
