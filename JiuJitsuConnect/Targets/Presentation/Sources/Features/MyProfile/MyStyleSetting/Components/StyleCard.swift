//
//  StyleCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem
import Domain

/// 스타일 카드 앞면 컴포넌트
///
/// 메인 화면에 표시되는 큰 스타일 카드의 앞면입니다.
/// 배경 이미지, 내 띠 캐릭터가 그 기술을 거는 그림, 타이틀, 설명을 포함합니다.
struct StyleCard: View {
    let style: any StyleSelectable
    let isSelected: Bool
    /// 캐릭터가 맬 띠. 띠가 없으면 흰띠로 그린다.
    var beltRank: BeltRank? = nil
    /// 조명이 켜졌는지 — 켜지면 카드 윗부분이 빛을 받아 밝아진다. 캐릭터와 글자는 그대로.
    var isLit = false
    
    // MARK: - Metrics

    private enum Metrics {
        // 배경 이미지 frame과 외곽 frame 2곳에서 공유
        static let cardWidth: CGFloat = 262
        static let cardHeight: CGFloat = 394
        // 캐릭터 그림 — 아래 글자 영역(타이틀·설명)을 뺀 높이를 채운다
        static let poseSize: CGFloat = 216
    }

    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .center) {
            // 배경 이미지 - 카드 크기에 딱 맞게 (비율 무시하고 꽉 채움)
            style.backgroundImage.swiftUIImage
                .resizable()
                .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)

            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.14), location: 0),
                    .init(color: .white.opacity(0), location: 0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(isLit ? 1 : 0)

            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // 내 띠 캐릭터가 그 기술을 거는 그림
                style.poseImage(belt: beltRank ?? .white).swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.poseSize, height: Metrics.poseSize)

                // 풀 타이틀
                // 한 줄에 다 들어가게 — 긴 이름(이스케이프 디펜스)만 글자를 줄이고 나머지는 40 그대로
                Text(style.fullTitle.replacingOccurrences(of: "\n", with: " "))
                    .font(.cookieRun.custom(weight: .black, size: 40))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .padding(.bottom, 20)

                // 카드 설명
                Text(style.cardDescription)
                    .font(.pretendard.custom(weight: .medium, size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    // 세 줄 안에 다 들어가게 — 한 줄이 넘치는 설명(하체 관절기)만 글자를 조금 줄인다
                    .minimumScaleFactor(0.9)
                    .frame(height: 72)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 32)
            }
        }
        .frame(width: Metrics.cardWidth, height: Metrics.cardHeight)
        .cornerRadius(40)
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
