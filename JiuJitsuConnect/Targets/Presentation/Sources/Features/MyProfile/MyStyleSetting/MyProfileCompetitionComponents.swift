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

/// 대회 기록 섹션
public struct MyProfileCompetitionSection: View {
    let competitions: [Competition]?
    var medalCount: MedalCount = .zero
    let onAddCompetitionTapped: () -> Void
    /// › 줄(부문 하나)을 누름 — 누른 부문과 그 대회의 부문들을 넘긴다(부문 수정 · 고정 · 부문 추가 · 순서 바꾸기 · 삭제 시트를 띄움).
    let onDivisionTapped: (_ entry: Competition, _ entries: [Competition]) -> Void
    /// 값이 바뀌면 순서 바꾸기를 시작한다(시트의 '순서 바꾸기'). 옮기는 순서는 이 섹션이 가지므로 신호만 받는다.
    var reorderRequest = 0
    /// 순서를 바꾸고 '완료' — 순서가 바뀐 묶음(고정한 줄들 / 고정 안 한 줄들)의 줄별 부문들, 위에서부터. 저장은 부모가 한다.
    var onCompetitionsReordered: ([[Competition]]) -> Void = { _ in }
    /// 프로필 저장 중 — 저장 전 목록으로 순서를 바꾸면 앞의 저장을 덮으므로 끌기와 '완료'를 막는다.
    var isSaving: Bool = false

    // 끌어 놓았지만 아직 저장하지 않은 줄 순서. 처음 하나를 옮기면 생기고, '완료'로 저장·'취소'로 처음 순서로 돌린다.
    // 여러 번 옮긴 뒤에도 한 번에 되돌릴 수 있게 놓을 때마다 저장하지 않는다. 화면 표시용 일시 상태라 Feature로 올리지 않는다.
    @State private var pendingGroups: [CompetitionGroup]?

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 타이틀 + 메달 합계 + 추가 버튼
            HStack(spacing: 8) {
                Text("대회 기록")
                    .font(.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)

                CompetitionMedalSummaryView(medalCount: medalCount)

                Spacer()

                // 순서를 옮기는 중에는 추가 대신 취소·완료 — 끝내는 자리를 눈 가는 머리줄 오른쪽에 둔다.
                if pendingGroups != nil {
                    // 글자만 있던 버튼이 잘 안 보여(#212) 바탕이 있는 작은 공통 버튼으로 — 완료가 주 동작이라 파랑.
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) { pendingGroups = nil }
                        } label: {
                            AppButtonConfiguration(title: "취소", size: .small)
                        }
                        .appButtonStyle(.neutral, size: .small, height: 32)

                        Button {
                            finishReordering()
                        } label: {
                            AppButtonConfiguration(title: "완료", size: .small)
                        }
                        .appButtonStyle(.primary, size: .small, height: 32)
                        .disabled(isSaving)
                    }
                } else {
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
            }

            // 대회 정보 컨테이너
            if let competitions = competitions, !competitions.isEmpty {
                CompetitionListView(
                    competitions: competitions,
                    onDivisionTapped: onDivisionTapped,
                    isSaving: isSaving,
                    pendingGroups: $pendingGroups
                )
            } else {
                EmptyCompetitionView(onAddCompetitionTapped: onAddCompetitionTapped)
            }
        }
        .onChange(of: reorderRequest) {
            let groups = CompetitionGroup.grouped(competitions ?? [])
            guard groups.count > 1, !isSaving else { return }
            withAnimation(.easeInOut(duration: 0.5)) { pendingGroups = groups }
        }
        // 옮기는 중에 목록이 바뀌면(다시 불러오기 등) 옮겨 둔 순서는 지키고, 사라진 줄은 빼고 새 줄은 그 묶음 끝에 둔다.
        // 목록이 비면 옮길 것이 없으므로 취소·완료도 거둔다.
        .onChange(of: competitions) {
            guard let pending = pendingGroups else { return }
            let latest = CompetitionGroup.grouped(competitions ?? [])
            guard !latest.isEmpty else {
                pendingGroups = nil
                return
            }
            // 줄 내용(부문·고정)은 최신 값으로 바꾸고, 자리만 옮겨 둔 순서를 따른다.
            let kept = pending.compactMap { group in latest.first { $0.id == group.id } }
            let added = latest.filter { group in !kept.contains { $0.id == group.id } }
            let merged = kept + added
            pendingGroups = merged.filter(\.isPinned) + merged.filter { !$0.isPinned }
        }
    }

    /// 순서가 바뀐 묶음만 넘겨 저장한다 — 고정 안 한 줄을 건드리지 않았으면 그 줄들은 계속 연도순으로 둔다.
    private func finishReordering() {
        guard let pendingGroups else { return }
        let original = CompetitionGroup.grouped(competitions ?? [])
        let changed = [true, false].flatMap { isPinned -> [CompetitionGroup] in
            let moved = pendingGroups.filter { $0.isPinned == isPinned }
            let before = original.filter { $0.isPinned == isPinned }
            return moved.map(\.id) == before.map(\.id) ? [] : moved
        }
        if !changed.isEmpty {
            onCompetitionsReordered(changed.map(\.entries))
        }
        withAnimation(.easeInOut(duration: 0.5)) { self.pendingGroups = nil }
    }
}

