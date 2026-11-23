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
            
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                
                // 내 띠 캐릭터가 그 기술을 거는 그림
                style.poseImage(belt: beltRank ?? .white).swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.poseSize, height: Metrics.poseSize)

                // 풀 타이틀
                Text(style.fullTitle)
                    .font(.cookieRun.custom(weight: .black, size: 40))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(height: 54)
                    .padding(.bottom, 20)

                // 카드 설명
                Text(style.cardDescription)
                    .font(.pretendard.custom(weight: .medium, size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
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

private extension StyleSelectable {
    var stylePose: StylePose? {
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
        typealias Pose = Assets.MyProfile.Pose
        guard let pose = stylePose else { return iconImage }
        switch (belt, pose) {
        case (.white, .top): return Pose.whiteTop
        case (.white, .guardPosition): return Pose.whiteGuard
        case (.white, .escape): return Pose.whiteEscape
        case (.white, .armLock): return Pose.whiteArmLock
        case (.white, .legLock): return Pose.whiteLegLock
        case (.white, .guardPass): return Pose.whiteGuardPass
        case (.white, .choke): return Pose.whiteChoke
        case (.white, .sweep): return Pose.whiteSweep
        case (.white, .takedown): return Pose.whiteTakedown
        case (.blue, .top): return Pose.blueTop
        case (.blue, .guardPosition): return Pose.blueGuard
        case (.blue, .escape): return Pose.blueEscape
        case (.blue, .armLock): return Pose.blueArmLock
        case (.blue, .legLock): return Pose.blueLegLock
        case (.blue, .guardPass): return Pose.blueGuardPass
        case (.blue, .choke): return Pose.blueChoke
        case (.blue, .sweep): return Pose.blueSweep
        case (.blue, .takedown): return Pose.blueTakedown
        case (.purple, .top): return Pose.purpleTop
        case (.purple, .guardPosition): return Pose.purpleGuard
        case (.purple, .escape): return Pose.purpleEscape
        case (.purple, .armLock): return Pose.purpleArmLock
        case (.purple, .legLock): return Pose.purpleLegLock
        case (.purple, .guardPass): return Pose.purpleGuardPass
        case (.purple, .choke): return Pose.purpleChoke
        case (.purple, .sweep): return Pose.purpleSweep
        case (.purple, .takedown): return Pose.purpleTakedown
        case (.brown, .top): return Pose.brownTop
        case (.brown, .guardPosition): return Pose.brownGuard
        case (.brown, .escape): return Pose.brownEscape
        case (.brown, .armLock): return Pose.brownArmLock
        case (.brown, .legLock): return Pose.brownLegLock
        case (.brown, .guardPass): return Pose.brownGuardPass
        case (.brown, .choke): return Pose.brownChoke
        case (.brown, .sweep): return Pose.brownSweep
        case (.brown, .takedown): return Pose.brownTakedown
        case (.black, .top): return Pose.blackTop
        case (.black, .guardPosition): return Pose.blackGuard
        case (.black, .escape): return Pose.blackEscape
        case (.black, .armLock): return Pose.blackArmLock
        case (.black, .legLock): return Pose.blackLegLock
        case (.black, .guardPass): return Pose.blackGuardPass
        case (.black, .choke): return Pose.blackChoke
        case (.black, .sweep): return Pose.blackSweep
        case (.black, .takedown): return Pose.blackTakedown
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
