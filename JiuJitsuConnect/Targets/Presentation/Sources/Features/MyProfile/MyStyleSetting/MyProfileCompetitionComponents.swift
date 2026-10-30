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
    /// 대회 한 줄을 누름 — 그 대회의 부문별 기록을 넘긴다(고칠 부문 / 부문 추가를 고르는 시트를 띄움).
    let onCompetitionTapped: ([Competition]) -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 타이틀 + 메달 합계 + 추가 버튼
            HStack(spacing: 8) {
                Text("대회 정보")
                    .font(.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)

                CompetitionMedalSummaryView(competitions: competitions ?? [])

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
                    onCompetitionTapped: onCompetitionTapped
                )
            } else {
                EmptyCompetitionView(onAddCompetitionTapped: onAddCompetitionTapped)
            }
        }
    }
}

// MARK: - CompetitionGroup

/// 같은 대회(대회명 + 연도)에서 나간 부문들을 묶은 단위(#123).
///
/// 서버는 아직 '대회 1개 = 메달 1개' 목록만 저장하므로(backend #164 전), 여러 부문은 같은 이름·연도로
/// 항목을 여러 개 저장하고 표시할 때만 묶는다.
struct CompetitionGroup {
    /// 맨 위에 고정할 수 있는 줄 수(#124). 많이 고정하면 고정의 의미(대표 기록)가 흐려진다.
    static let maxPinnedCount = 3

    /// 처음 입력한 기록의 대회명
    let name: String
    let year: Int
    /// 입력한 순서 그대로의 부문별 기록
    let entries: [Competition]

    /// 대회명 없이 저장한 기록(#125) — 나만 보이고, 다른 기록과 묶지 않는다.
    var isNameless: Bool { name.isEmpty }

    /// 부문 하나라도 고정돼 있으면 줄 전체를 고정으로 본다.
    /// 고정한 대회에 나중에 '부문 추가'로 더한 기록(고정 안 됨)이 섞여도 줄이 풀려 보이지 않게 한다.
    var isPinned: Bool {
        entries.contains(where: \.isPinned)
    }

    /// 대회 줄의 메달 — 묶인 부문 중 가장 높은 메달
    var representativeRank: CompetitionRank {
        entries.map(\.competitionRank).min { $0.medalOrder < $1.medalOrder } ?? .participation
    }

    /// 선택지 제목 — "2026 서울 오픈". 이름에 연도가 이미 있으면 붙이지 않는다.
    /// (연도를 숫자 그대로 문자열에 끼우면 "2,026"처럼 쉼표가 붙어 String으로 바꿔 넣는다.)
    var titleWithYear: String {
        let year = String(year)
        return name.contains(year) ? name : "\(year) \(name)"
    }

    /// 모든 부문의 띠가 같으면 그 띠(대부분), 다르면 nil — 다르면 부문 줄마다 띠를 붙인다.
    var sharedBelt: BeltRank? {
        let belts = Set(entries.compactMap(\.competitionBelt))
        return belts.count <= 1 ? belts.first : nil
    }

