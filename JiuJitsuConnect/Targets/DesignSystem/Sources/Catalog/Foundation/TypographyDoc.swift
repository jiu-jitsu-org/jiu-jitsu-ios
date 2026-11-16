#if DEBUG || BETA
//
//  TypographyDoc.swift
//  DesignSystem
//
//  기초 — 글자. Font.pretendard 12단계를 실물로 그린다.
//

import SwiftUI

struct TypographyDoc: View {
    /// 크기·굵기는 Font+.swift 에서, 쓰는 곳은 `pretendard.<이름>` 이 Presentation·App·Component 에 나온 횟수(2026-11-16 기준).
    private struct Style: Identifiable {
        let name: String
        let font: Font
        let size: Int
        let weight: String
        let uses: Int
        var id: String { name }
    }

    private let styles: [Style] = [
        Style(name: "display1", font: .pretendard.display1, size: 30, weight: "SemiBold", uses: 26),
        Style(name: "title1", font: .pretendard.title1, size: 22, weight: "SemiBold", uses: 0),
        Style(name: "title2", font: .pretendard.title2, size: 20, weight: "SemiBold", uses: 9),
        Style(name: "title3", font: .pretendard.title3, size: 18, weight: "SemiBold", uses: 19),
        Style(name: "bodyM", font: .pretendard.bodyM, size: 16, weight: "Medium", uses: 22),
        Style(name: "bodyS", font: .pretendard.bodyS, size: 14, weight: "Medium", uses: 31),
        Style(name: "labelM", font: .pretendard.labelM, size: 12, weight: "Medium", uses: 6),
        Style(name: "labelS", font: .pretendard.labelS, size: 10, weight: "Medium", uses: 0),
        Style(name: "buttonL", font: .pretendard.buttonL, size: 18, weight: "SemiBold", uses: 0),
        Style(name: "buttonM", font: .pretendard.buttonM, size: 16, weight: "SemiBold", uses: 6),
        Style(name: "buttonS", font: .pretendard.buttonS, size: 12, weight: "SemiBold", uses: 7),
        Style(name: "captionM", font: .pretendard.captionM, size: 12, weight: "Medium", uses: 2)
    ]

    var body: some View {
        CatalogDoc(
            group: .foundation,
            title: "글자",
            summary: "Pretendard 두 굵기(SemiBold·Medium)로 12단계. 크기는 고정이라 시스템 글자 크기 설정을 따라가지 않는다.",
            chips: ["스타일 \(styles.count)", "굵기 2", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("오늘도 한 판?")
                            .font(.pretendard.display1)
                        Text("특기 포지션을 골라 주세요")
                            .font(.pretendard.bodyM)
                            .foregroundStyle(Color.semantic.text.secondary)
                    }
                    .foregroundStyle(Color.semantic.text.primary)
                }
            }

            CatalogSection(title: "값 사다리", note: "왼쪽 숫자는 크기(pt). 아래 줄은 굵기 · 앱 화면에서 쓰는 곳.") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(styles) { style in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(style.size)")
                                    .font(.pretendard.labelM)
                                    .foregroundStyle(Color.semantic.text.secondary)
                                    .frame(width: 24, alignment: .leading)
                                Text("주짓수 \(style.name)")
                                    .font(style.font)
                                    .foregroundStyle(Color.semantic.text.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            Text("\(style.weight) · 쓰는 곳 \(style.uses)")
                                .font(.pretendard.labelM)
                                .foregroundStyle(Color.semantic.text.tertiary)
                                .padding(.leading, 36)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            CatalogSection(title: "어디에 쓰나") {
                CatalogSpecTable(colors: [], fonts: [
                    (token: "display1 · title1~3", role: "화면 제목, 시트 제목, 카드 제목"),
                    (token: "bodyM · bodyS", role: "본문, 설명, 목록 줄"),
                    (token: "labelM · labelS · captionM", role: "보조 설명, 칩, 단위"),
                    (token: "buttonL · buttonM · buttonS", role: "버튼 글자(appButtonStyle 은 buttonM·buttonS)"),
                    (token: "cookieRun.custom(weight: .black, size:)", role: "띠 축하 등 장식 글자 — 앱 화면 5곳")
                ])
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "토큰 이름으로 쓴다. 굵기·크기가 한 번에 맞는다.",
                    badText: "글꼴 이름 문자열이나 임의 크기로 만들지 않는다. 12단계 밖 크기가 생긴다."
                ) {
                    Text(".font(.pretendard.bodyM)")
                        .font(.pretendard.bodyM)
                        .foregroundStyle(Color.semantic.text.primary)
                } bad: {
                    Text(".font(.custom(\"Pretendard\", size: 15))")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(colors: [], fonts: [
                    (token: "Font.pretendard.<이름>", role: "SwiftUI — Font.custom(…, fixedSize:)"),
                    (token: "UIFont.pretendard.<이름>", role: "UIKit — 같은 12단계(MultilineTextField 등)"),
                    (token: ".lineHeight(_:)", role: "줄 간격 보정 modifier — 토큰에는 줄 높이가 없다")
                ])
            }
        }
    }
}

#Preview("글자") {
    NavigationStack { TypographyDoc() }
}

#endif
