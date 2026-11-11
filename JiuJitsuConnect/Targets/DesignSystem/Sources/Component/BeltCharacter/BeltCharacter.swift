import SwiftUI

// 흰 띠 캐릭터 부품: 굽은 몸(BeltPose)과 표정(BeltFace)을 골라 BeltCharacter 로 조합한다.
// 몸 그림마다 검은 띠(얼굴) 자리를 재 둔 값으로 표정을 얹는다. 값은 design/belt-poses/export-ds.py 가 만든다.

/// 몸 그림 안에서 검은 띠(얼굴)가 있는 자리
public struct BeltFaceAnchor: Sendable {
    /// 그림 가로/세로
    public let aspect: CGFloat
    /// 띠 가운데(그림 가로·세로 비율)
    public let x: CGFloat
    public let y: CGFloat
    /// 띠 폭(그림 가로 비율)
    public let width: CGFloat
    /// 띠 기울기(도)
    public let angle: Double
    /// 몸이 기운 쪽: 1 오른쪽, -1 왼쪽
    public let lean: CGFloat
}

public enum BeltPose: String, CaseIterable, Sendable {
    /// 반가움 — 몸 전체가 나를 향해 다가옴
    case greet
    /// 깜짝 — 뒤로 젖히며 물러남
    case startle
    /// 궁금함 — 앞으로·옆으로 내밀어 들여다봄
    case leanIn = "lean-in"
    /// 부끄러움 — 뒤로 물러나며 고개를 돌림
    case shyBack = "shy-back"
    /// 시무룩 — 옆으로 꺾여 고개가 처짐
    case sulk
    /// 뽐냄 — 허리를 내밀고 머리는 뒤로 멀리
    case proudFar = "proud-far"
    /// 인사 — 나를 향해 꾸벅 숙임
    case hello
    /// 뒤돌아봄 — 몸은 오른쪽, 고개는 어깨 너머
    case lookBack = "look-back"
    /// 속닥속닥 — 옆으로 기울어 고개를 숙임
    case whisper
    /// 기쁨(작게) — 오른쪽으로 살짝 기울고 고개를 듦
    case happyLean = "happy-lean"
    /// 부끄러움(작게) — 왼쪽으로 기울어 고개를 돌림
    case shyLean = "shy-lean"
    /// 궁금함(작게) — 앞으로 조금 기울고 갸웃
    case tilt
    /// 놀람(작게) — 머리만 살짝 뒤로
    case flinch
    /// 뽐냄(작게) — 곧게 서서 살짝 뒤로
    case standTall = "stand-tall"
    /// 신남(작게) — 작게 두 번 휨
    case wiggleSmall = "wiggle-small"
    /// 기쁨·신남 — 부드러운 S자
    case wiggle
    /// 궁금함 — 앞으로 쭉 내밀어 들여다봄
    case peek
    /// 지침 — 고개가 아래로 꺾인 갈고리
    case droop
    /// 부끄러움 — ㄱ자로 고개를 옆으로
    case shyTurn = "shy-turn"
    /// 놀람 — 뻣뻣하게 곧은 채 뒤로 기움
    case stiffBack = "stiff-back"
    /// 인사·관심 — 윗부분만 앞으로 숙임
    case nod
    /// 다정함 — 크게 앞으로 둥글게 굽힘
    case bow
    /// 슬픔 — 시든 꽃처럼 축 늘어짐
    case wilt
    /// 들썩들썩 — 큰 물결로 흔듦
    case wave
    /// 흥분 — 뾰족한 지그재그
    case zigzag

    public var image: ImageAsset {
        switch self {
        case .greet: Assets.Character.Belt.Pose.poseGreet
        case .startle: Assets.Character.Belt.Pose.poseStartle
        case .leanIn: Assets.Character.Belt.Pose.poseLeanIn
        case .shyBack: Assets.Character.Belt.Pose.poseShyBack
        case .sulk: Assets.Character.Belt.Pose.poseSulk
        case .proudFar: Assets.Character.Belt.Pose.poseProudFar
        case .hello: Assets.Character.Belt.Pose.poseHello
        case .lookBack: Assets.Character.Belt.Pose.poseLookBack
        case .whisper: Assets.Character.Belt.Pose.poseWhisper
        case .happyLean: Assets.Character.Belt.Pose.poseHappyLean
        case .shyLean: Assets.Character.Belt.Pose.poseShyLean
        case .tilt: Assets.Character.Belt.Pose.poseTilt
        case .flinch: Assets.Character.Belt.Pose.poseFlinch
        case .standTall: Assets.Character.Belt.Pose.poseStandTall
        case .wiggleSmall: Assets.Character.Belt.Pose.poseWiggleSmall
        case .wiggle: Assets.Character.Belt.Pose.poseWiggle
        case .peek: Assets.Character.Belt.Pose.posePeek
        case .droop: Assets.Character.Belt.Pose.poseDroop
        case .shyTurn: Assets.Character.Belt.Pose.poseShyTurn
        case .stiffBack: Assets.Character.Belt.Pose.poseStiffBack
        case .nod: Assets.Character.Belt.Pose.poseNod
        case .bow: Assets.Character.Belt.Pose.poseBow
        case .wilt: Assets.Character.Belt.Pose.poseWilt
        case .wave: Assets.Character.Belt.Pose.poseWave
        case .zigzag: Assets.Character.Belt.Pose.poseZigzag
        }
    }

