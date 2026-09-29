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
        // 바깥 GeometryReader는 키보드 영역을 존중해 하단 inset으로 키보드 높이를 읽는 용도로만 쓴다.
        // 시트 컨테이너가 키보드 safe area를 따라가면 키보드가 뜰 때 컨테이너 자체가 위로 밀려
        // 시트가 상태바를 침범한다(#38 "키보드 등장 시 콘텐츠 점프"). 그래서 안쪽은 키보드를 무시한
        // 고정 전체 화면에 두고, 키보드 부착은 시트가 bottomInset으로 직접 계산한다.
        GeometryReader { keyboardProbe in
            sheetContainer(bottomInset: keyboardProbe.safeAreaInsets.bottom)
        }
    }

    private func sheetContainer(bottomInset: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if let selectSheet {
                    Color.component.bottomSheet.selected.container.scrim
                        .ignoresSafeArea()
                        .onTapGesture { onSelectDismiss() }
                        .transition(.opacity)

                    // 높이 단계(중간·확장)·드래그·키보드 부착은 시트가 소유하고, 여기서는 화면 치수만 넘긴다.
                    SelectSheetView(
                        configuration: Self.sheetConfiguration(selectSheet),
                        screen: SelectSheetScreenMetrics(
                            height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom,
                            topInset: geometry.safeAreaInsets.top,
                            bottomInset: bottomInset
                        ),
                        onSubmit: { value, customText in onSelectSubmit(value, customText) },
                        onDismiss: onSelectDismiss
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            // 키보드가 떠 있으면 홈 인디케이터 영역이 키보드에 덮여 ignoresSafeArea가 하단을 넓히지 못한다
            // (컨테이너가 화면 하단보다 34pt 위에서 끝나 시트 전체가 그만큼 떠오름). 화면 전체 높이를 명시해 고정한다.
            .frame(height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: selectSheet != nil)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func alertConfiguration(_ payload: ConfirmDialogPayload) -> AppAlertConfiguration {
        AppAlertConfiguration(
            title: payload.titleParts.map { .truncatable($0.truncatable, suffix: $0.suffix) } ?? .plain(payload.title),
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
