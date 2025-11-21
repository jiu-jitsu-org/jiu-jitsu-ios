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
    
    private enum CancelID { case apiCall }
    
    @ObservableState
    public struct State: Equatable {
        // MARK: - Core State
        @Presents var alert: AlertState<Action.Alert>?
        
        var nickname: String = ""
        var validationState: ValidationState = .idle
        
        var validatedNickname: String? = nil
        
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
        
        case _checkNicknameResponse(TaskResult<Bool>)
        case _signupResponse(TaskResult<AuthInfo>)
        
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case signupSuccessful(info: AuthInfo)
            case signupFailed(message: String)
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
                
                if state.validationState == .available {
                    state.validationState = .idle
                    state.validatedNickname = nil
                }
                
                return .none
                
            case .doneButtonTapped:
                guard state.isCtaButtonEnabled else { return .none }
                
                // --- 1단계: 로컬 유효성 검사 ---
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
                
                // --- 2단계: 상태에 따른 API 호출 분기 ---
                if state.validationState == .available && state.nickname == state.validatedNickname {
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
                    .cancellable(id: CancelID.apiCall)
                } else {
                    return .run { [nickname = state.nickname] send in
                        await send(._checkNicknameResponse(
                            await TaskResult { try await self.userClient.checkNickname(.init(nickname: nickname)) }
                        ))
                    }
                    .cancellable(id: CancelID.apiCall)
                }
                
            case let ._checkNicknameResponse(.success(isAvailable)):
                if isAvailable {
                    state.validationState = .available // "사용 가능한 닉네임입니다." 메시지 표시
                    state.validatedNickname = state.nickname // 어떤 닉네임이 검증되었는지 저장
                } else {
                    state.validationState = .unavailable // "이미 사용 중인 닉네임입니다." 메시지 표시
                    state.isCtaButtonEnabled = false
                }
                return .none
                
            case let ._checkNicknameResponse(.failure(error)):
                return handleApiFailure(state: &state, error: error)
                
            case let ._signupResponse(.success(info)):
                return .send(.delegate(.signupSuccessful(info: info)))
                
            case let ._signupResponse(.failure(error)):
                return handleApiFailure(state: &state, error: error)
                
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
    
    private func handleApiFailure(state: inout State, error: Error) -> Effect<Action> {
        guard let domainError = error as? DomainError else {
            Log.trace("Unknown API error: \(error)", category: .network, level: .error)
            state.validationState = .networkError
            state.isKeyboardVisible = false // 정책: 키보드를 내린다
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
        }
        
        switch domainError {
        case .apiError(let code, _):
            // 1. Feature가 직접 처리해야 하는 구체적인 에러 (UI 상태 변경)
            if code == .invalidNickname {
                state.validationState = .invalidCharacters
                state.isCtaButtonEnabled = false
                return .none // 이 경우 토스트는 필요 없음
            }
            
            if code == .nicknameDuplicated {
                state.validationState = .unavailable
                state.isCtaButtonEnabled = false
                return .none // 이 경우 토스트는 필요 없음
            }
            
            // 2. 그 외 모든 API 에러 (공통 처리)
            state.validationState = .networkError
            state.isKeyboardVisible = false // 정책: 키보드를 내린다
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
            
        default:
            // 3. API 에러가 아닌 모든 에러 (네트워크 등)
            state.validationState = .networkError
            state.isKeyboardVisible = false // 정책: 키보드를 내린다
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
        }
    }
}
