//
//  MyAcademySettingView.swift
//  Presentation
//
//  Created by suni on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct MyAcademySettingView: View {
    
    @Bindable var store: StoreOf<MyAcademySettingFeature>
    
    public init(store: StoreOf<MyAcademySettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            titleSection
            // 긴 도장 이름(최대 100자, 큰 글씨로 8줄 안팎)이면 입력이 화면을 넘쳐 머리줄이 상태 막대 밑으로 밀리고
            // 위 안내 문구가 한 줄로 잘렸다. 입력만 스크롤 안에 두고 머리줄 · 안내 · 확인 버튼은 제자리에 둔다.
            // 짧으면 지금처럼 위에 붙고 남는 공간은 비운다.
            ScrollView {
                textFieldSection
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            // 입력이 길어지면 커서가 있는 끝 쪽이 보이게 한다.
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            ctaButtonSection
        }
        .onAppear {
            store.send(.view(.onAppear))
        }
        .onTapGesture {
            store.send(.view(.viewTapped))
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        // 아래 확인 버튼을 가리지 않도록 버튼 위에 띄운다.
        .toast(
            store.toast,
            bottomPadding: 120,
            onSwipe: { store.send(.view(.toastSwiped)) },
            onButtonTapped: { _ in store.send(.view(.toastSwiped)) }
        )
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Private Views
private extension MyAcademySettingView {
    
    var headerView: some View {
        TopHeader(
            title: store.mode.headerTitle,
            onBack: { store.send(.view(.backButtonTapped)) },
            trailing: store.mode.isEdit
                ? .init("삭제", isEnabled: !store.isSaving) { store.send(.view(.deleteButtonTapped)) }
                : nil
        )
    }
    
    var titleSection: some View {
        Text(store.validationState.message(isEdit: store.mode.isEdit))
            .font(Font.pretendard.display1)
            .foregroundStyle(store.validationState.messageColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            // 스크롤 안에서도 두 줄 문구가 잘리지 않게 높이를 글자에 맞춘다.
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(6.2)
            .padding(.horizontal, 30)
            .padding(.top, 120)
            .padding(.bottom, 8)
    }
    
    var textFieldSection: some View {
        ZStack {
            // 정책 1: 초기 상태에서 플레이스홀더를 보여줍니다.
            if !store.isTextFieldActive {
                Text("도장명을 입력해 주세요")
                    .font(Font.pretendard.display1)
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
            } else if store.academyName.isEmpty {
                // 정책 3: 입력을 시작했지만 비어있으면 키보드 상태와 관계없이 커스텀 커서를 보여줍니다.
                // (가운데 정렬 TextField는 빈 상태에서 네이티브 커서가 보이지 않음)
                BlinkingCursorView()
                    .allowsHitTesting(false)
            }
            
            // 표시와 입력을 하나의 줄바꿈 필드가 담당합니다.
            // 표시용 Text(줄바꿈)와 입력용 단일 라인 TextField(가로 스크롤)를 겹치면
            // 2줄 이상일 때 caret이 실제 텍스트 끝이 아닌 오른쪽 가운데에 고정되므로 분리하지 않습니다.
            // Return은 개행 없이 확인 버튼과 동일하게 처리합니다.
            MultilineTextField(
                text: $store.academyName,
                isFocused: $store.isKeyboardVisible,
                font: UIFont.pretendard.display1,
                textColor: store.validationState.textColor,
                // 정책 1: 초기 상태에서는 네이티브 커서를 숨깁니다.
                // 정책 2: 입력 시작 후에는 네이티브 커서를 보여줍니다.
                tintColor: store.isTextFieldActive ? Color.component.textfieldDisplay.focus.text : .clear,
                onSubmit: { store.send(.view(.doneButtonTapped)) }
            )
            // 저장 중엔 키보드를 내리고 입력을 막는다 — UIKit 필드라 disabled만으로는 터치가 막히지 않는다.
            .allowsHitTesting(!store.isSaving)
        }
        .padding(.horizontal, 30)
    }
    
    var ctaButtonSection: some View {
        CTAButton(
            title: "확인",
            type: .blue,
            style: .keypad,
            height: 56,
            action: {
                store.send(.view(.doneButtonTapped))
            }
        )
        .disabled(!store.isCtaButtonEnabled || store.isSaving)
    }
}

// MARK: - Custom Cursor View
private struct BlinkingCursorView: View {
    @State private var isVisible: Bool = false
    
    var body: some View {
        Rectangle()
            .fill(Color.component.textfieldDisplay.focus.text)
            .frame(width: 2, height: 36)
            .opacity(isVisible ? 1 : 0)
            // 반복 Timer는 커서가 사라져도 멈추지 않고 나타날 때마다 쌓인다 — 화면 수명에 묶인 task로 깜빡인다.
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isVisible.toggle()
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        MyAcademySettingView(
            store: Store(initialState: MyAcademySettingFeature.State()) {
                MyAcademySettingFeature()
            }
        )
    }
}
