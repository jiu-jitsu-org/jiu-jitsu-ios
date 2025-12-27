//
//  MyPrpfileFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import Foundation
import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct MyPrpfileFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?
        
        var authInfo: AuthInfo
        
        public init(authInfo: AuthInfo) {
            self.authInfo = authInfo
        }
    }
    
    @Reducer(state: .equatable, action: .equatable, .sendable)
    public enum Destination {
        case academySetting(MyAcademySettingFeature)
    }
    
    @CasePathable
    public enum Action: Equatable, Sendable {
        // View UI Actions
        case gymInfoButtonTapped
        case registerBeltButtonTapped
        case registerStyleButtonTapped
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .gymInfoButtonTapped:
                // 도장 정보 입력 화면으로 네비게이션
                state.destination = .academySetting(MyAcademySettingFeature.State())
                return .none
                
            case .registerBeltButtonTapped:
                // 벨트/체급 등록 화면 이동 로직
                return .none
                
            case .registerStyleButtonTapped:
                // 스타일 등록 화면 이동 로직
                return .none
                
            case .destination(.presented(.academySetting(.delegate(.didSaveAcademyName)))):
                // 학원 이름이 저장되면 처리
                // TODO: authInfo 업데이트 또는 저장 로직
                state.destination = nil
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
