//
//  MyProfileCompetitionComponents.swift
//  Presentation
//
//  Created by suni on 3/21/26.
//

import SwiftUI
import UniformTypeIdentifiers
import DesignSystem
import Domain

// MARK: - MyProfileCompetitionSection

/// 대회 정보 섹션
public struct MyProfileCompetitionSection: View {
    let competitions: [Competition]?
    let onAddCompetitionTapped: () -> Void
    let onCompetitionDetailTapped: (Competition) -> Void
    /// 묶인 한 줄의 부문들을 넘긴다 — 고정할지 풀지, 개수 제한은 부모(MyProfileFeature)가 판단한다.
    var onCompetitionPinToggled: ([Competition]) -> Void = { _ in }
    /// 순서를 바꾸고 '완료' — 순서가 바뀐 묶음(고정한 줄들 / 고정 안 한 줄들)의 줄별 부문들, 위에서부터. 저장은 부모가 한다.
    var onCompetitionsReordered: ([[Competition]]) -> Void = { _ in }
    /// 프로필 저장 중 — 저장 전 목록으로 순서를 바꾸면 앞의 저장을 덮으므로 끌기를 막는다.
    var isSaving: Bool = false

    // 끌어 놓았지만 아직 저장하지 않은 줄 순서. 처음 하나를 옮기면 생기고, '완료'로 저장·'취소'로 처음 순서로 돌린다.
    // 여러 번 옮긴 뒤에도 한 번에 되돌릴 수 있게 놓을 때마다 저장하지 않는다. 화면 표시용 일시 상태라 Feature로 올리지 않는다.
    @State private var pendingGroups: [CompetitionGroup]?

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 타이틀 + 메달 합계 + 추가 버튼
            HStack(spacing: 8) {
                Text("대회 정보")
                    .font(.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)

                CompetitionMedalSummaryView(competitions: competitions ?? [])

                Spacer()

                // 순서를 옮기는 중에는 추가 대신 취소·완료 — 끝내는 자리를 눈 가는 머리줄 오른쪽에 둔다.
                if pendingGroups != nil {
                    HStack(spacing: 16) {
                        Button("취소") {
                            withAnimation(.easeInOut(duration: 0.5)) { pendingGroups = nil }
                        }
                        .foregroundStyle(Color.component.sectionHeader.subTitle)

                        Button("완료") { finishReordering() }
                            .foregroundStyle(Color.component.button.ghost.defaultText)
                            .opacity(isSaving ? 0.3 : 1)
                            .disabled(isSaving)
                    }
                    .font(.pretendard.buttonS)
                    .buttonStyle(.plain)
                    .frame(height: 32)
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
                    onCompetitionDetailTapped: onCompetitionDetailTapped,
                    onCompetitionPinToggled: onCompetitionPinToggled,
                    isSaving: isSaving,
                    pendingGroups: $pendingGroups
                )
            } else {
                EmptyCompetitionView(onAddCompetitionTapped: onAddCompetitionTapped)
            }
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

/// 같은 대회(대회명 + 연도)에서 나간 부문들을 한 줄로 묶은 단위(#123).
///
/// 서버는 아직 '대회 1개 = 메달 1개' 목록만 저장하므로(backend #164 전), 여러 부문은 같은 이름·연도로
/// 항목을 여러 개 저장하고 표시할 때만 묶는다.
struct CompetitionGroup {
    /// 맨 위에 고정할 수 있는 줄 수(#124). 많이 고정하면 고정의 의미(대표 기록)가 흐려진다.
    static let maxPinnedCount = 3

    /// 줄 구분값 — 끌어서 옮기는 줄을 알아보는 데 쓴다. 대회명 없는 기록은 하나씩 따로 구분한다.
    let id: String
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

    /// 회원이 끌어서 정한 자리 — 묶인 부문 중 가장 앞 자리. 정한 적 없으면 nil.
    var displayOrder: Int? {
        entries.compactMap(\.displayOrder).min()
    }

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

