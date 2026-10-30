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
    
    // 중복 확인은 입력이 바뀌면 버려야 해서 가입·수정 저장(apiCall)과 따로 취소한다.
    private enum CancelID { case apiCall, checkNickname }
    
    // 정규식 객체 재사용을 위한 Static 선언
    // 허용 문자는 한글(완성형)·영문·숫자만 — 공백·`_`·`.` 등 특수문자 불허(정책 2026-10-21, #67).
    private static let nicknameRegex: NSRegularExpression? = {
        let pattern = "^[a-zA-Z0-9가-힣]*$"
        return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()
    
    @ObservableState
    public struct State: Equatable, Sendable {
        // MARK: - Core State
        @Presents var alert: AlertState<Alert>?
        
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

        // MARK: - Edit Mode
        // 진입 시 닉네임. 입력값이 같으면 서버 요청 없이 MY로 돌아간다(정책 2.2).
        let originalNickname: String?
        
        // 초기 설정 모드 생성자
        public init(tempToken: String, isMarketingAgreed: Bool) {
            self.mode = .initial
            self.tempToken = tempToken
            self.isMarketingAgreed = isMarketingAgreed
            self.originalNickname = nil
        }
        
        // 수정 모드 생성자
        public init(mode: Mode = .edit, nickname: String = "") {
            self.mode = mode
            self.nickname = nickname
            self.tempToken = nil
            self.isMarketingAgreed = nil
            self.originalNickname = nickname
            
            // 수정 모드이고 기존 닉네임이 있으면 텍스트필드를 활성화 상태로 시작
            if mode == .edit && !nickname.isEmpty {
                self.isTextFieldActive = true
            }
        }
    }
    
    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
        
        public enum ViewAction: Sendable {
            case onAppear
            case viewTapped
            case doneButtonTapped
            case backButtonTapped
        }
        
        public enum InternalAction: Sendable {
            /// 응답이 늦게 와도 검사한 값에만 반영하도록 검사한 닉네임을 함께 싣는다.
            case checkNicknameResponse(nickname: String, TaskResult<Bool>)
            case signupResponse(TaskResult<AuthInfo>)
            case updateNicknameResponse(TaskResult<String>)
        }
        
        public enum DelegateAction: Sendable {
            case signupSuccessful(info: AuthInfo)
            case signupFailed(message: String)
            /// 약관·닉네임에 시간이 걸려 임시 토큰이 만료됨 — 가입을 이어갈 수 없어 로그인부터 다시 해야 한다.
            case signupSessionExpired
            case didUpdateNickname(String)  // 닉네임 수정 저장 완료 — 부모가 화면을 닫고 프로필 반영
            case cancel
        }
    }
    
    public enum Alert: Equatable, Sendable {}
    
    // MARK: - Dependencies

    @Dependency(\.userClient) var userClient
    @Dependency(\.dismiss) var dismiss
    
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
                // 에러 상태(.invalidLength, .invalidCharacters, .unavailable, .saveFailed)나
                // 성공 상태(.available)에서 다시 입력하면 idle로 리셋
                if state.validationState != .idle {
                    state.validationState = .idle
                    state.validatedNickname = nil
                }
                // 이전 입력값으로 보낸 중복 확인은 결과가 와도 지금 입력과 무관하다.
                return .cancel(id: CancelID.checkNickname)
                
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
                    // 기존 닉네임 그대로면 서버 요청 없이 MY로 복귀(정책 2.2)
                    if state.nickname == state.originalNickname {
                        return .concatenate(
                            .send(.delegate(.cancel)),
                            .run { _ in await self.dismiss() }
                        )
                    }
                    if state.validationState == .available && state.nickname == state.validatedNickname {
                        // 2차 탭: 중복 검사를 통과한 닉네임으로 최종 저장. 결과가 올 때까지 CTA를 막는다.
                        state.isCtaButtonEnabled = false
                        return .run { [nickname = state.nickname] send in
                            await send(.internal(.updateNicknameResponse(
                                await TaskResult {
                                    try await userClient.updateNickname(nickname)
                                    return nickname
                                }
                            )))
                        }
                        .cancellable(id: CancelID.apiCall)
                    }
                    // 1차 탭: 중복 검사 → 통과 시 '사용 가능' 문구로 전환(정책 2.3)
                    return checkNickname(state.nickname)

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
                        // 결과가 올 때까지 CTA를 막아 연타로 가입이 두 번 나가지 않게 한다.
                        state.isCtaButtonEnabled = false
                        return .run { send in
                            await send(.internal(.signupResponse(
                                await TaskResult { try await userClient.signup(info) }
                            )))
                        }
                        .cancellable(id: CancelID.apiCall)
                        
                    } else {
                        // 검증되지 않은 닉네임 -> 중복 검사 시도
                        return checkNickname(state.nickname)
                    }
                }
                
            case .view(.backButtonTapped):
                // 수정 모드에서만 노출되는 뒤로가기 — 부모에 cancel 위임 후 화면 dismiss
                return .concatenate(
                    .send(.delegate(.cancel)),
                    .run { _ in await self.dismiss() }
                )
                
            case let .internal(.checkNicknameResponse(nickname, .success(isAvailable))):
                // 취소가 닿기 전에 도착한 이전 입력값의 응답은 버린다.
                guard nickname == state.nickname else { return .none }
                if isAvailable {
                    state.validationState = .available
                    state.validatedNickname = nickname
                } else {
                    state.validationState = .unavailable
                    state.isCtaButtonEnabled = false
                }
                return .none
                
            case let .internal(.checkNicknameResponse(nickname, .failure(error))):
                guard nickname == state.nickname else { return .none }
                return handleError(state: &state, error: error)
                
            case let .internal(.signupResponse(.success(info))):
                return .send(.delegate(.signupSuccessful(info: info)))
                
            case let .internal(.signupResponse(.failure(error))):
                // 임시 토큰 만료(403 A0003)는 다시 눌러도 계속 실패하므로 재시도 대신 로그인부터 다시 안내한다.
                if case .apiError(code: .expiredToken, message: _) = error as? DomainError {
                    return .send(.delegate(.signupSessionExpired))
                }
                // 일시 오류면 다시 시도할 수 있게 CTA를 살린다(중복·형식 오류는 handleError가 다시 끈다).
                state.isCtaButtonEnabled = true
                return handleError(state: &state, error: error)

            case let .internal(.updateNicknameResponse(.success(nickname))):
                return .send(.delegate(.didUpdateNickname(nickname)))

            case let .internal(.updateNicknameResponse(.failure(error))):
                Log.trace("Failed to update nickname: \(error)", category: .network, level: .error)
                return handleError(state: &state, error: error)
                
            case .view(.viewTapped):
                state.isKeyboardVisible = false
                return .none
                
            case .binding, .alert, .delegate, .view, .internal:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private func checkNickname(_ nickname: String) -> Effect<Action> {
        .run { send in
            await send(.internal(.checkNicknameResponse(
                nickname: nickname,
                await TaskResult { try await userClient.checkNickname(.init(nickname: nickname)) }
            )))
        }
        .cancellable(id: CancelID.checkNickname, cancelInFlight: true)
    }

    // 정규식 검사 최적화
    private func isValid(nickname: String) -> Bool {
        guard let regex = Self.nicknameRegex else {
            return false
        }
        let range = NSRange(location: 0, length: nickname.utf16.count)
        return regex.firstMatch(in: nickname, options: [], range: range) != nil
    }
    
    private func handleError(state: inout State, error: Error) -> Effect<Action> {
        if state.mode == .edit {
            return handleEditError(state: &state, error: error)
        }
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
            
            // Other API errors fall through to default handling
            state.validationState = .networkError
            state.isKeyboardVisible = false
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
            
        default:
            state.validationState = .networkError
            state.isKeyboardVisible = false
            return .send(.delegate(.signupFailed(message: "오류가 발생했습니다. 다시 시도해주세요.")))
        }
    }

    /// 수정 모드는 화면을 닫지 않고 그 자리에서 원인을 안내한다(정책 2.3).
    private func handleEditError(state: inout State, error: Error) -> Effect<Action> {
        if case let .apiError(code, _) = error as? DomainError {
            switch code {
            case .nicknameDuplicated:
                state.validationState = .unavailable
                state.isCtaButtonEnabled = false
                return .none
            case .invalidNickname:
                state.validationState = .invalidCharacters
                state.isCtaButtonEnabled = false
                return .none
            default:
                break
            }
        }
        // 네트워크 등 일시 오류는 같은 닉네임으로 다시 시도할 수 있게 CTA를 살려 둔다.
        state.validationState = .saveFailed
        state.validatedNickname = nil
        state.isCtaButtonEnabled = true
        return .none
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

        /// CTA 문구 — 수정은 '수정'(정책 2.3), 가입은 '확인'
        var ctaTitle: String {
            switch self {
            case .initial: return "확인"
            case .edit: return "수정"
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
        case saveFailed  // 수정 모드에서 중복 검사·저장이 일시 오류로 실패
    }
}

public extension NicknameSettingFeature.ValidationState {
    func message(in mode: NicknameSettingFeature.Mode) -> String {
        switch self {
        case .idle, .networkError:
            // 수정 상황은 안내 문구를 따로 둔다(정책 2.1)
            return mode == .edit ? "어떻게 수정할까요?" : "어떻게 불러드리면 될까요?"
        case .available:
            return "사용 가능한 닉네임입니다."
        case .unavailable:
            return "이미 사용 중인 닉네임입니다."
        case .invalidLength, .invalidCharacters:
            return "한글/영문/숫자,\n2~12자로 작성해주세요"
        case .saveFailed:
            return "잠시 문제가 생겼어요.\n다시 시도해주세요"
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
        case .idle, .available, .saveFailed:
            return Color.component.textfieldDisplay.focus.text
        case .unavailable, .invalidLength, .invalidCharacters, .networkError:
            return Color.component.textfieldDisplay.default.placeholder
        }
    }
}
