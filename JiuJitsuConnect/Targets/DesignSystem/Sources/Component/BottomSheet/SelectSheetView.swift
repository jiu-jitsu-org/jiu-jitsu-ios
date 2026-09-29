//
//  SelectSheetView.swift
//  DesignSystem
//
//  선택 바텀시트(핸들바 · 제목/설명 · 라디오 목록 · 자유 입력 · 하단 CTA).
//  문구·항목은 호출부가 configuration으로 넘기고, 이 뷰는 표시·선택 상태와 시트 높이 단계를 소유한다.
//  (웹 브릿지 SHOW_SELECT_SHEET 계약의 네이티브 셸 — 신고 사유 선택 등에 사용)
//  딤·표시 전환은 호출부 overlay가 담당하고, 시트 카드(배경·라운드·높이·드래그)는 이 뷰가 그린다.
//
//  높이 정책(#38): 중간(기본) · 확장 2단.
//  - 중간: 콘텐츠에 맞춘 높이. 사유 목록 + CTA(+「기타」 입력창)가 모두 보인다.
//  - 확장: 상태바 바로 아래(여백 0)까지. 키보드 때문에 콘텐츠가 중간에 다 안 들어갈 때 자동 전환되고,
//    키보드를 내려도 유지된다. 줄어드는 건 사용자 드래그 또는 「기타」 입력창이 사라질 때뿐이다.
//

import SwiftUI

// MARK: - Configuration

public struct SelectSheetConfiguration: Equatable {
    public struct Option: Equatable, Identifiable {
        public let value: String
        public let label: String
        /// 고르면 자유 입력 필드를 함께 노출한다("기타" 등).
        public let allowsCustomText: Bool
        public var id: String { value }

        public init(value: String, label: String, allowsCustomText: Bool) {
            self.value = value
            self.label = label
            self.allowsCustomText = allowsCustomText
        }
    }

    public let title: String
    public let message: String?
    public let options: [Option]
    public let customTextPlaceholder: String?
    public let submitText: String

    public init(
        title: String,
        message: String?,
        options: [Option],
        customTextPlaceholder: String?,
        submitText: String
    ) {
        self.title = title
        self.message = message
        self.options = options
        self.customTextPlaceholder = customTextPlaceholder
        self.submitText = submitText
    }
}

/// 시트가 놓이는 화면 치수. 높이 단계는 상태바·홈 인디케이터·키보드 영역을 알아야 계산되므로
/// safe area를 아는 호출부(GeometryReader)가 넘긴다.
public struct SelectSheetScreenMetrics: Equatable {
    /// safe area를 포함한 화면 전체 높이.
    public let height: CGFloat
    public let topInset: CGFloat
    /// 키보드가 올라와 있으면 키보드 높이, 아니면 홈 인디케이터 높이.
    public let bottomInset: CGFloat

    public init(height: CGFloat, topInset: CGFloat, bottomInset: CGFloat) {
        self.height = height
        self.topInset = topInset
        self.bottomInset = bottomInset
    }
}

// MARK: - SelectSheetView

public struct SelectSheetView: View {
    private enum Detent {
        case medium
        case expanded
    }

    /// 드래그 한 번이 무엇을 움직이는지. 시작 시점에 한 번 정하고 끝날 때까지 바꾸지 않는다
    /// (도중에 키보드가 내려가도 같은 드래그로 시트까지 끌려 내려가지 않게).
    private enum DragMode {
        case idle
        case keyboard
        case sheet
        case ignored
    }

    private enum Metrics {
        static let handleAreaHeight: CGFloat = 24
        static let ctaTopSpacing: CGFloat = 24
        static let ctaHeight: CGFloat = 51
        static let cornerRadius: CGFloat = 24
        // FIXME: 디자인 예시 이미지 기준 추정값 — 디자인 가이드 값 확인 후 교체
        /// 키보드 위에 붙은 CTA와 키보드 사이 간격. 키보드가 없을 땐 홈 인디케이터 영역이 간격 역할을 한다.
        static let ctaKeyboardSpacing: CGFloat = 10
        /// 하단 inset이 이보다 크면 키보드로 본다(홈 인디케이터 34pt와 키보드 최소 높이 사이).
        static let keyboardDetectionInset: CGFloat = 100
        /// 이만큼 아래로 끌면(관성 포함) 키보드를 내린다.
        static let keyboardDismissDistance: CGFloat = 20
        /// 중간 높이에서 이만큼 아래로 끌면(관성 포함) 시트를 닫는다.
        static let dismissDistance: CGFloat = 100
        // 위로 끌 때의 고무줄 저항 — View+BottomSheet와 같은 곡선.
        static let stretchBaseResistance: CGFloat = 3
        static let stretchResistanceScale: CGFloat = 150
        static let stretchMaxHeight: CGFloat = 50
    }

