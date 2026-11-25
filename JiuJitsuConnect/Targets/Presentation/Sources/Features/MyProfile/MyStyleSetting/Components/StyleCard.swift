//
//  StyleCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem
import Domain

/// 고르기 화면 큰 카드(앞면 · 뒷면 · 조명 · 빈 카드)가 함께 쓰는 모서리
enum StyleCardMetrics {
    static let cornerRadius: CGFloat = 56
}

/// 스타일 카드 앞면 컴포넌트
///
/// 메인 화면에 표시되는 큰 스타일 카드의 앞면입니다.
/// 기술마다 다른 바탕 그래픽(`StyleCardBackdrop`) 위에 내 띠 캐릭터가 그 기술을 거는 그림, 타이틀, 설명을 둡니다(#495).
struct StyleCard: View {
    let style: any StyleSelectable
    let isSelected: Bool
    /// 캐릭터가 맬 띠. 띠가 없으면 흰띠로 그린다.
    var beltRank: BeltRank? = nil
    /// 바탕 시안. 앱은 `StyleCardBackdrop.current`를 쓰고, 미리보기에서만 바꿔 본다.
    var backdrop: StyleCardBackdrop = .current

    // MARK: - Metrics

    private enum Metrics {
        // 캐릭터 그림 — 아래 글자 영역(타이틀·설명)을 뺀 높이를 채운다
        static let poseSize: CGFloat = 216
    }

    // MARK: - Body

    var body: some View {
        let belt = beltRank ?? .white
        let tone = belt.styleCardTone
        let poseImage = style.poseImage(belt: belt).swiftUIImage
        // 어두운 바탕이면 흰 글자, 밝은 바탕이면 진한 띠 색 글자
        let titleColor = backdrop.isDark ? Color.white : tone.title
        let textColor = backdrop.isDark ? Color.white.opacity(0.84) : tone.text

        VStack(alignment: .center, spacing: 0) {
            Spacer()

            // 내 띠 캐릭터가 그 기술을 거는 그림 — 어두운 바탕에선 그림자로 바탕과 떼어 놓는다
            poseImage
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.poseSize, height: Metrics.poseSize)
                .shadow(color: .black.opacity(backdrop.isDark ? 0.3 : 0), radius: 4, y: 6)

            // 풀 타이틀
            // 한 줄에 다 들어가게 — 긴 이름(이스케이프 디펜스)만 글자를 줄이고 나머지는 40 그대로
            Text(style.fullTitle.replacingOccurrences(of: "\n", with: " "))
                .font(.cookieRun.custom(weight: .black, size: 40))
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .padding(.bottom, 20)

            // 카드 설명
            Text(style.cardDescription)
                .font(.pretendard.custom(weight: .medium, size: 16))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                // 세 줄 안에 다 들어가게 — 한 줄이 넘치는 설명(하체 관절기)만 글자를 조금 줄인다
                .minimumScaleFactor(0.9)
                .frame(height: 72)
                .padding(.horizontal, 25)
                .padding(.bottom, 32)
        }
        .frame(width: 262, height: 394)
        .background {
            StyleCardBackdropView(
                backdrop: backdrop, impact: style.impact,
                colors: StyleCardBackdropColors(belt: belt), poseImage: poseImage
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: StyleCardMetrics.cornerRadius))
    }
}

// MARK: - 띠 캐릭터 기술 그림

private enum StylePose {
    case top, guardPosition, escape, armLock, legLock, guardPass, choke, sweep, takedown
}

extension StyleSelectable {
    private var stylePose: StylePose? {
        switch self {
        case let position as PositionType:
            switch position {
            case .top: return .top
            case .guard: return .guardPosition
            }
        case let submission as SubmissionType:
            switch submission {
            case .armLocks: return .armLock
            case .legLocks: return .legLock
            case .chokes: return .choke
            }
        case let technique as TechniqueType:
            switch technique {
            case .escapes: return .escape
            case .guardPasses: return .guardPass
            case .sweeps: return .sweep
            case .takedowns: return .takedown
            }
        default:
            return nil
        }
    }

    /// 그 띠를 맨 캐릭터가 이 기술을 거는 그림(상대는 회색). 모르는 스타일이면 아이콘.
    func poseImage(belt: BeltRank) -> ImageAsset {
        stylePose?.beltImages.image(for: belt) ?? iconImage
    }
}

/// 띠마다 칠해 둔 같은 장면 그림 한 벌
private struct BeltPoseImages {
    let white, blue, purple, brown, black: ImageAsset

    func image(for belt: BeltRank) -> ImageAsset {
        switch belt {
        case .white: return white
        case .blue: return blue
        case .purple: return purple
        case .brown: return brown
        case .black: return black
        }
    }
}

