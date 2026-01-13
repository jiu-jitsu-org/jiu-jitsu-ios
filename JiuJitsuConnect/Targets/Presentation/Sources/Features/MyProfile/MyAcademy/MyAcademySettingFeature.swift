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
import CoreKit
import OSLog

@Reducer
public struct MyAcademySettingFeature: Sendable {
    
    public init() {}
    
    private enum CancelID { case apiCall }
    
    // 정규식 객체 재사용을 위한 Static 선언
    // 닉네임과 다른 점: 띄어쓰기(\s) 추가
    private static let academyNameRegex: NSRegularExpression? = {
        let pattern = "^[a-zA-Z0-9가-힣\\s]*$"
        return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()
    
    @ObservableState
    public struct State: Equatable, Sendable {
        // MARK: - Core State
        @Presents var alert: AlertState<Action.Alert>?
        
        var mode: Mode
        var academyName: String = ""
        var validationState: ValidationState = .idle
        
        // MARK: - View State
        var isKeyboardVisible: Bool = false
        var isCtaButtonEnabled: Bool = true
        var isTextFieldActive: Bool = false
        
        public init(mode: Mode = .add, academyName: String = "") {
            self.mode = mode
            self.academyName = academyName
            
            // 수정 모드이고 기존 도장명이 있으면 텍스트필드를 활성화 상태로 시작
            if mode == .edit && !academyName.isEmpty {
                self.isTextFieldActive = true
            }
        }
    }
    
    public enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
        
        public enum ViewAction: Equatable, Sendable {
            case onAppear
            case viewTapped
            case doneButtonTapped
            case backButtonTapped
        }
        
        public enum Alert: Equatable, Sendable {}
        
        public enum DelegateAction: Equatable, Sendable {
            case saveAcademyName(String)  // 저장 요청만 위임
            case cancel
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.dismiss) var dismiss
    
    // TODO: 실제 AcademyClient나 UserClient dependency 추가 필요
    // @Dependency(\.academyClient) var academyClient
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isKeyboardVisible = true
                return .none
                
            case .binding(\.academyName):
                if !state.isTextFieldActive && !state.academyName.isEmpty {
                    state.isTextFieldActive = true
                }
                state.isCtaButtonEnabled = true
                
                // 입력 값이 변경되면 검증 상태 초기화
                // 에러 상태(.invalidLength, .invalidCharacters, .saveFailed)나
                // 성공 상태(.valid)에서 다시 입력하면 idle로 리셋
                if state.validationState != .idle {
                    state.validationState = .idle
                }
                return .none
                
            case .view(.doneButtonTapped):
                guard state.isCtaButtonEnabled else { return .none }
                
                // 1단계: 로컬 유효성 검사
                // 글자 수 체크 (1~100자)
                if !(1...100).contains(state.academyName.count) {
                    state.validationState = .invalidLength
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                // 허용된 문자 체크 (한글/영문/숫자/띄어쓰기)
                if !isValid(academyName: state.academyName) {
                    state.validationState = .invalidCharacters
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                // 유효성 검사 통과 - 부모 Feature에게 저장 요청 위임
                state.validationState = .valid
                return .send(.delegate(.saveAcademyName(state.academyName)))
                
            case .view(.backButtonTapped):
                return .concatenate(
                    .send(.delegate(.cancel)),
                    .run { _ in await self.dismiss() }
                )
                
            case .view(.viewTapped):
                state.isKeyboardVisible = false
                return .none
                
            case .binding, .alert, .delegate, .view:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    // 정규식 검사 최적화 (NicknameSettingFeature 방식)
    private func isValid(academyName: String) -> Bool {
        guard let regex = Self.academyNameRegex else {
            // Fallback: 정규식 생성 실패 시 기본 검증
            return academyName.allSatisfy { character in
                character.isLetter || character.isNumber || character.isWhitespace
            }
        }
        
        let range = NSRange(location: 0, length: academyName.utf16.count)
        return regex.firstMatch(in: academyName, options: [], range: range) != nil
    }
}

// MARK: - Validation State & View Helpers
public extension MyAcademySettingFeature {
    enum Mode: Equatable, Sendable {
        case add
        case edit
        
        var headerTitle: String {
            switch self {
            case .add:
                return "도장 정보 추가"
            case .edit:
                return "도장 정보 수정"
            }
        }
    }
    
    enum ValidationState: Equatable, Sendable {
        case idle
        case valid
        case invalidLength
        case invalidCharacters
        case saveFailed
    }
}

public extension MyAcademySettingFeature.ValidationState {
    var message: String {
        switch self {
        case .idle:
            return "도장 이름을 입력해주세요"
        case .valid:
            return "도장 이름이 설정되었습니다"
        case .invalidLength, .invalidCharacters:
            return "한글/영문/숫자로 작성해주세요"
        case .saveFailed:
            return "저장에 실패했습니다.\n다시 시도해주세요"
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
        case .invalidLength, .invalidCharacters, .saveFailed:
            return Color.component.textfieldDisplay.default.placeholder
        }
    }
}
