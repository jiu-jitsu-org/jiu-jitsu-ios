import SwiftUI
import Domain
import DesignSystem

/// 메달을 건 띠 캐릭터 그림 한 장과 그림 안의 메달 자리.
struct MedalCharacter: Equatable {
    let belt: BeltRank
    let rank: CompetitionRank

    /// '참가'는 메달을 걸지 않은 그림이라 메달 움직임이 없다.
    var hasMedal: Bool {
        rank != .participation
    }

    var image: Image {
        asset.swiftUIImage
    }

    private var asset: ImageAsset {
        typealias Medal = Assets.MyProfile.Medal
        switch (belt, rank) {
        case (.white, .gold): return Medal.whiteGold
        case (.white, .silver): return Medal.whiteSilver
        case (.white, .bronze): return Medal.whiteBronze
        case (.white, .participation): return Medal.whiteParticipation
        case (.blue, .gold): return Medal.blueGold
        case (.blue, .silver): return Medal.blueSilver
        case (.blue, .bronze): return Medal.blueBronze
        case (.blue, .participation): return Medal.blueParticipation
        case (.purple, .gold): return Medal.purpleGold
        case (.purple, .silver): return Medal.purpleSilver
        case (.purple, .bronze): return Medal.purpleBronze
        case (.purple, .participation): return Medal.purpleParticipation
        case (.brown, .gold): return Medal.brownGold
        case (.brown, .silver): return Medal.brownSilver
        case (.brown, .bronze): return Medal.brownBronze
        case (.brown, .participation): return Medal.brownParticipation
        case (.black, .gold): return Medal.blackGold
        case (.black, .silver): return Medal.blackSilver
        case (.black, .bronze): return Medal.blackBronze
        case (.black, .participation): return Medal.blackParticipation
        }
    }

    /// 그림 비율과 그림 안 메달 자리(0~1). 띠마다 기운 방향이 달라 메달 자리도 다르다. 같은 띠의 금·은·동은 자리가 같다.
    /// 참가 그림은 메달이 없어 비율만 쓴다.
    var layout: Layout {
        switch belt {
        case .white: return Layout(aspectRatio: 344.0 / 870.0, medalCenter: UnitPoint(x: 0.4142, y: 0.7851), medalHeightRatio: 0.2690)
        case .blue: return Layout(aspectRatio: 270.0 / 870.0, medalCenter: UnitPoint(x: 0.4648, y: 0.7701), medalHeightRatio: 0.2621)
        case .purple: return Layout(aspectRatio: 271.0 / 870.0, medalCenter: UnitPoint(x: 0.5314, y: 0.7695), medalHeightRatio: 0.2632)
        case .brown: return Layout(aspectRatio: 264.0 / 870.0, medalCenter: UnitPoint(x: 0.5530, y: 0.7776), medalHeightRatio: 0.2655)
        case .black: return Layout(aspectRatio: 266.0 / 870.0, medalCenter: UnitPoint(x: 0.4436, y: 0.7810), medalHeightRatio: 0.2678)
        }
    }

    /// 그림 가로 ÷ 세로. 메달 유무에 따라 그림 폭이 달라 띠와 함께 따로 둔다.
    var aspectRatio: CGFloat {
        guard !hasMedal else { return layout.aspectRatio }
        switch belt {
        // 참가 그림은 세로 1200px(#285).
        case .white: return 472.0 / 1200.0
        case .blue: return 373.0 / 1200.0
        case .purple: return 373.0 / 1200.0
        case .brown: return 309.0 / 1200.0
        case .black: return 307.0 / 1200.0
        }
    }

    struct Layout: Equatable {
        let aspectRatio: CGFloat
        let medalCenter: UnitPoint
        /// 메달 지름 ÷ 그림 높이
        let medalHeightRatio: CGFloat
    }
}