    private enum Timing {
        /// UIKit 키보드 등장/퇴장 곡선의 스프링 근사값. 시트 높이가 키보드와 같은 타이밍·이징으로 움직이게 한다.
        static let keyboardSync = Animation.interpolatingSpring(mass: 3, stiffness: 1000, damping: 500)
        static let snap = Animation.spring(response: 0.4, dampingFraction: 0.8)
    }

    private static let customTextFieldID = "customTextField"

    private let configuration: SelectSheetConfiguration
    private let screen: SelectSheetScreenMetrics
    /// 제출 시 선택된 항목의 value(+자유 입력 항목이면 입력 문구)를 전달한다.
    private let onSubmit: (_ value: String, _ customText: String?) -> Void
    /// 드래그로 닫힘.
    private let onDismiss: () -> Void

    // 선택·높이 상태는 셸이 소유한다 — 시트가 닫히면 언마운트되어 다음 표시 때 항상 초기화된다(진입 시 항상 중간).
    @State private var selectedValue: String?
    @State private var customText: String = ""
    @FocusState private var isCustomTextFocused: Bool
    @State private var detent: Detent = .medium
    /// 스크롤 본문(제목~입력창)의 실제 높이. 첫 측정 전에는 nil.
    @State private var contentHeight: CGFloat?
    /// 다음 콘텐츠 높이 변화를 키보드와 같은 곡선으로 애니메이션할지. 「기타」 입력창이 사라질 때만 켠다.
    @State private var animatesNextContentResize = false
    @State private var dragMode: DragMode = .idle
    @State private var dragTranslation: CGFloat = 0
    @State private var isBodyScrolledToTop = true

