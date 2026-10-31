import SwiftUI
import DesignSystem

/// 로그인 화면의 그림 부분. 스플래시가 끝난 모습에서 시작해 로그인 화면으로 이어진다.
///
/// 문구·OSS 글자는 위로 올라가며 작아지고, 둥근 그래픽은 아래로 가라앉으며 시트 뒤로 들어간다.
/// 그 사이 시트 뒤에서 띠 캐릭터 다섯이 거의 함께 띠용 올라오고, 숨 고른 뒤 머리 위로 `···` 말풍선이 오간다.
/// 시안 기준 화면은 393×852이며, 캐릭터 크기·위치는 화면 폭에 비례해 맞춘다.
struct LoginSceneView<Sheet: View>: View {
    @ViewBuilder let sheet: () -> Sheet

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var introStart: Date?
    @State private var isIntroFinished = false
    @State private var bubbles: [TalkBubble] = []
    @State private var hops = Array(repeating: 0, count: BeltCast.members.count)

    var body: some View {
        // 바깥 리더로 노치·홈 바 높이를 읽고, 안쪽 리더는 화면 끝까지 넓혀 그린다.
        // 화면 끝까지 넓힌 리더 안에서는 안전 영역이 0으로 보여 따로 읽어야 한다
        GeometryReader { safe in
            GeometryReader { full in
                let layout = SceneLayout(size: full.size, safeArea: safe.safeAreaInsets)

                TimelineView(.animation(paused: isIntroFinished)) { timeline in
                    let elapsed = isIntroFinished ? .infinity : timeline.date.timeIntervalSince(introStart ?? timeline.date)
                    scene(layout: layout, elapsed: elapsed)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // 닉네임 설정 화면에서 돌아왔을 때는 처음부터 다시 틀지 않는다
            guard introStart == nil else { return }
            introStart = .now
            if reduceMotion { isIntroFinished = true }
        }
        .task {
            guard !isIntroFinished else { return }
            try? await Task.sleep(for: .seconds(Timing.introEnd))
            isIntroFinished = true
        }
        .task(id: isIntroFinished) {
            guard isIntroFinished else { return }
            await talk()
        }
    }

    // MARK: - 장면

    private func scene(layout: SceneLayout, elapsed: TimeInterval) -> some View {
        let brand = Timing.brand.progress(at: elapsed)
        let sink = Timing.pattern.progress(at: elapsed)
        let rise = Timing.sheet.progress(at: elapsed)

        return ZStack(alignment: .topLeading) {
            Color.primitive.blue.b500p

            // 캐릭터끼리의 앞뒤(zIndex)가 그래픽·시트까지 넘어가지 않도록 한 겹으로 묶는다.
            // 시트가 멈추는 높이(둥근 모서리만큼 아래)보다 아래로는 그리지 않아, 시트가 올라오는 중에도 시트 자리로 띠가 비치지 않는다
            ZStack(alignment: .topLeading) {
                ForEach(Array(BeltCast.members.enumerated()), id: \.offset) { index, member in
                    let placement = layout.placement(of: member)
                    let rise = BeltRise.pose(elapsed: elapsed - member.start, speed: member.speed, visible: placement.visible)
                    BeltCharacterView(
                        member: member,
                        placement: placement,
                        rise: rise ?? BeltRise.Pose(),
                        isIdle: isIntroFinished && !reduceMotion,
                        hop: hops[index]
                    )
                    .frame(width: placement.frame.width, height: placement.frame.height)
                    .offset(x: placement.frame.minX, y: placement.frame.minY)
                    .opacity(rise == nil ? 0 : 1)
                    .zIndex(member.zIndex)
                }
            }
            .frame(width: layout.width, height: layout.height, alignment: .topLeading)
            .mask(alignment: .topLeading) {
                // 첫 레이아웃에서 크기가 0으로 들어오면 sheetTop이 음수가 되어 frame 경고가 난다
                Rectangle().frame(width: layout.width, height: max(layout.sheetTop + 28, 0))
            }
            .accessibilityHidden(true)

            // 가라앉는 그래픽이 캐릭터를 가리고 있다가 드러낸다. 그래서 캐릭터보다 위에 둔다
            centered(Assets.Login.pattern, width: layout.splash.patternWidth, top: lerp(layout.splash.patternTop, layout.patternRestTop, sink), in: layout)
            centered(Assets.Splash.tagline, width: lerp(layout.splash.taglineWidth, 150, brand), top: lerp(layout.splash.taglineTop, layout.brandTop, brand), in: layout)
            centered(Assets.Splash.logo, width: lerp(layout.splash.logoWidth, 116, brand), top: lerp(layout.splash.logoTop, layout.brandTop + 24, brand), in: layout)

            ForEach(bubbles) { bubble in
                let spot = layout.bubbleSpot(for: bubble, among: bubbles)
                let anchor = PuffBubble.anchor(pointsRight: spot.pointsRight)
                PuffBubble(pointsRight: spot.pointsRight, isStatic: reduceMotion)
                    .accessibilityHidden(true)
                    .offset(x: spot.origin.x, y: spot.origin.y)
                    .transition(
                        .asymmetric(
                            insertion: .identity,
                            removal: .modifier(active: BubbleLeave(progress: 1, anchor: anchor), identity: BubbleLeave(progress: 0, anchor: anchor))
                        )
                    )
            }

            sheetContainer(layout: layout)
                .offset(y: layout.sheetTop + (1 - rise) * layout.sheetHeight)
        }
    }

    private func sheetContainer(layout: SceneLayout) -> some View {
        sheet()
            .padding(.top, 28)
            .padding(.horizontal, 35)
            .padding(.bottom, layout.sheetBottomPadding)
            .frame(width: layout.width, height: layout.sheetHeight, alignment: .top)
            .background(
                Color.primitive.bw.trueWhite,
                in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
            )
    }

    private func centered(_ asset: ImageAsset, width: CGFloat, top: CGFloat, in layout: SceneLayout) -> some View {
        asset.swiftUIImage
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .offset(x: (layout.width - width) / 2, y: top)
            .accessibilityHidden(true)
    }

    // MARK: - 수다

    /// 다 모인 뒤 숨 고르고 나서 말풍선을 번갈아 띄운다. 화면을 떠나면 task가 끊기며 함께 멈춘다.
    private func talk() async {
        // 화면을 떠나며 끊겼을 때 남은 말풍선을 치우고 새로 시작한다
        bubbles = []
        if reduceMotion {
            bubbles = [TalkBubble(id: 0, member: 2), TalkBubble(id: 1, member: 4)]
            return
        }
        var speaker = TalkSpeaker()

        // 말풍선을 지우는 작업은 이 묶음 아래에 건다. 끝난 작업은 묶음이 바로 버리고,
        // 화면을 떠나 talk()가 끊기면 아직 기다리던 작업도 함께 취소된다
        await withDiscardingTaskGroup { removals in
            guard await pause(Timing.talkStart - Timing.introEnd) else { return }
            say(life: 1.8, speaker: &speaker, removals: &removals)
            guard await pause(1.3) else { return }
            say(life: 1.7, speaker: &speaker, removals: &removals)
            guard await pause(2.3) else { return }
            while true {
                say(life: 2.0, speaker: &speaker, removals: &removals)
                guard await pause(2.8) else { return }
            }
        }
    }

    /// 말풍선을 하나 띄우고, `life`초 뒤 지우는 작업을 `removals`에 건다. 이미 둘이 떠 있으면 건너뛴다.
    private func say(life: Double, speaker: inout TalkSpeaker, removals: inout DiscardingTaskGroup) {
        guard bubbles.count < Timing.maxBubbles else { return }
        let bubble = speaker.next()
        // 나타나는 움직임은 말풍선이 스스로 한다(PuffBubble)
        bubbles.append(bubble)
        hops[bubble.member] += 1
        removals.addTask { @MainActor in
            guard await pause(life) else { return }
            withAnimation(.easeIn(duration: 0.28)) { bubbles.removeAll { $0.id == bubble.id } }
        }
    }

    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil
    }
}

/// 이웃끼리 연달아 말하지 않도록 정해둔 순서를 돈다.
private struct TalkSpeaker {
    private static let order = BeltCast.speakers
    private var turn = 0
    private var last = -1
    private var nextID = 0

