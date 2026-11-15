#if DEBUG || BETA
//
//  ColorDoc.swift
//  DesignSystem
//
//  기초 — 색. Primitive → Semantic → Component 3단을 실제 토큰 색으로 그린다.
//

import SwiftUI

struct CatalogColorToken: Identifiable {
    /// `Color.` 뒤의 토큰 경로. 예: semantic.surface.container
    let path: String
    /// 그 토큰이 가리키는 값(Primitive 는 Colors.xcassets 의 hex, 나머지는 바로 윗단 토큰)
    let source: String
    let color: Color
    var id: String { path }
    var name: String { path.split(separator: ".").last.map(String.init) ?? path }
}

struct CatalogColorGroup: Identifiable {
    let name: String
    let tokens: [CatalogColorToken]
    var id: String { name }
}

struct CatalogColorTier: Identifiable {
    let name: String
    let groups: [CatalogColorGroup]
    var id: String { name }
    var tokenCount: Int { groups.reduce(0) { $0 + $1.tokens.count } }
}

struct ColorDoc: View {
    private let tiers: [CatalogColorTier] = [.primitive, .semantic, .component]

    var body: some View {
        CatalogDoc(
            group: .foundation,
            title: "색",
            summary: "원시 색(Primitive)에 역할 이름(Semantic)을 붙이고, 부품마다 그 역할을 골라 쓴다(Component). 화면 코드는 Component·Semantic 만 쓴다.",
            chips: tiers.map { "\($0.name) \($0.tokenCount)" } + ["라이트 전용", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "같은 파랑이 세 단을 거쳐 버튼 바탕이 된다.") {
                CatalogPlate {
                    HStack(spacing: 8) {
                        chainStep(color: Color.primitive.blue.b500p, name: "primitive\nblue.b500p")
                        arrow
                        chainStep(color: Color.semantic.interactive.primary, name: "semantic\ninteractive.primary")
                        arrow
                        chainStep(color: Color.component.button.filled.defaultBg, name: "component\nbutton.filled.defaultBg")
                    }
                }
            }

            ForEach(tiers) { tier in
                CatalogSection(title: tier.name, note: note(for: tier)) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(tier.groups) { group in
                            if tier.name == "Component" {
                                CatalogColorGroupFold(group: group)
                            } else {
                                CatalogColorGroupView(group: group)
                            }
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "부품 색은 Component 토큰에서 고른다. 그 부품의 역할이 이름에 들어 있다.",
                    badText: "화면 코드에서 Primitive 나 hex 값을 바로 쓰지 않는다. 역할이 바뀌면 따라 바뀌지 않는다."
                ) {
                    Text("Color.component.button.filled.defaultBg")
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.primary)
                } bad: {
                    Text("Color.primitive.blue.b500p")
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.primary)
                }
            }

            CatalogNote(
                title: "토큰 목록을 만든 방법",
                text: "Color+Primitive / Semantic / Component.swift 를 읽어 카탈로그 목록(Catalog/Data)을 만들었다. Primitive 의 hex 는 Colors.xcassets 라이트 값이다. 토큰을 더하거나 바꾸면 목록도 다시 만들어야 한다."
            )
        }
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.pretendard.labelM)
            .foregroundStyle(Color.semantic.icon.tertiary)
    }

    private func chainStep(color: Color, name: String) -> some View {
        VStack(spacing: 6) {
            CatalogColorDot(color: color, size: 36)
            Text(name)
                .font(.pretendard.labelS)
                .foregroundStyle(Color.semantic.text.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func note(for tier: CatalogColorTier) -> String {
        switch tier.name {
        case "Primitive": "Colors.xcassets 에 든 원래 색. 오른쪽 값은 라이트 hex."
        case "Semantic": "역할 이름. 오른쪽 값은 가리키는 Primitive."
        default: "부품별 색. 묶음을 누르면 펼쳐진다. 오른쪽 값은 가리키는 Semantic."
        }
    }
}

/// 토큰 묶음 하나 — 색 점 + 이름 + 가리키는 값.
struct CatalogColorGroupView: View {
    let group: CatalogColorGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.name)
                .font(.pretendard.buttonS)
                .foregroundStyle(Color.semantic.text.primary)
            CatalogColorRows(tokens: group.tokens)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Component 묶음은 많아서 접어 둔다.
struct CatalogColorGroupFold: View {
    let group: CatalogColorGroup

    var body: some View {
        DisclosureGroup {
            CatalogColorRows(tokens: group.tokens)
                .padding(.top, 10)
        } label: {
            HStack(spacing: 6) {
                HStack(spacing: -6) {
                    ForEach(group.tokens.prefix(4)) { token in
                        CatalogColorDot(color: token.color, size: 16)
                    }
                }
                Text("\(group.name) · \(group.tokens.count)")
                    .font(.pretendard.buttonS)
                    .foregroundStyle(Color.semantic.text.primary)
            }
        }
        .tint(Color.semantic.text.secondary)
        .padding(16)
        .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CatalogColorRows: View {
    let tokens: [CatalogColorToken]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tokens) { token in
                HStack(spacing: 12) {
                    CatalogColorDot(color: token.color, size: 28)
                    Text(token.name)
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                    Spacer(minLength: 8)
                    Text(token.source)
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.secondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }
        }
    }
}

#Preview("색") {
    NavigationStack { ColorDoc() }
}

#endif
