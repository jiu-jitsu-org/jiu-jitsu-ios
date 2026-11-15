#if DEBUG || BETA
//
//  CatalogKit.swift
//  DesignSystem
//
//  디자인 시스템 카탈로그 문서 틀. 카탈로그 화면 전용이라 앱 화면에서는 쓰지 않는다.
//  구분은 옅은 면과 간격으로만 한다(선·테두리를 넣지 않는다).
//

import SwiftUI

/// 문서가 속한 묶음.
enum CatalogGroup: String {
    case foundation = "기초"
    case component = "부품"
}

// MARK: - 문서 한 장

/// 문서 한 장의 골격: 분류 → 제목 → 한 줄 설명 → 메타 칩 → 절들.
struct CatalogDoc<Content: View>: View {
    let group: CatalogGroup
    let title: String
    let summary: String
    var chips: [String] = []
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.rawValue)
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.secondary)
                    Text(title)
                        .font(.pretendard.display1)
                        .foregroundStyle(Color.semantic.text.primary)
                    Text(summary)
                        .font(.pretendard.bodyM)
                        .foregroundStyle(Color.semantic.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !chips.isEmpty {
                        CatalogChips(chips: chips)
                            .padding(.top, 4)
                    }
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(Color.semantic.surface.container)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 실제로 센 값만 담는 작은 칩 줄.
struct CatalogChips: View {
    let chips: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(.pretendard.labelM)
                    .foregroundStyle(Color.semantic.interactive.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.semantic.surface.primarySubtle, in: Capsule())
            }
        }
    }
}

// MARK: - 절

/// 문서 안의 절 하나: 절 제목 + 설명(선택) + 내용.
struct CatalogSection<Content: View>: View {
    let title: String
    var note: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.pretendard.title3)
                .foregroundStyle(Color.semantic.text.primary)
            if let note {
                Text(note)
                    .font(.pretendard.bodyS)
                    .foregroundStyle(Color.semantic.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 견본을 올려 두는 회색 판.
struct CatalogPlate<Content: View>: View {
    var alignment: Alignment = .center
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(20)
            .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// 견본 아래에 이름을 붙인다.
struct CatalogCaptioned<Content: View>: View {
    let caption: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 8) {
            content()
            Text(caption)
                .font(.pretendard.labelM)
                .foregroundStyle(Color.semantic.text.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 해부도

/// 견본 위에 얹는 번호 표시.
struct CatalogMarker: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.pretendard.labelS)
            .foregroundStyle(Color.semantic.text.onDark)
            .frame(width: 18, height: 18)
            .background(Color.semantic.surface.overlaySurface, in: Circle())
    }
}

/// 번호별 이름 목록.
struct CatalogAnatomyList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    CatalogMarker(number: index + 1)
                    Text(item)
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - 좋은 예 / 피할 것

struct CatalogGuideline<Good: View, Bad: View>: View {
    let goodText: String
    let badText: String
    @ViewBuilder let good: () -> Good
    @ViewBuilder let bad: () -> Bad

    var body: some View {
        VStack(spacing: 12) {
            card(isGood: true, text: goodText, sample: AnyView(good()))
            card(isGood: false, text: badText, sample: AnyView(bad()))
        }
    }

    private func card(isGood: Bool, text: String, sample: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sample
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            Text(isGood ? "좋은 예" : "피할 것")
                .font(.pretendard.buttonS)
                .foregroundStyle(isGood ? Color.semantic.interactive.primary : Color.semantic.error.error)
            Text(text)
                .font(.pretendard.bodyS)
                .foregroundStyle(Color.semantic.text.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isGood ? Color.primitive.opacity.blue10 : Color.primitive.opacity.red10,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - 스펙

/// 스펙 표의 한 줄: 실제 칠해진 색 점 + 토큰 이름 + 쓰이는 자리.
struct CatalogColorSpec: Identifiable {
    let token: String
    let role: String
    let color: Color
    var id: String { token + role }
}

struct CatalogSpecTable: View {
    let colors: [CatalogColorSpec]
    var fonts: [(token: String, role: String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(colors) { spec in
                HStack(alignment: .top, spacing: 12) {
                    CatalogColorDot(color: spec.color)
                    rowText(token: spec.token, role: spec.role)
                }
            }
            ForEach(fonts, id: \.token) { font in
                HStack(alignment: .top, spacing: 12) {
                    Text("Aa")
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.primary)
                        .frame(width: 20)
                    rowText(token: font.token, role: font.role)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 16))
    }

    private func rowText(token: String, role: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(token)
                .font(.pretendard.labelM)
                .foregroundStyle(Color.semantic.text.primary)
                .textSelection(.enabled)
            Text(role)
                .font(.pretendard.labelM)
                .foregroundStyle(Color.semantic.text.secondary)
        }
    }
}

/// 비슷한 부품 비교 표: 이름 + 언제 쓰나.
struct CatalogCompareTable: View {
    let rows: [(token: String, role: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(rows, id: \.token) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.token)
                        .font(.pretendard.buttonS)
                        .foregroundStyle(Color.semantic.text.primary)
                    Text(row.role)
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// 실제 토큰 색을 칠한 점.
struct CatalogColorDot: View {
    let color: Color
    var size: CGFloat = 20

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - 접힘(옛 설명·경위)

struct CatalogNote: View {
    let title: String
    let text: String

    var body: some View {
        DisclosureGroup {
            Text(text)
                .font(.pretendard.bodyS)
                .foregroundStyle(Color.semantic.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } label: {
            Text(title)
                .font(.pretendard.bodyS)
                .foregroundStyle(Color.semantic.text.primary)
        }
        .tint(Color.semantic.text.secondary)
        .padding(16)
        .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 줄바꿈 배치

/// 칩·견본을 가로로 늘어놓다가 넘치면 다음 줄로 보낸다.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.originY + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        for row in rows {
            var posX = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: posX, y: bounds.minY + row.originY), proposal: .unspecified)
                posX += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        var originY: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let current = rows[rows.count - 1]
            if !current.indices.isEmpty, current.width + spacing + size.width > width {
                let originY = current.originY + current.height + spacing
                rows.append(Row(originY: originY))
            }
            let last = rows.count - 1
            rows[last].width += (rows[last].indices.isEmpty ? 0 : spacing) + size.width
            rows[last].height = max(rows[last].height, size.height)
            rows[last].indices.append(index)
        }
        return rows
    }
}

#endif