    /// 같은 대회명(앞뒤 공백 무시) + 연도끼리 묶어, 고정한 줄을 맨 위에 두고 그 아래 고정 안 한 줄을 둔다.
    /// - 고정한 줄: 자리 순. 새로 고정한 줄이 맨 위(자리 0)로 들어가고, 회원이 끌어서 바꿀 수 있다.
    /// - 고정 안 한 줄: 연도 최신순이 기본. 회원이 끌어서 정한 자리가 있으면 그 순서를 지키고,
    ///   자리를 정한 적 없는 기록(새로 입력한 기록 등)은 그 사이 연도에 맞는 자리(처음 나오는 더 오래된 줄 앞)로 들어간다.
    /// 같은 연도끼리는 처음 입력한 순서를 지킨다(월은 더 받지 않으므로).
    /// 대회명 없는 기록은 같은 대회인지 알 수 없어 하나씩 따로 둔다.
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
                name: competition.competitionName.trimmingCharacters(in: .whitespacesAndNewlines),
                year: competition.competitionYear,
                namelessIndex: competition.isNameless ? index : nil
            )
            if entriesByKey[key] == nil {
                order.append(key)
            }
            entriesByKey[key, default: []].append(competition)
        }
        let groups = order.enumerated().map { inputIndex, key in
            (
                inputIndex: inputIndex,
                group: CompetitionGroup(
                    id: key.namelessIndex.map { "nameless|\($0)" } ?? "\(key.year)|\(key.name)",
                    name: key.name,
                    year: key.year,
                    entries: entriesByKey[key] ?? []
                )
            )
        }
        typealias Indexed = (inputIndex: Int, group: CompetitionGroup)
        let newestYearFirst: (Indexed, Indexed) -> Bool = { lhs, rhs in
            lhs.group.year != rhs.group.year ? lhs.group.year > rhs.group.year : lhs.inputIndex < rhs.inputIndex
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
                return newestYearFirst(lhs, rhs)
            }
        }

        let unpinned = groups.filter { !$0.group.isPinned }
        var placed = unpinned
            .filter { $0.group.displayOrder != nil }
            .sorted { ($0.group.displayOrder ?? 0, $0.inputIndex) < ($1.group.displayOrder ?? 0, $1.inputIndex) }
            .map(\.group)
        for item in unpinned.filter({ $0.group.displayOrder == nil }).sorted(by: newestYearFirst) {
            let index = placed.firstIndex { $0.year < item.group.year } ?? placed.endIndex
            placed.insert(item.group, at: index)
        }
        return pinned.map(\.group) + placed
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
///
/// 줄을 길게 눌러 끌면 순서를 바꾼다(#124). 처음 하나를 옮기면 머리줄에 취소·완료가 나오고, 완료를 눌러야 저장한다.
/// 고정한 줄은 고정한 줄끼리,
/// 고정 안 한 줄은 고정 안 한 줄끼리만 자리를 바꾼다 — 고정 안 한 줄을 고정 자리로 올리려면 '맨 위에 고정'을 쓴다.
/// 길게 누르기는 끌기에만 쓴다 — 고정·해제는 ⋯ 에만 둔다(같은 메뉴를 두 곳에 두지 않고, 시스템 메뉴도 띄우지 않는다).
private struct CompetitionListView: View {
    let competitions: [Competition]
    let onCompetitionDetailTapped: (Competition) -> Void
    var onCompetitionPinToggled: ([Competition]) -> Void = { _ in }
    var isSaving: Bool = false
    /// 끌어 놓았지만 아직 저장하지 않은 순서(섹션이 갖고 취소·완료를 받는다)
    @Binding var pendingGroups: [CompetitionGroup]?

    // 여러 부문이 묶인 줄을 눌렀을 때 고칠 부문을 묻는 선택지. 화면 표시용 일시 상태라 Feature로 올리지 않고,
    // 고른 결과만 기존 콜백(수정 진입)으로 보낸다.
    @State private var groupPendingSelection: CompetitionGroup?

    // 끄는 동안의 줄 순서(손가락을 따라 바로 바뀜)와 끄는 줄. 놓으면 pendingGroups로 넘기고 비운다.
    @State private var liveGroups: [CompetitionGroup]?
    @State private var draggingID: String?
    @State private var rowHeights: [String: CGFloat] = [:]

    private enum Metrics {
        static let rowSpacing: CGFloat = 4
    }

