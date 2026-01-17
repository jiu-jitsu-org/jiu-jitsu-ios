//
//  SignupCompleteFeature.swift
//  Presentation
//
//  Created by suni on 11/21/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct SignupCompleteFeature: Sendable {
    
    @ObservableState
    public struct State: Equatable, Sendable {
        // MARK: - Passed Data
        let authInfo: AuthInfo
        
        // MARK: - View State
        // 중앙 컨텐츠 그룹의 애니메이션을 제어하기 위한 상태
        var isContentVisible: Bool = false
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        
        public enum ViewAction: Sendable {
            case onAppear
            case homeButtonTapped
        }
        
        public enum InternalAction: Sendable {
            case setContentVisible(Bool)
        }
        
        public enum DelegateAction: Sendable {
            // 회원가입/설정 흐름이 모두 완료되었음을 부모에게 알림
            case completeSignupFlow(info: AuthInfo)
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .run { send in
                    // 1. Lottie 시작 후 0.5초 대기
                    try await self.clock.sleep(for: .seconds(0.5))
                    
                    // 2. 0.8초 동안 부드럽게 애니메이션 (EaseOut 곡선 추천)
                    await send(.internal(.setContentVisible(true)), animation: .easeOut(duration: 0.8))
                }
                
            case .internal(.setContentVisible(let isVisible)):
                // 내부 액션을 받아 상태를 변경합니다.
                state.isContentVisible = isVisible
                return .none
                
            case .view(.homeButtonTapped):
                // "홈으로" 버튼이 탭되면, 부모에게 델리게이트 액션을 보냅니다.
                return .send(.delegate(.completeSignupFlow(info: state.authInfo)))
                
            case .delegate, .view, .internal:
                // 부모가 처리할 액션이므로 여기서는 아무것도 하지 않습니다.
                return .none
            }
        }
    }
}
