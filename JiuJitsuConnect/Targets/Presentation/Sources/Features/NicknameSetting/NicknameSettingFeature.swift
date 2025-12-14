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
public struct NicknameSettingFeature: Sendable {
    
    public init() {}
    
    private enum CancelID { case apiCall }
    
    // 정규식 객체 재사용을 위한 Static 선언
    private static let nicknameRegex: NSRegularExpression = {
        let pattern = "^[a-zA-Z0-9가-힣\\s_.]*$"
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()
    
    @ObservableState
    public struct State: Equatable, Sendable {
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
    
    public enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case onAppear
        case viewTapped
        case doneButtonTapped
        case alert(PresentationAction<Alert>)
        
        // Internal Actions
        case _checkNicknameResponse(TaskResult<Bool>)
        case _signupResponse(TaskResult<AuthInfo>)
        
        public enum Alert: Equatable, Sendable {}
        
        public enum Delegate: Equatable, Sendable {
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
                
                // 입력 값이 변경되면 이전 검증 상태 초기화
                if state.validationState == .available {
                    state.validationState = .idle
                    state.validatedNickname = nil
                }
                return .none
                
            case .doneButtonTapped:
                guard state.isCtaButtonEnabled else { return .none }
                
                // 1단계: 로컬 유효성 검사
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
                
                // 2단계: 상태에 따른 API 호출
                if state.validationState == .available && state.nickname == state.validatedNickname {
                    // 이미 검증 완료된 닉네임 -> 회원가입 시도
                    let info = SignupInfo(
                        tempToken: state.tempToken,
                        nickname: state.nickname,
                        isMarketingAgreed: state.isMarketingAgreed
                    )
                    return .run { send in
                        await send(._signupResponse(
                            await TaskResult { try await userClient.signup(info) }
                        ))
                    }
                    .cancellable(id: CancelID.apiCall)
                    
                } else {
                    // 검증되지 않은 닉네임 -> 중복 검사 시도
                    return .run { [nickname = state.nickname] send in
                        await send(._checkNicknameResponse(
                            await TaskResult { try await userClient.checkNickname(.init(nickname: nickname)) }
                        ))
                    }
                    .cancellable(id: CancelID.apiCall)
                }
                
            case let ._checkNicknameResponse(.success(isAvailable)):
                if isAvailable {
                    state.validationState = .available
                    state.validatedNickname = state.nickname
                } else {
                    state.validationState = .unavailable
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

    // 정규식 검사 최적화
    private func isValid(nickname: String) -> Bool {
        let range = NSRange(location: 0, length: nickname.utf16.count)
        return Self.nicknameRegex.firstMatch(in: nickname, options: [], range: range) != nil
    }
    
    private func handleApiFailure(state: inout State, error: Error) -> Effect<Action> {
        guard let domainError = error as? DomainError else {
            Log.trace("Unknown API error: \(error)", category: .network, level: .error)
            state.validationState = .networkError
            state.isKeyboardVisible = false
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
        }
        
        switch domainError {
        case .apiError(let code, _):
            if code == .invalidNickname {
                state.validationState = .invalidCharacters
                state.isCtaButtonEnabled = false
                return .none
            }
            
            if code == .nicknameDuplicated {
                state.validationState = .unavailable
                state.isCtaButtonEnabled = false
                return .none
            }
            
            fallthrough
            
        default:
            state.validationState = .networkError
            state.isKeyboardVisible = false
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
        }
    }
}

// MARK: - Validation State & View Helpers
public extension NicknameSettingFeature {
    enum ValidationState: Equatable, Sendable {
        case idle
        case available
        case unavailable
        case invalidLength
        case invalidCharacters
        case networkError
    }
}

public extension NicknameSettingFeature.ValidationState {
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