    public init(
        configuration: SelectSheetConfiguration,
        screen: SelectSheetScreenMetrics,
        onSubmit: @escaping (_ value: String, _ customText: String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.screen = screen
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
    }

    private var selectedOption: SelectSheetConfiguration.Option? {
        configuration.options.first { $0.value == selectedValue }
    }

    private var needsCustomText: Bool {
        selectedOption?.allowsCustomText == true
    }

    // 정책: 사유만 선택하면 제출 가능. "기타"도 상세 입력 없이 제출을 허용한다.
    private var canSubmit: Bool {
        selectedOption != nil
    }

    // MARK: Layout

    private var isKeyboardVisible: Bool {
        screen.bottomInset > Metrics.keyboardDetectionInset
    }

    /// CTA 아래 영역. 키보드가 있으면 키보드 위에 간격을 두고 붙고, 없으면 홈 인디케이터 위로 돌아간다.
    private var bottomAreaHeight: CGFloat {
        isKeyboardVisible ? screen.bottomInset + Metrics.ctaKeyboardSpacing : screen.bottomInset
    }

    /// 스크롤 본문을 뺀 고정 요소(핸들 · CTA · 하단 영역) 높이.
    private var chromeHeight: CGFloat {
        Metrics.handleAreaHeight + Metrics.ctaTopSpacing + Metrics.ctaHeight + bottomAreaHeight
    }

    /// 확장 높이: 상태바 바로 아래까지(디자인 가이드 여백 0pt).
    private var expandedHeight: CGFloat {
        screen.height - screen.topInset
    }

    /// 중간 높이: 콘텐츠에 맞추되 확장 높이를 넘지 않는다.
    private var mediumHeight: CGFloat? {
        contentHeight.map { min(chromeHeight + $0, expandedHeight) }
    }

    /// 키보드 때문에 콘텐츠가 중간 높이에 다 안 들어가는지. 이때 확장으로 스냅한다.
    private var keyboardNeedsExpansion: Bool {
        guard isKeyboardVisible, let contentHeight else { return false }
        return chromeHeight + contentHeight > expandedHeight
    }

    private var restingHeight: CGFloat? {
        detent == .expanded ? expandedHeight : mediumHeight
    }

    /// 드래그를 반영한 시트 높이와 아래로 밀린 거리. 측정 전(nil)에는 콘텐츠 크기에 맡긴다.
    private var sheetFrame: (height: CGFloat?, offset: CGFloat) {
        guard let restingHeight, let mediumHeight else { return (nil, 0) }
        let proposed = restingHeight - dragTranslation
        if proposed > restingHeight {
            // 위로: 중간은 콘텐츠에 맞춘 높이라 더 드러낼 내용이 없고, 확장은 이미 상태바에 닿아 있다.
            // 늘어나는 저항만 주고 손을 떼면 제자리로 돌아온다.
            let stretched = restingHeight + stretch(proposed - restingHeight)
            return (min(stretched, expandedHeight), 0)
        }
        if detent == .expanded {
            // 확장에서 아래로: 중간 높이까지 줄어든다. 닫힘은 중간에서만 일어난다.
            return (max(proposed, mediumHeight), 0)
        }
        return (restingHeight, restingHeight - proposed)
    }

    private func stretch(_ distance: CGFloat) -> CGFloat {
        let resistance = Metrics.stretchBaseResistance + distance / Metrics.stretchResistanceScale
        return min(distance / resistance, Metrics.stretchMaxHeight)
    }

    // MARK: Body

    public var body: some View {
        let frame = sheetFrame
        VStack(spacing: 0) {
            handle

            ScrollViewReader { proxy in
                scrollBody(proxy: proxy)
            }
            .frame(height: frame.height.map { max($0 - chromeHeight, 0) })

            submitButton
                .padding(.horizontal, 20)
                .padding(.top, Metrics.ctaTopSpacing)

            // 홈 인디케이터(또는 키보드) 영역까지 시트 배경을 연장한다(회색 갭 방지).
            Color.clear
                .frame(height: bottomAreaHeight)
        }
        .frame(height: frame.height, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
        .clipShape(.rect(topLeadingRadius: Metrics.cornerRadius, topTrailingRadius: Metrics.cornerRadius))
        .offset(y: frame.offset)
        .onChange(of: keyboardNeedsExpansion) { _, needsExpansion in
            // 표시 높이는 이미 키보드 레이아웃 패스에서 확장 높이로 계산됐다(키보드와 같은 애니메이션).
            // 여기서는 키보드가 내려가도 확장을 유지하도록 상태만 고정한다.
            if needsExpansion { detent = .expanded }
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Color.component.bottomSheet.selected.container.handle)
            .frame(width: 40, height: 4)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.handleAreaHeight)
            .contentShape(Rectangle())
            .onTapGesture { isCustomTextFocused = false }
            // 핸들을 잡고 끌면 본문 스크롤 위치와 관계없이 시트가 바로 움직인다.
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragChanged(value.translation.height, allowsSheetMove: true)
                    }
                    .onEnded { value in
                        dragEnded(predictedTranslation: value.predictedEndTranslation.height)
                    }
            )
    }

    private func scrollBody(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                optionList

                if needsCustomText {
                    customTextField
                        .padding(.top, 4)
                        .id(Self.customTextFieldID)
                }
            }
            .padding(.horizontal, 20)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { newHeight in
                updateContentHeight(newHeight)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // 본문을 당겨 시트를 옮기는 동안에는 본문 자체가 바운스되지 않게 스크롤을 잠근다.
        .scrollDisabled(dragMode == .sheet)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y <= -geometry.contentInsets.top
        } action: { _, isAtTop in
            isBodyScrolledToTop = isAtTop
        }
        // 본문을 아래로 쓸면: 키보드가 있으면 키보드만, 없으면 본문이 맨 위일 때만 시트가 움직인다.
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let height = value.translation.height
                    dragChanged(height, allowsSheetMove: isBodyScrolledToTop && height > 0)
                }
                .onEnded { value in
                    dragEnded(predictedTranslation: value.predictedEndTranslation.height)
                }
        )
        .onChange(of: isKeyboardVisible) { _, isVisible in
            // 포커스 시 입력창이 CTA 바로 위에 보이도록 맞춘다. 키보드 레이아웃이 끝난 뒤라야 위치가 맞는다.
            guard isVisible, isCustomTextFocused else { return }
            withAnimation(Timing.keyboardSync) {
                proxy.scrollTo(Self.customTextFieldID, anchor: .bottom)
            }
        }
        .onChange(of: customText) {
            // 줄이 늘어나도 입력 중인 줄이 CTA 뒤로 숨지 않게 따라간다.
            guard isCustomTextFocused else { return }
            proxy.scrollTo(Self.customTextFieldID, anchor: .bottom)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(configuration.title)
                .font(.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .padding(.top, 24)

            if let message = configuration.message {
                Text(message)
                    .font(.pretendard.labelM)
                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // 키보드를 내리려고 빈 곳을 탭하는 경우 — 선택은 바꾸지 않고 키보드만 내린다.
        .onTapGesture { isCustomTextFocused = false }
    }

    private var optionList: some View {
        VStack(spacing: 4) {
            ForEach(configuration.options) { option in
                optionRow(option)
            }
        }
        .padding(.top, 16)
        // 각 행의 좌우 8 탭 여백을 콘텐츠(20) 바깥으로 빼, 라디오/텍스트는 20 정렬을 유지한다.
        .padding(.horizontal, -8)
        // 행 사이 간격 탭도 키보드만 내린다. 행(Button) 탭은 자식 제스처가 우선해 선택으로 처리된다.
        .contentShape(Rectangle())
        .onTapGesture { isCustomTextFocused = false }
    }

    private func optionRow(_ option: SelectSheetConfiguration.Option) -> some View {
        let isSelected = option.value == selectedValue
        return Button {
            select(option)
        } label: {
            HStack(spacing: 9) {
                radio(isSelected: isSelected)
                Text(option.label)
                    .font(.pretendard.bodyS)
                    // 선택 여부와 무관하게 동일 폰트·색상.
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.label)
                Spacer(minLength: 0)
            }
            // 탭 영역: [8 마진][라디오 24][9][텍스트][8 마진]. 좌우 8은 탭 여백에 포함된다.
            .padding(.horizontal, 8)
            .frame(height: 40)
            .contentShape(Rectangle())
            // PlainButtonStyle은 눌림 해제를 자기 animation transaction으로 커밋하는데, 그 transaction이
            // label subtree까지 흐른다. "기타" 선택으로 입력창이 끼어들어 시트 레이아웃이 바뀌면 다른 행은
            // 즉시 점프하지만 방금 탭한 행의 라디오·글자만 옛 위치에서 새 위치로 흘러가 "글자가 움직이는"
            // 잔상이 생긴다(#19). label 안에서 animation을 끊어 눌림 페이드만 남기고 위치는 즉시 확정한다.
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .buttonStyle(.plain)
    }

    private func select(_ option: SelectSheetConfiguration.Option) {
        let hidesCustomText = needsCustomText && option.allowsCustomText == false
        selectedValue = option.value
        guard option.allowsCustomText == false else { return }
        // 입력 중에도 다른 사유를 바로 고를 수 있다(정책). 입력한 문구는 지우지 않아
        // 잘못 탭했어도 「기타」를 다시 누르면 그대로 돌아온다 — 제출 시 기타가 아니면 싣지 않는다.
        isCustomTextFocused = false
        if hidesCustomText {
            // 입력창이 사라지면 확장에 남아 CTA 위에 빈 공간이 생기므로 중간으로 돌아간다(#38).
            // 키보드가 내려가는 것과 같은 곡선으로 함께 움직인다.
            animatesNextContentResize = true
            withAnimation(Timing.keyboardSync) {
                detent = .medium
            }
        }
    }

    private func updateContentHeight(_ newHeight: CGFloat) {
        guard animatesNextContentResize else {
            contentHeight = newHeight
            return
        }
        animatesNextContentResize = false
        withAnimation(Timing.keyboardSync) {
            contentHeight = newHeight
        }
    }

    private func radio(isSelected: Bool) -> some View {
        // 선택/미선택 아이콘은 디자인 에셋(16×16)을 24×24 라디오 영역 중앙에 둔다.
        (isSelected ? Assets.Common.Icon.radioOn : Assets.Common.Icon.radioOff)
            .swiftUIImage
            .resizable()
            .frame(width: 16, height: 16)
            .frame(width: 24, height: 24)
    }

    private var customTextField: some View {
        // SwiftUI 기본 TextField는 placeholder 색을 못 바꿔, placeholder를 커스텀 오버레이로 그린다.
        // 입력 텍스트는 focused 색, placeholder는 default 색으로 분리한다.
        TextField("", text: $customText, axis: .vertical)
            .focused($isCustomTextFocused)
            .font(.pretendard.bodyS)
            .foregroundStyle(Color.component.textfieldMultiline.focused.text)
            // 정책: 2줄 높이로 시작해 입력에 따라 5줄까지 늘어나고, 그 이상은 높이를 고정한 채 내부 스크롤.
            // `reservesSpace: true`는 빈 상태에서도 5줄을 예약해 시트가 열리자마자 최대 높이가 되므로 쓰지 않는다.
            .lineLimit(2...5)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.component.textfieldMultiline.filled.bg)
            .overlay(alignment: .topLeading) {
                if customText.isEmpty {
                    Text(configuration.customTextPlaceholder ?? "")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.component.textfieldMultiline.default.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            // 포커스 중에만 안쪽 1pt 보더를 얹고, 해제되면 원상복귀한다.
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.component.textfieldMultiline.focused.border, lineWidth: 1)
                    .opacity(isCustomTextFocused ? 1 : 0)
                    .allowsHitTesting(false)
            }
    }

    private var submitButton: some View {
        Button {
            guard let option = selectedOption else { return }
            // "기타"에 실제 입력이 있을 때만 상세를 싣는다(빈 값은 nil로 생략).
            let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = needsCustomText && !trimmed.isEmpty ? trimmed : nil
            onSubmit(option.value, detail)
        } label: {
            AppButtonConfiguration(title: configuration.submitText, size: .large)
                .frame(maxWidth: .infinity)
        }
        .appButtonStyle(.primary, size: .large, height: Metrics.ctaHeight)
        .disabled(!canSubmit)
    }

    // MARK: Drag

    private func dragChanged(_ translation: CGFloat, allowsSheetMove: Bool) {
        if dragMode == .idle {
            dragMode = startMode(translation: translation, allowsSheetMove: allowsSheetMove)
        }
        switch dragMode {
        case .keyboard:
            // 키보드가 있을 때 아래로 쓸면 키보드만 내린다. 시트 높이는 그대로.
            if translation > Metrics.keyboardDismissDistance {
                isCustomTextFocused = false
            }
        case .sheet:
            dragTranslation = translation
        case .idle, .ignored:
            break
        }
    }

    private func startMode(translation: CGFloat, allowsSheetMove: Bool) -> DragMode {
        if isKeyboardVisible {
            return translation > 0 ? .keyboard : .ignored
        }
        // 본문에서 시작한 드래그는 본문이 맨 위이고 아래로 당길 때만 시트를 움직인다(그 외엔 본문 스크롤).
        return allowsSheetMove ? .sheet : .ignored
    }

    private func dragEnded(predictedTranslation: CGFloat) {
        defer { dragMode = .idle }
        guard dragMode == .sheet else { return }

        if detent == .medium, predictedTranslation > Metrics.dismissDistance {
            // 밀린 위치 그대로 두고 닫는다 — 되돌리면 제자리로 튀었다가 내려가 보인다.
            onDismiss()
            return
        }
        withAnimation(Timing.snap) {
            if detent == .expanded, let mediumHeight,
               predictedTranslation > (expandedHeight - mediumHeight) / 2 {
                detent = .medium
            }
            dragTranslation = 0
        }
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geometry in
        ZStack(alignment: .bottom) {
            Color.component.bottomSheet.selected.container.scrim
            SelectSheetView(
                configuration: SelectSheetConfiguration(
                    title: "어떤 문제인가요?",
                    message: "신고는 익명으로 처리되며, 검토 후 조치돼요.",
                    options: [
                        .init(value: "ABUSE", label: "욕설 및 비방", allowsCustomText: false),
                        .init(value: "SPAM", label: "광고 및 홍보", allowsCustomText: false),
                        .init(value: "ADULT", label: "음란 또는 부적절한 콘텐츠", allowsCustomText: false),
                        .init(value: "INCITEMENT", label: "분쟁유도", allowsCustomText: false),
                        .init(value: "HARASSMENT", label: "혐오 및 괴롭힘", allowsCustomText: false),
                        .init(value: "OTHER", label: "기타", allowsCustomText: true),
                    ],
                    customTextPlaceholder: "신고할 내용을 입력해주세요.",
                    submitText: "신고하기"
                ),
                screen: SelectSheetScreenMetrics(
                    height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom,
                    topInset: geometry.safeAreaInsets.top,
                    bottomInset: geometry.safeAreaInsets.bottom
                ),
                onSubmit: { _, _ in },
                onDismiss: {}
            )
        }
        .ignoresSafeArea()
    }
}