    /// 그림 가로/세로
    public var aspect: CGFloat { anchor.aspect }

    /// 검은 띠(얼굴) 자리
    public var anchor: BeltFaceAnchor {
        switch self {
        case .greet: BeltFaceAnchor(aspect: 0.5141, x: 0.4941, y: 0.3165, width: 0.5572, angle: 30.0, lean: 1)
        case .startle: BeltFaceAnchor(aspect: 0.5186, x: 0.7027, y: 0.1489, width: 0.3857, angle: 30.0, lean: 1)
        case .leanIn: BeltFaceAnchor(aspect: 0.6138, x: 0.6082, y: 0.2371, width: 0.3821, angle: 30.0, lean: 1)
        case .shyBack: BeltFaceAnchor(aspect: 0.3567, x: 0.4869, y: 0.1666, width: 0.4882, angle: -21.8, lean: 1)
        case .sulk: BeltFaceAnchor(aspect: 0.5628, x: 0.5504, y: 0.1431, width: 0.4138, angle: 30.0, lean: 1)
        case .proudFar: BeltFaceAnchor(aspect: 0.4233, x: 0.7499, y: 0.1260, width: 0.5693, angle: 22.3, lean: 1)
        case .hello: BeltFaceAnchor(aspect: 0.6692, x: 0.6339, y: 0.3087, width: 0.4749, angle: -30.0, lean: 1)
        case .lookBack: BeltFaceAnchor(aspect: 0.7385, x: 0.5088, y: 0.1521, width: 0.3157, angle: -30.0, lean: 1)
        case .whisper: BeltFaceAnchor(aspect: 0.7747, x: 0.2994, y: 0.2043, width: 0.3288, angle: 30.0, lean: -1)
        case .happyLean: BeltFaceAnchor(aspect: 0.3869, x: 0.6864, y: 0.1426, width: 0.4610, angle: 30.0, lean: 1)
        case .shyLean: BeltFaceAnchor(aspect: 0.3869, x: 0.3085, y: 0.1426, width: 0.4610, angle: -30.0, lean: -1)
        case .tilt: BeltFaceAnchor(aspect: 0.3655, x: 0.5611, y: 0.2022, width: 0.5451, angle: 29.0, lean: 1)
        case .flinch: BeltFaceAnchor(aspect: 0.2391, x: 0.5625, y: 0.1686, width: 0.7432, angle: 13.9, lean: 1)
        case .standTall: BeltFaceAnchor(aspect: 0.2446, x: 0.3906, y: 0.1794, width: 0.8430, angle: 3.3, lean: -1)
        case .wiggleSmall: BeltFaceAnchor(aspect: 0.2327, x: 0.4192, y: 0.1793, width: 0.8854, angle: 2.6, lean: -1)
        case .wiggle: BeltFaceAnchor(aspect: 0.3560, x: 0.4887, y: 0.1675, width: 0.4836, angle: -22.7, lean: 1)
        case .peek: BeltFaceAnchor(aspect: 0.5764, x: 0.6533, y: 0.1607, width: 0.3486, angle: 30.0, lean: 1)
        case .droop: BeltFaceAnchor(aspect: 0.5685, x: 0.7783, y: 0.3286, width: 0.3700, angle: -13.2, lean: 1)
        case .shyTurn: BeltFaceAnchor(aspect: 0.6044, x: 0.6811, y: 0.1326, width: 0.3652, angle: 30.0, lean: 1)
        case .stiffBack: BeltFaceAnchor(aspect: 0.4004, x: 0.7238, y: 0.1743, width: 0.4417, angle: 16.2, lean: 1)
        case .nod: BeltFaceAnchor(aspect: 0.5186, x: 0.6449, y: 0.1839, width: 0.3565, angle: 30.0, lean: 1)
        case .bow: BeltFaceAnchor(aspect: 0.4990, x: 0.7000, y: 0.1278, width: 0.3248, angle: 30.0, lean: 1)
        case .wilt: BeltFaceAnchor(aspect: 0.4215, x: 0.7449, y: 0.3264, width: 0.4322, angle: -9.1, lean: 1)
        case .wave: BeltFaceAnchor(aspect: 0.5827, x: 0.7546, y: 0.1192, width: 0.2210, angle: -23.3, lean: 1)
        case .zigzag: BeltFaceAnchor(aspect: 0.4167, x: 0.5121, y: 0.1837, width: 0.4140, angle: -30.0, lean: 1)
        }
    }
}

