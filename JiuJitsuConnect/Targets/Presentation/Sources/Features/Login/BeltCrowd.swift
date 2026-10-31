import SwiftUI
import DesignSystem

// MARK: - 몸통·눈

/// 도톰한 띠 몸통 그림 한 장의 치수. 단위는 그림 px이고, 눈은 밴드(검은 띠) 가운데에 얹는다.
struct BeltBody {
    let image: ImageAsset
    let size: CGSize
    let band: CGPoint
    let bandWidth: CGFloat
    /// 밴드가 기운 각도(도). 눈도 같은 각도로 기울인다
    let bandAngle: Double
    /// 머리 꼭대기의 가로 자리. 말풍선을 이 위에 띄운다
    let topX: CGFloat

    static let white = BeltBody(image: Assets.Login.Belt.bodyWhite, size: CGSize(width: 230, height: 605),
                                band: CGPoint(x: 99.5, y: 166.5), bandWidth: 184, bandAngle: 32.3, topX: 153)
    static let blue = BeltBody(image: Assets.Login.Belt.bodyBlue, size: CGSize(width: 214, height: 651),
                               band: CGPoint(x: 115.2, y: 157.3), bandWidth: 145.1, bandAngle: 11.8, topX: 141)
    static let purple = BeltBody(image: Assets.Login.Belt.bodyPurple, size: CGSize(width: 150, height: 654),
                                 band: CGPoint(x: 63, y: 159.5), bandWidth: 131, bandAngle: 0.7, topX: 75)
    static let brown = BeltBody(image: Assets.Login.Belt.bodyBrown, size: CGSize(width: 150, height: 653),
                                band: CGPoint(x: 63.4, y: 161.3), bandWidth: 131, bandAngle: 0.7, topX: 75.1)
    static let black = BeltBody(image: Assets.Login.Belt.bodyBlack, size: CGSize(width: 151, height: 653),
                                band: CGPoint(x: 74.3, y: 154.7), bandWidth: 131, bandAngle: 0.7, topX: 74.8)
}

/// 눈 한 쌍 그림. 눈 그림마다 키가 달라, 밴드를 알맞게 채우도록 폭·세로 늘림을 따로 둔다.
struct BeltEyes {
    let image: ImageAsset
    /// 그림의 세로/가로
    let aspect: CGFloat
    /// 밴드 폭 대비 눈 한 쌍의 폭
    let widthRatio: CGFloat
    var stretch: CGFloat = 1
    /// 밴드 폭 대비, 정가운데에서 비켜 두는 정도(화면 기준)
    var offset = CGSize.zero

    /// 흰 띠: 호기심 가득한 눈. 다른 눈보다 키가 커서 작게, 10시 방향으로 살짝 비켜 둔다
    static let curious = BeltEyes(image: Assets.Login.Belt.eyesCurious, aspect: 0.7414, widthRatio: 0.74, offset: CGSize(width: -0.12, height: -0.1))
    static let big = BeltEyes(image: Assets.Login.Belt.eyesBig, aspect: 0.5051, widthRatio: 1.07)
    static let lash = BeltEyes(image: Assets.Login.Belt.eyesLash, aspect: 0.7188, widthRatio: 0.9)
    /// 졸린 눈·화난 눈은 키가 낮아 세로로 늘려 밴드 위아래가 비지 않게 한다
    static let sleepy = BeltEyes(image: Assets.Login.Belt.eyesSleepy, aspect: 0.303, widthRatio: 1.12, stretch: 1.18)
    static let glare = BeltEyes(image: Assets.Login.Belt.eyesGlare, aspect: 0.362, widthRatio: 1.18, stretch: 1.4)
}

// MARK: - 출연진

/// 값은 393pt 폭 기준. `bandWidth`는 화면에 그릴 밴드 폭, `centerX`는 밴드 가운데, `visible`은 시트 위로 드러나는 높이다.
struct BeltMember {
    let body: BeltBody
    let eyes: BeltEyes
    let bandWidth: CGFloat
    let centerX: CGFloat
    let visible: CGFloat
    let tilt: Double
    let zIndex: Double
    /// 몸통을 좌우로 뒤집는다(휜 방향을 바꿀 때)
    var mirror = false
    /// 눈 그림을 좌우로 뒤집는다. 몸통 뒤집기와 별개로 바라보는 쪽을 정한다
    var eyesFlipped = false
    /// 말풍선을 머리 오른쪽에 띄운다
    var talksRight = false
    /// 등장 시작(초)과 속도 배율. 다섯이 거의 함께 출발하되 띠용 하는 순간이 조금씩 어긋난다
    let start: Double
    let speed: Double
}

