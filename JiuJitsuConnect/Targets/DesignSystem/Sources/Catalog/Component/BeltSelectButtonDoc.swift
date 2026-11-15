#if DEBUG || BETA
//
//  BeltSelectButtonDoc.swift
//  DesignSystem
//
//  부품 — 띠 고르기 버튼 · 띠 아이콘 · 띠 그림. 실제 BeltSelectButton·BeltIcon·BeltIllustration 으로 그린다.
//

import SwiftUI

struct BeltSelectButtonDoc: View {
    @State private var selected: BeltSelectButton.BeltColor = .blue

    private let belts: [(BeltSelectButton.BeltColor, String)] = [
        (.white, "화이트"), (.blue, "블루"), (.purple, "퍼플"), (.brown, "브라운"), (.black, "블랙")
    ]

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "띠 고르기 버튼",
            summary: "띠 색과 그랄(줄) 수를 고르는 버튼. 같은 파일의 띠 아이콘·띠 그림도 여기서 본다.",
            chips: ["띠 5색", "그랄 0~4", "크기 3", "띠 아이콘 쓰는 곳 2 · 띠 그림 1", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "눌러서 골라 본다.") {
                CatalogPlate {
                    HStack(spacing: 8) {
                        ForEach(belts, id: \.1) { color, name in
                            BeltSelectButton(color: color, title: name, isSelected: selected == color) { selected = color }
                        }
                    }
                }
            }

            CatalogSection(title: "크기", note: "높이 compact 40 · regular 56 · large 88") {
                CatalogPlate {
                    VStack(spacing: 16) {
                        CatalogCaptioned(caption: "compact") {
                            BeltSelectButton(color: .purple, title: "퍼플", size: .compact, isSelected: true) {}
                        }
                        CatalogCaptioned(caption: "regular") {
                            BeltSelectButton(color: .purple, title: "퍼플", isSelected: true) {}
                        }
                        CatalogCaptioned(caption: "large · 그랄 2") {
                            BeltSelectButton(color: .purple, title: "퍼플", stripes: 2, size: .large, isSelected: true) {}
                        }
                    }
                }
            }

            CatalogSection(title: "상태") {
                CatalogPlate {
                    HStack(spacing: 12) {
                        CatalogCaptioned(caption: "고름") {
                            BeltSelectButton(color: .brown, title: "브라운", stripes: 3, size: .large, isSelected: true) {}
                        }
                        CatalogCaptioned(caption: "안 고름") {
                            BeltSelectButton(color: .brown, title: "브라운", stripes: 3, size: .large, isSelected: false) {}
                        }
                    }
                }
            }

            CatalogSection(title: "띠 아이콘 · 띠 그림") {
                CatalogPlate {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            ForEach(belts, id: \.1) { color, _ in
                                BeltIcon(color: color)
                            }
                        }
                        CatalogCaptioned(caption: "BeltIllustration · 블랙 그랄 4") {
                            BeltIllustration(color: .black, stripes: 4, width: 280)
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "띠 색은 이 부품과 띠 색 토큰으로만 그린다. 다른 화면의 띠와 모양이 맞는다.",
                    badText: "화면마다 띠를 사각형으로 따로 그리지 않는다. 흰 띠 테두리·그랄 위치가 어긋난다."
                ) {
                    BeltIcon(color: .white)
                } bad: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.component.beltSelectButton.belt.white)
                        .frame(width: 40, height: 12)
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(colors: [
                    CatalogColorSpec(token: "component.beltSelectButton.selected.bg", role: "고름 · 바탕", color: Color.component.beltSelectButton.selected.bg),
                    CatalogColorSpec(token: "component.beltSelectButton.selected.labelText", role: "고름 · 글자", color: Color.component.beltSelectButton.selected.labelText),
                    CatalogColorSpec(token: "component.beltSelectButton.unselected.bg", role: "안 고름 · 바탕", color: Color.component.beltSelectButton.unselected.bg),
                    CatalogColorSpec(token: "component.beltSelectButton.unselected.labelText", role: "안 고름 · 글자", color: Color.component.beltSelectButton.unselected.labelText),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.white", role: "띠 · 화이트", color: Color.component.beltSelectButton.belt.white),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.whiteEdge", role: "띠 · 화이트 테두리", color: Color.component.beltSelectButton.belt.whiteEdge),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.blue", role: "띠 · 블루", color: Color.component.beltSelectButton.belt.blue),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.purple", role: "띠 · 퍼플", color: Color.component.beltSelectButton.belt.purple),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.brown", role: "띠 · 브라운", color: Color.component.beltSelectButton.belt.brown),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.black", role: "띠 · 블랙", color: Color.component.beltSelectButton.belt.black),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.rankBar", role: "그랄 바", color: Color.component.beltSelectButton.belt.rankBar),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.blackRankBar", role: "그랄 바 · 블랙", color: Color.component.beltSelectButton.belt.blackRankBar),
                    CatalogColorSpec(token: "component.beltSelectButton.belt.stripe", role: "그랄 줄", color: Color.component.beltSelectButton.belt.stripe)
                ])
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "띠 색(블루·퍼플·브라운·블랙)은 MY 상단 바탕 색(component.myProfileHeader.bg)을 그대로 가져다 쓴다. 그래서 MY 상단 색을 바꾸면 띠 색도 같이 바뀐다. 버튼 자체는 앱 화면에서 BeltSelectButton 이름으로 부르는 곳이 없고, 띠 아이콘·띠 그림이 쓰인다."
            )
        }
    }
}

#Preview("띠 고르기 버튼") {
    NavigationStack { BeltSelectButtonDoc() }
}

#endif
