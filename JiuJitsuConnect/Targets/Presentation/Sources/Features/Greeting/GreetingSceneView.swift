import SwiftUI
import DesignSystem

/// 이미 로그인한 사람이 앱을 열 때 스플래시와 홈 사이에 보여주는 인사 장면.
///
/// 스플래시가 끝난 모습에서 시작해 문구·OSS 글자는 위로 올라가고, 둥근 그래픽은 조금만 가라앉아 캐릭터 뒤에 남는다.
/// 띠 캐릭터 다섯이 화면 아래에서 올라와 다 같이 깡충 뛰고, 한 명이 오늘 요일 인사를 건넨다.
/// 이어서 `onCover`로 홈이 아래에서 올라와 덮기 시작하고, 다 덮으면 `onFinish`를 부른다.
/// 시안 기준 화면은 393×852이며, 캐릭터 크기·위치는 화면 폭에 비례해 맞춘다.
struct GreetingSceneView: View {
    let onCover: () -> Void
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?
    @State private var greeting = DayGreeting.today()
    @State private var bubbleWidth: CGFloat = 0

    var body: some View {
        // 바깥 리더로 노치 높이를 읽고, 안쪽 리더는 화면 끝까지 넓혀 그린다 (LoginSceneView와 같은 이유)
        GeometryReader { safe in
            GeometryReader { full in
                let layout = GreetingLayout(size: full.size, safeArea: safe.safeAreaInsets)

                TimelineView(.animation(paused: start == nil)) { timeline in
                    scene(layout: layout, elapsed: timeline.date.timeIntervalSince(start ?? timeline.date))
                }
            }
            .ignoresSafeArea()
        }
        .task {
            // 움직임 줄이기가 켜져 있으면 인사 없이 바로 홈으로 간다
            guard !reduceMotion else {
                onFinish()
                return
            }
            start = .now
            guard await pause(Timing.cover) else { return }
            onCover()
            guard await pause(Timing.coverDuration) else { return }
            onFinish()
        }
    }

    // MARK: - 장면

    private func scene(layout: GreetingLayout, elapsed: TimeInterval) -> some View {
        let brand = Timing.brand.progress(at: elapsed)
        let sink = Timing.pattern.progress(at: elapsed)

        return ZStack(alignment: .topLeading) {
            Color.primitive.blue.b500p

            // 시트가 없으니 다 가라앉히지 않고 조금만 내려 캐릭터 뒤 빈 곳에 연하게 남긴다
            centered(Assets.Login.pattern, width: layout.splash.patternWidth, top: lerp(layout.splash.patternTop, layout.patternRestTop, sink), in: layout)

            // 캐릭터끼리의 앞뒤(zIndex)가 그래픽·글자까지 넘어가지 않도록 한 겹으로 묶는다
            ZStack(alignment: .topLeading) {
                ForEach(Array(GreetingCast.members.enumerated()), id: \.offset) { index, member in
                    let frame = layout.frame(of: member)
                    let entrance = Timing.entrance(of: index).progress(at: elapsed)
                    let jump = Jump(at: elapsed - Timing.jumpStart(of: index))
                    LoginCharacterView(
                        member: member,
                        isIdle: elapsed >= Timing.idle,
                        // 인사를 건넬 때 한 번 들썩인다
                        hop: index == greeting.speaker && elapsed >= Timing.say ? 1 : 0
                    )
                    .frame(width: frame.width, height: frame.height)
                    .scaleEffect(x: jump.scaleX, y: jump.scaleY, anchor: .bottom)
                    .offset(
                        x: frame.minX,
                        y: frame.minY + castEntranceOffset(entrance, height: frame.height, scale: layout.scale) + jump.lift * layout.scale
                    )
                    .opacity(entrance < 0.2 ? entrance / 0.2 : 1)
                    .zIndex(member.zIndex)
                }
            }
            .accessibilityHidden(true)

            centered(Assets.Splash.tagline, width: lerp(layout.splash.taglineWidth, 150, brand), top: lerp(layout.splash.taglineTop, layout.brandTop, brand), in: layout)
            centered(Assets.Splash.logo, width: lerp(layout.splash.logoWidth, 116, brand), top: lerp(layout.splash.logoTop, layout.brandTop + 24, brand), in: layout)

            sayBubble(layout: layout, elapsed: elapsed)
        }
        .lightStatusBar()
    }

