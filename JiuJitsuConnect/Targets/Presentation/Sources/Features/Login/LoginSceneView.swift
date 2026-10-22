import SwiftUI
import DesignSystem

/// 로그인 화면의 그림 부분. 스플래시가 끝난 모습에서 시작해 로그인 화면으로 이어진다.
///
/// 문구·OSS 글자는 위로 올라가며 작아지고, 둥근 그래픽은 아래로 가라앉으며 시트 뒤로 들어간다.
/// 그 뒤에 모여 있던 캐릭터 다섯이 드러나고, 숨 고른 뒤 머리 위로 `···` 말풍선이 오간다.
/// 시안 기준 화면은 393×852이며, 캐릭터 크기·위치는 화면 폭에 비례해 맞춘다.
struct LoginSceneView<Sheet: View>: View {
    @ViewBuilder let sheet: () -> Sheet

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var introStart: Date?
    @State private var isIntroFinished = false
    @State private var bubbles: [TalkBubble] = []
    @State private var hops = Array(repeating: 0, count: LoginCast.members.count)

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

            // 캐릭터끼리의 앞뒤(zIndex)가 그래픽·시트까지 넘어가지 않도록 한 겹으로 묶는다
            ZStack(alignment: .topLeading) {
                ForEach(Array(LoginCast.members.enumerated()), id: \.offset) { index, member in
                    let frame = layout.frame(of: member)
                    let entrance = Timing.entrance(of: index).progress(at: elapsed)
                    LoginCharacterView(
                        member: member,
                        isIdle: isIntroFinished && !reduceMotion,
                        hop: hops[index]
                    )
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY + entranceOffset(entrance, height: frame.height, scale: layout.scale))
                    .opacity(entrance < 0.2 ? entrance / 0.2 : 1)
                    .zIndex(member.zIndex)
                }
            }
            .accessibilityHidden(true)

            // 가라앉는 그래픽이 캐릭터를 가리고 있다가 드러낸다. 그래서 캐릭터보다 위에 둔다
            centered(Assets.Login.pattern, width: layout.width, top: lerp(layout.patternTop, layout.patternRestTop, sink), in: layout)
            centered(Assets.Splash.tagline, width: lerp(layout.splashTaglineWidth, 150, brand), top: lerp(layout.splashTaglineTop, layout.brandTop, brand), in: layout)
            centered(Assets.Splash.logo, width: lerp(layout.splashLogoWidth, 116, brand), top: lerp(layout.splashLogoTop, layout.brandTop + 24, brand), in: layout)

            ForEach(bubbles) { bubble in
                let frame = layout.frame(of: LoginCast.members[bubble.member])
                let mirror = LoginCast.members[bubble.member].mirror
                TypingBubble(mirror: mirror, isStatic: reduceMotion)
                    .accessibilityHidden(true)
                    .offset(layout.bubbleOrigin(above: frame, mirror: mirror))
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.4, anchor: TypingBubble.anchor(mirror: mirror)).combined(with: .opacity),
                            removal: .scale(scale: 0.85, anchor: TypingBubble.anchor(mirror: mirror)).combined(with: .opacity)
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

    /// 시트 아래에서 반쯤 숨은 채 나타나 살짝 지나쳐 올라갔다가 제자리에 앉는다.
    private func entranceOffset(_ progress: Double, height: CGFloat, scale: CGFloat) -> CGFloat {
        let overshoot = -8 * scale
        switch progress {
        case ..<0.2: return lerp(height * 0.5, height * 0.38, progress / 0.2)
        case ..<0.75: return lerp(height * 0.38, overshoot, (progress - 0.2) / 0.55)
        default: return lerp(overshoot, 0, (progress - 0.75) / 0.25)
        }
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
        var removals: [Task<Void, Never>] = []
        defer { removals.forEach { $0.cancel() } }

        guard await pause(Timing.talkStart - Timing.introEnd) else { return }
        removals += say(life: 1.8, speaker: &speaker)
        guard await pause(1.3) else { return }
        removals += say(life: 1.7, speaker: &speaker)
        guard await pause(2.3) else { return }
        while true {
            removals += say(life: 2.0, speaker: &speaker)
            removals.removeAll { $0.isCancelled }
            guard await pause(2.8) else { return }
        }
    }

    /// 말풍선을 하나 띄우고, `life`초 뒤 지우는 작업을 돌려준다. 이미 둘이 떠 있으면 건너뛴다.
    private func say(life: Double, speaker: inout TalkSpeaker) -> [Task<Void, Never>] {
        guard bubbles.count < Timing.maxBubbles else { return [] }
        let bubble = speaker.next()
        withAnimation(.spring(duration: 0.32, bounce: 0.35)) { bubbles.append(bubble) }
        hops[bubble.member] += 1
        return [Task {
            guard (try? await Task.sleep(for: .seconds(life))) != nil else { return }
            withAnimation(.easeIn(duration: 0.22)) { bubbles.removeAll { $0.id == bubble.id } }
        }]
    }

    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil
    }
}