private extension StylePose {
    var beltImages: BeltPoseImages {
        typealias Pose = Assets.MyProfile.Pose
        switch self {
        case .top:
            return BeltPoseImages(
                white: Pose.whiteTop, blue: Pose.blueTop, purple: Pose.purpleTop,
                brown: Pose.brownTop, black: Pose.blackTop
            )
        case .guardPosition:
            return BeltPoseImages(
                white: Pose.whiteGuard, blue: Pose.blueGuard, purple: Pose.purpleGuard,
                brown: Pose.brownGuard, black: Pose.blackGuard
            )
        case .escape:
            return BeltPoseImages(
                white: Pose.whiteEscape, blue: Pose.blueEscape, purple: Pose.purpleEscape,
                brown: Pose.brownEscape, black: Pose.blackEscape
            )
        case .armLock:
            return BeltPoseImages(
                white: Pose.whiteArmLock, blue: Pose.blueArmLock, purple: Pose.purpleArmLock,
                brown: Pose.brownArmLock, black: Pose.blackArmLock
            )
        case .legLock:
            return BeltPoseImages(
                white: Pose.whiteLegLock, blue: Pose.blueLegLock, purple: Pose.purpleLegLock,
                brown: Pose.brownLegLock, black: Pose.blackLegLock
            )
        case .guardPass:
            return BeltPoseImages(
                white: Pose.whiteGuardPass, blue: Pose.blueGuardPass, purple: Pose.purpleGuardPass,
                brown: Pose.brownGuardPass, black: Pose.blackGuardPass
            )
        case .choke:
            return BeltPoseImages(
                white: Pose.whiteChoke, blue: Pose.blueChoke, purple: Pose.purpleChoke,
                brown: Pose.brownChoke, black: Pose.blackChoke
            )
        case .sweep:
            return BeltPoseImages(
                white: Pose.whiteSweep, blue: Pose.blueSweep, purple: Pose.purpleSweep,
                brown: Pose.brownSweep, black: Pose.blackSweep
            )
        case .takedown:
            return BeltPoseImages(
                white: Pose.whiteTakedown, blue: Pose.blueTakedown, purple: Pose.purpleTakedown,
                brown: Pose.brownTakedown, black: Pose.blackTakedown
            )
        }
    }
}

// MARK: - Preview

#Preview("StyleCard - Position Top") {
    StyleCard(
        style: PositionType.top,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Position Guard") {
    StyleCard(
        style: PositionType.guard,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Submission ArmLocks") {
    StyleCard(
        style: SubmissionType.armLocks,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Submission Chokes") {
    StyleCard(
        style: SubmissionType.chokes,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Submission LegLocks") {
    StyleCard(
        style: SubmissionType.legLocks,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique Takedowns") {
    StyleCard(
        style: TechniqueType.takedowns,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique Sweeps") {
    StyleCard(
        style: TechniqueType.sweeps,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique Escapes") {
    StyleCard(
        style: TechniqueType.escapes,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Technique GuardPasses") {
    StyleCard(
        style: TechniqueType.guardPasses,
        isSelected: true
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("StyleCard - Comparison") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Position Styles")
                .font(.pretendard.display1)
            
            HStack(spacing: 20) {
                StyleCard(style: PositionType.top, isSelected: true)
                StyleCard(style: PositionType.guard, isSelected: true)
            }
            
            Text("Submission Styles")
                .font(.pretendard.display1)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                StyleCard(style: SubmissionType.armLocks, isSelected: true)
                StyleCard(style: SubmissionType.chokes, isSelected: true)
                StyleCard(style: SubmissionType.legLocks, isSelected: true)
            }
            
            Text("Technique Styles")
                .font(.pretendard.display1)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                StyleCard(style: TechniqueType.takedowns, isSelected: true)
                StyleCard(style: TechniqueType.sweeps, isSelected: true)
                StyleCard(style: TechniqueType.escapes, isSelected: true)
                StyleCard(style: TechniqueType.guardPasses, isSelected: true)
            }
        }
        .padding()
    }
    .background(Color.component.background.default)
}

#Preview("StyleCard - 바탕 시안 × 기술 (#495)") {
    let styles: [any StyleSelectable] = [
        PositionType.top, PositionType.guard,
        SubmissionType.armLocks, SubmissionType.chokes, SubmissionType.legLocks,
        TechniqueType.takedowns, TechniqueType.sweeps, TechniqueType.escapes, TechniqueType.guardPasses
    ]
    ScrollView([.vertical, .horizontal]) {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(StyleCardBackdrop.allCases) { backdrop in
                Text(backdrop.title)
                    .font(.pretendard.title2)
                HStack(spacing: 16) {
                    ForEach(styles.indices, id: \.self) { index in
                        StyleCard(style: styles[index], isSelected: true, beltRank: .purple, backdrop: backdrop)
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.component.background.default)
}
