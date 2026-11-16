//
//  MyHeaderPattern.swift
//  Presentation
//
//  MY 헤더 바탕 무늬와 무늬 고르기 시트 (#320).
//  무늬는 띠 색 위에 같은 계열 색으로 옅게 깐다. 고른 무늬는 이 기기에만 저장한다(서버 없음).
//

import SwiftUI
import DesignSystem
import Domain

// MARK: - MyHeaderPattern

public enum MyHeaderPattern: String, CaseIterable, Identifiable, Sendable {
    case oss
    case bigBelt
    case beltTip
    case wrap

    /// UserDefaults(@AppStorage) 키
    static let storageKey = "myHeaderPattern"

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .oss: return "OSS 손"
        case .bigBelt: return "큰 띠"
        case .beltTip: return "띠 끝"
        case .wrap: return "감긴 띠"
        }
    }
}

// MARK: - MyHeaderPatternView

/// 무늬 그림. 모양 수치는 시안(belt-kids5·6)의 SVG를 pt 그대로 옮겼고, 격자(OSS 손·띠 끝)는 1.5배로 성기게 했다.
/// `anchor`는 사진 가운데 — 띠 한 줄 무늬(큰 띠·감긴 띠)를 사진 아래에 걸치게 하는 기준이다.
struct MyHeaderPatternView: View, Equatable {
    let pattern: MyHeaderPattern
    let beltRank: BeltRank
    let anchor: UnitPoint
    /// 시트 미리보기처럼 작은 자리에서 무늬를 줄여 그린다.
    var scale: CGFloat = 1

    /// 사진이 시안(72)보다 큰 만큼(90) 사진 기준 거리만 늘린다.
    private let avatarScale: CGFloat = 90 / 72

