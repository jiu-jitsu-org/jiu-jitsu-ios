#if DEBUG || BETA
//
//  SheetDocs.swift
//  DesignSystem
//
//  부품 — 바텀시트 · 고르기 시트 · 약관 동의 줄. 실제 customBottomSheet·SelectSheetView·TermsAgreementRow 로 그린다.
//

import SwiftUI

// MARK: - 바텀시트

struct BottomSheetDoc: View {
    @State private var isPresented = false

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "바텀시트",
            summary: "아래에서 올라오는 시트 틀. 내용은 부르는 쪽이 넣는다. 시스템 sheet 대신 우리 모양(위 모서리 24·끌어서 닫기)을 쓴다.",
            chips: ["앱 화면 쓰는 곳 0", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "눌러서 띄운다. 아래로 끌거나 어두운 막을 누르면 닫힌다.") {
                CatalogPlate {
                    Button {
                        isPresented = true
                    } label: {
                        AppButtonConfiguration(title: "바텀시트 열기", size: .medium)
                    }
                    .appButtonStyle(.primary, size: .medium, height: 44)
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "어두운 막 — component.bottomSheet.selected.container.scrim",
                    "시트 — container.background, 위 모서리 24",
                    "내용 — customBottomSheet { } 에 넣은 View. 손잡이·제목은 틀에 없어 내용 쪽에서 그린다",
                    "아래 여백 — 안전 영역만큼 시트 색으로 채운다"
                ])
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "바텀시트", role: "아무 내용이나 담는 빈 틀"),
                    (token: "고르기 시트", role: "목록 하나 고르고 보내기까지 들어 있는 완성 시트"),
                    (token: "알림창", role: "짧은 확인만 받을 때")
                ])
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(colors: [
                    CatalogColorSpec(token: "component.bottomSheet.selected.container.scrim", role: "어두운 막", color: Color.component.bottomSheet.selected.container.scrim),
                    CatalogColorSpec(token: "component.bottomSheet.selected.container.background", role: "시트", color: Color.component.bottomSheet.selected.container.background),
                    CatalogColorSpec(token: "component.bottomSheet.selected.container.handle", role: "손잡이(내용 쪽에서 그릴 때)", color: Color.component.bottomSheet.selected.container.handle),
                    CatalogColorSpec(token: "component.bottomSheet.selected.container.title", role: "제목(내용 쪽에서 그릴 때)", color: Color.component.bottomSheet.selected.container.title)
                ])
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "메뉴·선택지는 iOS 기본 모달(confirmationDialog 등) 대신 프로필 사진 수정 시트 모양의 우리 시트로 띄운다. 이 틀은 지금 앱 화면에서 쓰는 곳이 없고, 신고 사유 고르기는 고르기 시트를 쓴다."
            )
        }
        .customBottomSheet(isPresented: $isPresented) {
            VStack(spacing: 16) {
                Text("시트 내용")
                    .font(.pretendard.title3)
                    .foregroundStyle(Color.component.bottomSheet.selected.container.title)
                CTAButton(title: "닫기", type: .tint) { isPresented = false }
            }
            .padding(20)
        }
    }
}

// MARK: - 고르기 시트

struct SelectSheetDoc: View {
    private let configuration = SelectSheetConfiguration(
        title: "어떤 문제인가요?",
        message: "신고는 익명으로 처리되며, 검토 후 조치돼요.",
        options: [
            .init(value: "ABUSE", label: "욕설 및 비방", allowsCustomText: false),
            .init(value: "SPAM", label: "광고 및 홍보", allowsCustomText: false),
            .init(value: "HARASSMENT", label: "혐오 및 괴롭힘", allowsCustomText: false),
            .init(value: "OTHER", label: "기타", allowsCustomText: true)
        ],
        customTextPlaceholder: "신고할 내용을 입력해주세요.",
        customTextMaxLength: 200,
        submitText: "신고하기"
    )

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "고르기 시트",
            summary: "목록에서 하나를 고르고 보내는 시트. '기타'처럼 직접 쓰는 항목을 고르면 입력칸이 열린다. 어두운 막과 올라오는 움직임은 부르는 쪽이 맡는다.",
            chips: ["쓰는 곳 1(신고)", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "판 높이를 화면 높이로 넘겨 그린다. 항목을 눌러 본다.") {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Color.component.bottomSheet.selected.container.scrim
                        SelectSheetView(
                            configuration: configuration,
                            screen: SelectSheetScreenMetrics(height: geometry.size.height, topInset: 0, bottomInset: 0),
                            onSubmit: { _, _ in },
                            onDismiss: {}
                        )
                    }
                }
                .frame(height: 560)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "손잡이 · 제목(title2) · 설명(labelM)",
                    "항목 줄 — 라디오 + 글자, 고르면 라디오가 켜진다",
                    "직접 쓰기 칸 — allowsCustomText 항목을 고르면 열린다(customTextMaxLength 까지)",
                    "보내기 — 버튼 부품 primary·large, 고르기 전에는 비활성"
                ])
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "고르기 시트", role: "순서 없는 항목 중 하나를 골라 보냄"),
                    (token: "시트 피커", role: "차례가 있는 값을 굴려 고름"),
                    (token: "바텀시트", role: "내용을 직접 채우는 빈 틀")
                ])
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "항목 글자는 짧은 명사구로, 마지막에 '기타'를 두고 직접 쓰게 한다.",
                    badText: "고를 것이 둘뿐이면 시트 대신 세그먼트나 알림창을 쓴다."
                ) {
                    Text("욕설 및 비방 · 광고 및 홍보 · 기타")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                } bad: {
                    Text("예 · 아니오")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(colors: [
                    CatalogColorSpec(token: "component.bottomSheet.selected.listItem.leadingIcon", role: "고른 항목 · 라디오", color: Color.component.bottomSheet.selected.listItem.leadingIcon),
                    CatalogColorSpec(token: "component.bottomSheet.selected.listItem.label", role: "고른 항목 · 글자", color: Color.component.bottomSheet.selected.listItem.label),
                    CatalogColorSpec(token: "component.bottomSheet.unselected.listItem.leadingIcon", role: "안 고른 항목 · 라디오", color: Color.component.bottomSheet.unselected.listItem.leadingIcon),
                    CatalogColorSpec(token: "component.bottomSheet.unselected.listItem.label", role: "안 고른 항목 · 글자", color: Color.component.bottomSheet.unselected.listItem.label)
                ])
            }
        }
    }
}

