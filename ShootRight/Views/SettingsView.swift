import SwiftUI

/// 设置页
struct SettingsView: View {
    @ObservedObject var state: CameraUIState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("引导强度") {
                    Picker("引导强度", selection: Binding(
                        get: { state.guideMode.rawValue },
                        set: { state.guideMode = GuideMode(rawValue: $0) ?? .newbie }
                    )) {
                        Text("新手（完整引导）").tag(GuideMode.newbie.rawValue)
                        Text("轻引导（仅网格）").tag(GuideMode.light.rawValue)
                        Text("关闭").tag(GuideMode.off.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                Section("取景辅助") {
                    Toggle("三分网格", isOn: $state.showGrid)
                    Toggle("水平仪", isOn: $state.showLevel)
                }

                Section("隐私") {
                    Label("所有 AI 识别与滤镜处理都在手机本地完成", systemImage: "lock.shield.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("本应用不联网、不上传你的照片和画面，也不会采集你的位置信息。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