/// 큰 셋(갈색·검정·보라) 사이에 작은 둘(흰·파랑)이 끼어 머리 높이가 높고 낮게 번갈아 선다.
enum BeltCast {
    static let members: [BeltMember] = [
        .init(body: .brown, eyes: .lash, bandWidth: 94, centerX: 28, visible: 300, tilt: 7, zIndex: 5,
              talksRight: true, start: 0.91, speed: 1.04),
        .init(body: .white, eyes: .curious, bandWidth: 88, centerX: 104, visible: 160, tilt: 0, zIndex: 8,
              eyesFlipped: true, start: 0.87, speed: 0.92),
        .init(body: .black, eyes: .sleepy, bandWidth: 96, centerX: 190, visible: 312, tilt: 1, zIndex: 5,
              eyesFlipped: true, start: 0.95, speed: 0.98),
        .init(body: .blue, eyes: .glare, bandWidth: 86, centerX: 270, visible: 170, tilt: 0, zIndex: 8,
              mirror: true, start: 0.93, speed: 0.94),
        .init(body: .purple, eyes: .big, bandWidth: 94, centerX: 356, visible: 288, tilt: -6, zIndex: 5,
              eyesFlipped: true, start: 0.98, speed: 1.06)
    ]
    /// 수다를 떠는 차례. 머리가 높은 갈색·검정·보라만 말한다
    static let speakers = [0, 2, 4]

    /// 화면 폭 393pt에서 정한 자리를 화면 폭에 비례해 놓는다. 몸통 아래쪽은 시트 밑으로 들어간다
    static func placement(of member: BeltMember, scale: CGFloat, screenWidth: CGFloat, sheetTop: CGFloat) -> BeltPlacement {
        let body = member.body
        let pixel = member.bandWidth * scale / body.bandWidth
        let size = CGSize(width: body.size.width * pixel, height: body.size.height * pixel)
        // 그림 아래 잘린 끝이 띠용 지나쳐 올라올 때도 시트 밑에 있도록 드러나는 높이를 줄인다
        let visible = min(member.visible * scale, (size.height - 12) / 1.12)
        let centerX = screenWidth / 2 + (member.centerX - 393 / 2) * scale
        let bandX = body.band.x * pixel
        let frame = CGRect(x: centerX - bandX, y: sheetTop - visible, width: size.width, height: size.height)

        // 머리 꼭대기: 시트 위 끝을 축으로 기울인 자리
        let headDX = (member.mirror ? -1 : 1) * (body.topX - body.band.x) * pixel
        let angle = member.tilt * .pi / 180
        let head = CGPoint(
            x: centerX + headDX * cos(angle) + visible * sin(angle),
            y: sheetTop + headDX * sin(angle) - visible * cos(angle)
        )
        return BeltPlacement(frame: frame, pixel: pixel, bandX: bandX, visible: visible, head: head)
    }
}

struct BeltPlacement {
    /// 기울이기 전 그림 전체 자리
    let frame: CGRect
    /// 그림 px → 화면 pt
    let pixel: CGFloat
    let bandX: CGFloat
    let visible: CGFloat
    let head: CGPoint
    /// 기울기·늘고 줄기의 중심. 밴드 아래, 시트 위 끝 높이
    var pivot: UnitPoint { UnitPoint(x: bandX / frame.width, y: visible / frame.height) }
}

// MARK: - 띠용 등장

/// 한 번에 쭉 올라와(중간에 멈추지 않음) 살짝 띠용 늘어났다가 한두 번 출렁이며 앉는다.
enum BeltRise {
    /// 속도 배율 1일 때 한 캐릭터가 올라와 앉기까지 걸리는 시간(초)
    static let duration = 0.988

    struct Pose {
        var lift: CGFloat = 0
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
    }