// MARK: - CompetitionGroup

/// 같은 대회(대회명 + 연도)에서 나간 부문들을 묶은 단위(#123).
///
/// 앱의 `Competition`은 한 건 = 한 부문이라 같은 이름·연도의 기록을 표시할 때 묶는다.
/// 서버와는 대회 → 부문 중첩으로 주고받고, 그 변환은 Data 레이어 DTO가 맡는다.
struct CompetitionGroup {
    /// 맨 위에 고정할 수 있는 줄 수(#124). 많이 고정하면 고정의 의미(대표 기록)가 흐려진다.
    static let maxPinnedCount = 3

    /// 줄 구분값 — 끌어서 옮기는 줄을 알아보는 데 쓴다. 묶는 기준(연도 + 비교용 이름)과 같다.
    let id: String
    /// 처음 입력한 기록의 대회명
    let name: String
    let year: Int
    /// 입력한 순서 그대로의 부문별 기록
    let entries: [Competition]

    /// 부문 하나라도 고정돼 있으면 줄 전체를 고정으로 본다.
    /// 고정한 대회에 나중에 '부문 추가'로 더한 기록(고정 안 됨)이 섞여도 줄이 풀려 보이지 않게 한다.
    var isPinned: Bool {
        entries.contains(where: \.isPinned)
    }

    /// 회원이 끌어서 정한 자리(#204) — 묶인 부문 중 가장 앞 자리. 정한 적 없으면 nil.
    var displayOrder: Int? {
        entries.compactMap(\.displayOrder).min()
    }

    /// 줄에 보일 메달 — 딴 메달 전부를 금·은·동 순으로. 딴 메달이 없으면 참가 메달 하나.
    var displayedMedals: [CompetitionRank] {
        let won = entries.map(\.competitionRank)
            .filter { $0 != .participation }
            .sorted { $0.medalOrder < $1.medalOrder }
        return won.isEmpty ? [.participation] : won
    }

    /// 줄에 보일 띠 — 부문마다 띠가 다르면 가장 높은 띠. 부문별 띠는 시트의 부문 줄에 적혀 있다.
    var topBelt: BeltRank? {
        entries.compactMap(\.competitionBelt)
            .max { (BeltRank.allCases.firstIndex(of: $0) ?? 0) < (BeltRank.allCases.firstIndex(of: $1) ?? 0) }
    }

    /// 기본 순서 — 높은 띠 먼저, 같은 띠면 최신 연도 먼저. 띠를 안 적은 줄은 가장 낮게 본다.
    fileprivate func comesBefore(_ other: CompetitionGroup) -> Bool {
        let beltIndex = topBelt.flatMap { BeltRank.allCases.firstIndex(of: $0) } ?? -1
        let otherBeltIndex = other.topBelt.flatMap { BeltRank.allCases.firstIndex(of: $0) } ?? -1
        return beltIndex != otherBeltIndex ? beltIndex > otherBeltIndex : year > other.year
    }

