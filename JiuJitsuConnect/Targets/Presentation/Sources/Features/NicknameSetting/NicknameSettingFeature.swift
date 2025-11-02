//
//  NicknameSettingFeature.swift
//  Presentation
//
//  Created by suni on 10/6/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit
import OSLog

@Reducer
public struct NicknameSettingFeature {
    
    private enum CancelID { case validation }
    
    @ObservableState
    public struct State: Equatable {
        // MARK: - Core State
        @Presents var alert: AlertState<Action.Alert>?
        
        var nickname: String = ""
        var validationState: ValidationState = .idle
        
        // MARK: - View State
        var isKeyboardVisible: Bool = false
        var isCtaButtonEnabled: Bool = true
        var isTextFieldActive: Bool = false
        
        // MARK: - Passed Data
        let tempToken: String
        let isMarketingAgreed: Bool
        
        public init(tempToken: String, isMarketingAgreed: Bool) {
            self.tempToken = tempToken
            self.isMarketingAgreed = isMarketingAgreed
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case viewTapped
        case doneButtonTapped
        case alert(PresentationAction<Alert>)
        
        case _signupResponse(TaskResult<AuthInfo>)
    
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case signupSuccessful(info: AuthInfo)
        }
        case delegate(Delegate)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.userClient) var userClient
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isKeyboardVisible = true
                return .none

            case .binding(\.nickname):
                if !state.isTextFieldActive && !state.nickname.isEmpty {
                    state.isTextFieldActive = true
                }
                
                state.isCtaButtonEnabled = true
                
                // 사용자가 닉네임을 수정하면 유효성 검사 상태를 초기화합니다.
                state.validationState = .idle
                return .none
                
            case .doneButtonTapped:
                guard state.isCtaButtonEnabled else { return .none }
                
                if !(2...12).contains(state.nickname.count) {
                    state.validationState = .invalidLength
                    state.isCtaButtonEnabled = false
                    return .none
                }
                if !isValid(nickname: state.nickname) {
                    state.validationState = .invalidCharacters
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                let tempToken = state.tempToken
                let nickname = state.nickname
                let isMarketingAgreed = state.isMarketingAgreed

                return .run { send in
                    let signupInfo = SignupInfo(
                        tempToken: tempToken,
                        nickname: nickname,
                        isMarketingAgreed: isMarketingAgreed
                    )
                    await send(._signupResponse(
                        await TaskResult { try await self.userClient.signup(signupInfo) }
                    ))
                }
                .cancellable(id: CancelID.validation)
                
            case let ._signupResponse(.success(info)):
                return .send(.delegate(.signupSuccessful(info: info)))
                
            case let ._signupResponse(.failure(error)):
                
                guard let domainError = error as? DomainError else {
                    Logger.network.error("Unknown login error: \(error)")
                    state.validationState = .networkError
                    return .none
                }
                
                switch domainError {
                    
                case .apiError(let code, _):
                    if code == .nicknameDuplicated {
                        state.validationState = .unavailable
                        return .none
                    }
                    state.validationState = .networkError
                    return .none
                    
                default:
                    state.validationState = .networkError
                    return .none
                }
                
            case .viewTapped:
                state.isKeyboardVisible = false
                return .none
                
            case .binding, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    private func isValid(nickname: String) -> Bool {
        let pattern = "^[a-zA-Z0-9가-힣\\s_.]*$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: nickname.utf16.count)
            return regex.firstMatch(in: nickname, options: [], range: range) != nil
        }
        return false
    }
}

// MARK: - Validation State
public extension NicknameSettingFeature {
    enum ValidationState: Equatable {
        case idle
        case available
        case unavailable
        case invalidLength
        case invalidCharacters
        case networkError
        
        var message: String {
            switch self {
            case .idle, .networkError:
                return "어떻게 불러드리면 될까요?"
            case .available:
                return "사용 가능한 닉네임입니다."
            case .unavailable:
                return "이미 사용 중인 닉네임입니다."
            case .invalidLength, .invalidCharacters:
                return "한글/영문/숫자,\n2~12자로 작성해주세요"
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
            case .idle, .available:
                return Color.component.textfieldDisplay.focus.text
            case .unavailable, .invalidLength, .invalidCharacters, .networkError:
                return Color.component.textfieldDisplay.default.placeholder
            }
        }
    }
}
