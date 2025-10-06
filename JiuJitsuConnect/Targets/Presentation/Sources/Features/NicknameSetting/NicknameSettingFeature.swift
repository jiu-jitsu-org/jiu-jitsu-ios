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
        var isTextFieldFocused: Bool = false
        var isCtaButtonEnabled: Bool = true
        var isTextFieldActive: Bool = false
        var textFieldPlaceHolder: String = "닉네임을 입력해주세요"
        
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
        
        case _validationResponse(TaskResult<Bool>)
        
        public enum Alert: Equatable {}
        
        public enum Delegate: Equatable {
            case didCompleteNicknameSetting(nickname: String, tempToken: String, isMarketingAgreed: Bool)
        }
        case delegate(Delegate)
    }
    
    // MARK: - Dependencies
    @Dependency(\.nicknameValidationClient) var nicknameValidationClient
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isTextFieldFocused = true
                return .none

            // 닉네임이 수정될 때마다 실시간 유효성 검사를 수행하고, CTA 버튼을 다시 활성화합니다.
            case .binding(\.nickname):
                if !state.isTextFieldActive && !state.nickname.isEmpty {
                    state.isTextFieldActive = true
                    state.textFieldPlaceHolder = ""
                }
                
                // CTA 버튼 재활성화
                state.isCtaButtonEnabled = true
                
                // 닉네임이 비어있으면 초기 상태로 복귀
                guard !state.nickname.isEmpty else {
                    state.validationState = .idle
                    return .none
                }
                
                // 실시간 클라이언트 유효성 검사 (길이, 허용 문자)
                if !(2...12).contains(state.nickname.count) {
                    state.validationState = .invalidLength
                } else if !isValid(nickname: state.nickname) {
                    state.validationState = .invalidCharacters
                } else {
                    // 유효성 검사를 통과하면 idle 상태로 변경하여 안내 메시지를 숨깁니다.
                    state.validationState = .idle
                }
                return .none
                
            // '확인' 버튼을 눌렀을 때 서버에 중복 확인을 요청합니다.
            case .doneButtonTapped:
                guard state.isCtaButtonEnabled else { return .none }
                
                // 서버 요청 전, 최종 클라이언트 유효성 검사
                if !(2...12).contains(state.nickname.count) {
                    state.validationState = .invalidLength
                    return .none
                }
                if !isValid(nickname: state.nickname) {
                    state.validationState = .invalidCharacters
                    return .none
                }
                
                // 서버에 중복 확인 요청
                return .run { [nickname = state.nickname] send in
                    await send(._validationResponse(
                        await TaskResult { try await nicknameValidationClient.isAvailable(nickname) }
                    ))
                }
                .cancellable(id: CancelID.validation)

            // 서버 응답 처리
            case let ._validationResponse(.success(isAvailable)):
                if isAvailable {
                    // 사용 가능 시, 다음 단계로 진행
                    state.validationState = .available
                    return .run { [nickname = state.nickname, tempToken = state.tempToken, isMarketingAgreed = state.isMarketingAgreed] send in
                        // 성공 메시지를 잠시 보여주기 위한 딜레이 (선택 사항)
                        // try await clock.sleep(for: .seconds(1))
                        await send(.delegate(.didCompleteNicknameSetting(
                            nickname: nickname,
                            tempToken: tempToken,
                            isMarketingAgreed: isMarketingAgreed
                        )))
                    }
                } else {
                    // 중복 시, 에러 메시지 노출 및 CTA 버튼 비활성화
                    state.validationState = .unavailable
                    state.isCtaButtonEnabled = false
                }
                return .none
                
            case ._validationResponse(.failure):
                // 네트워크 에러 등 실패 케이스 처리
                state.validationState = .networkError
                return .none
                
            case .viewTapped:
                state.isTextFieldFocused = false
                return .none
                
            case .binding, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    /// 닉네임에 허용된 문자(한글, 영문, 숫자, 띄어쓰기, _, .)만 포함되어 있는지 확인합니다.
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
        case idle // 기본 또는 유효성 검사 통과 상태
        case available // 사용 가능 (서버 확인 완료)
        case unavailable // 중복 (서버 확인 완료)
        case invalidLength // 글자 수 오류
        case invalidCharacters // 허용 문자 오류
        case networkError // 네트워크 오류
        
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
    }
}
