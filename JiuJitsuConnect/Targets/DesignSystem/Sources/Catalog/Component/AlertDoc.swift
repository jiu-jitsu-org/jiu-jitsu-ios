#if DEBUG || BETA
//
//  AlertDoc.swift
//  DesignSystem
//
//  부품 — 알림창(appAlert). 실제 AppAlertView 를 높이를 정한 판 안에 그린다.
//

import SwiftUI

struct AlertDoc: View {
    @State private var isLivePresented = false

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "알림창",
            summary: "되돌리기 어려운 동작 앞에서 확인을 받는 가운데 창. 시스템 alert 대신 .appAlert(isPresented:configuration:) 를 쓴다.",
            chips: ["쓰는 곳 7(5화면)", "버튼 1·2개", "제목 2종", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "판 안에서는 어두운 막이 판만 덮는다. 실제로는 화면 전체를 덮는다.") {
                frame(height: 250) {
                    AppAlertView(configuration: twoButtons, isPresented: .constant(true))
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "어두운 막 — component.dialog.dimBg, 눌러도 닫히지 않는다",
                    "상자 — component.dialog.containerBg, 모서리 20, 화면 좌우 27.5 띄움",
                    "제목 — title2, 2줄까지",
                    "설명 — bodyM, 3줄까지",
                    "버튼 — 버튼 부품 large · 높이 51, 오른쪽이 주 동작"
                ])
            }

            CatalogSection(title: "변형") {
                VStack(spacing: 12) {
                    CatalogCaptioned(caption: "버튼 1개 — 알리기만") {
                        frame(height: 230) {
                            AppAlertView(configuration: oneButton, isPresented: .constant(true))
                        }
                    }
                    CatalogCaptioned(caption: "버튼 2개 — 확인받기") {
                        frame(height: 250) {
                            AppAlertView(configuration: twoButtons, isPresented: .constant(true))
                        }
                    }
                    CatalogCaptioned(caption: "말줄임 제목 + destructive — 긴 닉네임 뒤 접미사를 지킨다") {
                        frame(height: 230) {
                            AppAlertView(configuration: truncatable, isPresented: .constant(true))
                        }
                    }
                }
            }

            CatalogSection(title: "상태", note: "띄우기·닫기 움직임은 실제로 열어 본다. 버튼을 누르면 창이 스스로 닫힌다.") {
                CatalogPlate {
                    Button {
                        isLivePresented = true
                    } label: {
                        AppButtonConfiguration(title: "알림창 열기", size: .medium)
                    }
                    .appButtonStyle(.primary, size: .medium, height: 44)
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "버튼 글자에 결과를 쓴다(\"차단하기\"). 무엇이 일어나는지 바로 안다.",
                    badText: "\"확인\"·\"예\" 처럼 무엇을 하는지 안 보이는 버튼 글자는 피한다."
                ) {
                    frame(height: 230) {
                        AppAlertView(configuration: twoButtons, isPresented: .constant(true))
                    }
                } bad: {
                    frame(height: 230) {
                        AppAlertView(configuration: vague, isPresented: .constant(true))
                    }
                }
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "알림창", role: "멈춰서 답해야 할 때. 되돌리기 어려운 동작 앞"),
                    (token: "토스트", role: "끝난 일을 알리기만 할 때. 답이 필요 없다"),
                    (token: "고르기 시트", role: "여러 항목 중 하나를 골라야 할 때")
                ])
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.dialog.dimBg", role: "어두운 막", color: Color.component.dialog.dimBg),
                        CatalogColorSpec(token: "component.dialog.containerBg", role: "상자", color: Color.component.dialog.containerBg),
                        CatalogColorSpec(token: "component.dialog.titleText", role: "제목", color: Color.component.dialog.titleText),
                        CatalogColorSpec(token: "component.dialog.descriptionText", role: "설명", color: Color.component.dialog.descriptionText)
                    ],
                    fonts: [
                        (token: "pretendard.title2", role: "제목"),
                        (token: "pretendard.bodyM", role: "설명")
                    ]
                )
            }
        }
        .appAlert(isPresented: $isLivePresented, configuration: twoButtons)
    }

    private func frame<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var oneButton: AppAlertConfiguration {
        AppAlertConfiguration(
            title: "저장했어요",
            message: "내 스타일이 프로필에 보여요.",
            primaryButton: .init(title: "확인") {},
            secondaryButton: nil
        )
    }

    private var twoButtons: AppAlertConfiguration {
        AppAlertConfiguration(
            title: "이 사용자를 차단할까요?",
            message: "차단하면 서로의 글과 댓글이 보이지 않아요.",
            primaryButton: .init(title: "차단하기") {},
            secondaryButton: .init(title: "취소", style: .neutral) {}
        )
    }

    private var truncatable: AppAlertConfiguration {
        AppAlertConfiguration(
            title: .truncatable("아주아주긴닉네임을가진주짓수인", suffix: "님을 차단할까요?"),
            message: "차단하면 서로의 글과 댓글이 보이지 않아요.",
            primaryButton: .init(title: "차단하기", style: .destructive) {},
            secondaryButton: .init(title: "취소", style: .neutral) {}
        )
    }

    private var vague: AppAlertConfiguration {
        AppAlertConfiguration(
            title: "이 사용자를 차단할까요?",
            message: "차단하면 서로의 글과 댓글이 보이지 않아요.",
            primaryButton: .init(title: "확인") {},
            secondaryButton: .init(title: "취소", style: .neutral) {}
        )
    }
}

#Preview("알림창") {
    NavigationStack { AlertDoc() }
}

#endif
