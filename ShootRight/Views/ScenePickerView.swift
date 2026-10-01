import SwiftUI

/// 场景选择器：手动切换场景（含"自动识别"）
struct ScenePickerView: View {
    @ObservedObject var state: CameraUIState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("识别方式") {
                    Button {
                        state.clearSceneOverride()
                        dismiss()
                    } label: {
                        HStack {
                            Text("自动识别")
                            Spacer()
                            if state.sceneOverride == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                Section("手动选择场景") {
                    ForEach(PhotoScene.allCases.filter { $0 != .unknown }) { scene in
                        Button {
                            state.onSwitchScene?(scene)
                            dismiss()
                        } label: {
                            HStack {
                                Text(scene.displayName)
                                Spacer()
                                if state.sceneOverride == scene {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section {
                    Text("自动识别优先按画面中的人数判断（合影 / 单人照），拍对象和单人照建议手动切换，引导文案会更有针对性。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("拍摄场景")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