/// 캐릭터가 시트 뒤에서 올라오고, 메달만 커졌다 돌아오며 빛이 지나간다(#220).
struct MedalCharacterView: View {
    let character: MedalCharacter
    let height: CGFloat
    let celebrates: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRisen: Bool
    @State private var isMedalActive = false
    @State private var medalScale: CGFloat = 1
    @State private var gleamProgress: CGFloat = 0

    private enum Motion {
        static let rise = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)
        // 올라오는 움직임이 끝나기 조금 전에 메달이 움직이기 시작해 한 동작처럼 이어진다.
        static let medalDelay: Duration = .milliseconds(420)
        static let medalGrow = Animation.easeInOut(duration: 0.2)
        static let medalShrink = Animation.easeInOut(duration: 0.275)
        static let gleam = Animation.easeInOut(duration: 0.45)
        static let maxMedalScale: CGFloat = 1.18
    }

    init(character: MedalCharacter, height: CGFloat, celebrates: Bool) {
        self.character = character
        self.height = height
        self.celebrates = celebrates
        _isRisen = State(initialValue: !celebrates)
    }

    var body: some View {
        let layout = character.layout
        let width = height * character.aspectRatio
        let diameter = height * layout.medalHeightRatio
        let center = CGPoint(x: width * layout.medalCenter.x, y: height * layout.medalCenter.y)

        ZStack {
            character.image
                .resizable()
                .frame(width: width, height: height)

            if isMedalActive {
                medal(center: center, diameter: diameter)
                    .scaleEffect(medalScale, anchor: layout.medalCenter)
            }
        }
        .frame(width: width, height: height)
        // 밑단이 드러나지 않게 위로는 넘치지 않고, 아래에서 제자리까지만 올라온다.
        .offset(y: isRisen ? 0 : height * 1.05)
        .accessibilityElement()
        .accessibilityLabel("\(character.belt.displayName) 띠 \(character.rank.displayName) 캐릭터")
        .task { await play() }
    }

    /// 그림에서 메달만 오려 위에 겹친다. 크게 키워도 아래의 원래 메달을 덮으므로 두 개로 보이지 않는다.
    private func medal(center: CGPoint, diameter: CGFloat) -> some View {
        ZStack {
            character.image
                .resizable()
                .mask(
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .position(center)
                )

            LinearGradient(
                colors: [.clear, Color.primitive.bw.white.opacity(0.85), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: diameter * 0.45, height: diameter * 1.4)
            .rotationEffect(.degrees(12))
            .offset(x: diameter * (gleamProgress * 1.8 - 0.9))
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .position(center)
        }
    }

    private func play() async {
        guard celebrates, !reduceMotion else {
            isRisen = true
            return
        }
        withAnimation(Motion.rise) { isRisen = true }
        guard character.hasMedal else { return }

        guard (try? await Task.sleep(for: Motion.medalDelay)) != nil else { return }
        isMedalActive = true
        withAnimation(Motion.medalGrow) { medalScale = Motion.maxMedalScale }
        withAnimation(Motion.gleam.delay(0.05)) { gleamProgress = 1 }

        guard (try? await Task.sleep(for: .milliseconds(200))) != nil else { return }
        withAnimation(Motion.medalShrink) { medalScale = 1 }

        guard (try? await Task.sleep(for: .milliseconds(300))) != nil else { return }
        isMedalActive = false
    }
}

/// 캐릭터가 없는 경우('참가' 기록, 띠 정보 없음) 보여 주는 메달 아이콘.
struct MedalIconRiseView: View {
    let image: Image
    let celebrates: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible: Bool

    init(image: Image, celebrates: Bool) {
        self.image = image
        self.celebrates = celebrates
        _isVisible = State(initialValue: !celebrates)
    }

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 88, height: 88)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 40)
            .task {
                guard celebrates, !reduceMotion else {
                    isVisible = true
                    return
                }
                withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)) { isVisible = true }
            }
    }
}