    /// 줄의 부가 정보 — "도복 -76kg · 2026". 여러 부문이면 "4개 부문 · 2025"처럼 수만 적고, 비어 있는 값은 건너뛴다. 띠는 줄 앞에 따로 둔다.
    var rowDetailText: String {
        let division = entries.count > 1 ? "\(entries.count)개 부문" : entries.first?.divisionText
        return [division, String(year)]
            .compactMap { $0 }
            .joined(separator: " · ")
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

    /// 같은 대회끼리 묶어, 고정한 줄을 맨 위에 두고 그 아래 고정 안 한 줄을 둔다.
    /// - 고정한 줄: 자리 순. 새로 고정한 줄이 맨 위(자리 0)로 들어가고, 회원이 끌어서 바꿀 수 있다.
    ///   자리가 없는 고정 줄(순서 저장 전에 고정한 기록)은 자리 있는 줄 뒤에 기본 순서로 둔다.
    /// - 고정 안 한 줄: 높은 띠 먼저, 같은 띠 안에서는 연도 최신순이 기본이고 띠를 안 적은 줄은 맨 아래에 둔다.
    ///   회원이 끌어서 정한 자리가 있으면 그 순서를 지키고,
    ///   자리를 정한 적 없는 기록(새로 입력한 기록 등)은 기본 순서에 맞는 자리(처음 나오는 더 뒤에 올 줄 앞)로 들어간다.
    /// 띠와 연도가 같으면 처음 입력한 순서를 지킨다(월은 더 받지 않으므로).
    static func grouped(_ competitions: [Competition]) -> [CompetitionGroup] {
        struct Key: Hashable {
            let name: String
            let year: Int
        }
        var order: [Key] = []
        var entriesByKey: [Key: [Competition]] = [:]
        for competition in competitions {
            let key = Key(
                name: matchingName(competition.competitionName, year: competition.competitionYear),
                year: competition.competitionYear
            )
            if entriesByKey[key] == nil {
                order.append(key)
            }
            entriesByKey[key, default: []].append(competition)
        }
        typealias Indexed = (inputIndex: Int, group: CompetitionGroup)
        let groups: [Indexed] = order.enumerated().map { inputIndex, key in
            let entries = entriesByKey[key] ?? []
            let name = entries.first?.competitionName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return (inputIndex, CompetitionGroup(id: "\(key.year)|\(key.name)", name: name, year: key.year, entries: entries))
        }
        let defaultOrder: (Indexed, Indexed) -> Bool = { lhs, rhs in
            if lhs.group.comesBefore(rhs.group) { return true }
            if rhs.group.comesBefore(lhs.group) { return false }
            return lhs.inputIndex < rhs.inputIndex
        }

        let pinned = groups.filter { $0.group.isPinned }.sorted { lhs, rhs in
            switch (lhs.group.displayOrder, rhs.group.displayOrder) {
            case let (lhsOrder?, rhsOrder?) where lhsOrder != rhsOrder:
                return lhsOrder < rhsOrder
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return defaultOrder(lhs, rhs)
            }
        }

        let unpinned = groups.filter { !$0.group.isPinned }
        var placed = unpinned
            .filter { $0.group.displayOrder != nil }
            .sorted { ($0.group.displayOrder ?? 0, $0.inputIndex) < ($1.group.displayOrder ?? 0, $1.inputIndex) }
            .map(\.group)
        for item in unpinned.filter({ $0.group.displayOrder == nil }).sorted(by: defaultOrder) {
            let index = placed.firstIndex { item.group.comesBefore($0) } ?? placed.endIndex
            placed.insert(item.group, at: index)
        }
        return pinned.map(\.group) + placed
    }

    /// 섹션 머리 메달 합계 — 금·은·동 순으로 (메달, 개수). 부문(항목) 기준으로 세고 참가와 0개는 뺀다.
    static func medalCounts(of competitions: [Competition]) -> [(rank: CompetitionRank, count: Int)] {
        [CompetitionRank.gold, .silver, .bronze].compactMap { rank in
            let count = competitions.filter { $0.competitionRank == rank }.count
            return count > 0 ? (rank, count) : nil
        }
    }
}

// MARK: - CompetitionMedalSummaryView

/// 섹션 머리 메달 합계 — 메달 아이콘 + 개수. 이모지는 앱 글꼴에서 깨져 보여 목록과 같은 메달 아이콘을 쓴다.
/// 개수는 서버 합계(`medalCount`)를 쓴다 — 남이 보는 프로필과 같은 기준(대회명 없는 기록 제외)이어야 해서. 0개는 뺀다.
private struct CompetitionMedalSummaryView: View {
    let medalCount: MedalCount

