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

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 타이틀 + 메달 합계 + 추가 버튼
            HStack(spacing: 8) {
                Text("대회 정보")
                    .font(.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)

                if let medalSummary = CompetitionGroup.medalSummary(of: competitions ?? []) {
                    Text(medalSummary)
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.component.sectionHeader.subTitle)
                }

                Spacer()

                Button {
                    onAddCompetitionTapped()
                } label: {
                    Assets.Common.Icon.plus.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.component.button.ghost.defaultText)
                }
                .frame(width: 32, height: 32)
                .buttonStyle(.plain)
            }

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

// MARK: - CompetitionGroup

/// 같은 대회(대회명 + 연도)에서 나간 부문들을 한 줄로 묶은 단위(#123).
///
/// 서버는 아직 '대회 1개 = 메달 1개' 목록만 저장하므로(backend #164 전), 여러 부문은 같은 이름·연도로
/// 항목을 여러 개 저장하고 표시할 때만 묶는다.
struct CompetitionGroup {
    let name: String
    let year: Int
    /// 입력한 순서 그대로의 부문별 기록
    let entries: [Competition]

    /// 묶인 줄의 메달 아이콘 — 가장 높은 메달
    var representativeRank: CompetitionRank {
        entries.map(\.competitionRank).min { $0.medalOrder < $1.medalOrder } ?? .participation
    }

    /// 상세 줄 — 한 부문: "2026 · 브라운 · 도복 -76kg", 여러 부문: "2026 · 브라운 · 도복 -76kg 은 · 앱솔루트 금"
    var detailText: String {
        guard entries.count > 1, let first = entries.first else {
            return entries.first?.detailText ?? String(year)
        }
        // 띠가 모두 같으면(대부분) 앞에 한 번만, 다르면 부문마다 붙인다.
        let belts = Set(entries.compactMap(\.competitionBelt))
        let sharedBelt = belts.count <= 1 ? belts.first : nil

        var previousUniform: CompetitionUniform?
        let divisionParts = entries.enumerated().map { index, entry in
            // 앞 부문과 복장이 같으면 반복하지 않는다 — "도복 -76kg 은 · 앱솔루트 금"
            let uniform = (index == 0 || entry.competitionUniform != previousUniform) ? entry.competitionUniform : nil
            previousUniform = entry.competitionUniform
            return [
                sharedBelt == nil ? entry.competitionBelt?.displayName : nil,
                uniform?.displayName,
                entry.competitionWeightClass?.displayName,
                entry.competitionRank.shortName
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        }
        return ([first.formattedYear, sharedBelt?.displayName].compactMap { $0 } + divisionParts)
            .joined(separator: " · ")
    }

    /// 같은 대회명(앞뒤 공백 무시) + 연도끼리 묶어 연도 최신순으로 돌려준다.
    /// 같은 연도끼리는 처음 입력한 순서를 지킨다(월은 더 받지 않으므로).
    static func grouped(_ competitions: [Competition]) -> [CompetitionGroup] {
        struct Key: Hashable {
            let name: String
            let year: Int
        }
        var order: [Key] = []
        var entriesByKey: [Key: [Competition]] = [:]
        for competition in competitions {
            let key = Key(
                name: competition.competitionName.trimmingCharacters(in: .whitespacesAndNewlines),
                year: competition.competitionYear
            )
            if entriesByKey[key] == nil {
                order.append(key)
            }
            entriesByKey[key, default: []].append(competition)
        }
        return order.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.year != rhs.element.year {
                    return lhs.element.year > rhs.element.year
                }
                return lhs.offset < rhs.offset
            }
            .map { _, key in
                CompetitionGroup(name: key.name, year: key.year, entries: entriesByKey[key] ?? [])
            }
    }

    /// 섹션 머리 메달 합계 — "🥇 2 · 🥈 1 · 🥉 1". 부문(항목) 기준으로 세고 참가는 뺀다. 메달이 없으면 nil.
    static func medalSummary(of competitions: [Competition]) -> String? {
        let parts = [CompetitionRank.gold, .silver, .bronze].compactMap { rank -> String? in
            let count = competitions.filter { $0.competitionRank == rank }.count
            return count > 0 ? "\(rank.emoji) \(count)" : nil
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

// MARK: - CompetitionListView

/// 대회 정보 리스트 (정보가 있을 때)
private struct CompetitionListView: View {
    let competitions: [Competition]
    let onCompetitionDetailTapped: (Competition) -> Void

    // 여러 부문이 묶인 줄을 눌렀을 때 고칠 부문을 묻는 선택지. 화면 표시용 일시 상태라 Feature로 올리지 않고,
    // 고른 결과만 기존 콜백(수정 진입)으로 보낸다.
    @State private var groupPendingSelection: CompetitionGroup?

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(CompetitionGroup.grouped(competitions).enumerated()), id: \.offset) { _, group in
                CompetitionRowView(
                    group: group,
                    onTapped: {
                        if group.entries.count == 1, let entry = group.entries.first {
                            onCompetitionDetailTapped(entry)
                        } else {
                            groupPendingSelection = group
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .confirmationDialog(
            "수정할 부문을 골라주세요",
            isPresented: Binding(
                get: { groupPendingSelection != nil },
                set: { if !$0 { groupPendingSelection = nil } }
            ),
            titleVisibility: .visible,
            presenting: groupPendingSelection
        ) { group in
            ForEach(Array(group.entries.enumerated()), id: \.offset) { _, entry in
                Button(entry.divisionResultText) {
                    onCompetitionDetailTapped(entry)
                }
            }
            Button("취소", role: .cancel) {}
        }
    }
}

// MARK: - CompetitionRowView

/// 대회 한 줄 — 같은 대회의 여러 부문은 한 줄에 묶어 보여 준다.
private struct CompetitionRowView: View {
    let group: CompetitionGroup
    let onTapped: () -> Void

    var body: some View {
        Button {
            onTapped()
        } label: {
            HStack(spacing: 8) {
                // 메달 아이콘 — 묶인 부문 중 가장 높은 메달
                group.representativeRank.medalImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                // 대회 이름 + 상세 줄(연도 · 띠 · 부문) — 같은 메달도 띠·부문에 따라 무게가 달라 함께 보여 준다(#122).
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.pretendard.custom(weight: .semiBold, size: 14))
                        .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                        .lineLimit(1)

                    // 부문이 많으면 줄을 넘겨 다 보여 준다(잘리면 어떤 메달인지 알 수 없음).
                    Text(group.detailText)
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .frame(minHeight: 40)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyCompetitionView

/// 대회 정보가 없을 때의 뷰
private struct EmptyCompetitionView: View {
    let onAddCompetitionTapped: () -> Void

    private enum Metrics {
        // 메달 아이콘과 chevron 아이콘 2곳에서 공유
        static let iconSize: CGFloat = 18
    }

    var body: some View {
        Button {
            onAddCompetitionTapped()
        } label: {
            HStack(spacing: 8) {
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
            .frame(height: 56)
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .background(Color.component.list.setting.background)
            .clipShape(RoundedRectangle(cornerRadius: 18))
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
                competitionRank: .silver,
                competitionUniform: .gi,
                competitionWeightClass: .under76,
                competitionBelt: .brown
            ),
            // 같은 대회의 다른 부문 — 위 항목과 한 줄로 묶인다.
            Competition(
                competitionYear: 2025,
                competitionName: "2025 서울 오픈 챔피언십",
                competitionRank: .gold,
                competitionUniform: .gi,
                competitionWeightClass: .absolute,
                competitionBelt: .brown
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