    mutating func next() -> TalkBubble {
        var member = Self.order[turn % Self.order.count]
        turn += 1
        if member == last {
            member = Self.order[turn % Self.order.count]
            turn += 1
        }
        last = member
        nextID += 1
        return TalkBubble(id: nextID, member: member)
    }
}

private struct TalkBubble: Identifiable, Equatable {
    let id: Int
    let member: Int
}

// MARK: - 배치

private struct SceneLayout {
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let safeTop: CGFloat
    let sheetHeight: CGFloat
    let sheetBottomPadding: CGFloat
    /// 장면이 시작하는 모습. SplashView와 같은 배치여야 스플래시에서 넘어오는 순간 그림이 튀지 않는다
    let splash: SplashLayout

    init(size: CGSize, safeArea: EdgeInsets) {
        width = size.width
        height = size.height
        scale = size.width / 393
        safeTop = safeArea.top
        // 버튼 셋 + 둘러보기 + 위 여백 = 260. 홈 바가 있는 기기는 그만큼 띄우고, 없으면 16만 남긴다
        sheetBottomPadding = max(safeArea.bottom - 4, 16)
        sheetHeight = 260 + sheetBottomPadding

        splash = SplashLayout(size: size)
    }

    var sheetTop: CGFloat { height - sheetHeight }

    /// 문구·OSS 글자 묶음의 위 끝. 시계 아래부터 가장 높은 캐릭터 머리까지 빈 곳의 가운데쯤에 둔다
    var brandTop: CGFloat {
        let headTop = BeltCast.members.map { placement(of: $0).head.y }.min() ?? sheetTop
        return safeTop + max(headTop - safeTop - Self.brandHeight, 0) * 0.5
    }

