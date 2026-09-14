//
//  MyAcademySettingView.swift
//  Presentation
//
//  Created by suni on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

private enum Style {
    static let headerHeight: CGFloat = 60
    static let horizontalPadding: CGFloat = 16
}

public struct MyAcademySettingView: View {
    
    @Bindable var store: StoreOf<MyAcademySettingFeature>
    @FocusState private var isKeyboardVisible: Bool
    
    public init(store: StoreOf<MyAcademySettingFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            titleSection
            textFieldSection
            Spacer()
            ctaButtonSection
        }
        .onAppear {
            store.send(.view(.onAppear))
        }
        .onTapGesture {
            store.send(.view(.viewTapped))
        }
        .bind($store.isKeyboardVisible, to: $isKeyboardVisible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Private Views
private extension MyAcademySettingView {
    
    var headerView: some View {
        HStack {
            Button(action: { store.send(.view(.backButtonTapped)) }) {
                ZStack {
                    // 라운드 배경
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primitive.blue.b50)
                    
                    // 화살표 아이콘
                    Assets.Common.Icon.arrowLeft.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.primitive.blue.b500p)
                }
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(store.mode.headerTitle)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)
            
            Spacer()

            if store.mode.isEdit {
                Button {
                    store.send(.view(.deleteButtonTapped))
                } label: {
                    Text("삭제")
                        .font(Font.pretendard.buttonS)
                        .foregroundStyle(Color.component.button.text.defaultText)
                        .frame(width: 53, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
    }
    
    var titleSection: some View {
        Text(store.validationState.message)
            .font(Font.pretendard.display1)
            .foregroundStyle(store.validationState.messageColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .lineSpacing(6.2)
            .padding(.horizontal, 30)
            .padding(.top, 120)
            .padding(.bottom, 8)
    }
    
    var textFieldSection: some View {
        ZStack {
            // 정책 1: 초기 상태에서 플레이스홀더를 보여줍니다.
            if !store.isTextFieldActive {
                Text("도장명을 입력해주세요")
                    .font(Font.pretendard.display1)
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
            } else if store.academyName.isEmpty {
                // 정책 3: 입력을 시작했지만 비어있으면 키보드 상태와 관계없이 커스텀 커서를 보여줍니다.
                // (가운데 정렬 TextField는 빈 상태에서 네이티브 커서가 보이지 않음)
                BlinkingCursorView()
                    .allowsHitTesting(false)
            }
            
            // 표시와 입력을 하나의 세로 축 TextField가 담당합니다.
            // 표시용 Text(줄바꿈)와 입력용 단일 라인 TextField(가로 스크롤)를 겹치면
            // 2줄 이상일 때 caret이 실제 텍스트 끝이 아닌 오른쪽 가운데에 고정되므로 분리하지 않습니다.
            TextField("", text: $store.academyName, axis: .vertical)
                .font(Font.pretendard.display1)
                .focused($isKeyboardVisible)
                .multilineTextAlignment(.center)
                // 세로 축 TextField는 Return 키가 줄바꿈을 삽입하므로 onSubmit으로 가로채
                // 도장명에 개행이 들어가지 않게 합니다. (기존 단일 라인과 동일하게 Return은 동작 없음)
                .onSubmit {}
                .foregroundStyle(store.validationState.textColor)
                // 정책 1: 초기 상태에서는 네이티브 커서를 숨깁니다.
                // 정책 2: 입력 시작 후에는 네이티브 커서를 보여줍니다.
                .tint(store.isTextFieldActive ? Color.component.textfieldDisplay.focus.text : .clear)
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
        .disabled(!store.isCtaButtonEnabled)
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
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
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
