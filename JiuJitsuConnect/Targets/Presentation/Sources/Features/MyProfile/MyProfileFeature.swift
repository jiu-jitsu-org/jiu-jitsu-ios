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
        
        // TODO: 테스트 기간 동안만 사용 - 운영 배포 전 제거 필요
        // 디버그용: 데이터가 리셋된 상태인지 추적
        var isDataReset: Bool = false
        
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
        case myStyleSetting(MyStyleSettingFeature)
        case competitionInfo(CompetitionInfoFeature)
    }
    
    @Reducer
    public enum Sheet {
        case beltSetting(BeltSettingFeature)
        case weightClassSetting(WeightClassSettingFeature)
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
        // 시트 액션
        case sheet(PresentationAction<Sheet.Action>)
        
        public enum DelegateAction: Sendable {}

        public enum ViewAction: Sendable {
            case onAppear
            case gymInfoButtonTapped
            case nicknameEditButtonTapped
            case registerBeltButtonTapped
            case beltTapped             // 이미 등록된 벨트 영역 탭 → 수정 모드로 시트 노출
            case weightClassTapped      // 이미 등록된 체급 영역 탭 → 체급 수정 시트 노출
            case registerStyleButtonTapped
            case styleCardEditTapped(MyStyleSettingType, MyStyleSettingFeature.SelectionTab)  // 프로필 스타일 카드 탭 → 해당 타입 수정 모드 진입
            case weightVisibilityToggleButtonTapped
            case toastButtonTapped(ToastState.Action)
            case addCompetitionButtonTapped  // 대회 정보 추가 버튼 탭
            case competitionDetailTapped(Competition)  // 대회 정보 행 탭
            
            // TODO: 테스트 기간 동안만 사용 - 운영 배포 전 제거 필요
            case debugResetDataButtonTapped  // 디버그용 데이터 리셋 버튼 (리셋 상태에서는 데이터 불러오기 버튼)
        }
        
        public enum InternalAction: Sendable {
            case loadProfile
            case profileResponse(TaskResult<CommunityProfile>)
            case updateProfileSection(ProfileSection, String?)
            case saveBeltAndWeightInfo(rank: BeltRank, stripe: BeltStripe, gender: Gender, weightKg: Double, isWeightHidden: Bool)
            case saveBeltInfoOnly(rank: BeltRank, stripe: BeltStripe)
            case saveWeightInfoOnly(gender: Gender, weightKg: Double, isWeightHidden: Bool)
            case toggleWeightVisibility
            // 스타일 저장 (특기 + 최애 한 번에)
            case savePosition(best: PositionType?, favorite: PositionType?)
            case saveSubmission(best: SubmissionType?, favorite: SubmissionType?)
            case saveTechnique(best: TechniqueType?, favorite: TechniqueType?)

            // 응답 처리
            case updateProfileResponse(TaskResult<CommunityProfile>)
            case positionSaved(CommunityProfile)    // 포지션 저장 → register 시 서브미션 단계로
            case submissionSaved(CommunityProfile)  // 서브미션 저장 → register 시 기술 단계로
            case techniqueSaved(CommunityProfile)   // 기술 저장 → 프로필 화면으로 복귀
            
            case showToast(ToastState)
            case toastDismissed
            
            // TODO: 테스트 기간 동안만 사용 - 운영 배포 전 제거 필요
            case debugResetAllData  // 디버그용 모든 데이터 리셋
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.communityClient) var communityClient
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isDataReset, !state.isLoadingProfile else { return .none }
                // 이미 프로필 데이터가 있으면 불필요한 재로드 방지
                // (toast dismiss 등 state 변화로 onAppear가 재트리거되는 경우 차단)
                guard state.communityProfile == nil else { return .none }
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
                state.isDataReset = false  // 데이터 로드 성공 시 리셋 상태 해제
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
                
            case .view(.weightClassTapped):
                // 이미 등록된 체급 영역 탭 → 체급 수정 시트 노출
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
                
            case .view(.registerStyleButtonTapped):
                // 포지션 설정 화면으로 네비게이션 (스타일 설정의 첫 단계)
                state.destination = .myStyleSetting(
                    MyStyleSettingFeature.State(
                        settingType: .position,
                        mode: .register,
                        bestPosition: state.communityProfile?.bestPosition,
                        favoritePosition: state.communityProfile?.favoritePosition,
                        bestSubmission: state.communityProfile?.bestSubmission,
                        favoriteSubmission: state.communityProfile?.favoriteSubmission,
                        bestTechnique: state.communityProfile?.bestTechnique,
                        favoriteTechnique: state.communityProfile?.favoriteTechnique
                    )
                )
                return .none
                
            case let .view(.styleCardEditTapped(type, tab)):
                // 프로필 카드 탭 → 해당 타입만 수정하는 edit 모드로 진입
                state.destination = .myStyleSetting(
                    MyStyleSettingFeature.State(
                        settingType: type,
                        mode: .edit,
                        initialTab: tab,
                        bestPosition: state.communityProfile?.bestPosition,
                        favoritePosition: state.communityProfile?.favoritePosition,
                        bestSubmission: state.communityProfile?.bestSubmission,
                        favoriteSubmission: state.communityProfile?.favoriteSubmission,
                        bestTechnique: state.communityProfile?.bestTechnique,
                        favoriteTechnique: state.communityProfile?.favoriteTechnique
                    )
                )
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
                
            case let .destination(.presented(.myStyleSetting(.delegate(.didConfirmStyle(type, bestKey, favoriteKey))))):
                // 스타일 저장 (특기 + 최애 한 번에) → register 시 다음 단계, edit 시 화면 닫기
                switch type {
                case .position:
                    let best = bestKey.flatMap { PositionType(rawValue: $0) }
                    let favorite = favoriteKey.flatMap { PositionType(rawValue: $0) }
                    return .send(.internal(.savePosition(best: best, favorite: favorite)))

                case .submission:
                    let best = bestKey.flatMap { SubmissionType(rawValue: $0) }
                    let favorite = favoriteKey.flatMap { SubmissionType(rawValue: $0) }
                    return .send(.internal(.saveSubmission(best: best, favorite: favorite)))

                case .technique:
                    let best = bestKey.flatMap { TechniqueType(rawValue: $0) }
                    let favorite = favoriteKey.flatMap { TechniqueType(rawValue: $0) }
                    return .send(.internal(.saveTechnique(best: best, favorite: favorite)))
                }
                
            case .destination(.presented(.myStyleSetting(.delegate(.cancel)))):
                // 뒤로가기: 스타일 설정 화면 닫기
                state.destination = nil
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
                Log.trace("벨트 수정 확인됨 - rank: \(rank.displayName), stripe: \(stripe.displayName)", category: .debug, level: .info)
                state.sheet = nil
                return .send(.internal(.saveBeltInfoOnly(rank: rank, stripe: stripe)))
                
            case let .sheet(.presented(.weightClassSetting(.delegate(.didConfirmWeightClass(gender, weightKg, isWeightHidden))))):
                // 체급 설정 완료: 벨트 정보와 함께 API 호출
                guard let beltInfo = state.tempBeltInfo else {
                    // 벨트 정보가 없는 경우 = 체급만 수정하는 경우
                    state.sheet = nil
                    return .send(.internal(.saveWeightInfoOnly(gender: gender, weightKg: weightKg, isWeightHidden: isWeightHidden)))
                }
                
                // 벨트 정보가 있는 경우 = 최초 설정 (벨트 + 체급 함께 저장)
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
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 체중을 소수점 첫째 자리로 반올림하고 벨트와 체급 정보 업데이트
                let roundedWeight = round(weightKg * 10) / 10.0
                let updatedProfile = profile.updatingBeltAndWeight(
                    rank: rank,
                    stripe: stripe,
                    gender: gender,
                    weightKg: roundedWeight,
                    isWeightHidden: isWeightHidden
                )
                
                state.isLoadingProfile = true
                
                return .run { send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(updatedProfile, .beltWeight)
                        }
                    )))
                }
                
            case let .internal(.saveBeltInfoOnly(rank, stripe)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                Log.trace("벨트 수정 - 기존: \(profile.beltRank?.displayName ?? "없음") \(profile.beltStripe?.displayName ?? ""), 새로운: \(rank.displayName) \(stripe.displayName)", category: .debug, level: .info)
                
                // 벨트 정보만 업데이트
                let updatedProfile = profile.updatingBelt(rank: rank, stripe: stripe)
                
                Log.trace("API 요청할 프로필: \(updatedProfile.beltRank?.displayName ?? "없음") \(updatedProfile.beltStripe?.displayName ?? "")", category: .debug, level: .info)
                
                state.isLoadingProfile = true
                
                return .run { send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(updatedProfile, .beltWeight)
                        }
                    )))
                }
                
            case let .internal(.saveWeightInfoOnly(gender, weightKg, isWeightHidden)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 체중을 소수점 첫째 자리로 반올림
                let roundedWeight = round(weightKg * 10) / 10.0
                
                Log.trace("체급 수정 - 기존: \(profile.gender?.displayName ?? "없음") \(profile.weightKg ?? 0)kg (숨김: \(profile.isWeightHidden)), 새로운: \(gender.displayName) \(roundedWeight)kg (숨김: \(isWeightHidden))", category: .debug, level: .info)
                
                // 체급 정보만 업데이트
                let updatedProfile = profile.updatingWeight(gender: gender, weightKg: roundedWeight, isWeightHidden: isWeightHidden)
                
                state.isLoadingProfile = true
                
                return .run { send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(updatedProfile, .beltWeight)
                        }
                    )))
                }
                
            case .internal(.toggleWeightVisibility):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                
                // 체급 가시성만 토글
                let updatedProfile = profile.togglingWeightVisibility()
                
                state.isLoadingProfile = true
                
                return .run { send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            try await communityClient.updateProfile(updatedProfile, .beltWeight)
                        }
                    )))
                }
                
            // MARK: - API 호출: 프로필 섹션 업데이트

            case let .internal(.updateProfileSection(section, value)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }

                // 섹션별로 업데이트할 필드 설정
                let updatedProfile: CommunityProfile
                switch section {
                case .academy:
                    updatedProfile = profile.updatingAcademy(value)

                case .beltWeight, .position, .submission, .technique, .competition, .instructorInfo:
                    // TODO: 다른 섹션 업데이트 구현
                    return .none
                }
                
                state.isLoadingProfile = true
                
                return .run { [section] send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            // CommunityClient에 섹션 정보도 전달
                            try await communityClient.updateProfile(updatedProfile, section)
                        }
                    )))
                }
                
            // MARK: - API 호출: 스타일 정보 저장 (특기 + 최애 한 번에)

            case let .internal(.savePosition(best, favorite)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }

                let updatedProfile = profile.updatingPosition(best: best, favorite: favorite)
                state.isLoadingProfile = true

                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .position)
                    }

                    switch result {
                    case .success(let updatedProfile):
                        await send(.internal(.positionSaved(updatedProfile)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.saveSubmission(best, favorite)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }

                let updatedProfile = profile.updatingSubmission(best: best, favorite: favorite)
                state.isLoadingProfile = true

                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .submission)
                    }

                    switch result {
                    case .success(let updatedProfile):
                        await send(.internal(.submissionSaved(updatedProfile)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.saveTechnique(best, favorite)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }

                let updatedProfile = profile.updatingTechnique(best: best, favorite: favorite)
                state.isLoadingProfile = true

                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .technique)
                    }

                    switch result {
                    case .success(let updatedProfile):
                        await send(.internal(.techniqueSaved(updatedProfile)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            // MARK: - 저장 성공 후 처리

            case let .internal(.positionSaved(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                if case let .myStyleSetting(styleState) = state.destination, styleState.mode == .edit {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "포지션을 저장했어요", style: .info))))
                } else {
                    // register 플로우: 다음 단계(서브미션)로 이동
                    state.destination = .myStyleSetting(
                        MyStyleSettingFeature.State(
                            settingType: .submission,
                            mode: .register,
                            bestSubmission: profile.bestSubmission,
                            favoriteSubmission: profile.favoriteSubmission
                        )
                    )
                }
                return .none

            case let .internal(.submissionSaved(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                if case let .myStyleSetting(styleState) = state.destination, styleState.mode == .edit {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "서브미션을 저장했어요", style: .info))))
                } else {
                    // register 플로우: 다음 단계(기술)로 이동
                    state.destination = .myStyleSetting(
                        MyStyleSettingFeature.State(
                            settingType: .technique,
                            mode: .register,
                            bestTechnique: profile.bestTechnique,
                            favoriteTechnique: profile.favoriteTechnique
                        )
                    )
                }
                return .none

            case let .internal(.techniqueSaved(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                if case let .myStyleSetting(styleState) = state.destination, styleState.mode == .edit {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "기술을 저장했어요", style: .info))))
                }
                // register 플로우 마지막 단계: 프로필 화면으로 복귀
                state.destination = nil
                return .send(.internal(.showToast(.init(message: "모든 스타일 설정을 완료했어요", style: .info))))
                
            // MARK: - API 호출: 프로필 섹션 업데이트
                
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
                } else if previousProfile?.gender != updatedProfile.gender ||
                         previousProfile?.weightKg != updatedProfile.weightKg ||
                         (previousProfile?.isWeightHidden == updatedProfile.isWeightHidden &&
                          (previousProfile?.gender != updatedProfile.gender || previousProfile?.weightKg != updatedProfile.weightKg)) {
                    // 체급 정보 수정 (성별, 체중 변경)
                    message = "체급 정보 수정을 완료했어요"
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
                
            case .view(.addCompetitionButtonTapped):
                state.destination = .competitionInfo(CompetitionInfoFeature.State())
                return .none

            case let .destination(.presented(.competitionInfo(.delegate(.didFinish(competition))))):
                // TODO: Step 3 - 저장 client 연결. 현재는 로그만 남기고 화면 닫기
                Log.trace(
                    "대회 추가 완료: \(competition.competitionYear)/\(competition.competitionMonth) \(competition.competitionName) \(competition.competitionRank.displayName)",
                    category: .debug,
                    level: .info
                )
                state.destination = nil
                return .none
                
            case let .view(.competitionDetailTapped(competition)):
                // TODO: 대회 정보 상세 화면으로 네비게이션
                // 현재는 로그만 출력
                Log.trace("대회 정보 탭: \(competition.competitionName)", category: .debug, level: .info)
                return .none
                
            // MARK: - Debug Actions (테스트 전용)
            
            case .view(.debugResetDataButtonTapped):
                // TODO: 테스트 기간 동안만 사용 - 운영 배포 전 제거 필요
                if state.isDataReset {
                    // 리셋 상태에서 버튼 탭 = 데이터 다시 불러오기
                    Log.trace("🔄 디버그: 데이터 다시 불러오기", category: .debug, level: .info)
                    state.isDataReset = false
                    return .send(.internal(.loadProfile))
                } else {
                    // 일반 상태에서 버튼 탭 = 데이터 리셋
                    Log.trace("🔄 디버그: 데이터 리셋 버튼 탭", category: .debug, level: .info)
                    return .send(.internal(.debugResetAllData))
                }
                
            case .internal(.debugResetAllData):
                // TODO: 테스트 기간 동안만 사용 - 운영 배포 전 제거 필요
                Log.trace("🔄 디버그: 모든 데이터를 초기화합니다", category: .debug, level: .info)
                
                // 프로필을 nil로 설정하여 빈 화면 표시
                state.communityProfile = nil
                state.isDataReset = true
                state.isLoadingProfile = false
                
                return .send(.internal(.showToast(.init(message: "데이터를 초기화했어요. '내 데이터 불러오기'를 눌러 복원하세요", style: .info))))
                
            case .destination, .sheet, .view, .internal, .delegate:
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
