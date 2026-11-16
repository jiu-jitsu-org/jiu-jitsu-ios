#if DEBUG || BETA
//
//  SegmentControlDoc.swift
//  DesignSystem
//
//  부품 — 세그먼트(SegmentControl). 실제 부품으로 그린다.
//

import SwiftUI

struct SegmentControlDoc: View {
    @State private var regularSide: SegmentControl.Side? = .left
    @State private var compactSide: SegmentControl.Side?

    private let left = SegmentItem(title: "특기", subtitle: "탑포지션")
    private let right = SegmentItem(title: "최애", subtitle: "가드포지션")

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "세그먼트",
            summary: "둘 중 하나를 고르는 칸. 고른 쪽만 흰 면이 올라온다. 고르기 전(nil)에는 양쪽 다 꺼진 모양이다.",
            chips: ["쓰는 곳 1(대회 종목)", "크기 2", "선택지 2개 고정", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate {
                    SegmentControl(leftItem: left, rightItem: right, selectedSide: regularSide) { regularSide = $0 }
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "바깥 칸 — component.segment.container.bg, 모서리 28(compact 22)",
                    "고른 쪽 — component.segment.selected.bg, 안쪽 4(compact 3) 띄움",
                    "제목 — SemiBold 18(compact 14)",
                    "부제목 — labelM, regular 에서만 보인다"
                ])
            }

            CatalogSection(title: "크기") {
                CatalogPlate {
                    VStack(spacing: 20) {
                        CatalogCaptioned(caption: "regular · 262 × 67 고정") {
                            SegmentControl(leftItem: left, rightItem: right, selectedSide: .left) { _ in }
                        }
                        CatalogCaptioned(caption: "compact · 높이 44, 폭은 쓰는 곳에서(대회 종목 160)") {
                            SegmentControl(
                                leftItem: SegmentItem(title: "기"),
                                rightItem: SegmentItem(title: "노기"),
                                selectedSide: .right,
                                size: .compact
                            ) { _ in }
                            .frame(width: 160)
                        }
                    }
                }
            }

            CatalogSection(title: "상태") {
                CatalogPlate {
                    VStack(spacing: 20) {
                        CatalogCaptioned(caption: "고르기 전(nil)") {
                            SegmentControl(leftItem: left, rightItem: right, selectedSide: nil) { _ in }
                        }
                        CatalogCaptioned(caption: "왼쪽 고름") {
                            SegmentControl(leftItem: left, rightItem: right, selectedSide: .left) { _ in }
                        }
                        CatalogCaptioned(caption: "오른쪽 고름") {
                            SegmentControl(leftItem: left, rightItem: right, selectedSide: .right) { _ in }
                        }
                        CatalogCaptioned(caption: "직접 눌러 보기 · compact") {
                            SegmentControl(
                                leftItem: SegmentItem(title: "기"),
                                rightItem: SegmentItem(title: "노기"),
                                selectedSide: compactSide,
                                size: .compact
                            ) { compactSide = $0 }
                            .frame(width: 160)
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "화면의 주 질문이 따로 있고 그 조건(기/노기)을 고를 때는 compact 로 작게 둔다.",
                    badText: "세 개 이상을 고르거나 켜고 끄는 데 쓰지 않는다. 선택지는 두 개로 고정이다."
                ) {
                    SegmentControl(
                        leftItem: SegmentItem(title: "기"),
                        rightItem: SegmentItem(title: "노기"),
                        selectedSide: .left,
                        size: .compact
                    ) { _ in }
                    .frame(width: 160)
                } bad: {
                    SegmentControl(
                        leftItem: SegmentItem(title: "알림 켬"),
                        rightItem: SegmentItem(title: "알림 끔"),
                        selectedSide: .left,
                        size: .compact
                    ) { _ in }
                    .frame(width: 200)
                }
            }

            CatalogSection(title: "비슷한 부품") {
                CatalogCompareTable(rows: [
                    (token: "세그먼트", role: "두 선택지, 한 화면 안에서 바로 바뀜"),
                    (token: "시트 피커", role: "세 개 이상 값을 굴려 고름"),
                    (token: "고르기 시트", role: "목록에서 하나를 골라 보냄")
                ])
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.segment.container.bg", role: "바깥 칸", color: Color.component.segment.container.bg),
                        CatalogColorSpec(token: "component.segment.selected.bg", role: "고른 쪽 면", color: Color.component.segment.selected.bg),
                        CatalogColorSpec(token: "component.segment.selected.titleText", role: "고른 쪽 제목", color: Color.component.segment.selected.titleText),
                        CatalogColorSpec(token: "component.segment.selected.subText", role: "고른 쪽 부제목", color: Color.component.segment.selected.subText),
                        CatalogColorSpec(token: "component.segment.unselected.bg", role: "안 고른 쪽 면", color: Color.component.segment.unselected.bg),
                        CatalogColorSpec(token: "component.segment.unselected.titleText", role: "안 고른 쪽 제목", color: Color.component.segment.unselected.titleText),
                        CatalogColorSpec(token: "component.segment.unselected.subText", role: "안 고른 쪽 부제목", color: Color.component.segment.unselected.subText)
                    ],
                    fonts: [
                        (token: "pretendard.custom(.semiBold, 18 · 14)", role: "제목 — 12단계 밖 크기를 직접 쓴다"),
                        (token: "pretendard.labelM", role: "부제목")
                    ]
                )
            }
        }
    }
}

#Preview("세그먼트") {
    NavigationStack { SegmentControlDoc() }
}

#endif