    private func centered(_ asset: ImageAsset, width: CGFloat, top: CGFloat, in layout: GreetingLayout) -> some View {
        asset.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .offset(x: (layout.width - width) / 2, y: top)
            .accessibilityHidden(true)
    }

    // MARK: - 요일 인사

    /// 말하는 캐릭터 머리 위에 띄우고, 화면 밖으로 나가지 않게 민다. 꼬리는 늘 머리 쪽에 붙는다.
    @ViewBuilder
    private func sayBubble(layout: GreetingLayout, elapsed: TimeInterval) -> some View {
        let pop = Timing.sayPop.progress(at: elapsed)
        let fade = Timing.sayFade.progress(at: elapsed)
        if elapsed >= Timing.say, fade < 1 {
            let member = GreetingCast.members[greeting.speaker]
            let frame = layout.frame(of: member)
            let headX = frame.midX + (member.mirror ? -1 : 1) * frame.width * 0.1
            let left = min(max(headX - bubbleWidth * (member.mirror ? 0.7 : 0.3), 14), layout.width - 14 - bubbleWidth)
            let tailX = min(max(headX - left, 20), max(bubbleWidth - 20, 20))
            // 작게 튀어나와 살짝 지나쳤다가 제자리, 사라질 때는 줄어들며 흐려진다
            let grow = pop < 0.65 ? lerp(0.4, 1.06, pop / 0.65) : lerp(1.06, 1, (pop - 0.65) / 0.35)

            SayBubble(text: greeting.line, tailX: tailX, tailLean: member.mirror ? 4 : -4)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { bubbleWidth = $0 }
                .scaleEffect(grow * lerp(1, 0.85, fade), anchor: UnitPoint(x: bubbleWidth > 0 ? tailX / bubbleWidth : 0.5, y: 1.2))
                .opacity(min(pop / 0.65, 1) * (1 - fade))
                .offset(x: left, y: frame.minY + frame.height * 0.02 - SayBubble.height - 14)
                .accessibilityLabel(greeting.line)
        }
    }

    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil
    }
}

// MARK: - 출연진

/// 앞줄(흰·보라·검정)은 화면 아래 끝에 걸쳐 서고, 뒷줄(파랑·갈색)은 앞사람 머리 위로 눈을 내민다.
/// 뒷줄도 앞줄과 같은 크기로 보이게 폭을 맞추고, 어깨가 드러나지 않게 밴드 아래를 이어 붙인 몸통을 쓴다.
/// 값은 393pt 폭 기준이고, `show`는 화면 아래 끝 위로 드러나는 몸 비율이다. 순서는 흰·파랑·보라·갈색·검정.
enum GreetingCast {
    static let members: [LoginCastMember] = [
        .init(body: Assets.Login.Character.bodyWhite, width: 182, centerX: 78, rotation: 4, zIndex: 3, show: 0.80, mirror: true,
              eyeTilt: -6),
        .init(body: Assets.Login.Character.bodyExtBlue, width: 181, centerX: 89, rotation: -3, zIndex: 1, show: 1.32, mirror: true,
              eyeTilt: 8, eyeFlip: true, eyeScale: 0.94, isExtended: true),
        .init(body: Assets.Login.Character.bodyPurple, width: 196, centerX: 200, rotation: 1, zIndex: 5, show: 0.78, mirror: true,
              eyeTilt: 3, eyeScale: 1.04),
        .init(body: Assets.Login.Character.bodyExtBrown, width: 181, centerX: 295, rotation: 4, zIndex: 1, show: 1.333,
              eyes: Assets.Login.Character.eyesSad, eyeTilt: -9, eyeScale: 0.96, isExtended: true),
        .init(body: Assets.Login.Character.bodyBlack, width: 176, centerX: 330, rotation: -5, zIndex: 4, show: 0.80,
              eyeTilt: 6, eyeFlip: true)
    ]
}

