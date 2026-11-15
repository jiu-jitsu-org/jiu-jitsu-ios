#if DEBUG || BETA
//
//  MiscDocs.swift
//  DesignSystem
//
//  부품 — 시트 피커 · 로티 움직임 · 띠 캐릭터. 실제 SheetPickerView·JJSLottieView·BeltCharacter 로 그린다.
//

import SwiftUI

// MARK: - 시트 피커

struct SheetPickerDoc: View {
    private struct Number: Identifiable, Hashable {
        let id: Int
    }

    private let numbers = (2016...2026).map { Number(id: $0) }

    @State private var standardPick = Number(id: 2024)
    @State private var wheelPick = Number(id: 2024)
    @State private var beltPick: BeltOption = .blue

    private enum BeltOption: String, CaseIterable, Identifiable, Hashable {
        case white = "화이트", blue = "블루", purple = "퍼플", brown = "브라운", black = "블랙"

        var id: String { rawValue }

        var color: BeltSelectButton.BeltColor {
            switch self {
            case .white: .white
            case .blue: .blue
            case .purple: .purple
            case .brown: .brown
            case .black: .black
            }
        }
    }

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "시트 피커",
            summary: "목록을 위아래로 굴려 값 하나를 고른다. 대회 연도·결과·띠를 고르는 화면에서 쓴다. 고른 값은 부르는 쪽이 들고 있는다(onSelect).",
            chips: ["쓰는 곳 7(5화면)", "모양 2", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "변형", note: "standard 는 3줄, wheel 은 5줄이 보인다. 굴려 본다.") {
                CatalogPlate {
                    HStack(alignment: .top, spacing: 12) {
                        CatalogCaptioned(caption: "standard") {
                            SheetPickerView(
                                items: numbers,
                                selectedItem: standardPick,
                                displayText: { "\($0.id)" },
                                onSelect: { standardPick = $0 }
                            )
                        }
                        CatalogCaptioned(caption: "wheel") {
                            SheetPickerView(
                                items: numbers,
                                selectedItem: wheelPick,
                                displayText: { "\($0.id)" },
                                style: .wheel,
                                onSelect: { wheelPick = $0 }
                            )
                        }
                    }
                }
            }

            CatalogSection(title: "아이콘 붙이기", note: "대회 띠 고르기처럼 고른 줄만 아이콘을 크게 바꿀 수 있다(iconView).") {
                CatalogPlate {
                    SheetPickerView(
                        items: BeltOption.allCases,
                        selectedItem: beltPick,
                        displayText: { $0.rawValue },
                        iconView: { belt, isSelected in
                            AnyView(BeltIcon(color: belt.color, size: isSelected ? .regular : .compact))
                        },
                        width: 180,
                        style: .wheel,
                        onSelect: { beltPick = $0 }
                    )
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(colors: [
                    CatalogColorSpec(token: "component.picker.itemSelectedBg", role: "고른 줄 면", color: Color.component.picker.itemSelectedBg),
                    CatalogColorSpec(token: "component.picker.itemSelectedText", role: "고른 줄 글자", color: Color.component.picker.itemSelectedText),
                    CatalogColorSpec(token: "component.picker.itemUnselectedText", role: "다른 줄 글자", color: Color.component.picker.itemUnselectedText),
                    CatalogColorSpec(token: "component.picker.unit", role: "단위", color: Color.component.picker.unit)
                ])
            }
        }
    }
}

// MARK: - 로티 움직임

struct LottieDoc: View {
    var body: some View {
        CatalogDoc(
            group: .component,
            title: "로티 움직임",
            summary: "Resources/Lottie 의 .lottie 파일을 재생한다. 지금 들어 있는 움직임은 Confetti 하나.",
            chips: ["쓰는 곳 1", "파일 1", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "JJSLottieView(\"Confetti\") · 기본 반복 재생") {
                CatalogPlate {
                    JJSLottieView("Confetti")
                        .frame(height: 240)
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "축하처럼 한 번 크게 기뻐할 때만 쓴다.",
                    badText: "목록·버튼처럼 자주 보는 곳에 반복 재생으로 두지 않는다."
                ) {
                    Text("띠 승급 축하")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                } bad: {
                    Text("목록 줄마다 반짝이")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.primary)
                }
            }
        }
    }
}

// MARK: - 띠 캐릭터

struct BeltCharacterDoc: View {
    @State private var pose: BeltPose = .greet
    @State private var face: BeltFace = .happy

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "띠 캐릭터",
            summary: "띠 끝을 캐릭터로 쓴다. 굽은 몸(자세)에 표정을 얹어 BeltCharacter(pose:face:) 로 그린다.",
            chips: ["자세 \(BeltPose.allCases.count)", "표정 \(BeltFace.allCases.count)", "앱 화면 쓰는 곳 0", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요", note: "아래 자세·표정을 눌러 조합해 본다.") {
                CatalogPlate {
                    CatalogCaptioned(caption: "\(pose.rawValue) · \(face.rawValue)") {
                        BeltCharacter(pose: pose, face: face)
                            .frame(width: 140)
                    }
                }
            }

            CatalogSection(title: "자세", note: "표정은 happy 로 고정") {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(BeltPose.allCases, id: \.self) { item in
                        Button { pose = item } label: {
                            cell(name: item.rawValue, isSelected: item == pose) {
                                BeltCharacter(pose: item, face: .happy)
                                    .frame(width: 44)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            CatalogSection(title: "표정", note: "자세는 greet 로 고정") {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(BeltFace.allCases, id: \.self) { item in
                        Button { face = item } label: {
                            cell(name: item.rawValue, isSelected: item == face) {
                                BeltCharacter(pose: .greet, face: item)
                                    .frame(width: 44)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "자세와 표정을 함께 골라 감정을 만든다. 몸이 휘는 방향이 감정을 말한다.",
                    badText: "표정만 바꾸고 같은 자세를 계속 쓰지 않는다. 감정이 잘 안 읽힌다."
                ) {
                    BeltCharacter(pose: .droop, face: .sad)
                        .frame(width: 56)
                } bad: {
                    BeltCharacter(pose: .standTall, face: .sad)
                        .frame(width: 56)
                }
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "캐릭터는 띠 끝이다 — 아래 굵은 부분은 매듭이고, 팔다리는 검은색, 얼굴은 평면 표정을 원통에 감아 붙인다. 자세마다 얼굴을 붙일 자리(BeltFaceAnchor)가 정해져 있다."
            )
        }
    }

    private func cell<Content: View>(name: String, isSelected: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) {
            content()
                .frame(height: 64)
            Text(name)
                .font(.pretendard.labelS)
                .foregroundStyle(isSelected ? Color.semantic.interactive.primary : Color.semantic.text.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            isSelected ? Color.semantic.surface.primarySubtle : Color.component.background.default,
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

#Preview("시트 피커") {
    NavigationStack { SheetPickerDoc() }
}

#Preview("로티 움직임") {
    NavigationStack { LottieDoc() }
}

#Preview("띠 캐릭터") {
    NavigationStack { BeltCharacterDoc() }
}

#endif