// MARK: - 출연진

/// 크기·높이·기울기를 일부러 들쭉날쭉하게 둔다. 작은 둘(파랑·갈색)은 보라 바로 뒤에 세워
/// 양옆 캐릭터에 얼굴이 가려지지 않게 한다. 바라보는 쪽(`mirror`)은 이웃끼리 번갈아 둔다.
/// 값은 393pt 폭 기준이고, `show`는 시트 위로 드러나는 몸 비율이다.
struct LoginCastMember {
    let body: ImageAsset
    let width: CGFloat
    let centerX: CGFloat
    let rotation: Double
    let zIndex: Double
    let show: CGFloat
    var mirror = false
}

enum LoginCast {
    static let members: [LoginCastMember] = [
        .init(body: Assets.Login.Character.bodyWhite, width: 150, centerX: 36, rotation: 5, zIndex: 2, show: 0.78, mirror: true),
        .init(body: Assets.Login.Character.bodyBlue, width: 128, centerX: 102, rotation: 2, zIndex: 3.5, show: 0.88),
        .init(body: Assets.Login.Character.bodyPurple, width: 176, centerX: 200, rotation: 2, zIndex: 4, show: 0.80, mirror: true),
        .init(body: Assets.Login.Character.bodyBrown, width: 128, centerX: 278, rotation: -5, zIndex: 3.6, show: 0.88),
        // 검정 그림은 한쪽 끝이 캔버스에 잘려 있어, 뒤집은 채로만 쓴다
        .init(body: Assets.Login.Character.bodyBlack, width: 156, centerX: 360, rotation: 6, zIndex: 3, show: 0.76, mirror: true)
    ]
    /// 몸통·눈 그림 캔버스(800×1260)의 세로/가로 비율
    static let aspect: CGFloat = 1260 / 800
}

/// 이웃끼리 연달아 말하지 않도록 정해둔 순서를 돈다.
private struct TalkSpeaker {
    private static let order = [2, 0, 4, 1, 3, 0, 2, 4, 1, 3]
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
    let patternTop: CGFloat
    let splashTaglineWidth: CGFloat
    let splashTaglineTop: CGFloat
    let splashLogoWidth: CGFloat
    let splashLogoTop: CGFloat

    init(size: CGSize, safeArea: EdgeInsets) {
        width = size.width
        height = size.height
        scale = size.width / 393
        safeTop = safeArea.top
        // 버튼 셋 + 둘러보기 + 위 여백 = 260. 홈 바가 있는 기기는 그만큼 띄우고, 없으면 16만 남긴다
        sheetBottomPadding = max(safeArea.bottom - 4, 16)
        sheetHeight = 260 + sheetBottomPadding

        // SplashView와 같은 계산이어야 스플래시에서 넘어오는 순간 그림이 튀지 않는다
        let frameHeight = size.width * 1200 / 555
        let frameTop = (size.height - frameHeight) / 2
        patternTop = frameTop + frameHeight * 0.1775
        splashTaglineWidth = size.width * 0.477477
        splashTaglineTop = frameTop + frameHeight * 0.429167
        splashLogoWidth = size.width * 0.488288
        splashLogoTop = frameTop + frameHeight * 0.465
    }