    /// 대회 줄의 상세 줄 — 한 부문: "2026 · 브라운 · 도복 -76kg", 여러 부문: "2026 · 브라운"(부문은 아래 줄에)
    var detailText: String {
        guard entries.count > 1 else {
            return entries.first?.detailText ?? String(year)
        }
        return [String(year), sharedBelt?.displayName]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// 시트의 부문 행 — "도복 -76kg"(메달은 아이콘으로). 띠가 부문마다 다르면 "퍼플 · 노기", 부문을 비웠으면 메달 이름.
    func divisionLineText(of entry: Competition) -> String {
        let parts = [sharedBelt == nil ? entry.competitionBelt?.displayName : nil, entry.divisionText].compactMap { $0 }
        return parts.isEmpty ? entry.competitionRank.displayName : parts.joined(separator: " · ")
    }

    /// 같은 대회인지 가르는 이름 — 띄어쓰기·대소문자를 무시하고, 이름에 적은 연도도 뺀다.
    /// "서울 오픈", "서울오픈", "2026 서울 오픈"(2026년)은 같은 대회로 본다(#123).
    static func matchingName(_ name: String, year: Int) -> String {
        // 연도는 앞뒤가 숫자가 아닐 때만 뺀다 — "12026컵"의 2026은 연도가 아니다.
        name.replacingOccurrences(of: "(?<![0-9])\(year)(?![0-9])", with: "", options: .regularExpression)
            .filter { !$0.isWhitespace }
            .lowercased()
    }

    /// 같은 대회끼리 묶어, 고정한 줄을 맨 위에 두고 나머지는 연도 최신순으로 돌려준다.
    /// 고정한 줄끼리도 연도 최신순이다(고정한 시각은 저장하지 않으므로).
    /// 같은 연도끼리는 처음 입력한 순서를 지킨다(월은 더 받지 않으므로).
    /// 대회명 없는 기록은 같은 대회인지 알 수 없어 하나씩 따로 둔다(#125).
    static func grouped(_ competitions: [Competition]) -> [CompetitionGroup] {
        struct Key: Hashable {
            let name: String
            let year: Int
            /// 대회명 없는 기록끼리 묶이지 않게 하는 자리값 — 이름 있는 기록은 nil
            let namelessIndex: Int?
        }
        var order: [Key] = []
        var entriesByKey: [Key: [Competition]] = [:]
        for (index, competition) in competitions.enumerated() {
            let key = Key(
                name: matchingName(competition.competitionName, year: competition.competitionYear),
                year: competition.competitionYear,
                namelessIndex: competition.isNameless ? index : nil
            )
            if entriesByKey[key] == nil {
                order.append(key)
            }
            entriesByKey[key, default: []].append(competition)
        }
        return order
            .map { key in
                let entries = entriesByKey[key] ?? []
                let name = entries.first?.competitionName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return CompetitionGroup(name: name, year: key.year, entries: entries)
            }
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isPinned != rhs.element.isPinned {
                    return lhs.element.isPinned
                }
                if lhs.element.year != rhs.element.year {
                    return lhs.element.year > rhs.element.year
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// 부문 한 줄 — "도복 -76kg 은". 메달은 글로 적는다(아이콘은 대회 줄에 하나만).
    func divisionMedalText(of entry: Competition) -> String {
        let division = [sharedBelt == nil ? entry.competitionBelt?.displayName : nil, entry.divisionText]
            .compactMap { $0 }
            .joined(separator: " · ")
        return division.isEmpty ? entry.competitionRank.displayName : "\(division) \(entry.competitionRank.shortName)"
    }

    /// 섹션 머리 메달 합계 — 금·은·동 순으로 (메달, 개수). 부문(항목) 기준으로 세고 참가와 0개는 뺀다.
    /// 대회명 없는 기록은 어느 대회 메달인지 확인할 수 없어 합계에서 뺀다(#125).
    static func medalCounts(of competitions: [Competition]) -> [(rank: CompetitionRank, count: Int)] {
        let counted = competitions.filter { !$0.isNameless }
        return [CompetitionRank.gold, .silver, .bronze].compactMap { rank in
            let count = counted.filter { $0.competitionRank == rank }.count
            return count > 0 ? (rank, count) : nil
        }
    }
}

// MARK: - CompetitionMedalSummaryView

/// 섹션 머리 메달 합계 — 메달 아이콘 + 개수. 이모지는 앱 글꼴에서 깨져 보여 목록과 같은 메달 아이콘을 쓴다.
private struct CompetitionMedalSummaryView: View {
    let competitions: [Competition]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CompetitionGroup.medalCounts(of: competitions), id: \.rank) { item in
                HStack(spacing: 2) {
                    item.rank.medalImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(item.count)")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.component.sectionHeader.subTitle)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.rank.displayName) \(item.count)개")
            }
        }
    }
}

// MARK: - CompetitionListView

/// 대회 정보 리스트 (정보가 있을 때)
private struct CompetitionListView: View {
    let competitions: [Competition]
    let onCompetitionTapped: ([Competition]) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(CompetitionGroup.grouped(competitions).enumerated()), id: \.offset) { _, group in
                CompetitionRowView(
                    group: group,
                    onTapped: { onCompetitionTapped(group.entries) }
                )
            }
        }
        .padding(.vertical, 8)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - CompetitionRowView

/// 대회 한 줄 — 메달 아이콘은 가장 높은 것 하나만. 여러 부문이면 아래에 부문을 "도복 -76kg 은"처럼 글로 한 줄씩 적는다.
/// (부문마다 메달 아이콘을 달면 목록이 메달로 도배돼 보인다)
/// 줄이나 오른쪽 ⋯ 을 누르면 수정·부문 추가·삭제 시트를 띄운다.
private struct CompetitionRowView: View {
    let group: CompetitionGroup
    let onTapped: () -> Void

    private enum Metrics {
        static let medalSize: CGFloat = 18
        // 여러 줄일 때 메달을 대회 이름 줄 가운데에 맞춘다.
        static let titleLineHeight: CGFloat = 20
    }

    private var hasDivisions: Bool { group.entries.count > 1 }

