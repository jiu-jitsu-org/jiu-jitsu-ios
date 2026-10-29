//
//  CompetitionActionSheetView.swift
//  Presentation
//

import SwiftUI
import Domain
import DesignSystem

/// 프로필 대회 줄(또는 ⋯)을 눌렀을 때의 시트 — 맨 위 고정(#124), 부문 수정, 부문 추가, 대회 삭제(#123).
///
/// 프로필 사진 수정 시트(ProfileImageEditView)와 같은 모양(손잡이 · 제목 · 행 · 취소)을 쓴다.
struct CompetitionActionSheetView: View {
    let entries: [Competition]
    let onPinToggled: () -> Void
    let onDivisionTapped: (Competition) -> Void
    let onAddDivisionTapped: () -> Void
    let onDeleteTapped: () -> Void
    let onCancelTapped: () -> Void

    private enum Metrics {
        static let horizontalPadding: CGFloat = 20
        static let rowCornerRadius: CGFloat = 10
        static let rowHeight: CGFloat = 51
        static let rowSpacing: CGFloat = 8
        static let leadingIconSize: CGFloat = 18
        // 작은 화면(SE, 667pt)에서도 상태바 아래로 들어오는 높이 — 부문 4개(행 7개)까지는 스크롤 없이 다 보인다.
        static let maxContentHeight: CGFloat = 630
    }

    /// 바텀 시트 detent용 본문 높이(safe area 미포함).
    /// 24(handle) + 48(title) + 16+20(optionsTop) + rows + 20(optionsBottom) + 8+51+24(CTA)
    /// 부문이 많으면 maxContentHeight에서 멈추고 행 목록이 스크롤된다.
    static func contentHeight(divisionCount: Int) -> CGFloat {
        let rowCount = CGFloat(divisionCount + 3)
        let rows = Metrics.rowHeight * rowCount + Metrics.rowSpacing * (rowCount - 1)
        return min(24 + 48 + 16 + 20 + rows + 20 + 8 + 51 + 24, Metrics.maxContentHeight)
    }

    private var group: CompetitionGroup? {
        CompetitionGroup.grouped(entries).first
    }

    var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            // 부문이 많아 시트 높이 상한에 걸리면 행 목록만 스크롤한다(취소 버튼은 늘 보인다).
            ScrollView {
                optionsSection
            }
            .scrollBounceBehavior(.basedOnSize)
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
            }

            // 부문마다 한 행 — 누르면 그 부문을 고친다.
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                optionRow(
                    title: group?.divisionLineText(of: entry) ?? entry.divisionResultText,
                    showsChevron: true,
                    action: { onDivisionTapped(entry) }
                ) {
                    entry.competitionRank.medalImage
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(entry.competitionRank.displayName)
                }
            }

            optionRow(title: "부문 추가", showsChevron: true, action: onAddDivisionTapped) {
                Assets.Common.Icon.plus.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.component.bottomSheet.selected.listItem.leadingIcon)
            }

            // 휴지통 아이콘이 kit에 없어 자리만 둔다 — 글자는 다른 행과 같은 줄에 선다.
            optionRow(title: "삭제", showsChevron: false, action: onDeleteTapped) {
                Color.clear
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
                    .font(Font.pretendard.bodyS)
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
        CTAButton(title: "취소", action: onCancelTapped)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview("여러 부문") {
    CompetitionActionSheetView(
        entries: [
            Competition(competitionYear: 2026, competitionName: "서울 오픈", competitionRank: .silver,
                        competitionUniform: .gi, competitionWeightClass: .under76, competitionBelt: .brown),
            Competition(competitionYear: 2026, competitionName: "서울 오픈", competitionRank: .gold,
                        competitionUniform: .gi, competitionWeightClass: .absolute, competitionBelt: .brown)
        ],
        onPinToggled: { },
        onDivisionTapped: { _ in },
        onAddDivisionTapped: { },
        onDeleteTapped: { },
        onCancelTapped: { }
    )
}