    var sheetTop: CGFloat { height - sheetHeight }

    /// 문구·OSS 글자 묶음의 위 끝. 시계 아래부터 가장 높은 캐릭터 머리까지 빈 곳의 가운데쯤에 둔다
    var brandTop: CGFloat {
        let headTop = LoginCast.members.map { frame(of: $0).minY }.min() ?? sheetTop
        return safeTop + max(headTop - safeTop - Self.brandHeight, 0) * 0.5
    }

    /// 문구(150pt 폭) + 간격 10 + OSS 글자(116pt 폭)의 높이
    private static let brandHeight: CGFloat = 66
    /// 그래픽이 시트 뒤로 완전히 들어간 자리
    var patternRestTop: CGFloat { sheetTop + 50 }

    func frame(of member: LoginCastMember) -> CGRect {
        let width = member.width * scale
        let height = width * LoginCast.aspect
        let bottom = sheetTop + height * (1 - member.show)
        return CGRect(x: member.centerX * scale - width / 2, y: bottom - height, width: width, height: height)
    }

    /// 머리 꼭대기 옆, 캐릭터가 바라보는 쪽에 띄운다. 화면 밖으로 나가지 않게 민다.
    func bubbleOrigin(above frame: CGRect, mirror: Bool) -> CGSize {
        let headX = frame.midX + (mirror ? -1 : 1) * frame.width * 0.1
        let headTop = frame.minY + frame.height * 0.02
        let size = TypingBubble.size
        let left = mirror ? headX - 4 - size.width : headX + 4
        return CGSize(
            width: min(max(left, 14), width - 14 - size.width),
            height: headTop - size.height - 12
        )
    }
}

// MARK: - 시간표

/// 시안(웹)의 시간표를 그대로 옮긴 값. 단위는 초.
private enum Timing {
    static let brand = Segment(delay: 0.45, duration: 0.76, curve: .init(0.6, 0, 0.2, 1))
    static let pattern = Segment(delay: 0.6, duration: 1.1, curve: .init(0.55, 0, 0.3, 1))
    static let sheet = Segment(delay: 0.95, duration: 0.64, curve: .init(0.2, 0.8, 0.2, 1))
    /// 보라 → 파랑 → 검정 → 흰 → 갈색 순으로, 박자를 살짝 엇갈려 올라온다
    private static let entranceOrder = [2, 1, 4, 0, 3]
    static let introEnd: Double = 2.1
    static let talkStart: Double = 3.4
    static let maxBubbles = 2

    static func entrance(of member: Int) -> Segment {
        let turn = entranceOrder.firstIndex(of: member) ?? 0
        let stagger = Double(turn) * 0.09 + (turn % 2 == 1 ? 0.04 : 0)
        return Segment(delay: 1.0 + stagger, duration: 0.72, curve: .init(0.3, 0.7, 0.4, 1))
    }

    struct Segment {
        let delay: Double
        let duration: Double
        let curve: CubicBezier

        func progress(at elapsed: TimeInterval) -> Double {
            curve.value(at: min(max((elapsed - delay) / duration, 0), 1))
        }
    }
}

/// CSS `cubic-bezier()`와 같은 곡선. 시간 비율에 대한 진행 정도를 돌려준다.
private struct CubicBezier {
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

private func lerp(_ from: CGFloat, _ to: CGFloat, _ progress: Double) -> CGFloat {
    from + (to - from) * progress
}

// MARK: - 캐릭터

/// 몸통과 눈 두 장을 겹쳐 그린다. 다 모인 뒤에는 숨쉬기와 눈 깜빡임을 잔잔하게 이어간다.
private struct LoginCharacterView: View {
    let member: LoginCastMember
    let isIdle: Bool
    let hop: Int

    @State private var isBreathing = false
    @State private var isBlinking = false

