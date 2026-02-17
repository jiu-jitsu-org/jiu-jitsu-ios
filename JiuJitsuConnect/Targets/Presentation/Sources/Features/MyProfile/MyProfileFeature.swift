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
public struct MyProfileFeature: Sendable {
    public init() {}
    
    private enum CancelID { case toast }
    
    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        @Presents var sheet: Sheet.State?
        
        var authInfo: AuthInfo
        
        // 커뮤니티 프로필 정보
        var communityProfile: CommunityProfile?
        var isLoadingProfile: Bool = false
        
        // 토스트 메시지 상태
        var toast: ToastState?
        
        // 벨트 설정 임시 저장 (최초 설정 시 벨트 정보를 체급 설정으로 전달하기 위해)
        var tempBeltInfo: TempBeltInfo?
        
        public init(authInfo: AuthInfo, communityProfile: CommunityProfile? = nil) {
            self.authInfo = authInfo
            self.communityProfile = communityProfile
        }
        
        // 임시 벨트 정보를 담는 구조체
        public struct TempBeltInfo: Equatable, Sendable {
            let rank: BeltRank
            let stripe: BeltStripe
        }
    }
    
    @Reducer
    public enum Destination {
        case academySetting(MyAcademySettingFeature)
        case nicknameSetting(NicknameSettingFeature)
    }
    
    @Reducer
    public enum Sheet {
        case beltSetting(BeltSettingFeature)
        case weightClassSetting(WeightClassSettingFeature)
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
        // 시트 액션
        case sheet(PresentationAction<Sheet.Action>)
        
        public enum ViewAction: Sendable {
            case onAppear
            case gymInfoButtonTapped
            case nicknameEditButtonTapped
            case registerBeltButtonTapped
            case beltTapped             // 이미 등록된 벨트 영역 탭 → 수정 모드로 시트 노출
            case registerStyleButtonTapped
            case weightVisibilityToggleButtonTapped
            case toastButtonTapped(ToastState.Action)
        }
        
        public enum InternalAction: Sendable {
            case loadProfile
            case profileResponse(TaskResult<CommunityProfile>)
            case updateProfileSection(ProfileSection, String?)
            case saveBeltAndWeightInfo(rank: BeltRank, stripe: BeltStripe, gender: Gender, weightKg: Double, isWeightHidden: Bool)
            case saveBeltInfoOnly(rank: BeltRank, stripe: BeltStripe)
            case toggleWeightVisibility
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
                // 벨트/체급 등록 화면을 시트로 노출 (최초 설정 모드)
                let currentRank = state.communityProfile?.beltRank ?? .white
                let currentStripe = state.communityProfile?.beltStripe ?? .none
                // 최초 설정인지 확인 (벨트 정보가 없으면 최초 설정)
                let isInitialSetup = state.communityProfile?.beltRank == nil
                state.sheet = .beltSetting(
                    BeltSettingFeature.State(
                        selectedRank: currentRank,
                        selectedStripe: currentStripe,
                        isInitialSetup: isInitialSetup
                    )
                )
                return .none
                
            case .view(.beltTapped):
                // 이미 등록된 벨트 영역 탭 → 수정 모드(isInitialSetup: false)로 시트 노출
                let currentRank = state.communityProfile?.beltRank ?? .white
                let currentStripe = state.communityProfile?.beltStripe ?? .none
                state.sheet = .beltSetting(
                    BeltSettingFeature.State(
                        selectedRank: currentRank,
                        selectedStripe: currentStripe,
                        isInitialSetup: false
                    )
                )
                return .none
                
            case .view(.registerStyleButtonTapped):
                // 스타일 등록 화면 이동 로직
                return .none
                
            case .view(.weightVisibilityToggleButtonTapped):
                // 체급 숨김/보기 토글
                return .send(.internal(.toggleWeightVisibility))
                
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
                
            // MARK: - Sheet Delegate 처리
                
            case let .sheet(.presented(.beltSetting(.delegate(.proceedToWeightClassSetting(rank, stripe))))):
                // 최초 설정: 벨트 정보를 임시 저장하고 체급 설정 화면으로 이동
                state.tempBeltInfo = State.TempBeltInfo(rank: rank, stripe: stripe)
                let currentGender = state.communityProfile?.gender ?? .male
                let currentWeight = state.communityProfile?.weightKg ?? 60.0
                let isWeightHidden = state.communityProfile?.isWeightHidden ?? false
                
                state.sheet = .weightClassSetting(
                    WeightClassSettingFeature.State(
                        selectedGender: currentGender,
                        selectedWeightKg: currentWeight,
                        isWeightHidden: isWeightHidden
                    )
                )
                return .none
                
            case let .sheet(.presented(.beltSetting(.delegate(.didConfirmBelt(rank, stripe))))):
                // 벨트 수정: API 호출하고 토스트 표시
                state.sheet = nil
                return .send(.internal(.saveBeltInfoOnly(rank: rank, stripe: stripe)))
                
            case let .sheet(.presented(.weightClassSetting(.delegate(.didConfirmWeightClass(gender, weightKg, isWeightHidden))))):
                // 체급 설정 완료: 벨트 정보와 함께 API 호출
                guard let beltInfo = state.tempBeltInfo else {
                    state.sheet = nil
                    return .send(.internal(.showToast(.init(message: "벨트 정보를 찾을 수 없어요", style: .info))))
                }
                
                state.sheet = nil
                state.tempBeltInfo = nil
                return .send(.internal(.saveBeltAndWeightInfo(
                    rank: beltInfo.rank,
                    stripe: beltInfo.stripe,
                    gender: gender,
                    weightKg: weightKg,
                    isWeightHidden: isWeightHidden
                )))
                
            // MARK: - API 호출: 벨트/체급 정보 저장
                
            case let .internal(.saveBeltAndWeightInfo(rank, stripe, gender, weightKg, isWeightHidden)):
                guard var profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 체중을 소수점 첫째 자리로 반올림
                let roundedWeight = round(weightKg * 10) / 10.0
                
                // 벨트와 체급 정보 업데이트
                profile = CommunityProfile(
                    nickname: profile.nickname,
                    profileImageUrl: profile.profileImageUrl,
                    beltRank: rank,
                    beltStripe: stripe,
                    gender: gender,
                    weightKg: roundedWeight,
                    academyName: profile.academyName,
                    competitions: profile.competitions,
                    bestSubmission: profile.bestSubmission,
                    favoriteSubmission: profile.favoriteSubmission,
                    bestTechnique: profile.bestTechnique,
                    favoriteTechnique: profile.favoriteTechnique,
                    bestPosition: profile.bestPosition,
                    favoritePosition: profile.favoritePosition,
                    isWeightHidden: isWeightHidden,
                    isOwner: profile.isOwner,
                    teachingPhilosophy: profile.teachingPhilosophy,
                    teachingStartDate: profile.teachingStartDate,
                    teachingDetail: profile.teachingDetail
                )
                
                state.isLoadingProfile = true
                
                return .run { [profile] send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(profile, .beltWeight)
                        }
                    )))
                }
                
            case let .internal(.saveBeltInfoOnly(rank, stripe)):
                guard var profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 벨트 정보만 업데이트
                profile = CommunityProfile(
                    nickname: profile.nickname,
                    profileImageUrl: profile.profileImageUrl,
                    beltRank: rank,
                    beltStripe: stripe,
                    gender: profile.gender,
                    weightKg: profile.weightKg,
                    academyName: profile.academyName,
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
                
                state.isLoadingProfile = true
                
                return .run { [profile] send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(profile, .beltWeight)
                        }
                    )))
                }
                
            case .internal(.toggleWeightVisibility):
                guard var profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 체급 가시성만 토글
                let newVisibility = !(profile.isWeightHidden)
                profile = CommunityProfile(
                    nickname: profile.nickname,
                    profileImageUrl: profile.profileImageUrl,
                    beltRank: profile.beltRank,
                    beltStripe: profile.beltStripe,
                    gender: profile.gender,
                    weightKg: profile.weightKg,
                    academyName: profile.academyName,
                    competitions: profile.competitions,
                    bestSubmission: profile.bestSubmission,
                    favoriteSubmission: profile.favoriteSubmission,
                    bestTechnique: profile.bestTechnique,
                    favoriteTechnique: profile.favoriteTechnique,
                    bestPosition: profile.bestPosition,
                    favoritePosition: profile.favoritePosition,
                    isWeightHidden: newVisibility,
                    isOwner: profile.isOwner,
                    teachingPhilosophy: profile.teachingPhilosophy,
                    teachingStartDate: profile.teachingStartDate,
                    teachingDetail: profile.teachingDetail
                )
                
                state.isLoadingProfile = true
                
                return .run { [profile] send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(profile, .beltWeight)
                        }
                    )))
                }
                
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
                let previousProfile = state.communityProfile
                state.communityProfile = updatedProfile  // ← 업데이트된 프로필로 교체!
                state.destination = nil  // 화면 닫기
                
                // 어떤 섹션이 업데이트되었는지에 따라 다른 메시지 표시
                let message: String
                if previousProfile?.beltRank == nil && updatedProfile.beltRank != nil {
                    // 최초 벨트/체급 설정
                    message = "벨트와 체급 정보 입력을 완료했어요"
                } else if previousProfile?.academyName == nil && updatedProfile.academyName != nil {
                    // 도장 정보 추가
                    message = "도장 정보 입력을 완료했어요"
                } else if previousProfile?.beltRank != updatedProfile.beltRank ||
                         previousProfile?.beltStripe != updatedProfile.beltStripe {
                    // 벨트 정보 수정
                    message = "벨트 정보 수정을 완료했어요"
                } else if previousProfile?.isWeightHidden != updatedProfile.isWeightHidden {
                    // 체급 가시성 변경
                    message = updatedProfile.isWeightHidden ? "체급을 숨겼어요" : "체급을 공개했어요"
                } else {
                    // 기타
                    message = "프로필 수정을 완료했어요"
                }
                
                return .send(.internal(.showToast(.init(message: message, style: .info))))
                
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
                
            case .destination, .sheet, .view, .internal:
                return .none
                
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
        .ifLet(\.$sheet, action: \.sheet) {
            Sheet.body
        }
    }
}
// MARK: - Sendable Conformances
extension MyProfileFeature.Destination.State: Sendable, Equatable {}
extension MyProfileFeature.Destination.Action: Sendable {}
extension MyProfileFeature.Sheet.State: Sendable, Equatable {}
extension MyProfileFeature.Sheet.Action: Sendable {}