    private var groups: [CompetitionGroup] { CompetitionGroup.grouped(competitions) }
    /// 끌기를 시작할 때의 순서 — 앞서 옮겨 둔 순서가 있으면 그것부터
    private var baseGroups: [CompetitionGroup] { pendingGroups ?? groups }

    /// 같은 묶음(고정/고정 안 함) 안에서 한 칸 옮겨 '저장 전 순서'로 남긴다.
    private func moveByOne(_ group: CompetitionGroup, offset: Int) {
        var order = baseGroups
        guard let from = order.firstIndex(where: { $0.id == group.id }) else { return }
        let to = from + offset
        guard order.indices.contains(to), order[to].isPinned == group.isPinned, !isSaving else { return }
        order.swapAt(from, to)
        withAnimation(.easeInOut(duration: 0.2)) { pendingGroups = order }
    }

    var body: some View {
        VStack(spacing: Metrics.rowSpacing) {
            ForEach(liveGroups ?? baseGroups, id: \.id) { group in
                CompetitionRowView(
                    group: group,
                    // 순서를 옮기는 중에는 수정·고정으로 들어가지 않는다(저장 안 한 순서를 잃지 않게).
                    isInteractionDisabled: pendingGroups != nil,
                    onTapped: {
                        guard pendingGroups == nil else { return }
                        if group.entries.count == 1, let entry = group.entries.first {
                            onCompetitionDetailTapped(entry)
                        } else {
                            groupPendingSelection = group
                        }
                    },
                    onPinToggled: { onCompetitionPinToggled(group.entries) }
                )
                // 끄는 동안 원래 자리는 옅게 남겨 어디로 들어갈지 보이게 한다.
                .opacity(liveGroups != nil && draggingID == group.id ? 0.3 : 1)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowHeights[group.id] = $0 }
                // 끌 수 없는 VoiceOver 사용자도 같은 묶음 안에서 한 칸씩 옮길 수 있게 한다.
                .accessibilityAction(named: "위로 이동") { moveByOne(group, offset: -1) }
                .accessibilityAction(named: "아래로 이동") { moveByOne(group, offset: 1) }
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 14))
                .onDrag {
                    draggingID = group.id
                    return CompetitionDropDelegate.itemProvider(for: group)
                }
            }
        }
        .onDrop(of: [CompetitionDropDelegate.rowType], delegate: CompetitionDropDelegate(
            groups: baseGroups,
            isSaving: isSaving,
            rowHeights: rowHeights,
            rowSpacing: Metrics.rowSpacing,
            liveGroups: $liveGroups,
            draggingID: $draggingID,
            pendingGroups: $pendingGroups
        ))
        .padding(.vertical, 8)
        .background(Color.component.skillCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        // 끌기를 시작·끝낼 때가 아니라 줄이 실제로 자리를 바꿀 때만 울린다.
        .sensoryFeedback(.selection, trigger: liveGroups?.map(\.id)) { old, new in old != nil && new != nil }

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

/// 끄는 줄이 다른 줄의 가운데를 넘으면 그 자리로 옮기고, 놓으면 그 순서를 '저장 전 순서'로 남긴다.
/// 고정한 줄과 고정 안 한 줄은 서로의 자리로 넘어가지 않는다.
private struct CompetitionDropDelegate: DropDelegate {
    /// 이 앱 안에서만 쓰는 끌기 형식 — 다른 앱의 글을 끌어와도 순서가 바뀌지 않고, 줄을 다른 앱에 놓아도 내부 값이 붙여지지 않는다.
    static let rowType = UTType(importedAs: "com.jiujitsulab.connect.competition-row")

    static func itemProvider(for group: CompetitionGroup) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: rowType.identifier, visibility: .ownProcess) { completion in
            completion(Data(group.id.utf8), nil)
            return nil
        }
        return provider
    }

    let groups: [CompetitionGroup]
    /// 프로필 저장 중 — 저장 전 목록으로 순서를 바꾸면 앞의 저장을 덮으므로 놓기를 받지 않는다.
    let isSaving: Bool
    let rowHeights: [String: CGFloat]
    let rowSpacing: CGFloat
    @Binding var liveGroups: [CompetitionGroup]?
    @Binding var draggingID: String?
    @Binding var pendingGroups: [CompetitionGroup]?

    func validateDrop(info: DropInfo) -> Bool {
        draggingID != nil && !isSaving && info.hasItemsConforming(to: [Self.rowType])
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        if liveGroups == nil { liveGroups = groups }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        moveDraggedRow(toward: info.location.y)
        return DropProposal(operation: .move)
    }

    /// 카드 밖으로 끌고 나가면 바꾸던 순서를 되돌린다(밖에 놓으면 취소).
    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) { liveGroups = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            liveGroups = nil
            draggingID = nil
        }
        guard let live = liveGroups else { return false }
        if live.map(\.id) != groups.map(\.id) {
            pendingGroups = live
        }
        return true
    }

    private func moveDraggedRow(toward y: CGFloat) {
        guard var live = liveGroups,
              let from = live.firstIndex(where: { $0.id == draggingID }) else { return }
        var top: CGFloat = 0
        for (index, group) in live.enumerated() {
            let height = rowHeights[group.id] ?? 0
            defer { top += height + rowSpacing }
            guard y >= top, y < top + height + rowSpacing, index != from else { continue }
            // 고정한 줄과 고정 안 한 줄은 서로의 자리로 옮기지 않는다.
            guard group.isPinned == live[from].isPinned else { return }
            // 옆 줄의 가운데를 넘어야 옮긴다 — 키가 다른 줄끼리 바뀐 직후 되돌아 바뀌며 떨리지 않게.
            let middle = top + height / 2
            guard index > from ? y > middle : y < middle else { return }
            let moving = live.remove(at: from)
            live.insert(moving, at: index)
            withAnimation(.easeInOut(duration: 0.2)) { liveGroups = live }
            return
        }
    }
}