// MARK: - 약관 동의 줄

struct TermsRowDoc: View {
    @State private var checked = [true, false]

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "약관 동의 줄",
            summary: "약관 시트에서 한 줄씩 체크하는 줄. 왼쪽 체크, 가운데 약관 이름과 (필수)·(선택), 오른쪽 '보기'.",
            chips: ["쓰는 곳 1(약관 동의)", "상태 2", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "눌러서 체크해 본다.") {
                CatalogPlate {
                    VStack(spacing: 4) {
                        row(index: 0, title: "서비스 이용약관", type: "(필수)", typeColor: Color.component.bottomSheet.selected.listItem.labelRequired)
                        row(index: 1, title: "마케팅 정보 수신", type: "(선택)", typeColor: Color.component.bottomSheet.selected.listItem.labelOptional)
                    }
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "체크 — 켜면 파랑, 끄면 회색",
                    "약관 이름 + (필수)·(선택) — 종류 글자 색은 부르는 쪽이 준다",
                    "보기 화살표 — 약관 주소가 있을 때만(showsSeeDetails)"
                ])
            }

            CatalogSection(title: "상태") {
                CatalogPlate {
                    VStack(spacing: 4) {
                        TermsAgreementRow(
                            title: "체크함", typeText: "(필수)", isChecked: true,
                            leadingIconColor: .clear, labelColor: .clear,
                            typeTextColor: Color.component.bottomSheet.selected.listItem.labelRequired,
                            followingIconColor: .clear, onCheckTapped: {}, onSeeDetailsTapped: {}
                        )
                        TermsAgreementRow(
                            title: "체크 안 함 · 보기 없음", typeText: "(선택)", isChecked: false,
                            leadingIconColor: .clear, labelColor: .clear,
                            typeTextColor: Color.component.bottomSheet.unselected.listItem.labelOptional,
                            followingIconColor: .clear, showsSeeDetails: false, onCheckTapped: {}, onSeeDetailsTapped: {}
                        )
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "(필수)·(선택)을 이름 바로 뒤에 붙여 한 줄에서 읽히게 한다.",
                    badText: "필수 약관을 미리 체크해 두지 않는다. 사용자가 직접 체크한다."
                ) {
                    TermsAgreementRow(
                        title: "서비스 이용약관", typeText: "(필수)", isChecked: false,
                        leadingIconColor: .clear, labelColor: .clear,
                        typeTextColor: Color.component.bottomSheet.selected.listItem.labelRequired,
                        followingIconColor: .clear, onCheckTapped: {}, onSeeDetailsTapped: {}
                    )
                } bad: {
                    TermsAgreementRow(
                        title: "서비스 이용약관", typeText: "(필수)", isChecked: true,
                        leadingIconColor: .clear, labelColor: .clear,
                        typeTextColor: Color.component.bottomSheet.selected.listItem.labelRequired,
                        followingIconColor: .clear, onCheckTapped: {}, onSeeDetailsTapped: {}
                    )
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(colors: [
                    CatalogColorSpec(token: "component.bottomSheet.selected.listItem.leadingIcon", role: "체크 · 켬", color: Color.component.bottomSheet.selected.listItem.leadingIcon),
                    CatalogColorSpec(token: "component.bottomSheet.unselected.listItem.leadingIcon", role: "체크 · 끔", color: Color.component.bottomSheet.unselected.listItem.leadingIcon),
                    CatalogColorSpec(token: "component.bottomSheet.selected.listItem.labelRequired", role: "(필수)", color: Color.component.bottomSheet.selected.listItem.labelRequired),
                    CatalogColorSpec(token: "component.bottomSheet.selected.listItem.labelOptional", role: "(선택)", color: Color.component.bottomSheet.selected.listItem.labelOptional),
                    CatalogColorSpec(token: "component.bottomSheet.selected.listItem.followingIcon", role: "보기 화살표", color: Color.component.bottomSheet.selected.listItem.followingIcon)
                ])
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "init 에 색 넷(leadingIconColor·labelColor·typeTextColor·followingIconColor)을 받지만 실제로 쓰는 것은 typeTextColor 하나다. 나머지는 체크 상태에 따라 component.bottomSheet.(un)selected.listItem 에서 고른다."
            )
        }
    }

    private func row(index: Int, title: String, type: String, typeColor: Color) -> some View {
        TermsAgreementRow(
            title: title,
            typeText: type,
            isChecked: checked[index],
            leadingIconColor: .clear,
            labelColor: .clear,
            typeTextColor: typeColor,
            followingIconColor: .clear,
            onCheckTapped: { checked[index].toggle() },
            onSeeDetailsTapped: {}
        )
    }
}

#Preview("바텀시트") {
    NavigationStack { BottomSheetDoc() }
}

#Preview("고르기 시트") {
    NavigationStack { SelectSheetDoc() }
}

#Preview("약관 동의 줄") {
    NavigationStack { TermsRowDoc() }
}

#endif