    /// 문구(150pt 폭) + 간격 10 + OSS 글자(116pt 폭)의 높이
    private static let brandHeight: CGFloat = 66
    /// 그래픽이 시트 뒤로 완전히 들어간 자리
    var patternRestTop: CGFloat { sheetTop + 50 }

    func placement(of member: BeltMember) -> BeltPlacement {
        BeltCast.placement(of: member, scale: scale, screenWidth: width, sheetTop: sheetTop)
    }

    /// 꼬리 끝이 머리 꼭대기 옆에 오게, 캐릭터가 말하는 쪽에 띄운다. 이미 떠 있는 말풍선과 겹치면 반대쪽에,
    /// 화면 밖으로 나가지 않게, OSS 글자 아래로만 띄운다.
    func bubbleSpot(for bubble: TalkBubble, among bubbles: [TalkBubble]) -> (origin: CGPoint, pointsRight: Bool) {
        let member = BeltCast.members[bubble.member]
        let head = placement(of: member).head
        let size = PuffBubble.size, tip = PuffBubble.tip
        let minTop = brandTop + Self.brandHeight + 8

        func spot(pointsRight: Bool) -> CGRect {
            let tipX = head.x + (pointsRight ? 6 : -6)
            let left = pointsRight ? tipX - tip.x : tipX - (size.width - tip.x)
            return CGRect(
                x: min(max(left, 12), width - 12 - size.width),
                y: max(head.y - 6 - tip.y, minTop),
                width: size.width,
                height: size.height
            )
        }

        // 먼저 떠 있던 말풍선만 피한다(나중 것이 비켜 선다)
        let earlier = bubbles.prefix { $0.id != bubble.id }.map { bubbleSpot(for: $0, among: bubbles) }
        var pointsRight = member.talksRight
        if earlier.contains(where: { CGRect(origin: $0.origin, size: size).insetBy(dx: -6, dy: -6).intersects(spot(pointsRight: pointsRight)) }) {
            pointsRight.toggle()
        }
        return (spot(pointsRight: pointsRight).origin, pointsRight)
    }
}

// MARK: - 시간표

/// 시안(웹)의 시간표를 그대로 옮긴 값. 단위는 초.
private enum Timing {
    static let brand = Segment(delay: 0.45, duration: 0.76, curve: .init(0.6, 0, 0.2, 1))
    static let pattern = Segment(delay: 0.6, duration: 1.1, curve: .init(0.55, 0, 0.3, 1))
    /// 캐릭터(0.87초~)보다 먼저 올라와, 띠가 나올 때는 시트가 거의 다 올라와 있다
    static let sheet = Segment(delay: 0.6, duration: 0.6, curve: .init(0.2, 0.8, 0.2, 1))
    /// 캐릭터 등장은 BeltCast 각자의 시작·속도를 따른다. 마지막(보라)이 약 2.03초에 앉는다
    static let introEnd: Double = 2.1
    static let talkStart: Double = 2.95
    static let maxBubbles = 2

    typealias Segment = SceneSegment
}

/// 시작 시각(`delay`)부터 `duration` 동안 `curve`를 따라 0 → 1로 진행한다. 단위는 초.
struct SceneSegment {
    let delay: Double
    let duration: Double
    let curve: CubicBezier

    func progress(at elapsed: TimeInterval) -> Double {
        curve.value(at: min(max((elapsed - delay) / duration, 0), 1))
    }
}

/// CSS `cubic-bezier()`와 같은 곡선. 시간 비율에 대한 진행 정도를 돌려준다.
struct CubicBezier {
    let control1: (x: Double, y: Double)
    let control2: (x: Double, y: Double)

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) { // swiftlint:disable:this identifier_name
        control1 = (x1, y1)
        control2 = (x2, y2)
    }

    func value(at time: Double) -> Double {
        guard time > 0 else { return 0 }
        guard time < 1 else { return 1 }
        // 곡선의 가로값은 매개변수에 대해 단조 증가하므로 이분법으로 매개변수를 찾는다
        var low = 0.0, high = 1.0, param = time
        for _ in 0..<24 {
            let current = Self.point(param, control1.x, control2.x)
            if abs(current - time) < 1e-5 { break }
            if current < time { low = param } else { high = param }
            param = (low + high) / 2
        }
        return Self.point(param, control1.y, control2.y)
    }

    private static func point(_ param: Double, _ first: Double, _ second: Double) -> Double {
        let inv = 1 - param
        return 3 * inv * inv * param * first + 3 * inv * param * param * second + param * param * param
    }
}

func lerp(_ from: CGFloat, _ to: CGFloat, _ progress: Double) -> CGFloat {
    from + (to - from) * progress
}

#Preview("Login Scene") {
    LoginSceneView {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primitive.coolGray.cg75)
                    .frame(height: 52)
            }
        }
    }
}