    private var items: [(rank: CompetitionRank, count: Int)] {
        [(CompetitionRank.gold, medalCount.gold), (.silver, medalCount.silver), (.bronze, medalCount.bronze)]
            .filter { $0.1 > 0 }
            .map { (rank: $0.0, count: $0.1) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.rank) { item in
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
///
/// › 줄을 눌러 뜨는 시트의 '순서 바꾸기'를 고르면 머리줄에 취소·완료가 나오고, 그동안 줄 끝 ≡ 를 잡고 끌어 순서를 바꾼다(#204). 완료를 눌러야 저장한다.
/// 끌기를 순서 바꾸기 중의 ≡ 에만 두는 건 — 예전처럼 줄마다 길게 눌러 끌기를 붙여 두면 그 인식이 짧은 탭을 가끔 가로채 한 번 눌러서는 반응하지 않았다.
/// 고정한 줄은 고정한 줄끼리, 고정 안 한 줄은 고정 안 한 줄끼리만 자리를 바꾼다
/// — 고정 안 한 줄을 고정 자리로 올리려면 같은 시트의 '맨 위에 고정'을 쓴다.
private struct CompetitionListView: View {
    let competitions: [Competition]
    let onDivisionTapped: (_ entry: Competition, _ entries: [Competition]) -> Void
    var isSaving: Bool = false
    /// 끌어 놓았지만 아직 저장하지 않은 순서(섹션이 갖고 취소·완료를 받는다)
    @Binding var pendingGroups: [CompetitionGroup]?

    // 끄는 동안의 줄 순서(손가락을 따라 바로 바뀜)와 끄는 줄. 놓으면 pendingGroups로 넘기고 비운다.
    @State private var liveGroups: [CompetitionGroup]?
    @State private var draggingID: String?
    /// 끄는 손가락의 세로 위치와, 잡은 곳이 줄 위끝에서 얼마나 아래인지 — 끄는 줄이 손가락을 따라오게 한다.
    @State private var dragY: CGFloat = 0
    @State private var grabOffset: CGFloat = 0
    @State private var rowHeights: [String: CGFloat] = [:]
    /// 손가락이 닿아 있는 동안만 참 — 끌기가 끝나지 않고 끊겨도(앱이 뒤로 감 · 시스템 방해) 거짓으로 돌아와 정리할 수 있게 한다.
    @GestureState private var isDragActive = false

    private enum Metrics {
        static let rowSpacing: CGFloat = 0
        /// 줄 오른쪽 끝에서 ≡ 를 잡는 폭 — 12pt 손잡이 둘레를 손가락에 걸리게 넓힌다.
        static let handleHitWidth: CGFloat = 56
        static let rowCornerRadius: CGFloat = 14
    }

    private static let coordinateSpace = "competitionList"

    private var isReordering: Bool { pendingGroups != nil }

    /// 끌기를 시작할 때의 순서 — 앞서 옮겨 둔 순서가 있으면 그것부터
    private var baseGroups: [CompetitionGroup] { pendingGroups ?? CompetitionGroup.grouped(competitions) }

    /// 같은 묶음(고정/고정 안 함) 안에서 한 칸 옮겨 '저장 전 순서'로 남긴다.
    private func moveByOne(_ group: CompetitionGroup, offset: Int) {
        var order = baseGroups
        guard let from = order.firstIndex(where: { $0.id == group.id }) else { return }
        let to = from + offset
        guard order.indices.contains(to), order[to].isPinned == group.isPinned, !isSaving else { return }
        order.swapAt(from, to)
        withAnimation(.easeInOut(duration: 0.2)) { pendingGroups = order }
    }

    /// 주어진 순서에서 줄의 위끝 — 목록 맨 위(첫 줄 위끝)가 0이다.
    private func top(of id: String, in groups: [CompetitionGroup]) -> CGFloat {
        var top: CGFloat = 0
        for group in groups {
            if group.id == id { return top }
            top += (rowHeights[group.id] ?? 0) + Metrics.rowSpacing
        }
        return top
    }

    var body: some View {
        VStack(spacing: Metrics.rowSpacing) {
            let groups = liveGroups ?? baseGroups
            ForEach(groups, id: \.id) { group in
                let index = groups.firstIndex { $0.id == group.id } ?? 0
                let isDragging = draggingID == group.id
                // 순서를 옮기는 중에는 수정 화면·시트로 들어가지 않는다(저장 안 한 순서를 잃지 않게).
                CompetitionRowView(
                    group: group,
                    startsPlainBlock: index > 0 && groups[index - 1].isPinned && !group.isPinned,
                    onEntryTapped: { entry in
                        guard pendingGroups == nil else { return }
                        onDivisionTapped(entry, group.entries)
                    },
                    isReordering: isReordering
                )
                // 줄 높이를 내용만큼 고정한다 — 없으면 부문이 여러 줄인 대회가 다른 줄과 같은 높이로 눌려 위아래 줄과 겹친다(#140).
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowHeights[group.id] = $0 }
                // 끄는 줄은 카드 면을 깔고 살짝 띄워 손가락을 따라오게 한다. 다른 줄이 자리를 바꿔도 끄는 줄은 애니메이션 없이 손가락에 붙어 있는다.
                .background {
                    if isDragging {
                        RoundedRectangle(cornerRadius: Metrics.rowCornerRadius)
                            .fill(Color.component.skillCard.default.bg)
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    }
                }
                .offset(y: isDragging ? dragY - grabOffset - top(of: group.id, in: groups) : 0)
                .zIndex(isDragging ? 1 : 0)
                .transaction { if isDragging { $0.animation = nil } }
                // 순서 바꾸기 중에는 줄 끝 ≡ 를 잡자마자 끈다 — 길게 누를 필요가 없다. 줄의 나머지는 화면 스크롤에 남긴다.
                .overlay(alignment: .trailing) {
                    if isReordering {
                        Color.clear
                            .frame(width: Metrics.handleHitWidth)
                            .contentShape(Rectangle())
                            .gesture(reorderGesture(for: group))
                            .accessibilityHidden(true)
                    }
                }
                // 끌 수 없는 VoiceOver 사용자도 같은 묶음 안에서 한 칸씩 옮길 수 있게 한다.
                .accessibilityAction(named: "위로 이동") { moveByOne(group, offset: -1) }
                .accessibilityAction(named: "아래로 이동") { moveByOne(group, offset: 1) }
            }
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        // 끌기가 끝나든 끊기든 손가락이 떨어지면 정리한다(끊길 때는 onEnded가 오지 않는다).
        .onChange(of: isDragActive) { _, active in
            if !active { finishDrag() }
        }
        // 취소·완료로 순서 바꾸기가 끝나면 끌던 상태도 버린다.
        .onChange(of: isReordering) { _, reordering in
            if !reordering {
                liveGroups = nil
                draggingID = nil
            }
        }
        .padding(.vertical, 8)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        // 끌기를 시작·끝낼 때가 아니라 줄이 실제로 자리를 바꿀 때만 울린다.
        .sensoryFeedback(.selection, trigger: liveGroups?.map(\.id)) { old, new in old != nil && new != nil }
    }

    private func reorderGesture(for group: CompetitionGroup) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.coordinateSpace))
            .updating($isDragActive) { _, active, _ in active = true }
            .onChanged { value in
                // 다른 손가락이 다른 줄의 ≡ 를 잡아도 끄던 줄만 따라간다.
                guard !isSaving, draggingID == nil || draggingID == group.id else { return }
                if draggingID == nil {
                    draggingID = group.id
                    liveGroups = baseGroups
                    grabOffset = value.startLocation.y - top(of: group.id, in: baseGroups)
                }
                dragY = value.location.y
                moveDraggedRow()
            }
            .onEnded { _ in finishDrag() }
    }

