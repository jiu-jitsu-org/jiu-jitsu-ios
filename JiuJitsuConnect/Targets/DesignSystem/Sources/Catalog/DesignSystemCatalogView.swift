#if DEBUG || BETA
//
//  DesignSystemCatalogView.swift
//  DesignSystem
//
//  디자인 시스템 카탈로그 첫 화면. 기초·부품 문서 목록에서 한 장씩 연다.
//  Debug·Beta 빌드에만 들어간다(Release 에서는 컴파일되지 않는다).
//

import SwiftUI

/// 카탈로그 문서 목록.
enum CatalogPage: String, CaseIterable, Hashable, Identifiable {
    // 기초
    case color, typography, asset
    // 부품
    case button, textField, toast, alert, segmentControl
    case ctaButton, beltSelectButton, bottomSheet, selectSheet, termsRow, sheetPicker, lottie, beltCharacter

    var id: String { rawValue }

    var group: CatalogGroup {
        switch self {
        case .color, .typography, .asset: .foundation
        default: .component
        }
    }

    var title: String {
        switch self {
        case .color: "색"
        case .typography: "글자"
        case .asset: "에셋"
        case .button: "버튼"
        case .textField: "입력칸"
        case .toast: "토스트"
        case .alert: "알림창"
        case .segmentControl: "세그먼트"
        case .ctaButton: "CTA 버튼"
        case .beltSelectButton: "띠 고르기 버튼"
        case .bottomSheet: "바텀시트"
        case .selectSheet: "고르기 시트"
        case .termsRow: "약관 동의 줄"
        case .sheetPicker: "시트 피커"
        case .lottie: "로티 움직임"
        case .beltCharacter: "띠 캐릭터"
        }
    }

    var summary: String {
        switch self {
        case .color: "Primitive → Semantic → Component 3단 색 토큰"
        case .typography: "Pretendard 12단계와 CookieRun"
        case .asset: "아이콘·띠 캐릭터·메달 등 SwiftGen 이미지"
        case .button: "appButtonStyle — 화면 안의 일반 버튼"
        case .textField: "MultilineTextField — 가운데 정렬 큰 입력칸"
        case .toast: "아래에서 떠오르는 짧은 알림"
        case .alert: "확인을 받는 가운데 알림창"
        case .segmentControl: "둘 중 하나를 고르는 칸"
        case .ctaButton: "화면 아래 꽉 찬 주요 버튼"
        case .beltSelectButton: "띠 색·그랄을 고르는 버튼"
        case .bottomSheet: "아래에서 올라오는 시트 틀"
        case .selectSheet: "항목 하나를 골라 보내는 시트"
        case .termsRow: "약관 시트의 체크 줄"
        case .sheetPicker: "시트 안에서 굴려 고르는 목록"
        case .lottie: "Lottie 움직임 재생"
        case .beltCharacter: "띠 끝 캐릭터의 자세와 표정"
        }
    }

    static var foundations: [CatalogPage] { allCases.filter { $0.group == .foundation } }
    static var components: [CatalogPage] { allCases.filter { $0.group == .component } }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .color: ColorDoc()
        case .typography: TypographyDoc()
        case .asset: AssetDoc()
        case .button: ButtonDoc()
        case .textField: TextFieldDoc()
        case .toast: ToastDoc()
        case .alert: AlertDoc()
        case .segmentControl: SegmentControlDoc()
        case .ctaButton: CTAButtonDoc()
        case .beltSelectButton: BeltSelectButtonDoc()
        case .bottomSheet: BottomSheetDoc()
        case .selectSheet: SelectSheetDoc()
        case .termsRow: TermsRowDoc()
        case .sheetPicker: SheetPickerDoc()
        case .lottie: LottieDoc()
        case .beltCharacter: BeltCharacterDoc()
        }
    }
}

/// 카탈로그 첫 화면 — 목록(기초 / 부품) → 문서 한 장.
public struct DesignSystemCatalogView: View {
    private let initialPage: CatalogPage?
    private let onClose: (() -> Void)?
    @State private var path: [CatalogPage] = []

    /// - Parameters:
    ///   - openingPage: 바로 열 문서 이름(`CatalogPage` rawValue, 예: "button"). 캡처·점검용.
    ///   - onClose: 전체 화면으로 띄웠을 때 목록 왼쪽 위 '닫기'를 누르면 부른다. nil 이면 닫기를 그리지 않는다.
    public init(openingPage: String? = nil, onClose: (() -> Void)? = nil) {
        initialPage = openingPage.flatMap(CatalogPage.init(rawValue:))
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Text("기초 \(CatalogPage.foundations.count)장 · 부품 \(CatalogPage.components.count)장")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.semantic.text.secondary)
                }
                section(.foundation, pages: CatalogPage.foundations)
                section(.component, pages: CatalogPage.components)
            }
            .navigationTitle("디자인 시스템")
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("닫기", action: onClose)
                    }
                }
            }
            .navigationDestination(for: CatalogPage.self) { page in
                page.destination
            }
        }
        .tint(Color.semantic.interactive.primary)
        // 앱은 라이트 전용이라 카탈로그도 시스템 다크 설정과 상관없이 라이트로 그린다.
        .preferredColorScheme(.light)
        .onAppear {
            if let initialPage, path.isEmpty {
                path = [initialPage]
            }
        }
    }

    private func section(_ group: CatalogGroup, pages: [CatalogPage]) -> some View {
        Section {
            ForEach(pages) { page in
                NavigationLink(value: page) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(page.title)
                            .font(.pretendard.bodyM)
                            .foregroundStyle(Color.semantic.text.primary)
                        Text(page.summary)
                            .font(.pretendard.labelM)
                            .foregroundStyle(Color.semantic.text.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text(group.rawValue)
                .font(.pretendard.labelM)
        }
    }
}

#Preview("디자인 시스템 카탈로그") {
    DesignSystemCatalogView()
}

#endif
