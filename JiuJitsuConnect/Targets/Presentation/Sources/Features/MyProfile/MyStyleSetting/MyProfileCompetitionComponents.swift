//
//  MyProfileCompetitionComponents.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - MyProfileCompetitionSection

/// 대회 정보 섹션
public struct MyProfileCompetitionSection: View {
    let competitions: [Competition]?
    let onAddCompetitionTapped: () -> Void
    let onCompetitionDetailTapped: (Competition) -> Void
    
    private enum Metrics {
        static let titleBottomPadding: CGFloat = 8
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Metrics.titleBottomPadding) {
            // 섹션 타이틀
            Text("대회 정보")
                .font(.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)
            
            // 대회 정보 컨테이너
            if let competitions = competitions, !competitions.isEmpty {
                CompetitionListView(
                    competitions: competitions,
                    onCompetitionDetailTapped: onCompetitionDetailTapped
                )
            } else {
                EmptyCompetitionView(onAddCompetitionTapped: onAddCompetitionTapped)
            }
        }
    }
}

// MARK: - CompetitionListView

/// 대회 정보 리스트 (정보가 있을 때)
private struct CompetitionListView: View {
    let competitions: [Competition]
    let onCompetitionDetailTapped: (Competition) -> Void
    
    private enum Metrics {
        static let verticalPadding: CGFloat = 8
        static let rowSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 18
    }
    
    var body: some View {
        VStack(spacing: Metrics.rowSpacing) {
            ForEach(Array(competitions.enumerated()), id: \.offset) { _, competition in
                CompetitionRowView(
                    competition: competition,
                    onTapped: { onCompetitionDetailTapped(competition) }
                )
            }
        }
        .padding(.vertical, Metrics.verticalPadding)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }
}

// MARK: - CompetitionRowView

/// 개별 대회 정보 행
private struct CompetitionRowView: View {
    let competition: Competition
    let onTapped: () -> Void
    
    private enum Metrics {
        static let height: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
        static let iconSize: CGFloat = 18
        static let contentSpacing: CGFloat = 8
    }
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            HStack(spacing: Metrics.contentSpacing) {
                // 메달 아이콘
                competition.competitionRank.medalImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                
                // 대회 이름
                Text(competition.competitionName)
                    .font(.pretendard.bodyS)
                    .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // 날짜 (YYYY.MM 형식)
                Text(competition.formattedDate)
                    .font(.pretendard.labelM)
                    .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
            }
            .frame(height: Metrics.height)
            .padding(.horizontal, Metrics.horizontalPadding)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyCompetitionView

/// 대회 정보가 없을 때의 뷰
private struct EmptyCompetitionView: View {
    let onAddCompetitionTapped: () -> Void
    
    private enum Metrics {
        static let height: CGFloat = 56
        static let leadingPadding: CGFloat = 12
        static let trailingPadding: CGFloat = 20
        static let iconSize: CGFloat = 18
        static let contentSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 18
    }
    
    var body: some View {
        Button {
            onAddCompetitionTapped()
        } label: {
            HStack(spacing: Metrics.contentSpacing) {
                // 메달 아이콘
                Assets.MyProfile.Icon.medalDefaultDisable.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                
                // 텍스트
                Text("출전한 대회 정보를 입력해주세요")
                    .font(.pretendard.bodyS)
                    .foregroundStyle(Color.component.list.setting.text)
                
                Spacer()
                
                // Chevron 아이콘
                Assets.Common.Icon.chevronRight.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .foregroundStyle(Color.component.list.setting.icon)
            }
            .frame(height: Metrics.height)
            .padding(.leading, Metrics.leadingPadding)
            .padding(.trailing, Metrics.trailingPadding)
            .background(Color.component.list.setting.background)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("MyProfileCompetitionSection - 정보 있음") {
    MyProfileCompetitionSection(
        competitions: [
            Competition(
                competitionYear: 2025,
                competitionMonth: 11,
                competitionName: "2025 서울 오픈 챔피언십",
                competitionRank: .gold
            ),
            Competition(
                competitionYear: 2025,
                competitionMonth: 8,
                competitionName: "전국 주짓수 선수권 대회",
                competitionRank: .silver
            ),
            Competition(
                competitionYear: 2025,
                competitionMonth: 5,
                competitionName: "부산 국제 주짓수 대회",
                competitionRank: .bronze
            ),
            Competition(
                competitionYear: 2025,
                competitionMonth: 3,
                competitionName: "강남 주짓수 토너먼트",
                competitionRank: .participation
            )
        ],
        onAddCompetitionTapped: { },
        onCompetitionDetailTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 정보 없음") {
    MyProfileCompetitionSection(
        competitions: nil,
        onAddCompetitionTapped: { },
        onCompetitionDetailTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 빈 배열") {
    MyProfileCompetitionSection(
        competitions: [],
        onAddCompetitionTapped: { },
        onCompetitionDetailTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("CompetitionListView - 다양한 메달") {
    CompetitionListView(
        competitions: [
            Competition(
                competitionYear: 2026,
                competitionMonth: 3,
                competitionName: "2026 봄 주짓수 페스티벌",
                competitionRank: .gold
            ),
            Competition(
                competitionYear: 2026,
                competitionMonth: 1,
                competitionName: "신년 토너먼트",
                competitionRank: .silver
            ),
            Competition(
                competitionYear: 2025,
                competitionMonth: 12,
                competitionName: "연말 챔피언십",
                competitionRank: .bronze
            ),
            Competition(
                competitionYear: 2025,
                competitionMonth: 10,
                competitionName: "지역 예선전",
                competitionRank: .participation
            )
        ],
        onCompetitionDetailTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}
