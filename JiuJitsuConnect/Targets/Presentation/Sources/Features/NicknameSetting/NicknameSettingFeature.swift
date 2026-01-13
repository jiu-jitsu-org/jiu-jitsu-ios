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
        
        var mode: Mode
        var nickname: String = ""
        var validationState: ValidationState = .idle
        var validatedNickname: String? = nil
        
        // MARK: - View State
        var isKeyboardVisible: Bool = false
        var isCtaButtonEnabled: Bool = true
        var isTextFieldActive: Bool = false
        
        // MARK: - Passed Data (초기 설정 모드에만 사용)
        let tempToken: String?
        let isMarketingAgreed: Bool?
        
        // 초기 설정 모드 생성자
        public init(tempToken: String, isMarketingAgreed: Bool) {
            self.mode = .initial
            self.tempToken = tempToken
            self.isMarketingAgreed = isMarketingAgreed
        }
        
        // 수정 모드 생성자
        public init(mode: Mode = .edit, nickname: String = "") {
            self.mode = mode
            self.nickname = nickname
            self.tempToken = nil
            self.isMarketingAgreed = nil
            
            // 수정 모드이고 기존 닉네임이 있으면 텍스트필드를 활성화 상태로 시작
            if mode == .edit && !nickname.isEmpty {
                self.isTextFieldActive = true
            }
        }
    }
    
    public enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
        
        public enum ViewAction: Equatable, Sendable {
            case onAppear
            case viewTapped
            case doneButtonTapped
            case backButtonTapped
        }
        
        public enum InternalAction: Equatable, Sendable {
            case checkNicknameResponse(TaskResult<Bool>)
            case signupResponse(TaskResult<AuthInfo>)
        }
        
        public enum Alert: Equatable, Sendable {}
        
        public enum DelegateAction: Equatable, Sendable {
            case signupSuccessful(info: AuthInfo)
            case signupFailed(message: String)
            case saveNickname(String)  // 닉네임 수정 요청
            case cancel
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.userClient) var userClient
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.isKeyboardVisible = true
                return .none
                
            case .binding(\.nickname):
                if !state.isTextFieldActive && !state.nickname.isEmpty {
                    state.isTextFieldActive = true
                }
                state.isCtaButtonEnabled = true
                
                // 입력 값이 변경되면 검증 상태 초기화
                // 에러 상태(.invalidLength, .invalidCharacters, .saveFailed)나
                // 성공 상태(.valid)에서 다시 입력하면 idle로 리셋
                if state.validationState != .idle {
                    state.validationState = .idle
                    state.validatedNickname = nil
                }
                return .none
                
            case .view(.doneButtonTapped):
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
                
                // 2단계: 모드에 따른 분기
                switch state.mode {
                case .edit:
                    // 수정 모드: 부모 Feature에게 저장 요청 위임
                    state.validationState = .valid
                    return .send(.delegate(.saveNickname(state.nickname)))
                    
                case .initial:
                    // 초기 설정 모드: 기존 회원가입 플로우
                    if state.validationState == .available && state.nickname == state.validatedNickname {
                        // 이미 검증 완료된 닉네임 -> 회원가입 시도
                        guard let tempToken = state.tempToken,
                              let isMarketingAgreed = state.isMarketingAgreed else {
                            return .none
                        }
                        
                        let info = SignupInfo(
                            tempToken: tempToken,
                            nickname: state.nickname,
                            isMarketingAgreed: isMarketingAgreed
                        )
                        return .run { send in
                            await send(.internal(.signupResponse(
                                await TaskResult { try await userClient.signup(info) }
                            )))
                        }
                        .cancellable(id: CancelID.apiCall)
                        
                    } else {
                        // 검증되지 않은 닉네임 -> 중복 검사 시도
                        return .run { [nickname = state.nickname] send in
                            await send(.internal(.checkNicknameResponse(
                                await TaskResult { try await userClient.checkNickname(.init(nickname: nickname)) }
                            )))
                        }
                        .cancellable(id: CancelID.apiCall)
                    }
                }
                
            case .view(.backButtonTapped):
                return .send(.delegate(.cancel))
                
            case let .internal(.checkNicknameResponse(.success(isAvailable))):
                if isAvailable {
                    state.validationState = .available
                    state.validatedNickname = state.nickname
                } else {
                    state.validationState = .unavailable
                    state.isCtaButtonEnabled = false
                }
                return .none
                
            case let .internal(.checkNicknameResponse(.failure(error))):
                return handleApiFailure(state: &state, error: error)
                
            case let .internal(.signupResponse(.success(info))):
                return .send(.delegate(.signupSuccessful(info: info)))
                
            case let .internal(.signupResponse(.failure(error))):
                return handleApiFailure(state: &state, error: error)
                
            case .view(.viewTapped):
                state.isKeyboardVisible = false
                return .none
                
            case .binding, .alert, .delegate, .view, .internal:
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
    enum Mode: Equatable, Sendable {
        case initial  // 최초 설정 (회원가입)
        case edit     // 수정
        
        var headerTitle: String {
            switch self {
            case .initial:
                return ""  // 최초 설정에는 헤더 없음
            case .edit:
                return "닉네임 수정"
            }
        }
    }
    
    enum ValidationState: Equatable, Sendable {
        case idle
        case available
        case unavailable
        case invalidLength
        case invalidCharacters
        case networkError
        case valid  // 수정 모드에서 사용
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
        case .valid:
            return "닉네임이 설정되었습니다"
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
        case .idle, .available, .valid:
            return Color.component.textfieldDisplay.focus.text
        case .unavailable, .invalidLength, .invalidCharacters, .networkError:
            return Color.component.textfieldDisplay.default.placeholder
        }
    }
}