    var body: some View {
        ZStack {
            member.body.swiftUIImage
                .resizable()
            Assets.Login.Character.eyesMeh.swiftUIImage
                .resizable()
                // 눈 그림의 가운데(캔버스 43.5%, 44.3%)를 기준으로 감는다
                .scaleEffect(x: 1, y: isBlinking ? 0.08 : 1, anchor: UnitPoint(x: 0.435, y: 0.443))
        }
        .scaleEffect(x: isBreathing ? 1.006 : 1, y: isBreathing ? 1.018 : 1, anchor: .bottom)
        // 말할 때 한 번 들썩인다
        .keyframeAnimator(initialValue: 0, trigger: hop) { content, lift in
            content.offset(y: lift)
        } keyframes: { _ in
            CubicKeyframe(-4, duration: 0.19)
            CubicKeyframe(0, duration: 0.19)
        }
        .rotationEffect(.degrees(member.rotation), anchor: .bottom)
        .scaleEffect(x: member.mirror ? -1 : 1, y: 1)
        .task(id: isIdle) {
            // 다른 화면에 갔다 오면 task가 다시 돈다. 값을 되돌려 둬야 반복 움직임이 다시 걸리고, 감긴 눈도 뜬다
            isBreathing = false
            isBlinking = false
            guard isIdle else { return }
            withAnimation(
                .easeInOut(duration: .random(in: 2.4...3.0))
                .repeatForever(autoreverses: true)
                .delay(.random(in: 0...0.9))
            ) {
                isBreathing = true
            }
            try? await Task.sleep(for: .seconds(.random(in: 0.6...3.0)))
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.075)) { isBlinking = true }
                try? await Task.sleep(for: .seconds(0.075))
                withAnimation(.easeInOut(duration: 0.095)) { isBlinking = false }
                try? await Task.sleep(for: .seconds(.random(in: 2.6...5.6)))
            }
        }
    }
}

// MARK: - ··· 말풍선

/// 글 대신 입력 중 표시처럼 점 셋이 통통 튄다. 꼬리는 작은 원 두 개로, 캐릭터 머리 쪽에 붙는다.
private struct TypingBubble: View {
    let mirror: Bool
    let isStatic: Bool

    static let size = CGSize(width: 64, height: 38)

    /// 꼬리 끝에서 커지고 줄어들게 한다
    static func anchor(mirror: Bool) -> UnitPoint {
        UnitPoint(x: mirror ? 58 / size.width : 6 / size.width, y: 1.2)
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                dot(index)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background(
            Capsule()
                .fill(Color.primitive.bw.trueWhite)
                .shadow(color: Color.primitive.blue.b900.opacity(0.22), radius: 11, y: 8)
        )
        .overlay(alignment: mirror ? .bottomTrailing : .bottomLeading) {
            ZStack(alignment: mirror ? .bottomTrailing : .bottomLeading) {
                Circle()
                    .frame(width: 12, height: 12)
                    .offset(x: mirror ? -3 : 3, y: 6)
                Circle()
                    .frame(width: 6, height: 6)
                    .offset(x: mirror ? 3 : -3, y: 14)
            }
            .foregroundStyle(Color.primitive.bw.trueWhite)
        }
    }

    @ViewBuilder
    private func dot(_ index: Int) -> some View {
        let circle = Circle()
            .fill(Color.primitive.coolGray.cg400)
            .frame(width: 8, height: 8)
        if isStatic {
            circle
        } else {
            // 한 바퀴 1.1초 안에서 점마다 0.14초씩 늦게 튄다
            circle.keyframeAnimator(initialValue: DotPose(), repeating: true) { content, pose in
                content
                    .offset(y: pose.lift)
                    .opacity(pose.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.lift) {
                    LinearKeyframe(0, duration: 0.14 * Double(index))
                    LinearKeyframe(-3, duration: 0.33)
                    LinearKeyframe(0, duration: 0.33)
                    LinearKeyframe(0, duration: 0.44 - 0.14 * Double(index))
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.35, duration: 0.14 * Double(index))
                    LinearKeyframe(1, duration: 0.33)
                    LinearKeyframe(0.35, duration: 0.33)
                    LinearKeyframe(0.35, duration: 0.44 - 0.14 * Double(index))
                }
            }
        }
    }

    private struct DotPose {
        var lift: CGFloat = 0
        var opacity: Double = 0.35
    }
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
