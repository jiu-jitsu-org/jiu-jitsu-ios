//
//  MyAcademySettingFeature.swift
//  Presentation
//
//  Created by suni on 12/27/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import DesignSystem

@Reducer
public struct MyAcademySettingFeature: Sendable {
    
    public init() {}
    
    @ObservableState
    public struct State: Equatable, Sendable {
        // MARK: - Core State
        @Presents var alert: AlertState<Action.Alert>?
        
        var academyName: String = ""
        var validationState: ValidationState = .idle
        
        // MARK: - View State
        var isKeyboardVisible: Bool = false
        var isCtaButtonEnabled: Bool = true
        var isTextFieldActive: Bool = false
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case onAppear
        case viewTapped
        case doneButtonTapped
        case alert(PresentationAction<Alert>)
        
        public enum Alert: Equatable, Sendable {}
        
        public enum Delegate: Equatable, Sendable {
            case didSaveAcademyName(String)
        }
        case delegate(Delegate)
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isKeyboardVisible = true
                return .none
                
            case .binding(\.academyName):
                if !state.isTextFieldActive && !state.academyName.isEmpty {
                    state.isTextFieldActive = true
                }
                state.isCtaButtonEnabled = true
                
                // 입력 값이 변경되면 검증 상태 초기화
                if state.validationState == .valid {
                    state.validationState = .idle
                }
                return .none
                
            case .doneButtonTapped:
                guard state.isCtaButtonEnabled else { return .none }
                
                // TODO: 도장 정보 입력 - 유효성 검사
                if state.academyName.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.validationState = .empty
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                if state.academyName.count > 30 {
                    state.validationState = .tooLong
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                // 유효성 검사 통과
                state.validationState = .valid
                return .send(.delegate(.didSaveAcademyName(state.academyName)))
                
            case .viewTapped:
                state.isKeyboardVisible = false
                return .none
                
            case .binding, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Validation State & View Helpers
public extension MyAcademySettingFeature {
    enum ValidationState: Equatable, Sendable {
        case idle
        case valid
        case empty
        case tooLong
    }
}
public extension MyAcademySettingFeature.ValidationState {
    var message: String {
        switch self {
        case .idle:
            return "도장 이름을 입력해주세요"
        case .valid:
            return "도장 이름이 설정되었습니다"
        case .empty:
            return "도장 이름을 입력해주세요"
        case .tooLong:
            return "도장 이름은 30자\n이내로 작성해주세요"
        }
    }
    
    var messageColor: Color {
        switch self {
        default:
            return Color.component.textfieldDisplay.`default`.title
        }
    }
    
    var textColor: Color {
        switch self {
        case .idle, .valid:
            return Color.component.textfieldDisplay.focus.text
        case .empty, .tooLong:
            return Color.component.textfieldDisplay.default.placeholder
        }
    }
}
