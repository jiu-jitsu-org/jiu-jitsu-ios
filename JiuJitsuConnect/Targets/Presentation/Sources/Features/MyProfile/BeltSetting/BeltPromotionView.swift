import SwiftUI
import Domain
import DesignSystem

/// MY에서 더 높은 띠로 바꿔 저장했을 때 잠깐 덮는 축하 장면(#278).
///
/// 새 띠 캐릭터가 화면 아래에서 커지며 나타나고, 대회 완료 화면과 같은 종이 꽃가루가 퍼진다.
/// 아무 데나 누르거나 2초가 지나면 옅어지며 사라진다.
struct BeltPromotionView: View {
    let belt: BeltRank
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    @State private var isClosing = false

    private enum Metrics {
        // 캐릭터는 화면 높이의 절반까지, 대회 완료 화면 캐릭터보다 크지 않게 한다.
        static let characterHeightRatio: CGFloat = 0.5
        static let maxCharacterHeight: CGFloat = 400
        static let titleGap: CGFloat = 32
    }

    private enum Motion {
        static let appear = Animation.spring(duration: 0.5, bounce: 0.3)
        static let disappear = Animation.easeOut(duration: 0.25)
        static let startScale: CGFloat = 0.6
        static let stay: Duration = .seconds(2)
    }

    var body: some View {
        GeometryReader { proxy in
            // 메달을 걸지 않은 '참가' 그림이 띠 캐릭터 한 장이라 그대로 쓴다. 밑단은 잘린 단면이라 화면 아래 끝에 붙인다.
            let character = MedalCharacter(belt: belt, rank: .participation)
            let height = min(proxy.size.height * Metrics.characterHeightRatio, Metrics.maxCharacterHeight)

            ZStack(alignment: .bottom) {
                Color.primitive.coolGray.cg25

                PaperConfettiView(startDelay: 0.2)

                VStack(spacing: Metrics.titleGap) {
                    Text("\(belt.displayName)띠 승급을 축하해요!")
                        .font(Font.pretendard.display1)
                        .foregroundStyle(Color.component.textfieldDisplay.focus.title)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    character.image
                        .resizable()
                        .frame(width: height * character.aspectRatio, height: height)
                        .scaleEffect(isShown ? 1 : Motion.startScale, anchor: .bottom)
                        .accessibilityHidden(true)
                }
            }
            .opacity(isShown ? 1 : 0)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { Task { await close() } }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("누르면 닫혀요")
        .sensoryFeedback(.success, trigger: isShown) { _, isNowShown in isNowShown }
        .presentationBackground(.clear)
        .task {
            if reduceMotion {
                isShown = true
            } else {
                withAnimation(Motion.appear) { isShown = true }
            }
            guard (try? await Task.sleep(for: Motion.stay)) != nil else { return }
            await close()
        }
    }

    /// 눌렀거나 시간이 다 되었을 때 부른다. 어느 쪽이 먼저든 한 번만 닫는다.
    private func close() async {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(reduceMotion ? nil : Motion.disappear) { isShown = false }
        if !reduceMotion {
            try? await Task.sleep(for: .milliseconds(250))
        }
        onDismiss()
    }
}

// MARK: - Preview

#Preview {
    BeltPromotionView(belt: .blue, onDismiss: {})
}