    /// 진행 비율, 내려간 정도(드러난 높이 대비, 시작은 시트 밑), 가로·세로 배율
    private struct Frame {
        let time: Double
        let drop: CGFloat
        let scaleX: CGFloat
        let scaleY: CGFloat
    }

    private static let frames: [Frame] = [
        .init(time: 0, drop: 1, scaleX: 1, scaleY: 1),
        .init(time: 0.55, drop: -0.06, scaleX: 0.955, scaleY: 1.055),
        .init(time: 0.72, drop: 0.012, scaleX: 1.03, scaleY: 0.97),
        .init(time: 0.86, drop: -0.008, scaleX: 0.99, scaleY: 1.01),
        .init(time: 1, drop: 0, scaleX: 1, scaleY: 1)
    ]
    /// 첫 구간은 빠르게 치고 올라가고, 띠용 지나친 뒤 내려앉는 구간은 부드럽게
    private static let curves = [CubicBezier(0.35, 0, 0.25, 1), CubicBezier(0.42, 0, 0.58, 1)]
    private static let overall = CubicBezier(0.42, 0, 0.58, 1)

    /// 등장 시작부터 `elapsed`초가 지났을 때의 모습. 아직 나오지 않았으면 nil
    static func pose(elapsed: TimeInterval, speed: Double, visible: CGFloat) -> Pose? {
        guard elapsed >= 0 else { return nil }
        let progress = overall.value(at: min(elapsed / (duration * speed), 1))
        guard let index = frames.indices.dropLast().last(where: { frames[$0].time <= progress }) else { return Pose() }
        let from = frames[index], to = frames[index + 1]
        var local = (progress - from.time) / (to.time - from.time)
        if index < curves.count { local = curves[index].value(at: local) }
        // 시작은 가림 경계(시트 위 끝 + 28)보다 아래. 시트가 덜 올라온 순간에도 머리 끝이 비치지 않는다
        let hidden = visible + 32
        let drop = { (value: CGFloat) in value == 1 ? hidden : value * visible }
        return Pose(
            lift: lerp(drop(from.drop), drop(to.drop), local),
            scaleX: lerp(from.scaleX, to.scaleX, local),
            scaleY: lerp(from.scaleY, to.scaleY, local)
        )
    }
}

// MARK: - 캐릭터

/// 몸통과 눈을 겹쳐 그린다. 다 모인 뒤에는 숨쉬기와 눈 깜빡임을 잔잔하게 이어간다.
struct BeltCharacterView: View {
    let member: BeltMember
    let placement: BeltPlacement
    let rise: BeltRise.Pose
    let isIdle: Bool
    let hop: Int

    @State private var isBreathing = false
    @State private var isBlinking = false