    /// 놓은 순서를 '저장 전 순서'로 남기고 끌던 상태를 비운다. 끝남·끊김 양쪽에서 불리므로 두 번 와도 한 번만 한다.
    private func finishDrag() {
        guard draggingID != nil else { return }
        if let live = liveGroups {
            // 끄는 사이 목록이 바뀌었으면(다시 불러오기 등) 줄 내용은 최신 값으로, 자리만 끈 순서를 따른다 — 섹션의 병합과 같은 규칙.
            let latest = baseGroups
            let kept = live.compactMap { group in latest.first { $0.id == group.id } }
            let added = latest.filter { group in !kept.contains { $0.id == group.id } }
            let merged = kept + added
            let order = merged.filter(\.isPinned) + merged.filter { !$0.isPinned }
            if order.map(\.id) != latest.map(\.id) {
                pendingGroups = order
            }
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            liveGroups = nil
            draggingID = nil
        }
    }

    /// 끄는 줄의 가운데가 옆 줄의 가운데를 넘으면 그 자리로 옮긴다.
    /// 고정한 줄과 고정 안 한 줄은 서로의 자리로 넘어가지 않는다.
    private func moveDraggedRow() {
        guard var live = liveGroups, let draggingID,
              let from = live.firstIndex(where: { $0.id == draggingID }) else { return }
        let center = dragY - grabOffset + (rowHeights[draggingID] ?? 0) / 2
        var top: CGFloat = 0
        for (index, group) in live.enumerated() {
            let height = rowHeights[group.id] ?? 0
            defer { top += height + Metrics.rowSpacing }
            guard center >= top, center < top + height + Metrics.rowSpacing, index != from else { continue }
            guard group.isPinned == live[from].isPinned else { return }
            // 옆 줄의 가운데를 넘어야 옮긴다 — 키가 다른 줄끼리 바뀐 직후 되돌아 바뀌며 떨리지 않게.
            let middle = top + height / 2
            guard index > from ? center > middle : center < middle else { return }
            let moving = live.remove(at: from)
            live.insert(moving, at: index)
            withAnimation(.easeInOut(duration: 0.2)) { liveGroups = live }
            return
        }
    }
}

// MARK: - CompetitionMedalCluster

/// 한 대회에서 딴 메달을 금·은·동 순서로 가로로 놓는다. 겹치지 않게 띄워 개수와 색이 그대로 보이게 한다.
private struct CompetitionMedalCluster: View {
    let medals: [CompetitionRank]
    /// 펼칠 때 메달이 부문 줄의 자기 자리로 이어서 움직이게 하는 이름 공간
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(medals.enumerated()), id: \.offset) { index, rank in
                rank.medalImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .accessibilityLabel(rank.displayName)
                    .matchedGeometryEffect(id: index, in: namespace)
            }
        }
        .fixedSize()
    }
}