/// 오늘 요일에 맞는 인사. 요일마다 말하는 캐릭터와 두 안 중 하나를 무작위로 고른다.
private struct DayGreeting {
    let line: String
    let speaker: Int

    static func today(_ date: Date = .now, calendar: Calendar = .current) -> Self {
        // weekday는 일요일이 1이다
        let day = (calendar.component(.weekday, from: date) - 1) % 7
        let options = lines[day]
        return Self(line: options.randomElement() ?? options[0], speaker: speakers[day])
    }

    /// 일요일부터
    private static let lines: [[String]] = [
        ["쉬어도 되지만, 한 판?", "도복 빨아두는 날, 일요일"],
        ["몸 풀러 주짓수 고고?", "월요병엔 롤링이 약이지"],
        ["어제 털린 거 복수하러 고?", "화요일도 매트 위에서 한 판?"],
        ["벌써 수요일? 한 판 고고?", "몸이 슬슬 매트를 찾는 수요일"],
        ["목요일 출석 도장 찍으러 고?", "목요일엔 탭 덜 치는 날"],
        ["불금이니까 주짓수 고고?", "불금엔 술 대신 롤링"],
        ["오늘은 오픈매트?", "주말 롤링 한 판 고?"]
    ]
    /// 일 흰 / 월 보라 / 화 검정 / 수 흰 / 목 파랑 / 금 보라 / 토 검정 (출연진 순서의 번호)
    private static let speakers = [0, 2, 4, 0, 1, 2, 4]
}

// MARK: - 배치

private struct GreetingLayout {
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let brandTop: CGFloat
    /// 장면이 시작하는 모습. SplashView와 같은 배치여야 스플래시에서 넘어오는 순간 그림이 튀지 않는다
    let splash: SplashLayout

    init(size: CGSize, safeArea: EdgeInsets) {
        width = size.width
        height = size.height
        scale = size.width / 393
        // 시안(852 높이, 위 안전 영역 59)에서 문구 묶음의 위 끝이 118이 되도록 안전 영역에서 59만큼 띄운다
        brandTop = safeArea.top + 59
        splash = SplashLayout(size: size)
    }

    /// 그래픽이 가라앉아 멈추는 자리. 시안에서 120pt 내린 만큼을 화면 폭에 맞춘다
    var patternRestTop: CGFloat { splash.patternTop + 120 * scale }

    /// 아래 끝은 화면 아래 끝에 맞추고, `show`만큼만 화면 위로 드러낸다
    func frame(of member: LoginCastMember) -> CGRect {
        LoginCast.frame(of: member, scale: scale, screenWidth: width, baseline: height)
    }
}

// MARK: - 시간표

/// 시안(웹)의 시간표를 그대로 옮긴 값. 단위는 초.
private enum Timing {
    static let brand = SceneSegment(delay: 0.45, duration: 0.76, curve: .init(0.6, 0, 0.2, 1))
    static let pattern = SceneSegment(delay: 0.6, duration: 1.1, curve: .init(0.55, 0, 0.3, 1))
    /// 보라 → 파랑 → 검정 → 흰 → 갈색 순으로, 박자를 살짝 엇갈려 올라온다 (로그인 화면과 같다)
    private static let entranceOrder = [2, 1, 4, 0, 3]
    static let idle: Double = 1.8
    /// 다 같이 깡충. 가운데(보라)부터 바깥으로 0.05초씩 늦게 뛴다
    static let jump: Double = 2.15
    static let jumpDuration: Double = 0.44
    static let jumpCurve = CubicBezier(0, 0, 0.58, 1)
    static let say: Double = jump + 0.48
    static let sayLife: Double = 1.3
    static let sayPop = SceneSegment(delay: say, duration: 0.32, curve: .init(0.3, 0.7, 0.4, 1))
    static let sayFade = SceneSegment(delay: say + sayLife, duration: 0.22, curve: .init(0.42, 0, 1, 1))
    /// 읽을 시간을 두고 홈이 덮기 시작한다
    static let cover: Double = 3.95
    static let coverDuration: Double = 0.52

