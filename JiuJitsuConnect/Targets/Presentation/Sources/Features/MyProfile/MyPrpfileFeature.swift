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
    
    private enum CancelID { case toast }
    
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?
        
        var authInfo: AuthInfo
        
        // 커뮤니티 프로필 정보
        var communityProfile: CommunityProfile?
        var isLoadingProfile: Bool = false
        
        // 토스트 메시지 상태
        var toast: ToastState?
        
        public init(authInfo: AuthInfo, communityProfile: CommunityProfile? = nil) {
            self.authInfo = authInfo
            self.communityProfile = communityProfile
        }
    }
    
    @Reducer(state: .equatable, action: .equatable, .sendable)
    public enum Destination {
        case academySetting(MyAcademySettingFeature)
    }
    
    @CasePathable
    public enum Action: Equatable, Sendable {
        // View Lifecycle Actions
        case onAppear
        
        // View UI Actions
        case gymInfoButtonTapped
        case registerBeltButtonTapped
        case registerStyleButtonTapped
        
        // API Actions
        case loadProfile
        case _profileResponse(TaskResult<CommunityProfile>)
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
        
        // 토스트 관련 액션
        case showToast(ToastState)
        case toastDismissed
        case toastButtonTapped(ToastState.Action)
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.communityClient) var communityClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadProfile)
                
            case .loadProfile:
                state.isLoadingProfile = true
                return .run { send in
                    await send(._profileResponse(
                        await TaskResult { try await communityClient.fetchProfile() }
                    ))
                }
                
            case let ._profileResponse(.success(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .none
                
            case let ._profileResponse(.failure(error)):
                state.isLoadingProfile = false
                Log.trace("Failed to load profile: \(error)", category: .network, level: .error)
                return .send(.showToast(.init(message: "프로필을 불러오는데 실패했어요", style: .info)))
                
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
                // 도장 이름 저장 성공 처리
                // TODO: authInfo 또는 사용자 프로필 정보 업데이트
                // state.authInfo.academyName = academyName
                
                // 화면 닫기
                state.destination = nil
                
                // 토스트 메시지 표시
                return .send(.showToast(.init(message: "도장 정보 입력을 완료했어요", style: .info)))
                
            case .destination(.presented(.academySetting(.delegate(.saveFailed)))):
                // 저장 실패 시 화면은 유지 (사용자가 다시 시도할 수 있도록)
                return .none
                
            case let .showToast(toastState):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.toastDismissed)
                }
                .cancellable(id: CancelID.toast)
                
            case .toastDismissed:
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .toastButtonTapped:
                return .send(.toastDismissed)
                
            case .destination:
                return .none
                
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