public enum BeltFace: String, CaseIterable, Sendable {
    /// 웃는 반달
    case happy
    /// 질끈 ><
    case squint
    /// 깜짝 점 눈동자
    case shock
    /// 겁먹음
    case scared
    /// 화남
    case angry
    /// 노려봄
    case glare
    /// 시무룩
    case sad
    /// 울먹
    case teary
    /// 심드렁
    case bored
    /// 의심 게슴츠레
    case sus
    /// 갸웃
    case puzzled
    /// 뽐냄 한쪽 눈썹
    case smug
    /// 반짝 신남
    case star
    /// 반함
    case heart
    /// 어지러움
    case dizzy
    /// 평온 감은 눈
    case calm
    /// 찡긋
    case wink
    /// 흘깃
    case side
    /// 부끄러움
    case shy
    /// 집중 결의
    case focus
    /// 걱정
    case worry
    /// 아야 한쪽 질끈
    case pain
    /// 꾸벅 졸림
    case sleepy
    /// 감동 글썽
    case moved
    /// 멍 몰린 눈
    case cross
    /// 진땀 머쓱
    case sweat

    public var image: ImageAsset {
        switch self {
        case .happy: Assets.Character.Belt.Face.faceHappy
        case .squint: Assets.Character.Belt.Face.faceSquint
        case .shock: Assets.Character.Belt.Face.faceShock
        case .scared: Assets.Character.Belt.Face.faceScared
        case .angry: Assets.Character.Belt.Face.faceAngry
        case .glare: Assets.Character.Belt.Face.faceGlare
        case .sad: Assets.Character.Belt.Face.faceSad
        case .teary: Assets.Character.Belt.Face.faceTeary
        case .bored: Assets.Character.Belt.Face.faceBored
        case .sus: Assets.Character.Belt.Face.faceSus
        case .puzzled: Assets.Character.Belt.Face.facePuzzled
        case .smug: Assets.Character.Belt.Face.faceSmug
        case .star: Assets.Character.Belt.Face.faceStar
        case .heart: Assets.Character.Belt.Face.faceHeart
        case .dizzy: Assets.Character.Belt.Face.faceDizzy
        case .calm: Assets.Character.Belt.Face.faceCalm
        case .wink: Assets.Character.Belt.Face.faceWink
        case .side: Assets.Character.Belt.Face.faceSide
        case .shy: Assets.Character.Belt.Face.faceShy
        case .focus: Assets.Character.Belt.Face.faceFocus
        case .worry: Assets.Character.Belt.Face.faceWorry
        case .pain: Assets.Character.Belt.Face.facePain
        case .sleepy: Assets.Character.Belt.Face.faceSleepy
        case .moved: Assets.Character.Belt.Face.faceMoved
        case .cross: Assets.Character.Belt.Face.faceCross
        case .sweat: Assets.Character.Belt.Face.faceSweat
        }
    }

    /// 그림 세로/가로
    public var aspect: CGFloat {
        switch self {
        case .happy: 0.1866
        case .squint: 0.3475
        case .shock: 0.6273
        case .scared: 0.5808
        case .angry: 0.5831
        case .glare: 0.4808
        case .sad: 0.6178
        case .teary: 0.6430
        case .bored: 0.2428
        case .sus: 0.1875
        case .puzzled: 0.6522
        case .smug: 0.6331
        case .star: 0.6250
        case .heart: 0.5131
        case .dizzy: 0.4774
        case .calm: 0.3358
        case .wink: 0.5922
        case .side: 0.4760
        case .shy: 0.6048
        case .focus: 0.5385
        case .worry: 0.6178
        case .pain: 0.5707
        case .sleepy: 0.2024
        case .moved: 0.6273
        case .cross: 0.4712
        case .sweat: 0.5396
        }
    }
}

/// 굽은 몸 위 검은 띠 자리에 표정을 얹는다. 표정 눈동자는 몸이 기운 쪽을 보게 좌우를 뒤집는다.
public struct BeltCharacter: View {
    let pose: BeltPose
    let face: BeltFace

    /// 띠 폭 대비 표정 폭
    static let faceWidthRatio: CGFloat = 1.1

    public init(pose: BeltPose, face: BeltFace) {
        self.pose = pose
        self.face = face
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let anchor = pose.anchor
            let faceWidth = size.width * anchor.width * Self.faceWidthRatio
            ZStack(alignment: .topLeading) {
                pose.image.swiftUIImage
                    .resizable()
                    .frame(width: size.width, height: size.height)
                face.image.swiftUIImage
                    .resizable()
                    .frame(width: faceWidth, height: faceWidth * face.aspect)
                    .scaleEffect(x: anchor.lean, y: 1)
                    .rotationEffect(.degrees(anchor.angle))
                    .position(x: size.width * anchor.x, y: size.height * anchor.y)
            }
        }
        .aspectRatio(pose.aspect, contentMode: .fit)
    }
}
