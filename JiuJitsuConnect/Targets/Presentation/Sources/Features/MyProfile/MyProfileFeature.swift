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
    
    private enum CancelID { case toast, profileImageUpload, instructorVerificationUpload }

    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        @Presents var sheet: Sheet.State?
        
        var authInfo: AuthInfo
        
        // 커뮤니티 프로필 정보
        var communityProfile: CommunityProfile?
        var isLoadingProfile: Bool = false

        // user-level 프로필 — 관장사범 인증 상태(ownerRequested)·제출 이미지(ownerRequestImageUrl) 등.
        // 닉네임/프로필이미지 등 community와 겹치는 필드는 표시에 쓰지 않는다(단일 소스는 communityProfile).
        var userProfile: UserProfile?
        
        // 토스트 메시지 상태
        var toast: ToastState?
        
        // 벨트 설정 임시 저장 (최초 설정 시 벨트 정보를 체급 설정으로 전달하기 위해)
        var tempBeltInfo: TempBeltInfo?

        // 우측 상단 "..." 메뉴 노출 여부 (관장 사범 인증 메뉴)
        var isMoreMenuPresented: Bool = false

        // 프로필 이미지 캡처 픽커 (카메라/앨범 풀스크린)
        var imageCaptureSource: ImageCaptureSource?

        // 1:1 크롭 화면 풀스크린 커버
        @Presents var imageCropCover: ProfileImageCropFeature.State?

        // 현재 진행 중인 이미지 픽 흐름의 목적 — 픽커→크롭→업로드 파이프라인 전반에 걸쳐
        // 어느 사용처(프로필 이미지 vs. 관장 사범 인증)에서 시작됐는지 식별하기 위함.
        // 시트가 닫힌 뒤(파일러/크롭 진행 중)에도 유지되어야 하므로 별도 상태로 둔다.
        var pendingImagePurpose: ProfileImageEditFeature.Purpose?

        // MARK: - 프로필 이미지 Optimistic Update 상태
        //
        // ImageKit 업로드 + BE 반영까지 2~5초 걸리는 동안 사용자가 변화를 즉시 인지하도록
        // 크롭 직후 로컬 데이터를 헤더에 미리 표시한다. 응답 성공 시 communityProfile.profileImageUrl로
        // 자연스럽게 전환되고, 실패 시 두 필드를 비워 이전 이미지로 롤백한다.

        /// 업로드 진행 중 헤더에 미리 노출할 로컬 이미지 데이터
        var pendingProfileImageData: Data?
        /// 이미지 삭제 진행 중 — 헤더를 기본 아이콘으로 미리 전환
        var isProfileImageDeleting: Bool = false

        public enum ImageCaptureSource: Equatable, Sendable {
            case camera
            case photoLibrary
        }

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
        case profileImageEdit(ProfileImageEditFeature)
        case instructorVerification(InstructorVerificationFeature)
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
        
        // 네비게이션 액션
        case destination(PresentationAction<Destination.Action>)
        // 시트 액션
        case sheet(PresentationAction<Sheet.Action>)
        // 1:1 크롭 풀스크린 커버 액션
        case imageCropCover(PresentationAction<ProfileImageCropFeature.Action>)
        
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
            case moreButtonTapped                   // 우측 상단 "..." 버튼 탭 (토글)
            case instructorVerificationMenuTapped   // "관장 사범 인증" 메뉴 항목 탭
            case imagePicked(Data)                  // 카메라/앨범 픽커에서 이미지 선택됨
            case imagePickerCancelled               // 픽커 취소 (시스템 dismiss 포함)
            case profileImageEditButtonTapped       // 프로필 이미지 우측 하단 카메라 버튼 탭
        }
        
        public enum InternalAction: Sendable {
            case loadProfile
            case profileResponse(TaskResult<CommunityProfile>)
            // user-level 프로필(GET /api/user/profile) 응답 — 관장사범 인증 상태(ownerRequested) 등.
            // community 프로필과 독립적으로 처리해 한쪽 실패가 다른 쪽을 막지 않게 한다.
            case userProfileResponse(TaskResult<UserProfile>)
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
            case positionSaved(CommunityProfile)    // 포지션 저장 → register 시 기술 단계로
            case submissionSaved(CommunityProfile)  // 서브미션 저장 → 프로필 화면으로 복귀
            case techniqueSaved(CommunityProfile)   // 기술 저장 → register 시 서브미션 단계로
            case competitionAdded(CommunityProfile)   // 대회 정보 추가 저장 완료
            case competitionUpdated(CommunityProfile) // 대회 정보 수정 저장 완료
            case competitionDeleted(CommunityProfile) // 대회 정보 삭제 저장 완료
            
            case showToast(ToastState)
            case toastDismissed

            // 프로필 이미지 수정 흐름 — 시트/풀스크린 전환 사이에 짧은 딜레이를 두고 발화
            case presentImageCaptureSource(State.ImageCaptureSource)
            case presentImageCrop(Data)
            // 관장 사범 인증 → 사진 첨부 시트로의 시트-시트 전환을 위한 딜레이 발화
            case presentImageEditSheet(ProfileImageEditFeature.Purpose, canDelete: Bool)

            // 프로필 이미지 업로드/반영 응답
            case profileImageUploadResponse(TaskResult<RegisteredImage>)   // CDN 업로드 + 서버 등록 결과(id 포함)
            case profileImageUpdateResponse(TaskResult<CommunityProfile>)  // PUT /api/user/profile 반영 결과

            // 관장 사범 인증 사진 업로드 응답 (ImageKit 호스팅 URL)
            // 성공 시 확보한 URL로 BE 인증 요청(PUT /api/user/owner)을 체이닝한다.
            case instructorVerificationImageUploadResponse(TaskResult<RegisteredImage>)
            // 관장 사범 인증 요청 응답 (PUT /api/user/owner)
            case instructorVerificationRequestResponse(TaskResult<Bool>)

            // 닉네임 갱신 응답 (이미지와 동일한 PUT /api/user/profile 사용)
            case nicknameUpdateResponse(TaskResult<CommunityProfile>)
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.communityClient) var communityClient
    @Dependency(\.imageUploadClient) var imageUploadClient
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.userClient) var userClient


    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                // 게스트 상태에서는 프로필 API를 호출하지 않는다.
                // AppTabView가 모든 탭을 미리 마운트하므로 게스트일 때도 onAppear가 발화한다.
                guard !state.authInfo.isGuest else { return .none }
                guard !state.isLoadingProfile else { return .none }
                // 이미 프로필 데이터가 있으면 불필요한 재로드 방지
                // (toast dismiss 등 state 변화로 onAppear가 재트리거되는 경우 차단)
                guard state.communityProfile == nil else { return .none }
                return .send(.internal(.loadProfile))

            case .internal(.loadProfile):
                guard !state.authInfo.isGuest else { return .none }
                state.isLoadingProfile = true
                // community 프로필과 user 프로필을 병렬 조회 — 둘은 서로 다른 엔드포인트이고
                // 의존성이 없어 직렬로 기다릴 이유가 없다. 각각 독립 TaskResult로 흘려보내
                // user 조회 실패가 화면(community) 로딩을 막지 않게 한다.
                return .run { send in
                    async let communityResult = TaskResult { try await communityClient.fetchProfile() }
                    async let userResult = TaskResult { try await userClient.fetchUserProfile() }
                    await send(.internal(.profileResponse(communityResult)))
                    await send(.internal(.userProfileResponse(userResult)))
                }

            case let .internal(.profileResponse(.success(profile))):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .none

            case let .internal(.userProfileResponse(.success(profile))):
                state.userProfile = profile
                return .none

            case let .internal(.userProfileResponse(.failure(error))):
                // user 프로필 조회 실패는 화면 표시를 막지 않는다(인증 뱃지 등 부가 정보 한정).
                Log.trace("Failed to load user profile: \(error)", category: .network, level: .error)
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
                Log.trace("닉네임 저장 요청: \(nickname)", category: .debug, level: .info)
                state.destination = nil
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", style: .info
                    ))))
                }
                let updatedProfile = profile.updatingNickname(nickname)
                state.isLoadingProfile = true
                return .run { send in
                    await send(.internal(.nicknameUpdateResponse(
                        await TaskResult {
                            // 닉네임 전용 엔드포인트 (PUT /api/user/profile/nickname, 쿼리 파라미터)
                            try await userClient.updateNickname(nickname)
                            return updatedProfile
                        }
                    )))
                }
                
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

            case let .destination(.presented(.competitionInfo(.delegate(.didFinishAdding(competition))))):
                guard let profile = state.communityProfile else {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                Log.trace(
                    "대회 추가 요청: \(competition.competitionYear)/\(competition.competitionMonth) \(competition.competitionName) \(competition.competitionRank.displayName)",
                    category: .debug,
                    level: .info
                )
                let updatedProfile = profile.addingCompetition(competition)
                state.destination = nil
                state.isLoadingProfile = true
                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .competition)
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionAdded(saved)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .destination(.presented(.competitionInfo(.delegate(.didFinishEditing(original, updated))))):
                guard let profile = state.communityProfile else {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                Log.trace(
                    "대회 수정 요청: \(original.competitionName) → \(updated.competitionName)",
                    category: .debug,
                    level: .info
                )
                let updatedProfile = profile.updatingCompetition(original: original, with: updated)
                state.destination = nil
                state.isLoadingProfile = true
                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .competition)
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionUpdated(saved)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .destination(.presented(.competitionInfo(.delegate(.didDelete(competition))))):
                guard let profile = state.communityProfile else {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", style: .info))))
                }
                Log.trace("대회 삭제 요청: \(competition.competitionName)", category: .debug, level: .info)
                let updatedProfile = profile.removingCompetition(competition)
                state.destination = nil
                state.isLoadingProfile = true
                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .competition)
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionDeleted(saved)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.competitionAdded(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .send(.internal(.showToast(.init(message: "대회 정보를 추가했어요", style: .info))))

            case let .internal(.competitionUpdated(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .send(.internal(.showToast(.init(message: "대회 정보를 수정했어요", style: .info))))

            case let .internal(.competitionDeleted(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .send(.internal(.showToast(.init(message: "대회 정보를 삭제했어요", style: .info))))

            case let .view(.competitionDetailTapped(competition)):
                state.destination = .competitionInfo(
                    CompetitionInfoFeature.State(mode: .edit(original: competition))
                )
                return .none

            case .view(.moreButtonTapped):
                state.isMoreMenuPresented.toggle()
                return .none

            case .view(.instructorVerificationMenuTapped):
                state.isMoreMenuPresented = false
                state.sheet = .instructorVerification(InstructorVerificationFeature.State())
                return .none

            case .sheet(.presented(.instructorVerification(.delegate(.didSelectUpload)))):
                // 시트→시트 전환 — 안내 시트 dismiss 후 짧은 딜레이를 두고 사진 첨부 시트 노출
                // (`.sheet(item:)` 모디파이어가 케이스마다 분리되어 있어 즉시 교체 시 한쪽이 누락될 수 있음)
                state.sheet = nil
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.internal(.presentImageEditSheet(.instructorVerification, canDelete: false)))
                }

            case .sheet(.presented(.instructorVerification(.delegate(.didCancel)))):
                state.sheet = nil
                return .none

            case let .internal(.presentImageEditSheet(purpose, canDelete)):
                state.sheet = .profileImageEdit(
                    ProfileImageEditFeature.State(purpose: purpose, canDelete: canDelete)
                )
                return .none

            case .view(.profileImageEditButtonTapped):
                // 프로필 이미지 수정 옵션 바텀시트 노출
                // 실제로 이미지가 렌더링되는 상태일 때만 '삭제' 옵션 노출
                let canDelete = state.communityProfile?.hasProfileImage ?? false
                state.sheet = .profileImageEdit(
                    ProfileImageEditFeature.State(canDelete: canDelete)
                )
                return .none

            case .sheet(.presented(.profileImageEdit(.delegate(.didSelectCamera)))):
                // 액션 시트는 유지한 채 picker를 위에 띄운다 — picker 취소 시 시트가 그대로
                // 남아 사용자가 즉시 다른 옵션을 다시 선택할 수 있게 한다(2-depth 재진입 제거).
                // purpose는 picker→crop→업로드 파이프라인 분기에 필요하므로 시트가 살아있는
                // 동안 별도 상태에 보관해둔다.
                state.pendingImagePurpose = state.sheet?.profileImageEdit?.purpose ?? .profileImage
                state.imageCaptureSource = .camera
                return .none

            case .sheet(.presented(.profileImageEdit(.delegate(.didSelectAlbum)))):
                state.pendingImagePurpose = state.sheet?.profileImageEdit?.purpose ?? .profileImage
                state.imageCaptureSource = .photoLibrary
                return .none

            case .sheet(.presented(.profileImageEdit(.delegate(.didSelectDelete)))):
                state.sheet = nil
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", style: .info
                    ))))
                }
                // 삭제는 DELETE /api/image/{id} 사용 — 현재 이미지의 서버 파일 id가 필요하다.
                // id는 프로필 조회 응답(GET /api/user/profile)의 profileImage.id에서 온다.
                guard let imageFileId = state.userProfile?.profileImageFileId else {
                    Log.trace("프로필 이미지 - 삭제 불가(파일 id 없음)", category: .network, level: .error)
                    return .send(.internal(.showToast(.init(
                        message: "이미지 정보를 불러올 수 없어 삭제하지 못했어요", style: .info
                    ))))
                }
                let updatedProfile = profile.updatingProfileImageUrl(nil)
                state.isLoadingProfile = true
                // Optimistic UX — 헤더를 즉시 기본 아이콘으로 전환
                state.isProfileImageDeleting = true
                Log.trace("프로필 이미지 - 삭제 요청 (imageFileId=\(imageFileId))", category: .network, level: .info)
                return .run { send in
                    await send(.internal(.profileImageUpdateResponse(
                        await TaskResult {
                            try await imageClient.deleteImage(imageFileId)
                            return updatedProfile
                        }
                    )))
                }

            case .sheet(.presented(.profileImageEdit(.delegate(.didCancel)))):
                state.sheet = nil
                // 시트가 사라지면 시트 안에서 attach된 picker도 같이 해제되므로
                // 관련 상태를 모두 정리해 다음 시트 오픈 시 stale 상태로 picker가
                // 자동 재현하지 않도록 한다
                state.imageCaptureSource = nil
                state.pendingImagePurpose = nil
                return .none

            case let .internal(.presentImageCaptureSource(source)):
                state.imageCaptureSource = source
                return .none

            case let .view(.imagePicked(data)):
                // 사진 선택 완료 — picker dismiss + 액션 시트 정리.
                // purpose에 따라 다음 단계 분기:
                //   - 프로필 이미지: 1:1 크롭 단계로 진행 (헤더 아바타는 정사각형이라 필수)
                //   - 관장 사범 인증: 크롭 생략, 바로 ImageKit 업로드
                //     (검수용 사진은 자격증/명판 등 원본 컴포지션 유지가 중요)
                state.imageCaptureSource = nil
                state.sheet = nil

                let purpose = state.pendingImagePurpose ?? .profileImage

                switch purpose {
                case .profileImage:
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(300))
                        await send(.internal(.presentImageCrop(data)))
                    }

                case .instructorVerification:
                    // 파이프라인이 여기서 끝나므로 purpose 리셋
                    state.pendingImagePurpose = nil
                    // FIXME: 업로드 진행 피드백 부재 (구현 보류). 사진 선택 즉시 시트가 닫힌 뒤
                    //   순차 3-홉(ImageKit 토큰 발급 → ImageKit 업로드 → PUT /api/user/owner)이
                    //   끝날 때까지 2~5초간 화면에 표시가 없어, 사용자가 실패로 오인하거나 메뉴
                    //   재진입으로 중복 인증요청을 보낼 수 있다. 인증 사진은 노출되지 않는 검수용이라
                    //   프로필 이미지의 Optimistic Update는 적용 불가.
                    //   구현 방향(합의됨): 로딩 오버레이(화면 딤 + 인디케이터)로 업로드 내내 진행을
                    //   표시하고 터치를 막아 중복 제출을 차단, 완료 시 오버레이 제거 + 결과 토스트.
                    Log.trace(
                        "관장 사범 인증 - 크롭 생략, 원본 업로드 시작 (\(data.count) bytes)",
                        category: .network,
                        level: .info
                    )
                    return .run { send in
                        await send(.internal(.instructorVerificationImageUploadResponse(
                            await TaskResult {
                                try await imageUploadClient.uploadImage(data, .instructorVerification)
                            }
                        )))
                    }
                    .cancellable(id: CancelID.instructorVerificationUpload)
                }

            case .view(.imagePickerCancelled):
                // picker만 닫고 액션 시트와 purpose는 그대로 유지 — 사용자가 같은 시트에서
                // 다른 옵션을 즉시 재선택할 수 있도록 (pendingImagePurpose는 시트 자체가
                // 닫히는 경로(didCancel) 또는 크롭 단계 종료 시 리셋된다)
                state.imageCaptureSource = nil
                return .none

            case let .internal(.presentImageCrop(data)):
                state.imageCropCover = ProfileImageCropFeature.State(originalImageData: data)
                return .none

            case let .imageCropCover(.presented(.delegate(.didConfirm(croppedData)))):
                // 크롭 단계는 프로필 이미지 흐름 전용 — 관장 사범 인증은 imagePicked에서
                // 크롭을 생략하고 바로 ImageKit으로 업로드된다. 따라서 여기서는 purpose
                // 분기 없이 프로필 업로드 경로만 처리한다.
                state.imageCropCover = nil
                state.pendingImagePurpose = nil
                guard state.communityProfile != nil else {
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", style: .info
                    ))))
                }
                state.isLoadingProfile = true
                // Optimistic UX — 크롭 결과를 헤더에 즉시 노출 (네트워크와 무관하게)
                state.pendingProfileImageData = croppedData
                Log.trace(
                    "프로필 이미지 - 업로드 시작 (\(croppedData.count) bytes)",
                    category: .network,
                    level: .info
                )
                return .run { send in
                    await send(.internal(.profileImageUploadResponse(
                        await TaskResult {
                            try await imageUploadClient.uploadImage(croppedData, .profileImage)
                        }
                    )))
                }
                .cancellable(id: CancelID.profileImageUpload)

            case .imageCropCover(.presented(.delegate(.didCancel))):
                state.imageCropCover = nil
                // 크롭 단계 취소 → 파이프라인 종료, purpose 리셋
                state.pendingImagePurpose = nil
                return .none

            case let .internal(.profileImageUploadResponse(.success(registeredImage))):
                guard let profile = state.communityProfile else {
                    state.isLoadingProfile = false
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", style: .info
                    ))))
                }
                // 헤더 표시는 등록된 이미지 URL을, BE 반영은 발급된 id를 사용한다.
                let updatedProfile = profile.updatingProfileImageUrl(registeredImage.imageUrl)
                let imageFileId = registeredImage.id
                return .run { send in
                    await send(.internal(.profileImageUpdateResponse(
                        await TaskResult {
                            // 4단계: 서버 등록 id로 프로필 이미지 설정 (PUT /api/user/profile/image?imageFileId=)
                            try await userClient.setProfileImage(imageFileId)
                            return updatedProfile
                        }
                    )))
                }
                .cancellable(id: CancelID.profileImageUpload)

            case let .internal(.profileImageUploadResponse(.failure(error))):
                state.isLoadingProfile = false
                // 업로드 실패 → 미리보기 롤백
                state.pendingProfileImageData = nil
                Log.trace("Failed to upload profile image: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(
                    message: "이미지 업로드에 실패했어요. 다시 시도해주세요", style: .info
                ))))

            case let .internal(.instructorVerificationImageUploadResponse(.success(registeredImage))):
                // CDN 업로드 + 서버 등록 완료 → 발급된 id로 BE 인증 요청(PUT /api/user/owner) 체이닝.
                Log.trace(
                    "관장 사범 인증 - 이미지 등록 완료. imageFileId=\(registeredImage.id), 인증 요청 시작",
                    category: .network,
                    level: .info
                )
                let imageFileId = registeredImage.id
                return .run { send in
                    await send(.internal(.instructorVerificationRequestResponse(
                        await TaskResult {
                            try await userClient.requestOwnerVerification(imageFileId)
                            return true
                        }
                    )))
                }
                .cancellable(id: CancelID.instructorVerificationUpload)

            case let .internal(.instructorVerificationImageUploadResponse(.failure(error))):
                Log.trace("Failed to upload instructor verification image: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(
                    message: "사진 업로드에 실패했어요. 다시 시도해주세요", style: .info
                ))))

            case .internal(.instructorVerificationRequestResponse(.success)):
                // 인증 요청 접수 완료. 검수는 비동기이므로 "업로드했어요" 안내가 정확하다.
                Log.trace("관장 사범 인증 - 인증 요청 완료", category: .network, level: .info)
                // Optimistic — BE 응답을 기다리지 않고 ownerRequested를 즉시 반영해
                // MY 탭 뱃지 등 인증 상태 UI가 바로 업데이트되도록 한다.
                // 다음 MY 진입 시 loadProfile이 실제값으로 덮어쓰므로 드리프트가 남지 않는다.
                state.userProfile = state.userProfile.map {
                    UserProfile(
                        userId: $0.userId,
                        email: $0.email,
                        nickname: $0.nickname,
                        profileImageUrl: $0.profileImageUrl,
                        profileImageFileId: $0.profileImageFileId,
                        snsProvider: $0.snsProvider,
                        ownerRequested: true,
                        ownerRequestImageUrl: $0.ownerRequestImageUrl,
                        role: $0.role,
                        status: $0.status
                    )
                }
                return .send(.internal(.showToast(.init(
                    message: "업로드 완료! 관리자 검토 후 결과를 알려드릴게요.", style: .info
                ))))

            case let .internal(.instructorVerificationRequestResponse(.failure(error))):
                Log.trace("Failed to request owner verification: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(
                    message: "인증 요청에 실패했어요. 다시 시도해주세요", style: .info
                ))))

            case let .internal(.profileImageUpdateResponse(.success(updatedProfile))):
                state.isLoadingProfile = false
                state.communityProfile = updatedProfile
                state.isProfileImageDeleting = false
                // 업로드 성공 시에는 pendingProfileImageData를 유지한다.
                // AsyncImage가 새 URL을 가져오는 동안 `.empty` 단계에서 기본 아이콘이
                // 잠깐 깜빡이는 걸 fallback으로 덮기 위함. 다음 업로드 때 새 값으로 덮어쓰고,
                // 삭제 케이스에서는 명시적으로 nil로 정리한다.
                if updatedProfile.profileImageUrl == nil {
                    state.pendingProfileImageData = nil
                }
                // 업로드/삭제 동일 핸들러로 통합 — profileImageUrl 유무로 토스트 문구 분기
                let message = updatedProfile.profileImageUrl == nil
                    ? "프로필 이미지를 삭제했어요"
                    : "프로필 이미지를 변경했어요"
                return .send(.internal(.showToast(.init(message: message, style: .info))))

            case let .internal(.profileImageUpdateResponse(.failure(error))):
                state.isLoadingProfile = false
                // BE 반영 실패 → 미리보기/삭제 표시 롤백
                state.pendingProfileImageData = nil
                state.isProfileImageDeleting = false
                Log.trace("Failed to update profile image url: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(
                    message: "프로필 저장에 실패했어요. 다시 시도해주세요", style: .info
                ))))

            case let .internal(.nicknameUpdateResponse(.success(updatedProfile))):
                state.isLoadingProfile = false
                state.communityProfile = updatedProfile
                return .send(.internal(.showToast(.init(
                    message: "닉네임 수정을 완료했어요", style: .info
                ))))

            case let .internal(.nicknameUpdateResponse(.failure(error))):
                state.isLoadingProfile = false
                Log.trace("Failed to update nickname: \(error)", category: .network, level: .error)
                return .send(.internal(.showToast(.init(
                    message: "닉네임 저장에 실패했어요. 다시 시도해주세요", style: .info
                ))))

            case .destination, .sheet, .imageCropCover, .view, .internal, .delegate:
                return .none

            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
        .ifLet(\.$sheet, action: \.sheet) {
            Sheet.body
        }
        .ifLet(\.$imageCropCover, action: \.imageCropCover) {
            ProfileImageCropFeature()
        }
    }
}
// MARK: - Sendable Conformances
extension MyProfileFeature.Destination.State: Sendable, Equatable {}
extension MyProfileFeature.Destination.Action: Sendable {}
extension MyProfileFeature.Sheet.State: Sendable, Equatable {}
extension MyProfileFeature.Sheet.Action: Sendable {}
