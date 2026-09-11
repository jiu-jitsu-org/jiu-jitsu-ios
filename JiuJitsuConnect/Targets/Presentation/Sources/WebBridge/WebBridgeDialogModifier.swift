//
//  WebBridgeDialogModifier.swift
//  Presentation
//
//  브릿지가 요청한 확인 알럿(SHOW_CONFIRM_DIALOG) · 선택 시트(SHOW_SELECT_SHEET)를
//  네이티브 표면으로 그리는 공용 프리젠터. 문구·항목은 payload가, 표시 셸은 DesignSystem이 소유한다.
//
//  WHY 공용: 리스트 웹뷰의 다이얼로그는 GNB·하단 탭바까지 덮어야 해 AppTabView(최상위)가 그리고,
//  상세 웹뷰는 이미 풀스크린이라 CommunityDetailView가 로컬로 그린다. 두 진입점이 같은 매핑을
//  쓰도록 한 곳에 모은다. 결과 회신은 각 화면이 payload의 requestId로 자기 outbox에 넣는다.
//

import SwiftUI
import DesignSystem

private struct WebBridgeDialogModifier: ViewModifier {
    let confirmDialog: ConfirmDialogPayload?
    let selectSheet: SelectSheetPayload?
    /// 확인 알럿의 [확인]/[취소] 버튼 탭.
    let onConfirmButton: (ConfirmDialogOutcome) -> Void
    /// 버튼 외 닫힘(바깥 탭·시스템 닫힘). 버튼으로 이미 처리됐으면 호출부가 무시한다.
    let onConfirmDismiss: () -> Void
    /// 선택 시트 제출(선택 value + 자유 입력).
    let onSelectSubmit: (String, String?) -> Void
    /// 선택 시트 제출 없이 닫힘(드래그·딤 탭).
    let onSelectDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .appAlert(
                isPresented: Binding(
                    get: { confirmDialog != nil },
                    set: { if !$0 { onConfirmDismiss() } }
                ),
                configuration: confirmDialog.map(alertConfiguration) ?? Self.placeholderConfiguration
            )
            // 시트도 알럿과 같은 overlay 방식으로 띄운다. customBottomSheet는 대상 뷰 전체를
            // GeometryReader+ignoresSafeArea로 감싸 하단 탭바의 safe-area 레이아웃을 틀어지게 하므로
            // (AppTabView처럼 풀스크린 컨테이너엔 부적합), 콘텐츠 레이아웃을 건드리지 않는 overlay로 그린다.
            .overlay { selectSheetOverlay }
    }

    @ViewBuilder
    private var selectSheetOverlay: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if let selectSheet {
                    Color.component.bottomSheet.selected.container.scrim
                        .ignoresSafeArea()
                        .onTapGesture { onSelectDismiss() }
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        SelectSheetView(
                            configuration: Self.sheetConfiguration(selectSheet),
                            onSubmit: { value, customText in onSelectSubmit(value, customText) }
                        )
                        // 홈 인디케이터 영역까지 시트 배경을 연장한다(회색 갭 방지).
                        Color.component.bottomSheet.selected.container.background
                            .frame(height: geometry.safeAreaInsets.bottom)
                    }
                    .background(Color.component.bottomSheet.selected.container.background)
                    .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                    // 키보드로 시트가 길어져도 상단 safe area(상태바) 아래에서 멈추게 한다.
                    // 없으면 시트가 화면 끝까지 올라가 제목이 시계·다이내믹 아일랜드와 겹친다.
                    .padding(.top, geometry.safeAreaInsets.top)
                    .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea()
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: selectSheet != nil)
        }
    }

    private func alertConfiguration(_ payload: ConfirmDialogPayload) -> AppAlertConfiguration {
        AppAlertConfiguration(
            title: payload.title,
            message: payload.message ?? "",
            primaryButton: .init(
                title: payload.confirmText,
                style: payload.destructive ? .destructive : .primary,
                action: { onConfirmButton(.confirm) }
            ),
            secondaryButton: .init(
                title: payload.cancelText ?? "취소",
                style: .neutral,
                action: { onConfirmButton(.cancel) }
            )
        )
    }

    // 표시 중이 아닐 때 넘기는 껍데기 설정(isPresented=false라 실제로 그려지지 않는다).
    private static let placeholderConfiguration = AppAlertConfiguration(
        title: "",
        message: "",
        primaryButton: .init(title: "", action: {}),
        secondaryButton: nil
    )

    private static func sheetConfiguration(_ payload: SelectSheetPayload) -> SelectSheetConfiguration {
        SelectSheetConfiguration(
            title: payload.title,
            message: payload.message,
            options: payload.options.map {
                .init(value: $0.value, label: $0.label, allowsCustomText: $0.allowsCustomText)
            },
            customTextPlaceholder: payload.customTextPlaceholder,
            submitText: payload.submitText
        )
    }
}

extension View {
    /// 브릿지 다이얼로그(확인 알럿 + 선택 시트)를 이 뷰 위에 그린다.
    /// payload가 nil이면 해당 표면은 표시되지 않는다.
    func webBridgeDialogs(
        confirmDialog: ConfirmDialogPayload?,
        selectSheet: SelectSheetPayload?,
        onConfirmButton: @escaping (ConfirmDialogOutcome) -> Void,
        onConfirmDismiss: @escaping () -> Void,
        onSelectSubmit: @escaping (String, String?) -> Void,
        onSelectDismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            WebBridgeDialogModifier(
                confirmDialog: confirmDialog,
                selectSheet: selectSheet,
                onConfirmButton: onConfirmButton,
                onConfirmDismiss: onConfirmDismiss,
                onSelectSubmit: onSelectSubmit,
                onSelectDismiss: onSelectDismiss
            )
        )
    }
}