    var body: some View {
        let shaka = Assets.Common.Shaka.icon.swiftUIImage.renderingMode(.template)
        Canvas { context, size in
            let center = CGPoint(x: size.width * anchor.x, y: size.height * anchor.y)
            context.translateBy(x: center.x, y: center.y)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -center.x, y: -center.y)
            let area = CGRect(
                x: center.x - center.x / scale,
                y: center.y - center.y / scale,
                width: size.width / scale,
                height: size.height / scale
            )

            switch pattern {
            case .oss:
                var symbol = context.resolve(shaka)
                symbol.shading = .color(ink(0.16))
                let rotations: [Double] = [-18, 12, -6, 20]
                tile(in: area, dx: 99, dy: 87) { point, index in
                    var tileContext = context
                    tileContext.translateBy(x: point.x + 17, y: point.y + 16)
                    tileContext.rotate(by: .degrees(rotations[index % 4]))
                    tileContext.draw(symbol, in: CGRect(x: -17, y: -16, width: 34, height: 32))
                }

            case .bigBelt:
                var band = context
                band.translateBy(x: center.x, y: center.y + 63 * avatarScale)
                band.rotate(by: .degrees(-16))
                let bandRect = CGRect(x: -area.width * 1.5, y: -18, width: area.width * 3, height: 34)
                band.fill(Path(roundedRect: bandRect, cornerRadius: 4), with: .color(ink(0.14)))
                let barX = 13 * avatarScale
                band.fill(Path(CGRect(x: barX, y: -18, width: 34, height: 34)), with: .color(ink(0.26)))
                for gapX in [barX + 10, barX + 18] {
                    band.fill(Path(CGRect(x: gapX, y: -18, width: 3, height: 34)), with: .color(beltRank.beltColor))
                }

            case .beltTip:
                tile(in: area, dx: 96, dy: 69) { point, _ in
                    var tip = context
                    tip.translateBy(x: point.x, y: point.y)
                    tip.rotate(by: .degrees(-24))
                    tip.fill(Path(roundedRect: CGRect(x: 0, y: 0, width: 34, height: 12), cornerRadius: 2), with: .color(ink(0.12)))
                    for gapX: CGFloat in [12, 19] {
                        tip.fill(Path(CGRect(x: gapX, y: 0, width: 3, height: 12)), with: .color(beltRank.beltColor))
                    }
                }

            case .wrap:
                var wrap = context
                wrap.translateBy(x: center.x, y: center.y + 43 * avatarScale)
                wrap.rotate(by: .degrees(-8))
                let width = area.width * 3
                wrap.fill(
                    Path(roundedRect: CGRect(x: -width / 2, y: -20 * avatarScale, width: width, height: 28), cornerRadius: 5),
                    with: .color(ink(0.13))
                )
                wrap.fill(
                    Path(roundedRect: CGRect(x: -width / 2, y: 14 * avatarScale, width: width, height: 28), cornerRadius: 5),
                    with: .color(ink(0.08))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 밝은 띠는 먹색을 조금 더 옅게(×0.55), 나머지는 흰색.
    /// 시안 값(alpha)보다 절반으로 옅게 깐다 — 시안대로는 무늬가 시끄러웠다.
    private func ink(_ alpha: Double) -> Color {
        let calmAlpha = alpha * 0.5
        return beltRank.isLightBelt
            ? Color.component.myBelt.lightInk.opacity(calmAlpha * 0.55)
            : Color.primitive.bw.trueWhite.opacity(calmAlpha)
    }

    /// 엇갈린 격자 — 홀수 줄은 반 칸 민다. index는 그린 순서(회전을 돌려 쓰는 데 쓴다).
    private func tile(in area: CGRect, dx: CGFloat, dy: CGFloat, draw: (CGPoint, Int) -> Void) {
        var index = 0
        var row = 0
        var y = area.minY - dy
        while y < area.maxY {
            var x = area.minX - dx
            while x < area.maxX {
                draw(CGPoint(x: x + (row % 2 == 1 ? dx / 2 : 0), y: y), index)
                index += 1
                x += dx
            }
            y += dy
            row += 1
        }
    }
}

// MARK: - MyHeaderPatternSheetView

/// "배경 고르기" 시트 — 프로필 사진 수정 시트와 같은 손잡이·제목·CTA 모양.
struct MyHeaderPatternSheetView: View {
    let beltRank: BeltRank
    let onApply: (MyHeaderPattern) -> Void

    @State private var selection: MyHeaderPattern

    init(current: MyHeaderPattern, beltRank: BeltRank, onApply: @escaping (MyHeaderPattern) -> Void) {
        self.beltRank = beltRank
        self.onApply = onApply
        _selection = State(initialValue: current)
    }

    /// 바텀 시트 detent용 본문 높이: 24(handle) + 48(title) + 16+20(top) + 104+8+20(thumb·label) + 20(bottom) + 8+51+24(CTA)
    static let contentHeight: CGFloat = 343

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.component.bottomSheet.selected.container.handle)
                .frame(width: 48, height: 4)
                .frame(maxWidth: .infinity)
                .frame(height: 24)

            Text("배경 고르기")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
                .frame(height: 48, alignment: .bottom)
                .padding(.horizontal, 20)

            HStack(spacing: 8) {
                ForEach(MyHeaderPattern.allCases) { pattern in
                    thumbnail(pattern)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .padding(.top, 16)

            CTAButton(title: "적용하기") {
                onApply(selection)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
    }

    private func thumbnail(_ pattern: MyHeaderPattern) -> some View {
        let isSelected = pattern == selection
        return Button {
            selection = pattern
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    beltRank.beltColor
                    MyHeaderPatternView(pattern: pattern, beltRank: beltRank, anchor: UnitPoint(x: 0.5, y: 0.2), scale: 0.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.semantic.interactive.primary, lineWidth: 2)
                    }
                }

                Text(pattern.title)
                    .font(Font.pretendard.labelM)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(
                        isSelected
                            ? Color.semantic.interactive.primary
                            : Color.component.bottomSheet.unselected.listItem.label
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pattern.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("MyHeaderPatternSheetView") {
    MyHeaderPatternSheetView(current: .oss, beltRank: .blue, onApply: { _ in })
}
