import SwiftUI
import DesignSystem

/// 이미 로그인한 사람이 앱을 열 때 스플래시와 홈 사이에 보여주는 인사 장면.
///
/// 스플래시가 끝난 모습에서 시작해 문구·OSS 글자는 위로 올라가고, 둥근 그래픽은 조금만 가라앉아 캐릭터 뒤에 남는다.
/// 로그인 화면과 같은 띠 캐릭터 다섯이 화면 아래 끝에서 띠용 올라와 다 같이 깡충 뛰고, 한 명이 오늘 요일 인사를 건넨다.
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
                ForEach(Array(BeltCast.members.enumerated()), id: \.offset) { index, member in
                    let placement = layout.placement(of: member)
                    let rise = BeltRise.pose(elapsed: elapsed - member.start, speed: member.speed, visible: placement.visible)
                    let jump = Jump(at: elapsed - Timing.jumpStart(of: index))
                    BeltCharacterView(
                        member: member,
                        placement: placement,
                        rise: jump.applied(to: rise ?? BeltRise.Pose(), scale: layout.scale),
                        isIdle: elapsed >= Timing.idle,
                        // 인사를 건넬 때 한 번 들썩인다
                        hop: index == greeting.speaker && elapsed >= Timing.say ? 1 : 0
                    )
                    .frame(width: placement.frame.width, height: placement.frame.height)
                    .offset(x: placement.frame.minX, y: placement.frame.minY)
                    .opacity(rise == nil ? 0 : 1)
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
    /// 로그인 화면의 `···` 말풍선처럼 꼬리 쪽에서 튀어나와 둥실 떠 있다가, 위로 떠오르며 작아진다.
    @ViewBuilder
    private func sayBubble(layout: GreetingLayout, elapsed: TimeInterval) -> some View {
        let leave = Timing.sayLeave.progress(at: elapsed)
        if elapsed >= Timing.say, leave < 1 {
            let head = layout.placement(of: BeltCast.members[greeting.speaker]).head
            // 머리가 화면 오른쪽에 있으면 말풍선을 왼쪽으로 펼친다
            let opensLeft = head.x > layout.width / 2
            let left = min(max(head.x - bubbleWidth * (opensLeft ? 0.7 : 0.3), 14), layout.width - 14 - bubbleWidth)
            let tailX = min(max(head.x - left, 20), max(bubbleWidth - 20, 20))
            let anchor = UnitPoint(x: bubbleWidth > 0 ? tailX / bubbleWidth : 0.5, y: 1.2)

            SayBubble(text: greeting.line, tailX: tailX, tailLean: opensLeft ? 4 : -4, anchor: anchor)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { bubbleWidth = $0 }
                .modifier(BubbleLeave(progress: leave, anchor: anchor))
                .offset(x: left, y: head.y - SayBubble.height - 14)
                .accessibilityLabel(greeting.line)
        }
    }

    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil
    }
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
    /// 일 갈색 / 월 보라 / 화 검정 / 수 갈색 / 목 검정 / 금 보라 / 토 검정 (BeltCast 순서의 번호).
    /// 로그인 화면처럼 머리가 높은 셋만 말한다. 작은 둘 머리 위에 띄우면 옆 캐릭터 눈을 가린다
    private static let speakers = [0, 4, 2, 0, 2, 4, 2]
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

    /// 시트가 없으니 화면 아래 끝을 로그인 화면의 시트 위 끝 삼아 세운다. 몸통 아래쪽은 화면 밖으로 나간다
    func placement(of member: BeltMember) -> BeltPlacement {
        BeltCast.placement(of: member, scale: scale, screenWidth: width, sheetTop: height)
    }
}

// MARK: - 시간표

/// 시안(웹)의 시간표를 그대로 옮긴 값. 단위는 초.
private enum Timing {
    static let brand = SceneSegment(delay: 0.45, duration: 0.76, curve: .init(0.6, 0, 0.2, 1))
    static let pattern = SceneSegment(delay: 0.6, duration: 1.1, curve: .init(0.55, 0, 0.3, 1))
    /// 캐릭터 등장은 BeltCast 각자의 시작·속도를 따른다(로그인 화면과 같다). 마지막(보라)이 약 2.03초에 앉는다
    static let idle: Double = 2.1
    /// 다 같이 깡충. 가운데(검정)부터 바깥으로 0.05초씩 늦게 뛴다
    static let jump: Double = 2.15
    static let jumpDuration: Double = 0.44
    static let jumpCurve = CubicBezier(0, 0, 0.58, 1)
    static let say: Double = jump + 0.48
    static let sayLife: Double = 1.3
    /// 로그인 화면의 말풍선이 사라지는 움직임(easeIn 0.28초)과 같다
    static let sayLeave = SceneSegment(delay: say + sayLife, duration: 0.28, curve: .init(0.42, 0, 1, 1))
    /// 읽을 시간을 두고 홈이 덮기 시작한다
    static let cover: Double = 3.95
    static let coverDuration: Double = 0.52

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

    /// 띠용 등장 모습 위에 얹는다. 깡충은 다 앉은 뒤라 겹치지 않는다
    func applied(to pose: BeltRise.Pose, scale: CGFloat) -> BeltRise.Pose {
        BeltRise.Pose(lift: pose.lift + lift * scale, scaleX: pose.scaleX * scaleX, scaleY: pose.scaleY * scaleY)
    }

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

/// 글 한 줄을 담은 흰 말풍선. 로그인 화면 `···` 말풍선과 같은 말랑한 몸통을 글 길이만큼 늘이고,
/// 꼬리는 작은 원 두 개로 `tailX` 자리에서 아래로 떨어진다.
private struct SayBubble: View {
    let text: String
    let tailX: CGFloat
    /// 작은 원을 머리 쪽으로 살짝 기울인다
    let tailLean: CGFloat
    /// 꼬리 쪽에서 튀어나온다
    let anchor: UnitPoint

    static let height: CGFloat = 40

    @State private var hasAppeared = false

    var body: some View {
        Text(text)
            .font(.pretendard.custom(weight: .semiBold, size: 15))
            .tracking(-0.3)
            .foregroundStyle(Color.primitive.coolGray.cg900)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 16)
            .frame(height: Self.height)
            .background(alignment: .bottomLeading) {
                ZStack(alignment: .bottomLeading) {
                    PuffShape(hasTail: false)
                    Circle()
                        .frame(width: 12, height: 12)
                        .offset(x: tailX - 6, y: 6)
                    Circle()
                        .frame(width: 6, height: 6)
                        .offset(x: tailX - 3 + tailLean, y: 14)
                }
                .foregroundStyle(Color.primitive.bw.trueWhite)
                .compositingGroup()
                .shadow(color: Color.primitive.blue.b900.opacity(0.09), radius: 4, y: 4.8)
            }
            .modifier(BubbleEntrance(anchor: anchor, isStatic: false, trigger: hasAppeared))
            .onAppear { hasAppeared = true }
    }
}

#Preview("Greeting Scene") {
    GreetingSceneView(onCover: {}, onFinish: {})
}
