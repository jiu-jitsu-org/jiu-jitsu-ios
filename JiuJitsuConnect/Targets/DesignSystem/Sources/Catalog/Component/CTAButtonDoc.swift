#if DEBUG || BETA
//
//  CTAButtonDoc.swift
//  DesignSystem
//
//  부품 — CTA 버튼. 실제 CTAButton 으로 그린다.
//

import SwiftUI

struct CTAButtonDoc: View {
    private let types: [(CTAButton.ButtonType, String)] = [(.blue, "blue"), (.dark, "dark"), (.tint, "tint"), (.text, "text")]

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "CTA 버튼",
            summary: "화면 맨 아래에 폭을 꽉 채우는 다음 단계·저장 버튼. 기본 높이 51.",
            chips: ["쓰는 곳 22(15화면)", "종류 4", "모양 2", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate {
                    CTAButton(title: "다음") {}
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "바탕 — component.cta.<종류>.bg, 폭을 꽉 채운다",
                    "글자 — component.cta.<종류>.text",
                    "왼쪽 아이콘(선택) — leftIcon"
                ])
            }

            CatalogSection(title: "변형", note: "type 을 따로 주지 않으면 blue. 앱에서 type 을 적은 곳: blue 4 · text 2 · tint 1") {
                CatalogPlate {
                    VStack(spacing: 12) {
                        ForEach(types, id: \.1) { type, name in
                            CatalogCaptioned(caption: name) {
                                CTAButton(title: "저장하기", type: type) {}
                            }
                        }
                        CatalogCaptioned(caption: "왼쪽 아이콘") {
                            CTAButton(title: "글쓰기", type: .dark, leftIcon: Assets.Common.Icon.pencil.swiftUIImage) {}
                        }
                    }
                }
            }

            CatalogSection(title: "크기", note: "모양은 rounded(모서리 12)와 keypad(모서리 16, 좌우·아래 12 띄움) 둘.") {
                CatalogPlate {
                    VStack(spacing: 12) {
                        CatalogCaptioned(caption: "rounded · 51") {
                            CTAButton(title: "다음") {}
                        }
                        CatalogCaptioned(caption: "keypad · 키보드 위에 붙을 때") {
                            CTAButton(title: "확인", style: .keypad) {}
                        }
                    }
                }
            }

            CatalogSection(title: "상태") {
                CatalogPlate {
                    VStack(spacing: 12) {
                        ForEach(types, id: \.1) { type, name in
                            CatalogCaptioned(caption: "\(name) 비활성") {
                                CTAButton(title: "저장하기", type: type) {}
                                    .disabled(true)
                            }
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "화면에 하나만, 맨 아래에 둔다. 다 채우기 전엔 비활성으로 둔다.",
                    badText: "본문 중간이나 카드 안에 넣지 않는다. 그곳에는 버튼(appButtonStyle)을 쓴다."
                ) {
                    CTAButton(title: "다음") {}
                } bad: {
                    VStack(spacing: 8) {
                        CTAButton(title: "수정", type: .tint) {}
                        CTAButton(title: "삭제", type: .dark) {}
                    }
                }
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "CTA 버튼", role: "화면의 다음 단계·저장. 맨 아래 하나"),
                    (token: "버튼 (appButtonStyle)", role: "카드·줄 안의 작은 동작. 폭은 글자만큼")
                ])
            }

            CatalogSection(title: "스펙", note: "blue 기준. 다른 종류는 component.cta.<dark·tint·transparentText> 를 같은 자리에 쓴다.") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.cta.primary.bg", role: "바탕", color: Color.component.cta.primary.bg),
                        CatalogColorSpec(token: "component.cta.primary.pressedBg", role: "바탕 · 누름", color: Color.component.cta.primary.pressedBg),
                        CatalogColorSpec(token: "component.cta.primary.disabledBg", role: "바탕 · 비활성", color: Color.component.cta.primary.disabledBg),
                        CatalogColorSpec(token: "component.cta.primary.text", role: "글자", color: Color.component.cta.primary.text),
                        CatalogColorSpec(token: "component.cta.primary.disabledText", role: "글자 · 비활성", color: Color.component.cta.primary.disabledText)
                    ]
                )
            }
        }
    }
}

#Preview("CTA 버튼") {
    NavigationStack { CTAButtonDoc() }
}

#endif