// MARK: - CompetitionBeltMark

/// 세로로 놓인 띠 한 토막 — 글자 없이 색과 끝부분(검은 띠만 빨강)으로 띠를 알린다.
private struct CompetitionBeltMark: View {
    let belt: BeltRank

    private var fill: Color {
        let colors = Color.component.beltSelectButton.belt
        switch belt {
        case .white: return colors.white
        case .blue: return colors.blue
        case .purple: return colors.purple
        case .brown: return colors.brown
        case .black: return colors.black
        }
    }

    var body: some View {
        let colors = Color.component.beltSelectButton.belt
        RoundedRectangle(cornerRadius: 2)
            .fill(fill)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(belt == .black ? colors.blackRankBar : colors.rankBar)
                    .frame(height: 7)
                    .padding(.bottom, 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay {
                // 흰 띠는 카드 바탕에 묻혀 띠 선택 버튼과 같은 옅은 테두리를 두른다.
                if belt == .white {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(colors.whiteEdge, lineWidth: 1)
                }
            }
            .frame(width: 8, height: 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(belt.displayName) 띠")
    }
}

// MARK: - CompetitionRowView

/// 대회 한 줄 — 왼쪽에 띠, 가운데에 대회 이름과 그 아래 약한 부가 정보 한 줄(종목·체급 · 연도), 오른쪽에 메달.
/// 고정한 줄은 맨 위에 두고 이름을 굵게 해서 알린다.
///
/// 내 프로필에서는 › 가 붙은 줄이 부문 하나다 — 누르면 그 부문 수정이 맨 위에 있는 시트(고정 · 부문 추가 · 순서 바꾸기 · 삭제)를 띄운다.
/// 부문이 하나면 대회 줄이 곧 부문 줄이고, 여럿이면 대회 줄을 눌러 펼친 뒤 부문 줄을 누른다.
/// 줄 끝 표시는 › 하나만 둔다 — ›와 ···를 함께 두면 어느 쪽을 누를지 헷갈린다.
/// 예전에는 부문 하나인 줄은 시트를, 여럿인 줄은 펼치기만 해서 부문을 어디서 고치는지 찾기 어려웠다.
/// 남의 프로필처럼 읽기만 하는 곳은 두 동작을 비워 둔다 — 부문이 여럿인 줄의 펼치기만 남는다.
struct CompetitionRowView: View {
    let group: CompetitionGroup
    /// 고정 묶음 다음 첫 줄 — 위에 여백을 둬 두 묶음을 가른다.
    var startsPlainBlock = false
    /// › 줄(부문 하나)을 누름
    var onEntryTapped: ((Competition) -> Void)?
    /// 순서 바꾸기 중 — › 대신 끄는 손잡이(≡)를 보여 준다. 누르는 동작은 받지 않는다.
    var isReordering = false

    // 펼침은 화면 표시용 일시 상태라 저장하지 않는다.
    @State private var isExpanded = false
    @Namespace private var medalNamespace

    private enum Metrics {
        static let medalSize: CGFloat = 22
        /// 부문 줄의 글자를 대회 이름과 같은 세로줄에 맞추는 들여쓰기(띠 8 + 띠 뒤 여백 4 + 간격 8)
        static let divisionIndent: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        /// 줄 끝 ›·≡ 크기 — 모든 줄이 같은 세로줄에 둔다.
        static let indicatorSize: CGFloat = 12
    }

    private var hasDivisions: Bool { group.entries.count > 1 }
    /// 고칠 수 있는 줄(내 프로필) — 줄 끝 › 자리를 둔다.
    private var isEditable: Bool { onEntryTapped != nil || isReordering }

    /// 펼쳤을 때의 부문 — 접은 줄의 메달과 같은 금·은·동 순서
    private var sortedEntries: [Competition] {
        group.entries.enumerated()
            .sorted { lhs, rhs in
                let (left, right) = (lhs.element.competitionRank.medalOrder, rhs.element.competitionRank.medalOrder)
                return left == right ? lhs.offset < rhs.offset : left < right
            }
            .map(\.element)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(sortedEntries.enumerated()), id: \.offset) { index, entry in
                        divisionRow(entry, index: index)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .padding(.top, startsPlainBlock ? 12 : 0)
        // 옮기는 동안에는 펼친 부문을 접어 줄 높이를 고르게 한다.
        .onChange(of: isReordering) { _, reordering in
            if reordering { isExpanded = false }
        }
        // 줄의 빈 곳까지 눌리는 영역에 넣는다 — 이름과 메달 사이 빈 곳을 눌러도 반응하게.
        .contentShape(Rectangle())
        // 펼치는 동안 부문 줄이 아래 대회 줄과 겹쳐 보이지 않게 줄 높이만큼만 보여 준다.
        .clipped()
    }

    @ViewBuilder
    private var header: some View {
        if hasDivisions && !isReordering {
            Button(action: toggleExpanded) {
                headerContent
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "펼침" : "접힘")
        } else if let entry = group.entries.first, let onEntryTapped, !isReordering {
            Button { onEntryTapped(entry) } label: {
                headerContent
            }
            .buttonStyle(.plain)
        } else {
            // 버튼이 없으면 이름·부가 정보·메달이 따로 읽히므로 한 덩어리로 묶는다.
            headerContent
                .accessibilityElement(children: .combine)
        }
    }

    private func toggleExpanded() {
        withAnimation(.easeInOut(duration: 0.5)) { isExpanded.toggle() }
    }

    /// 줄 끝 표시 — 고칠 수 있는 부문 줄은 ›, 순서 바꾸기 중에는 ≡, 펼치는 줄은 자리만 비운다.
    @ViewBuilder
    private func trailingIndicator(isEntry: Bool) -> some View {
        Group {
            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .scaledToFit()
            } else {
                Assets.Common.Icon.chevronRight.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .opacity(isEntry ? 1 : 0)
            }
        }
        .frame(width: Metrics.indicatorSize, height: Metrics.indicatorSize)
        .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
        .accessibilityHidden(true)
    }

    private var headerContent: some View {
        HStack(spacing: 8) {
            // 띠를 안 적은 줄도 띠 자리를 비워 대회 이름이 같은 세로줄에서 시작하게 한다.
            Group {
                if let belt = group.topBelt {
                    CompetitionBeltMark(belt: belt)
                } else {
                    Color.clear.frame(width: 8, height: 24)
                }
            }
            .padding(.trailing, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(group.isPinned ? .pretendard.custom(weight: .semiBold, size: 16) : .pretendard.bodyM)
                    .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                    .lineLimit(1)
                    .accessibilityLabel(group.isPinned ? "\(group.name), 고정됨" : group.name)

                HStack(spacing: 2) {
                    Text(group.rowDetailText)
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                        .lineLimit(1)

                    if hasDivisions {
                        Assets.Common.Icon.chevronRight.swiftUIImage
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                            .rotationEffect(.degrees(isExpanded ? -90 : 90))
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isExpanded {
                CompetitionMedalCluster(medals: group.displayedMedals, namespace: medalNamespace)
            }

            if isEditable {
                trailingIndicator(isEntry: !hasDivisions || isReordering)
            }
        }
        // 줄 안 간격(2)보다 줄 사이 간격(8 + 8)을 크게 둬, 이름과 부가 정보가 한 덩어리로 읽히게 한다.
        .padding(.vertical, 8)
        .padding(.horizontal, Metrics.horizontalPadding)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func divisionRow(_ entry: Competition, index: Int) -> some View {
        if let onEntryTapped, !isReordering {
            Button { onEntryTapped(entry) } label: {
                divisionContent(entry, index: index)
            }
            .buttonStyle(.plain)
        } else {
            divisionContent(entry, index: index)
                .accessibilityElement(children: .combine)
        }
    }

    private func divisionContent(_ entry: Competition, index: Int) -> some View {
        HStack(spacing: 8) {
            Text(group.divisionLineText(of: entry))
                .font(.pretendard.bodyS)
                .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            entry.competitionRank.medalImage
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.medalSize, height: Metrics.medalSize)
                .accessibilityLabel(entry.competitionRank.displayName)
                .matchedGeometryEffect(id: index, in: medalNamespace)

            if isEditable {
                trailingIndicator(isEntry: !isReordering)
                    .opacity(isReordering ? 0 : 1)
            }
        }
        // 누르는 줄이면 손가락에 걸리게 위아래를 넓힌다(읽기만 하는 곳은 예전처럼 촘촘히).
        .padding(.vertical, isEditable ? 6 : 2)
        .padding(.leading, Metrics.horizontalPadding + Metrics.divisionIndent)
        .padding(.trailing, Metrics.horizontalPadding)
        .contentShape(Rectangle())
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
                    .frame(width: 22)

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
            .padding(.horizontal, 16)
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
                competitionWeightLimit: .under(kg: 76),
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
        medalCount: MedalCount(gold: 1, silver: 2, bronze: 1),
        onAddCompetitionTapped: { },
        onDivisionTapped: { _, _ in }
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
        medalCount: MedalCount(gold: 1, silver: 1, bronze: 1),
        onAddCompetitionTapped: { },
        onDivisionTapped: { _, _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 정보 없음") {
    MyProfileCompetitionSection(
        competitions: nil,
        onAddCompetitionTapped: { },
        onDivisionTapped: { _, _ in }
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("MyProfileCompetitionSection - 빈 배열") {
    MyProfileCompetitionSection(
        competitions: [],
        onAddCompetitionTapped: { },
        onDivisionTapped: { _, _ in }
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
        onDivisionTapped: { _, _ in },
        pendingGroups: .constant(nil)
    )
    .padding()
    .background(Color.component.background.default)
}