    static func entrance(of member: Int) -> SceneSegment {
        let turn = entranceOrder.firstIndex(of: member) ?? 0
        let stagger = Double(turn) * 0.09 + (turn % 2 == 1 ? 0.04 : 0)
        return SceneSegment(delay: 1.0 + stagger, duration: 0.72, curve: .init(0.3, 0.7, 0.4, 1))
    }

    static func jumpStart(of member: Int) -> Double {
        jump + Double(abs(member - 2)) * 0.05
    }
}

/// 깡충 한 번: 웅크렸다(0.15) 솟구치고(0.5) 눌리며 내려앉았다(0.8) 제 모양으로 돌아온다. 높이는 393pt 기준.
private struct Jump {
    private(set) var lift: CGFloat = 0
    private(set) var scaleX: CGFloat = 1
    private(set) var scaleY: CGFloat = 1

    private struct Key {
        let time: Double
        let lift: CGFloat
        let scaleX: CGFloat
        let scaleY: CGFloat
    }

    private static let keys: [Key] = [
        Key(time: 0, lift: 0, scaleX: 1, scaleY: 1),
        Key(time: 0.15, lift: 0, scaleX: 1.05, scaleY: 0.94),
        Key(time: 0.5, lift: -18, scaleX: 0.98, scaleY: 1.03),
        Key(time: 0.8, lift: 0, scaleX: 1.04, scaleY: 0.96),
        Key(time: 1, lift: 0, scaleX: 1, scaleY: 1)
    ]

    init(at time: TimeInterval) {
        let progress = Timing.jumpCurve.value(at: time / Timing.jumpDuration)
        guard progress > 0, progress < 1 else { return }
        for (from, to) in zip(Self.keys, Self.keys.dropFirst()) where progress <= to.time {
            let local = (progress - from.time) / (to.time - from.time)
            lift = lerp(from.lift, to.lift, local)
            scaleX = lerp(from.scaleX, to.scaleX, local)
            scaleY = lerp(from.scaleY, to.scaleY, local)
            return
        }
    }
}

// MARK: - 말풍선

/// 글 한 줄을 담은 흰 말풍선. 꼬리는 작은 원 두 개로, `tailX` 자리에서 아래로 떨어진다.
private struct SayBubble: View {
    let text: String
    let tailX: CGFloat
    /// 작은 원을 머리 쪽으로 살짝 기울인다
    let tailLean: CGFloat

    static let height: CGFloat = 40

    var body: some View {
        Text(text)
            .font(.pretendard.custom(weight: .semiBold, size: 15))
            .tracking(-0.3)
            .foregroundStyle(Color.primitive.coolGray.cg900)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 16)
            .frame(height: Self.height)
            .background(
                Capsule()
                    .fill(Color.primitive.bw.trueWhite)
                    .shadow(color: Color.primitive.blue.b900.opacity(0.22), radius: 11, y: 8)
            )
            .overlay(alignment: .bottomLeading) {
                ZStack(alignment: .bottomLeading) {
                    Circle()
                        .frame(width: 12, height: 12)
                        .offset(x: tailX - 6, y: 6)
                    Circle()
                        .frame(width: 6, height: 6)
                        .offset(x: tailX - 3 + tailLean, y: 14)
                }
                .foregroundStyle(Color.primitive.bw.trueWhite)
            }
    }
}

#Preview("Greeting Scene") {
    GreetingSceneView(onCover: {}, onFinish: {})
}