    var body: some View {
        let body = member.body
        let eyes = member.eyes
        let pixel = placement.pixel
        let size = placement.frame.size
        let eyeWidth = body.bandWidth * pixel * eyes.widthRatio
        let eyeHeight = eyeWidth * eyes.aspect * eyes.stretch
        // 비켜 두기는 화면 기준이라, 뒤집은 몸통 안에서는 반대로 민다
        let shiftX = eyes.offset.width * body.bandWidth * pixel * (member.mirror ? -1 : 1)
        let eyeCenter = CGPoint(x: placement.bandX + shiftX, y: body.band.y * pixel + eyes.offset.height * body.bandWidth * pixel)

        ZStack(alignment: .topLeading) {
            body.image.swiftUIImage
                .resizable()
                .frame(width: size.width, height: size.height)
            eyes.image.swiftUIImage
                .resizable()
                .frame(width: eyeWidth, height: eyeHeight)
                .scaleEffect(x: member.eyesFlipped ? -1 : 1, y: isBlinking ? 0.08 : 1)
                .rotationEffect(.degrees(body.bandAngle))
                .offset(x: eyeCenter.x - eyeWidth / 2, y: eyeCenter.y - eyeHeight / 2)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(x: member.mirror ? -1 : 1, y: 1, anchor: UnitPoint(x: placement.pivot.x, y: 0))
        .scaleEffect(x: isBreathing ? 1.004 : 1, y: isBreathing ? 1.006 : 1, anchor: placement.pivot)
        // 말할 때 한 번 들썩인다
        .keyframeAnimator(initialValue: 0, trigger: hop) { content, lift in
            content.offset(y: lift)
        } keyframes: { _ in
            CubicKeyframe(-4, duration: 0.19)
            CubicKeyframe(0, duration: 0.19)
        }
        .scaleEffect(x: rise.scaleX, y: rise.scaleY, anchor: placement.pivot)
        .offset(y: rise.lift)
        .rotationEffect(.degrees(member.tilt), anchor: placement.pivot)
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

/// 살짝 비대칭인 말랑한 캡슐에 꼬리 동그라미 둘. 브랜드 파랑 점 셋이 크기·높이를 조금씩 달리해 통통 튄다.
/// 기본 모양은 꼬리가 왼쪽 아래(캐릭터 오른쪽에 뜰 때)이고, 반대쪽은 좌우로 뒤집는다.
struct PuffBubble: View {
    let pointsRight: Bool
    let isStatic: Bool

    /// 그림 기준 크기(70×42)에서 줄인 배율
    private static let scale: CGFloat = 0.68
    static let size = CGSize(width: 70 * scale, height: 42 * scale)
    /// 꼬리 끝. 몸통 왼쪽 위 기준이고, 몸통 밖(왼쪽 아래)에 있다
    static let tip = CGPoint(x: -1 * scale, y: 58 * scale)

    private static let dots: [(size: CGFloat, lift: CGFloat)] = [(9, 1), (10.5, -1), (8.5, 0.5)]

    /// 꼬리 끝에서 커지고 줄어든다
    static func anchor(pointsRight: Bool) -> UnitPoint {
        UnitPoint(x: (pointsRight ? tip.x : size.width - tip.x) / size.width, y: tip.y / size.height)
    }

    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            PuffShape()
                .fill(Color.primitive.bw.trueWhite)
                .frame(width: Self.size.width, height: Self.size.height)
                .scaleEffect(x: pointsRight ? 1 : -1, y: 1)
                .shadow(color: Color.primitive.blue.b900.opacity(0.09), radius: 4, y: 4.8)
            HStack(spacing: 3) {
                ForEach(Self.dots.indices, id: \.self) { index in
                    dot(index)
                }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .modifier(BubbleEntrance(anchor: Self.anchor(pointsRight: pointsRight), isStatic: isStatic, trigger: hasAppeared))
        .onAppear { hasAppeared = true }
    }

    @ViewBuilder
    private func dot(_ index: Int) -> some View {
        let spec = Self.dots[index]
        let circle = Circle()
            .fill(Color.primitive.blue.b500p)
            .frame(width: spec.size * Self.scale, height: spec.size * Self.scale)
            .offset(y: spec.lift * Self.scale)
        if isStatic {
            circle
        } else {
            // 하나씩 퐁퐁 생긴 뒤, 0.14초씩 늦게 물결처럼 통통 튄다
            circle
                .keyframeAnimator(initialValue: CGFloat(0), trigger: hasAppeared) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    LinearKeyframe(0, duration: 0.2 + 0.09 * Double(index))
                    CubicKeyframe(1.3, duration: 0.16)
                    CubicKeyframe(1, duration: 0.1)
                }
                .keyframeAnimator(initialValue: DotPose(), repeating: true) { content, pose in
                    content.offset(y: pose.lift).opacity(pose.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.lift) {
                        LinearKeyframe(0, duration: 0.14 * Double(index))
                        CubicKeyframe(-3.5, duration: 0.26)
                        CubicKeyframe(0, duration: 0.26)
                        LinearKeyframe(0, duration: 0.53 - 0.14 * Double(index))
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0.45, duration: 0.14 * Double(index))
                        CubicKeyframe(1, duration: 0.26)
                        CubicKeyframe(0.45, duration: 0.26)
                        LinearKeyframe(0.45, duration: 0.53 - 0.14 * Double(index))
                    }
                }
        }
    }

    private struct DotPose {
        var lift: CGFloat = 0
        var opacity: Double = 0.45
    }
}

/// 70×42 그림 기준 좌표로 그린 몸통 + 꼬리 동그라미 둘. 꼬리는 그림 밖(왼쪽 아래)으로 나간다.
/// 높이에 맞춰 키우고, 그림보다 넓으면 가운데만 늘려 양 끝 둥근 모양은 그대로 둔다(인사 장면의 글 말풍선).
struct PuffShape: Shape {
    /// 꼬리를 따로 다는 글 말풍선은 끈다
    var hasTail = true

