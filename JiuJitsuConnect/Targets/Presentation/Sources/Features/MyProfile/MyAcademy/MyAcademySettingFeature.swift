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
    
    private enum CancelID { case apiCall, toast }
    
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
        // 부모(MY)가 저장 · 삭제 중. 결과가 올 때까지 입력 · 저장 · 삭제를 막는다(#156) — 응답 전에 고친 값은 저장되지 않는다.
        var isSaving: Bool = false
        // 마지막으로 부모에 맡긴 요청. 실패 안내 문구를 저장/삭제에 맞추는 데 쓴다.
        var pendingRequest: Request?
        // 이 화면은 MY 위에 push돼 MY 토스트가 가려지므로 실패는 여기서 띄운다(스타일 화면과 같은 방식).
        var toast: ToastState?
        
        public init(mode: Mode = .add, academyName: String = "") {
            self.mode = mode
            self.academyName = academyName
            
            // 수정 모드이고 기존 도장명이 있으면 텍스트필드를 활성화 상태로 시작
            if mode == .edit && !academyName.isEmpty {
                self.isTextFieldActive = true
            }
        }
    }
    
    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case view(ViewAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
        case `internal`(InternalAction)
        /// 부모(MY)의 저장 · 삭제가 실패했다. MY 토스트는 이 화면에 가려지므로 이 화면이 직접 알린다(#156).
        case saveFailed
        
        public enum ViewAction: Sendable {
            case onAppear
            case toastSwiped
            case viewTapped
            case doneButtonTapped
            case deleteButtonTapped
            case backButtonTapped
        }

        // AlertState<Alert> 요구사항을 충족하기 위해 Equatable 유지
        public enum Alert: Equatable, Sendable {}

        public enum InternalAction: Sendable {
            case toastDismissed
        }

        public enum DelegateAction: Sendable {
            case saveAcademyName(String)  // 저장 요청만 위임
            case deleteAcademy            // 도장 정보 삭제 요청 위임 (수정 모드 전용)
            case cancel
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock
    
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
                // 에러 상태(.invalidLength, .invalidCharacters)에서 다시 입력하면 idle로 리셋
                if state.validationState != .idle {
                    state.validationState = .idle
                }
                return .none
                
            case .view(.doneButtonTapped):
                guard state.isCtaButtonEnabled, !state.isSaving else { return .none }
                
                // 1단계: 로컬 유효성 검사
                // 서버가 앞뒤 공백을 지우고 저장하므로 같은 값으로 검사한다 — 공백만 있으면 빈 값이 돼 도장이 지워진다(#156).
                let academyName = state.academyName.trimmingCharacters(in: .whitespacesAndNewlines)
                // 글자 수 체크 (1~100자)
                if !(1...100).contains(academyName.count) {
                    state.validationState = .invalidLength
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                // 허용된 문자 체크 (한글/영문/숫자/띄어쓰기)
                if !isValid(academyName: academyName) {
                    state.validationState = .invalidCharacters
                    state.isCtaButtonEnabled = false
                    return .none
                }
                
                // 유효성 검사 통과 - 부모 Feature에게 저장 요청 위임. 성공하면 부모가 화면을 닫는다.
                state.isSaving = true
                state.pendingRequest = .save
                state.isKeyboardVisible = false
                // 다시 시도하는 동안 앞 실패 안내가 남아 또 실패한 것처럼 보이지 않게 거둔다.
                state.toast = nil
                return .merge(.cancel(id: CancelID.toast), .send(.delegate(.saveAcademyName(academyName))))

            case .view(.deleteButtonTapped):
                // 수정 모드에서만 노출되는 삭제 — 부모에 삭제 요청 위임(도장 정보 "" 처리)
                guard state.mode.isEdit, !state.isSaving else { return .none }
                state.isSaving = true
                state.pendingRequest = .delete
                state.isKeyboardVisible = false
                state.toast = nil
                return .merge(.cancel(id: CancelID.toast), .send(.delegate(.deleteAcademy)))

            case .saveFailed:
                // 입력값은 그대로 두어 같은 화면에서 다시 저장 · 삭제하게 한다.
                state.isSaving = false
                let message = state.pendingRequest == .delete
                    ? "삭제에 실패했어요. 다시 시도해주세요"
                    : "저장에 실패했어요. 다시 시도해주세요"
                state.pendingRequest = nil
                let toast = ToastState(message: message, status: .error)
                state.toast = toast
                return .run { [clock] send in
                    try await clock.sleep(for: toast.duration)
                    await send(.internal(.toastDismissed))
                }
                .cancellable(id: CancelID.toast, cancelInFlight: true)

            case .view(.toastSwiped), .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)

            case .view(.backButtonTapped):
                return .concatenate(
                    .send(.delegate(.cancel)),
                    .run { _ in await self.dismiss() }
                )
                
            case .view(.viewTapped):
                state.isKeyboardVisible = false
                return .none
                
            case .binding, .alert, .delegate, .view, .internal:
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
        
        var isEdit: Bool {
            self == .edit
        }

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
        case invalidLength
        case invalidCharacters
    }

    enum Request: Equatable, Sendable {
        case save
        case delete
    }
}

public extension MyAcademySettingFeature.ValidationState {
    var message: String {
        switch self {
        case .idle:
            return "도장 이름을 입력해주세요"
        case .invalidLength, .invalidCharacters:
            return "한글/영문/숫자로 작성해주세요"
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
        case .idle:
            return Color.component.textfieldDisplay.focus.text
        case .invalidLength, .invalidCharacters:
            return Color.component.textfieldDisplay.default.placeholder
        }
    }
}
