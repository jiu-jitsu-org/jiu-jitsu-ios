//
//  CompetitionActionSheetView.swift
//  Presentation
//

import SwiftUI
import Domain
import DesignSystem

/// 프로필 대회 기록의 › 줄(부문 하나)을 눌렀을 때의 시트 — 누른 부문 수정, 맨 위 고정(#124), 부문 추가, 순서 바꾸기, 대회 삭제(#123).
/// 고치기를 맨 위에 둬 눌러서 바로 찾게 하고, 대회 단위 일은 그 아래에 둔다.
///
/// 프로필 사진 수정 시트(ProfileImageEditView)와 같은 모양(손잡이 · 제목 · 행 · 취소)을 쓴다.
struct CompetitionActionSheetView: View {
    /// 누른 부문
    let entry: Competition
    /// 그 대회의 부문들
    let entries: [Competition]
    let onEditTapped: () -> Void
    let onPinToggled: () -> Void
    let onAddDivisionTapped: () -> Void
    /// 대회가 둘 이상일 때만 — 하나면 옮길 곳이 없어 행을 숨긴다.
    var onReorderTapped: (() -> Void)?
    let onDeleteTapped: () -> Void
    let onCancelTapped: () -> Void

    private enum Metrics {
        static let horizontalPadding: CGFloat = 20
        static let rowCornerRadius: CGFloat = 10
        static let rowHeight: CGFloat = 51
        static let rowSpacing: CGFloat = 8
        static let leadingIconSize: CGFloat = 18
    }

    /// 바텀 시트 detent용 본문 높이(safe area 미포함).
    /// 24(handle) + 48(title) + 16+20(optionsTop) + rows + 20(optionsBottom) + 8+51+24(CTA)
    static func contentHeight(showsReorder: Bool) -> CGFloat {
        let rowCount: CGFloat = showsReorder ? 5 : 4
        let rows = Metrics.rowHeight * rowCount + Metrics.rowSpacing * (rowCount - 1)
        return 24 + 48 + 16 + 20 + rows + 20 + 8 + 51 + 24
    }

    private var group: CompetitionGroup? {
        CompetitionGroup.grouped(entries).first
    }

    var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            optionsSection
                .padding(.top, 16)
            cancelButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
    }

    // MARK: - View Components

    private var handleBar: some View {
        Capsule()
            .fill(Color.component.bottomSheet.selected.container.handle)
            .frame(width: 48, height: 4)
            .frame(maxWidth: .infinity)
            .frame(height: 24)
    }

    private var titleSection: some View {
        VStack {
            Spacer()
            Text(group?.titleWithYear ?? "")
                .font(Font.pretendard.title2)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 48)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private var optionsSection: some View {
        VStack(spacing: Metrics.rowSpacing) {
            // 누른 부문 고치기 — 메달로 어느 부문인지 알린다.
            optionRow(
                title: group?.divisionLineText(of: entry) ?? entry.divisionResultText,
                showsChevron: true,
                action: onEditTapped
            ) {
                entry.competitionRank.medalImage
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(entry.competitionRank.displayName)
            }

            optionRow(
                title: (group?.isPinned ?? false) ? "고정 해제" : "맨 위에 고정",
                showsChevron: false,
                action: onPinToggled
            ) {
                // 프로필 줄의 고정 표시와 같은 압정을 회색으로 — 동작 아이콘(+)보다 한 단계 낮게 둔다.
                Assets.Common.Icon.pin.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.leadingIcon)
                    // 글자와 같은 뜻의 장식이라 화면 읽기에서는 빼고 행 글자만 읽힌다.
                    .accessibilityHidden(true)
            }

            optionRow(title: "부문 추가", showsChevron: true, action: onAddDivisionTapped) {
                Assets.Common.Icon.plus.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.component.bottomSheet.selected.listItem.leadingIcon)
                    // 글자와 같은 뜻의 장식이라 화면 읽기에서는 빼고 행 글자만 읽힌다.
                    .accessibilityHidden(true)
            }

            if let onReorderTapped {
                optionRow(title: "순서 바꾸기", showsChevron: false, action: onReorderTapped) {
                    // 고정·삭제와 같은 회색 — 시트를 닫고 목록에서 이어서 하는 동작이다.
                    Image(systemName: "arrow.up.arrow.down")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.component.bottomSheet.unselected.listItem.leadingIcon)
                        .accessibilityHidden(true)
                }
            }

            optionRow(title: "삭제", showsChevron: false, action: onDeleteTapped) {
                // 고정과 같은 회색 — 파란 아이콘은 이어서 입력하는 동작(부문 추가)에만 쓴다.
                Assets.Common.Icon.trash.swiftUIImage
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.leadingIcon)
                    // 글자와 같은 뜻의 장식이라 화면 읽기에서는 빼고 행 글자만 읽힌다.
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 20)
    }

    private func optionRow<Leading: View>(
        title: String,
        showsChevron: Bool,
        action: @escaping () -> Void,
        @ViewBuilder leading: () -> Leading
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                leading()
                    .frame(width: Metrics.leadingIconSize, height: Metrics.leadingIconSize)

                Text(title)
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.label)

                Spacer()

                if showsChevron {
                    Assets.Common.Icon.chevronRight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.component.bottomSheet.selected.listItem.followingIcon)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.rowHeight)
            .contentShape(RoundedRectangle(cornerRadius: Metrics.rowCornerRadius))
        }
        // 기본 상태는 모두 비선택 — 탭(터치 다운) 동안에만 배경 하이라이트 노출
        .buttonStyle(PressableRowButtonStyle(cornerRadius: Metrics.rowCornerRadius))
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private var cancelButton: some View {
        // 긍정 행동이 아니라 닫기라 파란 면 대신 회색 면
        CTAButton(title: "취소", type: .neutral, action: onCancelTapped)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview("여러 부문") {
    let entries = [
        Competition(competitionYear: 2026, competitionName: "서울 오픈", competitionRank: .silver,
                    competitionUniform: .gi, competitionWeightLimit: .under(kg: 76),
                    competitionBelt: .brown),
        Competition(competitionYear: 2026, competitionName: "서울 오픈", competitionRank: .gold,
                    competitionUniform: .gi, competitionAbsolute: true, competitionBelt: .brown)
    ]
    CompetitionActionSheetView(
        entry: entries[0],
        entries: entries,
        onEditTapped: { },
        onPinToggled: { },
        onAddDivisionTapped: { },
        onReorderTapped: { },
        onDeleteTapped: { },
        onCancelTapped: { }
    )
}