    func path(in rect: CGRect) -> Path {
        let scale = rect.height / 42
        let stretch = max(rect.width / scale - 70, 0)
        let point = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: rect.minX + (x < 35 ? x : x + stretch) * scale, y: rect.minY + y * scale)
        }
        var path = Path()
        path.move(to: point(22, 1.5))
        path.addCurve(to: point(50, 1.5), control1: point(30, 0), control2: point(42, 0))
        path.addCurve(to: point(69.5, 21.5), control1: point(62, 3.5), control2: point(70, 10))
        path.addCurve(to: point(48, 41.5), control1: point(69, 33), control2: point(61, 40.5))
        path.addCurve(to: point(21, 41), control1: point(39, 42.3), control2: point(30, 42.3))
        path.addCurve(to: point(1, 21), control1: point(9, 39.5), control2: point(1, 33))
        path.addCurve(to: point(22, 1.5), control1: point(1, 9.5), control2: point(10, 3))
        path.closeSubpath()
        guard hasTail else { return path }
        for (x, y, radius) in [(CGFloat(7.5), CGFloat(46.5), CGFloat(5.6)), (0.5, 55, 3)] {
            let center = point(x, y)
            path.addEllipse(in: CGRect(x: center.x - radius * scale, y: center.y - radius * scale, width: radius * 2 * scale, height: radius * 2 * scale))
        }
        return path
    }
}

/// 꼬리 쪽에서 쭉 늘며 튀어나왔다 눌리고 자리 잡은 뒤, 살짝 둥실 떠 있는다.
struct BubbleEntrance: ViewModifier {
    let anchor: UnitPoint
    let isStatic: Bool
    /// 나타날 때 한 번 바뀌어 튀어나오는 움직임을 재생한다
    let trigger: Bool

    func body(content: Content) -> some View {
        if isStatic {
            content
        } else {
            content
                .keyframeAnimator(initialValue: BubbleFloat(), repeating: true) { content, pose in
                    content.offset(y: pose.lift)
                } keyframes: { _ in
                    KeyframeTrack(\.lift) {
                        CubicKeyframe(-2, duration: 0.8)
                        CubicKeyframe(0, duration: 0.8)
                    }
                }
                .keyframeAnimator(initialValue: BubblePop(), trigger: trigger) { content, pose in
                    content
                        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: anchor)
                        .rotationEffect(.degrees(pose.rotation), anchor: anchor)
                        .opacity(pose.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scaleX) {
                        CubicKeyframe(1.1, duration: 0.2)
                        CubicKeyframe(0.95, duration: 0.12)
                        CubicKeyframe(1, duration: 0.14)
                    }
                    KeyframeTrack(\.scaleY) {
                        CubicKeyframe(0.9, duration: 0.2)
                        CubicKeyframe(1.06, duration: 0.12)
                        CubicKeyframe(1, duration: 0.14)
                    }
                    KeyframeTrack(\.rotation) {
                        CubicKeyframe(4, duration: 0.2)
                        CubicKeyframe(-2, duration: 0.12)
                        CubicKeyframe(0, duration: 0.14)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(1, duration: 0.2)
                        LinearKeyframe(1, duration: 0.26)
                    }
                }
        }
    }

    private struct BubbleFloat {
        var lift: CGFloat = 0
    }

    private struct BubblePop {
        var scaleX: CGFloat = 0.2
        var scaleY: CGFloat = 0.3
        var rotation: Double = -10
        var opacity: Double = 0
    }
}

/// 사라질 때 위로 살짝 떠오르며 작아진다. 말풍선 제거 전환으로 쓴다
struct BubbleLeave: ViewModifier {
    let progress: CGFloat
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 - 0.45 * progress, anchor: anchor)
            .rotationEffect(.degrees(6 * progress), anchor: anchor)
            .offset(y: -8 * progress)
            .opacity(1 - progress)
    }
}
