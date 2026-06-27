//
//  SelectSheetView.swift
//  DesignSystem
//
//  선택 바텀시트 셸(핸들바 · 제목/설명 · 라디오 목록 · 자유 입력 · 하단 CTA).
//  문구·항목은 호출부가 configuration으로 넘기고, 이 셸은 표시·선택 상태만 소유한다.
//  (웹 브릿지 SHOW_SELECT_SHEET 계약의 네이티브 셸 — 신고 사유 선택 등에 사용)
//  표시/딤/드래그 닫기는 기존 `.customBottomSheet` 모디파이어가 담당하고,
//  이 뷰는 그 content로 들어간다(배경/상단 라운드는 컨테이너가 그림).
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

// MARK: - SelectSheetView

public struct SelectSheetView: View {
    private let configuration: SelectSheetConfiguration
    /// 제출 시 선택된 항목의 value(+자유 입력 항목이면 입력 문구)를 전달한다.
    private let onSubmit: (_ value: String, _ customText: String?) -> Void

    // 선택 상태는 셸이 소유한다 — 시트가 닫히면 언마운트되어 다음 표시 때 항상 초기화된다.
    @State private var selectedValue: String?
    @State private var customText: String = ""
    @FocusState private var isCustomTextFocused: Bool

    public init(
        configuration: SelectSheetConfiguration,
        onSubmit: @escaping (_ value: String, _ customText: String?) -> Void
    ) {
        self.configuration = configuration
        self.onSubmit = onSubmit
    }

    private var selectedOption: SelectSheetConfiguration.Option? {
        configuration.options.first { $0.value == selectedValue }
    }

    private var needsCustomText: Bool {
        selectedOption?.allowsCustomText == true
    }

    // 자유 입력 항목은 내용이 있어야 제출할 수 있다(빈 사유 전송 방지).
    private var canSubmit: Bool {
        guard selectedOption != nil else { return false }
        return !needsCustomText || !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            handle
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

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

            VStack(spacing: 0) {
                ForEach(configuration.options) { option in
                    optionRow(option)
                }
            }
            .padding(.top, 16)

            if needsCustomText {
                customTextField
                    .padding(.top, 4)
            }

            submitButton
                .padding(.top, 24)
        }
        .padding(.horizontal, 20)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.component.bottomSheet.selected.container.handle)
            .frame(width: 40, height: 4)
    }

    private func optionRow(_ option: SelectSheetConfiguration.Option) -> some View {
        let isSelected = option.value == selectedValue
        return Button {
            selectedValue = option.value
            // 자유 입력이 필요 없는 항목으로 바꾸면 이전 입력을 흘리지 않도록 비운다.
            if option.allowsCustomText == false {
                customText = ""
                isCustomTextFocused = false
            }
        } label: {
            HStack(spacing: 12) {
                radio(isSelected: isSelected)
                Text(option.label)
                    .font(.pretendard.bodyM)
                    .foregroundStyle(
                        isSelected
                        ? Color.semantic.text.primary
                        : Color.semantic.text.secondary
                    )
                Spacer(minLength: 0)
            }
            .frame(height: 51)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func radio(isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                // 선택: 파란 원 채움 + 중앙 흰 점.
                Circle()
                    .fill(Color.semantic.interactive.primary)
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(Color.semantic.surface.container)
                    .frame(width: 7, height: 7)
            } else {
                // 미선택: 회색 테두리 원.
                Circle()
                    .strokeBorder(Color.semantic.border.default, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(width: 20, height: 20)
    }

    private var customTextField: some View {
        // SwiftUI 기본 TextField는 placeholder 색을 못 바꿔, placeholder를 커스텀 오버레이로 그린다.
        // 입력 텍스트는 focused 색, placeholder는 default 색으로 분리한다.
        TextField("", text: $customText, axis: .vertical)
            .focused($isCustomTextFocused)
            .font(.pretendard.bodyS)
            .foregroundStyle(Color.component.textfieldMultiline.focused.text)
            .lineLimit(5, reservesSpace: true)
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
            let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
            onSubmit(option.value, needsCustomText ? trimmed : nil)
        } label: {
            AppButtonConfiguration(title: configuration.submitText, size: .large)
                .frame(maxWidth: .infinity)
        }
        .appButtonStyle(.primary, size: .large, height: 51)
        .disabled(!canSubmit)
    }
}

// MARK: - Preview

#Preview {
    Color.component.background.default
        .customBottomSheet(isPresented: .constant(true)) {
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
                onSubmit: { _, _ in }
            )
        }
}
