import SwiftUI

/// 相机叠加层：网格 / 水平仪 / 主体框 / 引导箭头文案 / 滤镜条 / 快门
struct CameraOverlayView: View {
    @ObservedObject var state: CameraUIState
    @ObservedObject var motion: MotionManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear

                if state.showGrid && state.guideMode != .off {
                    gridLines(in: geo.size)
                }

                if let rect = state.subjectRect, state.guideMode != .off {
                    subjectBox(rect)
                }

                if state.showLevel && state.guideMode != .off {
                    levelIndicator
                }

                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 8)
                    Spacer()
                    guidanceArea
                    Spacer()
                    bottomBar
                        .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $state.showScenePicker) {
            ScenePickerView(state: state)
        }
        .sheet(isPresented: $state.showGuideCards) {
            GuideCardsView(scene: state.effectiveScene)
        }
        .sheet(isPresented: $state.showSettings) {
            SettingsView(state: state)
        }
        .alert("出错了", isPresented: Binding(
            get: { state.errorMessage != nil },
            set: { if !$0 { state.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { state.errorMessage = nil }
        } message: {
            Text(state.errorMessage ?? "")
        }
    }

    // MARK: - 顶部

    private var topBar: some View {
        HStack {
            Button {
                state.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.35), in: Circle())
            }

            Spacer()

            Button {
                state.showScenePicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(state.effectiveScene.displayName)
                        .font(.system(size: 15, weight: .semibold))
                    if state.sceneOverride != nil {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 11))
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.35), in: Capsule())
            }

            Spacer()

            Button {
                state.showGuideCards = true
            } label: {
                Image(systemName: "book.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.35), in: Circle())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 引导区

    @ViewBuilder
    private var guidanceArea: some View {
        if state.guideMode == .newbie {
            if state.aligned {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("可以拍了")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.85), in: Capsule())
                .transition(.scale.combined(with: .opacity))
            } else if let tip = state.tip {
                HStack(spacing: 10) {
                    if let arrow = Self.arrowIcon(for: tip.direction) {
                        Image(systemName: arrow)
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text(tip.text)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.black.opacity(0.55), in: Capsule())
            }
        }
    }

    private static func arrowIcon(for direction: TipDirection) -> String? {
        switch direction {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .closer: return "plus.magnifyingglass"
        case .farther: return "minus.magnifyingglass"
        case .none: return nil
        }
    }

    // MARK: - 底部

    private var bottomBar: some View {
        VStack(spacing: 16) {
            filterStrip
            HStack(spacing: 0) {
                // 切换摄像头
                Button {
                    state.toggleCamera()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                }

                Spacer()

                // 快门
                Button {
                    state.capture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 5)
                            .frame(width: 78, height: 78)
                        Circle()
                            .fill(state.isCapturing ? Color.gray : Color.white)
                            .frame(width: 62, height: 62)
                    }
                }
                .disabled(state.isCapturing)

                Spacer()

                // 引导强度切换
                Button {
                    let next = GuideMode(rawValue: (state.guideMode.rawValue + 1) % 3) ?? .newbie
                    state.guideMode = next
                } label: {
                    Image(systemName: state.guideMode == .newbie ? "wand.and.stars" : "viewfinder")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(state.filters) { filter in
                    filterCell(filter)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 96)
    }

    private func filterCell(_ filter: FilterPreset) -> some View {
        let isSelected = state.selectedFilter?.id == filter.id
        return Button {
            state.selectFilter(filter)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                        .frame(width: 58, height: 58)
                    if let thumb = state.filterThumbs[filter.id] {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black.opacity(0.4))
                            .frame(width: 58, height: 58)
                    }
                }
                Text(filter.name)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - 网格 / 主体框 / 水平仪

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            for i in 1...2 {
                let x = size.width * CGFloat(i) / 3
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for i in 1...2 {
                let y = size.height * CGFloat(i) / 3
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.white.opacity(0.45), lineWidth: 0.5)
    }

    private func subjectBox(_ rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(Color.yellow.opacity(0.8), lineWidth: 1.5)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }

    private var levelIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: 140, height: 6)
                    Circle()
                        .fill(levelColor)
                        .frame(width: 10, height: 10)
                        .offset(x: levelOffset)
                }
                Spacer()
            }
            .padding(.bottom, 150)
        }
    }

    private var levelColor: Color {
        abs(motion.rollDegrees) < 2 ? .green : .orange
    }

    private var levelOffset: CGFloat {
        CGFloat(max(-1, min(1, motion.rollDegrees / 6.0))) * 55
    }
}
