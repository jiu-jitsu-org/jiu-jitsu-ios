#if DEBUG || BETA
//
//  ToastDoc.swift
//  DesignSystem
//
//  부품 — 토스트. 실제 ToastView 와 .toast(_:) 로 그린다.
//

import SwiftUI

struct ToastDoc: View {
    @State private var liveToast: ToastState?
    @State private var dismissTask: Task<Void, Never>?

    private let statuses: [(ToastState.Status, String, String)] = [
        (.success, "success", "포지션을 저장했어요"),
        (.info, "info", "새 글이 올라왔어요"),
        (.warning, "warning", "사진은 10장까지 올릴 수 있어요"),
        (.error, "error", "네트워크 연결을 확인해 주세요")
    ]

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "토스트",
            summary: "끝난 일·짧은 안내를 화면 아래에 잠깐 띄운다. 화면에는 .toast(_:onSwipe:onButtonTapped:) 로 붙이고, 닫는 시점은 부르는 쪽이 정한다.",
            chips: ["쓰는 곳 16(12화면)", "상태 4", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate {
                    toastSample(ToastState(message: "포지션을 저장했어요", status: .success))
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "상자 — component.toast.strong.background, 모서리 20, 최소 높이 58, 옅은 그림자",
                    "상태 아이콘 — 20, 아이콘 ↔ 글자 12",
                    "글자 — bodyS, 여러 줄이면 상자가 늘어난다",
                    "글자 버튼(선택) — buttonS, 누르는 동안만 옅은 면"
                ])
            }

            CatalogSection(title: "변형", note: "상태 4가지 + 글자 버튼 · 여러 줄.") {
                CatalogPlate {
                    VStack(spacing: 12) {
                        ForEach(statuses, id: \.1) { status, name, message in
                            CatalogCaptioned(caption: name) {
                                toastSample(ToastState(message: message, status: status))
                            }
                        }
                        CatalogCaptioned(caption: "버튼 있음 — 5초 동안 떠 있다") {
                            toastSample(ToastState(message: "글을 삭제했어요", status: .info, button: .init(title: "확인", action: .done)))
                        }
                        CatalogCaptioned(caption: "여러 줄") {
                            toastSample(ToastState(message: "프로필 사진을 바꾸지 못했어요. 잠시 뒤 다시 시도해 주세요.", status: .error))
                        }
                    }
                }
            }

            CatalogSection(title: "상태", note: "나타남·다시 불림·아래로 밀어 닫기를 실제로 본다. 버튼 없으면 2초, 있으면 5초 뒤 닫는다.") {
                CatalogPlate {
                    FlowLayout(spacing: 8) {
                        ForEach(statuses, id: \.1) { status, name, message in
                            Button {
                                show(ToastState(message: message, status: status))
                            } label: {
                                AppButtonConfiguration(title: name, size: .small)
                            }
                            .appButtonStyle(.neutral, size: .small, height: 32)
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "한 문장으로 일어난 일을 말한다. 답이 필요 없을 때만 쓴다.",
                    badText: "되돌릴 수 없는 결정을 토스트로 묻지 않는다. 2초 뒤 사라진다 — 알림창을 쓴다."
                ) {
                    toastSample(ToastState(message: "차단했어요", status: .success))
                } bad: {
                    toastSample(ToastState(message: "정말 탈퇴할까요?", status: .warning, button: .init(title: "탈퇴", action: .done)))
                }
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "토스트", role: "끝난 일 알림. 저절로 사라진다"),
                    (token: "알림창", role: "답을 받아야 할 때. 닫을 때까지 남는다")
                ])
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.toast.strong.background", role: "상자", color: Color.component.toast.strong.background),
                        CatalogColorSpec(token: "component.toast.strong.shadow", role: "그림자", color: Color.component.toast.strong.shadow),
                        CatalogColorSpec(token: "component.toast.default.text", role: "글자", color: Color.component.toast.default.text),
                        CatalogColorSpec(token: "component.toast.action.text", role: "글자 버튼", color: Color.component.toast.action.text),
                        CatalogColorSpec(token: "component.toast.action.pressedBg", role: "글자 버튼 · 누름", color: Color.component.toast.action.pressedBg),
                        CatalogColorSpec(token: "component.toast.icon.success", role: "아이콘 · success", color: Color.component.toast.icon.success),
                        CatalogColorSpec(token: "component.toast.icon.info", role: "아이콘 · info", color: Color.component.toast.icon.info),
                        CatalogColorSpec(token: "component.toast.icon.warning", role: "아이콘 · warning", color: Color.component.toast.icon.warning),
                        CatalogColorSpec(token: "component.toast.icon.error", role: "아이콘 · error", color: Color.component.toast.icon.error)
                    ],
                    fonts: [
                        (token: "pretendard.bodyS", role: "글자"),
                        (token: "pretendard.buttonS", role: "글자 버튼")
                    ]
                )
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "웹 토스트와 모양·움직임을 맞춘다(상태 아이콘 그림도 웹 ToastIcon 과 같다). ToastState 에는 저절로 닫히는 기능이 없어 화면의 Reducer 가 state.duration(2초·5초) 뒤 nil 로 바꾼다. 떠 있는 채로 다시 불리면 상자는 그대로 두고 아이콘·글자만 바뀐다."
            )
        }
        .toast(liveToast, onSwipe: { liveToast = nil }, onButtonTapped: { _ in liveToast = nil })
        .onDisappear { dismissTask?.cancel() }
    }

    private func toastSample(_ state: ToastState) -> some View {
        ToastView(state: state, onSwipe: {}, onButtonTapped: { _ in })
    }

    private func show(_ state: ToastState) {
        liveToast = state
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: state.duration)
            guard !Task.isCancelled else { return }
            liveToast = nil
        }
    }
}

#Preview("토스트") {
    NavigationStack { ToastDoc() }
}

#endif