// MARK: - CompetitionRowView

/// 대회 한 줄 — 같은 대회의 여러 부문은 한 줄에 묶어 보여 준다.
///
/// 줄을 누르면 수정으로 들어가므로, 고정은 오른쪽 ⋯ 메뉴로 따로 둔다(#124).
/// 길게 눌러 끌면 순서를 바꾼다(CompetitionListView).
private struct CompetitionRowView: View {
    let group: CompetitionGroup
    /// 순서를 옮기는 중 — ⋯ 을 막는다(줄 탭은 목록이 무시한다. 버튼을 막으면 끌기까지 막힐 수 있어서).
    var isInteractionDisabled = false
    let onTapped: () -> Void
    var onPinToggled: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
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
                        if group.isNameless {
                            namelessTitle
                        } else {
                            // 고정 표시는 이름 뒤에 옅은 회색으로 — 대회 이름보다 눈에 띄지 않게 한다.
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

                        // 부문이 많으면 줄을 넘겨 다 보여 준다(잘리면 어떤 메달인지 알 수 없음).
                        Text(group.detailText)
                            .font(.pretendard.labelM)
                            .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)

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

            // 나만 보는 기록은 대표 기록(고정)으로 내세울 수 없어 메뉴를 두지 않는다.
            if group.isNameless {
                Spacer().frame(width: 16)
            } else {
                menuButton
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
        Menu {
            menuItems
        } label: {
            Assets.MyProfile.Icon.menu.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("\(group.name) 더보기")
        .disabled(isInteractionDisabled)
        .opacity(isInteractionDisabled ? 0.3 : 1)
        .padding(.trailing, 4)
    }

    @ViewBuilder
    private var menuItems: some View {
        Button {
            onPinToggled()
        } label: {
            Text(group.isPinned ? "고정 해제" : "맨 위에 고정")
        }
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

#Preview("MyProfileCompetitionSection - 맨 위 고정") {
    MyProfileCompetitionSection(
        competitions: [
            Competition(competitionYear: 2026, competitionName: "2026 서울 오픈", competitionRank: .silver),
            // 오래된 대회라도 고정하면 최신 대회보다 위에 온다.
            Competition(competitionYear: 2022, competitionName: "2022 아시안 오픈", competitionRank: .gold, isPinned: true),
            Competition(competitionYear: 2024, competitionName: "2024 부산 오픈", competitionRank: .bronze)
        ],
        onAddCompetitionTapped: { },
        onCompetitionDetailTapped: { _ in }
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
        onCompetitionDetailTapped: { _ in },
        pendingGroups: .constant(nil)
    )
    .padding()
    .background(Color.component.background.default)
}
