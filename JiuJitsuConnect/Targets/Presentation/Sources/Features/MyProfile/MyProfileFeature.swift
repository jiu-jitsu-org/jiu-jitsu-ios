//
//  MyProfileFeature.swift
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
public struct MyProfileFeature {
    public init() {}
    
    private enum CancelID { case toast }
    
    @ObservableState
    public struct State: Sendable {
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
    
    @Reducer
    public enum Destination {
        case academySetting(MyAcademySettingFeature)
        case nicknameSetting(NicknameSettingFeature)
    }
    
    @CasePathable
    public enum Action: Equatable, Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
        
        public enum ViewAction: Equatable, Sendable {
            case onAppear
            case gymInfoButtonTapped
            case nicknameEditButtonTapped
            case registerBeltButtonTapped
            case registerStyleButtonTapped
            case toastButtonTapped(ToastState.Action)
        }
        
        public enum InternalAction: Equatable, Sendable {
            case loadProfile
            case profileResponse(TaskResult<CommunityProfile>)
            case updateProfileSection(ProfileSection, String?)
            case updateProfileResponse(TaskResult<CommunityProfile>)
            case showToast(ToastState)
            case toastDismissed
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.communityClient) var communityClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadProfile))
                
            case .internal(.loadProfile):
                state.isLoadingProfile = true
                return .run { send in
                    await send(.internal(.profileResponse(
                        await TaskResult { try await communityClient.fetchProfile() }
                    )))
                }
                
            case let .internal(.profileResponse(.success(profile))):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .none
                
            case let .internal(.profileResponse(.failure(error))):
                state.isLoadingProfile = false
                Log.trace("Failed to load profile: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(message: "프로필을 불러오는데 실패했어요", style: .info))))
                
            case .view(.gymInfoButtonTapped):
                // 도장 정보 입력 화면으로 네비게이션
                let currentAcademyName = state.communityProfile?.academyName ?? ""
                let mode: MyAcademySettingFeature.Mode = currentAcademyName.isEmpty ? .add : .edit
                state.destination = .academySetting(
                    MyAcademySettingFeature.State(mode: mode, academyName: currentAcademyName)
                )
                return .none
                
            case .view(.nicknameEditButtonTapped):
                // 닉네임 수정 화면으로 네비게이션
                let currentNickname = state.communityProfile?.nickname ?? ""
                state.destination = .nicknameSetting(
                    NicknameSettingFeature.State(mode: .edit, nickname: currentNickname)
                )
                return .none
                
            case .view(.registerBeltButtonTapped):
                // 벨트/체급 등록 화면 이동 로직
                return .none
                
            case .view(.registerStyleButtonTapped):
                // 스타일 등록 화면 이동 로직
                return .none
                
            // MARK: - Delegate 처리 (자식 Feature로부터)
                
            case let .destination(.presented(.academySetting(.delegate(.saveAcademyName(academyName))))):
                // 도장 이름 저장 요청 받음 → API 호출
                return .send(.internal(.updateProfileSection(.academy, academyName)))
                
            case .destination(.presented(.academySetting(.delegate(.cancel)))):
                // 취소 - 아무것도 하지 않음
                return .none
                
            case let .destination(.presented(.nicknameSetting(.delegate(.saveNickname(nickname))))):
                // 닉네임 저장 요청 받음 → TODO: API 호출 구현 필요
                Log.trace("닉네임 저장 요청: \(nickname)", category: .debug, level: .info)
                state.destination = nil
                return .send(.internal(.showToast(.init(message: "닉네임 수정을 완료했어요", style: .info))))
                
            case .destination(.presented(.nicknameSetting(.delegate(.cancel)))):
                // 취소 - 아무것도 하지 않음
                return .none
                
            // MARK: - API 호출: 프로필 섹션 업데이트
                
            case let .internal(.updateProfileSection(section, value)):
                guard var profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 섹션별로 업데이트할 필드 설정
                switch section {
                case .academy:
                    profile = CommunityProfile(
                        nickname: profile.nickname,
                        profileImageUrl: profile.profileImageUrl,
                        beltRank: profile.beltRank,
                        beltStripe: profile.beltStripe,
                        gender: profile.gender,
                        weightKg: profile.weightKg,
                        academyName: value,  // ← 업데이트!
                        competitions: profile.competitions,
                        bestSubmission: profile.bestSubmission,
                        favoriteSubmission: profile.favoriteSubmission,
                        bestTechnique: profile.bestTechnique,
                        favoriteTechnique: profile.favoriteTechnique,
                        bestPosition: profile.bestPosition,
                        favoritePosition: profile.favoritePosition,
                        isWeightHidden: profile.isWeightHidden,
                        isOwner: profile.isOwner,
                        teachingPhilosophy: profile.teachingPhilosophy,
                        teachingStartDate: profile.teachingStartDate,
                        teachingDetail: profile.teachingDetail
                    )
                    
                case .beltWeight, .position, .submission, .technique, .competition, .instructorInfo:
                    // TODO: 다른 섹션 업데이트 구현
                    break
                }
                
                state.isLoadingProfile = true
                
                return .run { [profile, section] send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            // CommunityClient에 섹션 정보도 전달
                            try await communityClient.updateProfile(profile, section)
                        }
                    )))
                }
                
            case let .internal(.updateProfileResponse(.success(updatedProfile))):
                state.isLoadingProfile = false
                state.communityProfile = updatedProfile  // ← 업데이트된 프로필로 교체!
                state.destination = nil  // 화면 닫기
                return .send(.internal(.showToast(.init(message: "도장 정보 입력을 완료했어요", style: .info))))
                
            case let .internal(.updateProfileResponse(.failure(error))):
                state.isLoadingProfile = false
                Log.trace("Failed to update profile: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(message: "저장에 실패했어요. 다시 시도해주세요", style: .info))))
                
            case let .internal(.showToast(toastState)):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.internal(.toastDismissed))
                }
                .cancellable(id: CancelID.toast)
                
            case .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .view(.toastButtonTapped):
                return .send(.internal(.toastDismissed))
                
            case .destination, .view, .internal:
                return .none
                
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }
}
