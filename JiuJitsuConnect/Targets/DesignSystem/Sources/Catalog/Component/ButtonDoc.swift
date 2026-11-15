#if DEBUG || BETA
//
//  ButtonDoc.swift
//  DesignSystem
//
//  부품 — 버튼(appButtonStyle). 실제 AppButtonStyle·AppButtonConfiguration 으로 그린다.
//

import SwiftUI

struct ButtonDoc: View {
    private let styles: [(ButtonStyleType, String)] = [
        (.primary, "primary"), (.tint, "tint"), (.neutral, "neutral"), (.text, "text"), (.destructive, "destructive")
    ]
    /// 앱 화면에서 실제로 쓰는 높이(medium 38·44, small 32)를 따른다.
    private let sizes: [(ButtonSize, String, CGFloat)] = [
        (.large, "large", 51), (.medium, "medium", 38), (.small, "small", 32)
    ]

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "버튼",
            summary: "화면 안에서 쓰는 일반 버튼. Button 에 AppButtonConfiguration 라벨을 넣고 .appButtonStyle(_:size:) 를 붙인다.",
            chips: ["쓰는 곳 11(10화면)", "변형 5", "크기 4", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate {
                    sample("저장하기", style: .primary, size: .medium, height: 44)
                }
            }

            CatalogSection(title: "해부도") {
                CatalogPlate {
                    Button {} label: {
                        AppButtonConfiguration(title: "다음", rightIcon: Assets.Common.Icon.chevronRight.swiftUIImage, size: .medium)
                    }
                    .appButtonStyle(.primary, size: .medium, hasRightIcon: true, height: 44)
                    // 번호는 버튼 밖에 둔다 — 1 바탕은 왼쪽 위 모서리, 2 글자·3 아이콘은 그 바로 아래.
                    .overlay(alignment: .topLeading) {
                        CatalogMarker(number: 1).offset(x: -9, y: -9)
                    }
                    .overlay(alignment: .bottomLeading) {
                        CatalogMarker(number: 2).offset(x: 23, y: 24)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        CatalogMarker(number: 3).offset(x: -13, y: 24)
                    }
                    .padding(.vertical, 16)
                }
                CatalogAnatomyList(items: [
                    "바탕 — component.button.<변형>.defaultBg, 모서리 large 15 · 그 밖 10",
                    "글자 — buttonM(large·medium) · buttonS(small)",
                    "아이콘 — 크기 24·20·16·16(large·medium·small·iconOnly), hasRightIcon 이면 오른쪽 여백을 줄인다"
                ])
            }

            CatalogSection(title: "변형", note: "앱 화면에서 쓰는 곳: neutral 6 · primary 2 · tint 2 · text 1 · destructive 0") {
                CatalogPlate {
                    FlowLayout(spacing: 12) {
                        ForEach(styles, id: \.1) { style, name in
                            CatalogCaptioned(caption: name) {
                                sample("버튼", style: style, size: .medium, height: 38)
                            }
                        }
                    }
                }
            }

            CatalogSection(title: "크기", note: "높이는 부르는 쪽에서 준다. 여기 높이는 앱에서 실제로 쓰는 값.") {
                CatalogPlate {
                    VStack(spacing: 16) {
                        ForEach(sizes, id: \.1) { size, name, height in
                            CatalogCaptioned(caption: "\(name) · 높이 \(Int(height))") {
                                sample("버튼", style: .primary, size: size, height: height)
                            }
                        }
                        CatalogCaptioned(caption: "iconOnly · 44") {
                            Button {} label: {
                                AppButtonConfiguration(title: nil, leftIcon: Assets.Common.Icon.plus.swiftUIImage, size: .iconOnly)
                            }
                            .appButtonStyle(.neutral, size: .iconOnly, height: 44)
                        }
                    }
                }
            }

            CatalogSection(title: "상태", note: "누름은 견본을 직접 눌러 본다. destructive 는 누름·비활성 색이 없다.") {
                CatalogPlate {
                    VStack(spacing: 16) {
                        ForEach(styles.filter { $0.0 != .destructive }, id: \.1) { style, name in
                            HStack(spacing: 12) {
                                CatalogCaptioned(caption: "\(name) 기본") {
                                    sample("버튼", style: style, size: .medium, height: 38)
                                }
                                CatalogCaptioned(caption: "\(name) 비활성") {
                                    sample("버튼", style: style, size: .medium, height: 38)
                                        .disabled(true)
                                }
                            }
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "한 줄에 주된 동작 하나만 primary, 나머지는 neutral·tint 로 둔다.",
                    badText: "primary 를 나란히 두 개 두면 무엇을 먼저 누를지 알 수 없다."
                ) {
                    HStack(spacing: 8) {
                        sample("취소", style: .neutral, size: .medium, height: 38)
                        sample("저장", style: .primary, size: .medium, height: 38)
                    }
                } bad: {
                    HStack(spacing: 8) {
                        sample("취소", style: .primary, size: .medium, height: 38)
                        sample("저장", style: .primary, size: .medium, height: 38)
                    }
                }
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "버튼 (appButtonStyle)", role: "화면·카드 안의 작은 동작. 폭은 글자만큼"),
                    (token: "CTA 버튼 (CTAButton)", role: "화면 맨 아래 꽉 찬 다음 단계·저장"),
                    (token: "띠 고르기 버튼", role: "띠 색·그랄을 고르는 선택지")
                ])
            }

            CatalogSection(title: "스펙", note: "primary 기준. 다른 변형은 같은 자리에 component.button.<변형> 을 쓴다.") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.button.filled.defaultBg", role: "바탕 · 기본", color: Color.component.button.filled.defaultBg),
                        CatalogColorSpec(token: "component.button.filled.pressedBg", role: "바탕 · 누름", color: Color.component.button.filled.pressedBg),
                        CatalogColorSpec(token: "component.button.filled.disabledBg", role: "바탕 · 비활성", color: Color.component.button.filled.disabledBg),
                        CatalogColorSpec(token: "component.button.filled.defaultText", role: "글자 · 기본", color: Color.component.button.filled.defaultText),
                        CatalogColorSpec(token: "component.button.filled.disabledText", role: "글자 · 비활성", color: Color.component.button.filled.disabledText)
                    ],
                    fonts: [
                        (token: "pretendard.buttonM", role: "large · medium"),
                        (token: "pretendard.buttonS", role: "small")
                    ]
                )
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "destructive 는 토큰 대신 AppButtonStyle 안에 #E52012 를 직접 적어 두었고, 누름·비활성 색이 없다. 앱 화면에서는 아직 쓰지 않는다. 높이를 주지 않으면 버튼이 세로로 늘어나므로(frame maxHeight .infinity) 부르는 쪽에서 height 를 주거나 높이가 정해진 칸에 넣는다."
            )
        }
    }

    private func sample(_ title: String, style: ButtonStyleType, size: ButtonSize, height: CGFloat) -> some View {
        Button {} label: {
            AppButtonConfiguration(title: title, size: size)
        }
        .appButtonStyle(style, size: size, height: height)
    }

}

#Preview("버튼") {
    NavigationStack { ButtonDoc() }
}

#endif