    var body: some View {
        HStack(alignment: hasDivisions ? .top : .center, spacing: 0) {
            Button {
                onTapped()
            } label: {
                HStack(alignment: hasDivisions ? .top : .center, spacing: 8) {
                    group.representativeRank.medalImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: Metrics.medalSize, height: Metrics.medalSize)
                        .frame(height: hasDivisions ? Metrics.titleLineHeight : nil)
                        .accessibilityLabel(group.representativeRank.displayName)

                    // 대회 이름 + 상세 줄(연도 · 띠 · 부문) — 같은 메달도 띠·부문에 따라 무게가 달라 함께 보여 준다(#122).
                    VStack(alignment: .leading, spacing: 2) {
                        Group {
                            if group.isNameless {
                                namelessTitle
                            } else {
                                title
                            }
                        }
                        .frame(minHeight: Metrics.titleLineHeight)

                        Text(group.detailText)
                            .font(.pretendard.labelM)
                            .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // 부문 줄은 위 상세 줄(연도 · 띠)과 구분되게 진한 글자 + 간격을 둔다.
                        if hasDivisions {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(group.entries.enumerated()), id: \.offset) { _, entry in
                                    Text(group.divisionMedalText(of: entry))
                                        .font(.pretendard.labelM)
                                        .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 6)
                        }

                        // 줄을 누르면 수정으로 들어가므로, 여기서 대회명을 채우면 공개된다는 걸 알려 준다.
                        if group.isNameless {
                            Text("대회명을 채우면 공개돼요 ›")
                                .font(.pretendard.labelM)
                                .foregroundStyle(Color.primitive.blue.b500p)
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 12)
                .frame(minHeight: 40)
                .padding(.leading, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 나만 보는 기록은 대표 기록(고정)으로 내세울 수 없고 줄을 누르면 바로 수정으로 들어가 ⋯ 을 두지 않는다.
            if group.isNameless {
                Spacer().frame(width: 16)
            } else {
                menuButton
            }
        }
    }

    // 고정 표시는 이름 뒤에 옅은 회색 압정으로 — 대회 이름보다 눈에 띄지 않게 한다(#124).
    private var title: some View {
        HStack(spacing: 4) {
            Text(group.name)
                .font(.pretendard.custom(weight: .semiBold, size: 14))
                .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                .lineLimit(1)

            if group.isPinned {
                Assets.Common.Icon.pin.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                    .accessibilityLabel("고정됨")
            }
        }
    }

    private var namelessTitle: some View {
        HStack(spacing: 6) {
            Text(Competition.namelessTitle)
                .font(.pretendard.custom(weight: .semiBold, size: 14))
                .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                .lineLimit(1)

            Text("나만 보기")
                .font(.pretendard.labelS)
                .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primitive.coolGray.cg75)
                .clipShape(Capsule())
        }
    }

    private var menuButton: some View {
        Button {
            onTapped()
        } label: {
            Assets.MyProfile.Icon.menu.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 줄을 눌러도 같은 시트가 떠서, 화면 읽기에서는 줄 하나만 읽히게 한다.
        .accessibilityHidden(true)
        .padding(.trailing, 2)
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
                competitionWeightLimit: CompetitionWeightLimit(kg: 76, bound: .under),
                competitionBelt: .brown
            ),
            // 같은 대회의 다른 부문 — 위 항목과 한 줄로 묶인다.
            Competition(
                competitionYear: 2025,
                competitionName: "2025 서울 오픈 챔피언십",
                competitionRank: .gold,
                competitionUniform: .gi,
                competitionAbsolute: true,
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
        onCompetitionTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 맨 위 고정") {
    MyProfileCompetitionSection(
        competitions: [
            Competition(competitionYear: 2026, competitionName: "2026 서울 오픈", competitionRank: .silver),
            // 오래된 대회라도 고정하면 최신 대회보다 위에 온다.
            Competition(competitionYear: 2022, competitionName: "2022 아시안 오픈", competitionRank: .gold, isPinned: true),
            Competition(competitionYear: 2024, competitionName: "2024 부산 오픈", competitionRank: .bronze)
        ],
        onAddCompetitionTapped: { },
        onCompetitionTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 대회명 없는 기록") {
    MyProfileCompetitionSection(
        competitions: [
            Competition(competitionYear: 2026, competitionName: "2026 서울 오픈", competitionRank: .silver),
            // 합계에 들어가지 않고, 서로 묶이지도 않는다.
            Competition(competitionYear: 2025, competitionName: "", competitionRank: .gold),
            Competition(competitionYear: 2025, competitionName: "", competitionRank: .bronze)
        ],
        onAddCompetitionTapped: { },
        onCompetitionTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 정보 없음") {
    MyProfileCompetitionSection(
        competitions: nil,
        onAddCompetitionTapped: { },
        onCompetitionTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 빈 배열") {
    MyProfileCompetitionSection(
        competitions: [],
        onAddCompetitionTapped: { },
        onCompetitionTapped: { _ in }
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
        onCompetitionTapped: { _ in }
    )
    .padding()
    .background(Color.component.background.default)
}
