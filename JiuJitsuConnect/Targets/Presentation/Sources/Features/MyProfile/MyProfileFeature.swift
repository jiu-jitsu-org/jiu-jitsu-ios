//
//  MyProfileFeature.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem
import CoreKit

@Reducer
public struct MyProfileFeature: Sendable {
    public init() {}
    
    private enum CancelID { case toast, profileImageUpload, instructorVerificationUpload, profileRefresh, userProfileForEntry }

    @ObservableState
    public struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?
        @Presents var sheet: Sheet.State?
        // '커뮤니티 활동' 등 프로필 탭 스택에 push되는 웹 서브뷰. 서브뷰 안의 중첩 OPEN_SUBVIEW도 여기에 쌓인다. (#44)
        var path = StackState<Path.State>()
        
        var authInfo: AuthInfo
        
        // 커뮤니티 프로필 정보
        var communityProfile: CommunityProfile?
        // 프로필 불러오기 · 저장 중(사진 제외). 저장은 한 번에 하나만 진행한다 — 응답이 프로필 전체를 바꾸므로
        // 겹치면 늦게 온 응답이 앞 저장을 화면에서 되돌린다(#155).
        var isLoadingProfile: Bool = false
        // 몇 번째 저장인지. 재조회 응답이 그사이 시작된 저장보다 오래된 값이면 버리는 데 쓴다(#155).
        var profileSaveGeneration = 0
        // 프로필 사진 업로드 · 삭제 중. 다른 저장과 서버 자원이 달라 따로 둔다 — 사진 스피너가 다른 저장의
        // 응답에 꺼지거나, 사진 업로드 중에 대회 · 띠 저장이 막히지 않게(#155).
        var isUploadingProfileImage: Bool = false
        // 탭 재진입·포그라운드 복귀 시 백그라운드 재조회 중 (#69). 헤더 스피너와 묶인
        // isLoadingProfile과 분리해, 재조회 중에도 기존 화면을 깜빡임 없이 유지한다.
        var isRefreshingProfile: Bool = false
        // 처음 불러오기가 실패해 보여 줄 프로필이 없음 — 카드 자리에 실패 안내와 다시 시도를 둔다(#387).
        // 다시 불러오기를 시작하면 내린다.
        var profileLoadFailed: Bool = false

        // user-level 프로필 — 관장사범 인증 신청 상태(ownerVerification) 등.
        // 닉네임/프로필이미지 등 community와 겹치는 필드는 표시에 쓰지 않는다(단일 소스는 communityProfile).
        var userProfile: UserProfile?
        // user 프로필을 바꾸는 일(사진 업로드 · 삭제, 관장 사범 인증 신청)을 몇 번 시작했는지.
        // 그 전에 나간 조회 응답이 늦게 와 방금 바꾼 사진 · 인증 상태를 옛 값으로 덮지 않게 버리는 데 쓴다(QA A2-7).
        var userProfileGeneration = 0
        
        // 토스트 메시지 상태
        var toast: ToastState?

        /// 띠나 그랄을 올려 저장한 직후 보여 줄 축하(#278, #286). 있으면 MY 위를 덮는다.
        var promotion: BeltPromotion?
        /// View가 혼자 띄우는 시트(대회 줄 동작 · 머리줄 무늬)가 떠 있는지. 화면 기록(#425)이 맨 위 화면을 알게 한다.
        var isCompetitionSheetPresented = false
        var isPatternSheetPresented = false
        /// 띠 고르기 시트가 내려가는 중인지. 내려가는 중엔 덮개를 띄울 수 없어, 저장이 먼저 끝나면 pendingPromotion에 두었다가 다 내려간 뒤 띄운다.
        var isBeltSheetClosing = false
        /// 저장은 끝났지만 아직 띄우지 않은 축하. 띄우는 순간(presentBeltPromotion·beltSheetDidDismiss) 비운다.
        var pendingPromotion: BeltPromotion?
        /// 축하 장면이 실제로 떠서 링이 가려진 동안 돌지 않고, 장면을 닫아 MY가 다시 보이면 그때 한 번 돈다(#339).
        var isBeltEntranceAfterPromotion = false
        
        // 관장 사범 인증 업로드(토큰 발급 → ImageKit 업로드 → PUT /api/user/owner) 진행 중.
        // 동안 로딩 오버레이로 화면 터치를 막아 중복 제출을 차단한다(#62).
        var isUploadingInstructorVerification: Bool = false

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
        // 크롭 직후 로컬 데이터를 헤더에 미리 표시한다. 응답 성공 시 userProfile.profileImageUrl로
        // 자연스럽게 전환되고, 실패 시 두 필드를 비워 이전 이미지로 롤백한다.

        /// 업로드 진행 중 헤더에 미리 노출할 로컬 이미지 데이터
        var pendingProfileImageData: Data?
        /// 이미지 삭제 진행 중 — 헤더를 기본 아이콘으로 미리 전환
        var isProfileImageDeleting: Bool = false

        public enum ImageCaptureSource: Equatable, Sendable {
            case camera
            case photoLibrary
        }

        /// 커뮤니티에서 내 사진을 눌러 스택에 쌓은 MY인지(#197). 탭 화면이 아니라 왼쪽 위에 뒤로가기가 붙고 탭바가 없다.
        var isPushed: Bool = false

        /// 쌓인 MY를 지금 닫으면 안 되는지 — 스택에서 빠지면 저장 · 업로드 effect가 함께 취소돼
        /// 결과 안내 없이 저장이 끊긴다(QA A2-1). 처음 불러오는 중(프로필 없음)은 끊겨도 잃을 게 없어 막지 않는다.
        var blocksLeaving: Bool {
            isPushed && (
                isUploadingProfileImage
                    || isUploadingInstructorVerification
                    || (isLoadingProfile && communityProfile != nil)
            )
        }

        // 띠 링 등장 움직임(#320) — 세션에서 MY가 처음 보일 때 한 번, 띠를 바꾼 직후 다시.
        // 탭이 미리 마운트돼 화면의 onAppear로는 '보인 때'를 알 수 없어 탭 진입(tabEntered)·쌓은 MY의 onAppear로 정한다.
        var hasPlayedBeltEntrance = false
        /// 화면에 들어왔지만 띠를 아직 못 받았다 — 띠가 오면 그때 돈다.
        var isWaitingBeltEntrance = false
        /// 오를 때마다 링이 한 번 돈다.
        var beltEntranceTrigger = 0

        // 상단 바탕 무늬는 서버가 기준이다(#337). 서버에 저장하기 전(#320) 이 기기에만 남긴 무늬는
        // 처음 한 번 서버로 옮겨 담고 지운다. 옮겨 담기 전까지는 그 무늬로 그려 바탕이 기본 무늬로 튀지 않게 한다.
        var legacyHeaderPattern: MyHeaderPattern?
        var hasLoadedLegacyHeaderPattern = false

        /// 상단 바탕 무늬 — 서버 값, 없으면 기기에 남은 무늬, 그것도 없으면 기본 무늬
        var headerPattern: MyHeaderPattern {
            if let pattern = communityProfile?.backgroundPattern {
                return MyHeaderPattern(pattern)
            }
            return legacyHeaderPattern ?? .default
        }

        /// 이 무늬가 이미 서버에 저장돼 있는지. 보이는 무늬(`headerPattern`)가 아니라 서버 값으로 본다 —
        /// 서버 값이 이 앱이 모르는 무늬면 기본 무늬로 보이지만, 회원이 기본 무늬를 고르면 저장해야 한다.
        func isSavedHeaderPattern(_ pattern: MyHeaderPattern) -> Bool {
            communityProfile?.backgroundPattern == pattern.serverValue
        }

        public init(authInfo: AuthInfo, communityProfile: CommunityProfile? = nil) {
            self.authInfo = authInfo
            self.communityProfile = communityProfile
        }

        /// 커뮤니티에 쌓을 MY(#197). 탭의 MY가 이미 불러온 프로필을 그대로 받아 바로 그린다.
        public static func pushed(from tab: State) -> State {
            var state = State(authInfo: tab.authInfo, communityProfile: tab.communityProfile)
            state.userProfile = tab.userProfile
            state.isPushed = true
            state.hasPlayedBeltEntrance = tab.hasPlayedBeltEntrance
            state.legacyHeaderPattern = tab.legacyHeaderPattern
            state.hasLoadedLegacyHeaderPattern = tab.hasLoadedLegacyHeaderPattern
            return state
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
    public enum Path {
        case communityDetail(CommunityDetailFeature)
        case userProfile(UserProfileFeature)
        // 하단 탭에서 빠진 설정은 MY 오른쪽 위 톱니바퀴로 연다(#241). 차단한 회원 등 설정이 여는 웹 화면도 이 스택에 쌓인다.
        case settings(SettingsFeature)
    }

    @Reducer
    public enum Sheet {
        case beltSetting(BeltSettingFeature)
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
        // 웹 서브뷰 스택 액션
        case path(StackAction<Path.State, Path.Action>)
        /// 다른 회원 프로필 열기 — 커뮤니티 활동 웹에서 작성자를 누름(#116)
        case openUserProfile(userId: Int)
        // 부모(AppTabFeature)가 세션 변화(토큰 갱신 등)를 웹 서브뷰에 전파하는 통로.
        case session(CommunityDetailFeature.SessionUpdate)

        public enum DelegateAction: Sendable {
            // '커뮤니티 활동' 줄 탭 → 부모가 커뮤니티 웹과 같은 origin·토큰으로 서브뷰를 이 스택에 push한다.
            case communityActivityRequested
            // 웹 서브뷰의 인증류 위임(로그인 유도·로그아웃·토큰 갱신) → 부모가 커뮤니티와 같은 흐름으로 처리한다.
            case webSubview(CommunityDetailFeature.Action.DelegateAction)
            // 띠·도장 등 프로필 저장이 서버에 반영됨 → 부모가 열린 웹뷰 모두에 PROFILE_UPDATED를 보낸다(jiu-jitsu-frontend#413).
            case profileUpdated
            // 이 스택에 쌓인 남의 프로필에서 회원을 차단·해제함(#328) → 부모가 열린 웹뷰 모두에 USER_BLOCK_CHANGED를 보낸다.
            case userBlockChanged(userId: Int, blocked: Bool)
            // 비로그인 MY의 '로그인하기'(#242) → 부모가 로그인 화면을 띄운다.
            case loginRequested
            // MY 스택에 연 설정의 위임(로그아웃·탈퇴·로그인·차단한 회원) → 부모가 설정 탭이던 때와 같이 처리한다.
            case settings(SettingsFeature.Action.DelegateAction)
        }

        public enum ViewAction: Sendable {
            case onAppear
            /// View 상태로 띄운 시트가 열리고 닫힘(화면 기록용, #425)
            case competitionSheetPresentedChanged(Bool)
            case patternSheetPresentedChanged(Bool)
            /// 머리 무늬를 다른 것으로 바꿈 — 서버에 저장하고(#337) 분석 기록도 남긴다(#429).
            case headerPatternChanged(MyHeaderPattern)
            /// 헤더에 서버 사진이 그려짐(#157)
            case profileImageDisplayed(url: String)
            /// 커뮤니티에서 연 MY의 뒤로가기(#197)
            case backTapped
            // 다른 탭에서 MY로 전환 (탭 뷰가 유지돼 onAppear가 다시 오지 않으므로 AppTab이 보낸다)
            case tabEntered
            // MY 탭을 보는 중 앱이 포그라운드로 복귀
            case sceneBecameActive
            case gymInfoButtonTapped
            case nicknameEditButtonTapped
            case registerBeltButtonTapped
            case profileRetryTapped     // 프로필을 못 불러온 카드의 '다시 시도' (#387)
            case beltTapped             // 이미 등록된 벨트 영역 탭 → 벨트 시트 노출
            case registerStyleButtonTapped
            case styleCardEditTapped(MyStyleSettingType)  // 프로필 스타일 카드 탭 → 해당 타입 수정 모드 진입
            case toastButtonTapped(ToastState.Action)
            case beltPromotionDismissed     // 띠·그랄 축하 장면의 닫기(X)를 누름 (#278, #286, #339)
            case beltSheetDidDismiss        // 띠 고르기 시트가 다 내려감 (#278)
            case addCompetitionButtonTapped  // 대회 정보 추가 버튼 탭
            case competitionDetailTapped(Competition)  // 대회 정보 행 탭
            case addDivisionTapped([Competition])     // 저장한 대회에 부문 추가 (그 대회의 기록들)
            case deleteCompetitionConfirmed([Competition])  // 대회 시트에서 삭제 확인 (그 대회의 부문 전부)
            case competitionPinToggled([Competition])  // 대회 줄 시트 '맨 위에 고정'/'고정 해제' — 묶인 부문 전부 (#124)
            case competitionsReordered([[Competition]])  // 대회 줄을 끌어 옮기고 '완료' — 순서가 바뀐 묶음(고정/고정 안 함)의 줄별 부문들, 위에서부터 (#204)
            case instructorVerificationMenuTapped   // "..." 메뉴의 "관장 사범 인증" 탭
            case imagePicked(Data)                  // 카메라/앨범 픽커에서 이미지 선택됨
            case imagePickerCancelled               // 픽커 취소 (시스템 dismiss 포함)
            case profileImageEditButtonTapped       // 프로필 이미지 우측 하단 카메라 버튼 탭
            case communityActivityTapped            // 벨트 카드 아래 '커뮤니티 활동' 줄 탭 (#44)
            case settingsButtonTapped               // 우측 상단 톱니바퀴 탭 — 설정 열기 (#241)
            case guestLoginTapped                   // 비로그인 MY의 '로그인하기' 탭 (#242)
        }
        
        public enum InternalAction: Sendable {
            case loadProfile
            case profileResponse(TaskResult<CommunityProfile>)
            // user-level 프로필(GET /api/user/profile) 응답 — 관장사범 인증 신청 상태(ownerVerification) 등.
            // community 프로필과 독립적으로 처리해 한쪽 실패가 다른 쪽을 막지 않게 한다.
            case userProfileResponse(TaskResult<UserProfile>, generation: Int)
            case refreshProfile
            case refreshProfileResponse(TaskResult<CommunityProfile>, saveGeneration: Int)
            case refreshUserProfileResponse(TaskResult<UserProfile>, generation: Int)
            // user 프로필이 없어 사진 바꾸기 · 관장 사범 인증을 열기 전에 다시 받은 결과(QA A2-2, A3-10). 받으면 그 화면을 연다.
            case userProfileFetchedForEntry(TaskResult<UserProfile>, generation: Int, entry: UserProfileEntry)
            case updateProfileSection(ProfileSection, String?)
            case saveBeltInfoOnly(rank: BeltRank, stripe: BeltStripe)
            // 스타일 저장 (특기 + 최애 한 번에)
            // mode: 저장을 시작한 화면의 모드. 응답이 올 때 화면이 이미 닫혔을 수 있어 그때 값으로 분기한다(#155).
            case savePosition(best: PositionType?, favorite: PositionType?, mode: MyStyleSettingFeature.Mode)
            case saveSubmission(best: SubmissionType?, favorite: SubmissionType?, mode: MyStyleSettingFeature.Mode)
            case saveTechnique(best: TechniqueType?, favorite: TechniqueType?, mode: MyStyleSettingFeature.Mode)

            // 응답 처리
            case updateProfileResponse(TaskResult<CommunityProfile>)
            case positionSaved(CommunityProfile, mode: MyStyleSettingFeature.Mode)    // 포지션 저장 → register 시 기술 단계로
            case submissionSaved(CommunityProfile, mode: MyStyleSettingFeature.Mode)  // 서브미션 저장 → 프로필 화면으로 복귀
            case techniqueSaved(CommunityProfile, mode: MyStyleSettingFeature.Mode)   // 기술 저장 → register 시 서브미션 단계로
            case competitionAdded(CommunityProfile, Competition)   // 대회 정보 추가 저장 완료
            case competitionAddFailed                              // 대회 정보 추가 저장 실패
            case competitionUpdated(CommunityProfile) // 대회 정보 수정 저장 완료
            case competitionDeleted(CommunityProfile) // 대회 정보 삭제 저장 완료
            case competitionDeleteFailed              // 대회 정보 삭제 저장 실패 — 저장이 아니라 삭제 실패로 알린다(QA A3-3)
            // 바꿀 기록을 새로 받은 목록에서 못 찾아 저장하지 않음(QA A3-1, A3-7) — 화면을 서버 목록으로 맞추고 실패로 알린다.
            case competitionTargetMissing(latest: CommunityProfile, isDelete: Bool)
            case competitionPinUpdated(CommunityProfile, isPinned: Bool) // 대회 고정/해제 저장 완료
            case competitionOrderSaved(CommunityProfile)    // 대회 순서 저장 완료
            case competitionOrderReverted(CommunityProfile) // 대회 순서 저장 실패 — 바꾸기 전 목록으로 되돌림
            case headerPatternSaved(CommunityProfile)      // 상단 무늬 저장 완료 (#337)
            case headerPatternReverted(CommunityProfile)   // 상단 무늬 저장 실패 — 고르기 전 프로필로 되돌림
            case legacyHeaderPatternMigrated(TaskResult<CommunityProfile>) // 기기에 남은 무늬를 서버로 옮겨 담은 결과 (#337)
            // 알림 화면을 나간 뒤 대신 저장한 알림 설정이 서버에 반영됨. 루트의 분석 기록만 본다(#430).
            case notificationSettingSaved(NoticeSettingUpdate)
            // 알림 화면을 나간 뒤 대신 저장하다 실패함 — 맨 위에 보이는 화면에 알린다(QA A4-2).
            case notificationSettingSaveFailed

            case showToast(ToastState)
            case toastDismissed
            case presentBeltPromotion(BeltPromotion)     // 더 높은 띠·그랄로 저장됨 → 축하 장면 띄우기 (#278, #286)

            // 프로필 이미지 수정 흐름 — 시트/풀스크린 전환 사이에 짧은 딜레이를 두고 발화
            case presentImageCaptureSource(State.ImageCaptureSource)
            case cameraUnavailable
            case presentImageCrop(Data)
            // 관장 사범 인증 → 사진 첨부 시트로의 시트-시트 전환을 위한 딜레이 발화
            case presentImageEditSheet(ProfileImageEditFeature.Purpose, canDelete: Bool)
            // 인증 사진을 고른 뒤 픽커가 내려가면 인증 시트를 다시 띄워 신청 전에 확인받는다(#388)
            case presentPickedVerificationImage(Data)

            // 프로필 이미지 업로드/반영 응답
            case profileImageUploadResponse(TaskResult<RegisteredImage>)   // CDN 업로드 + 서버 등록 결과(id 포함)
            case profileImageUpdateResponse(TaskResult<UserProfile>)  // PUT /api/user/profile 반영 결과

            // 관장 사범 인증 사진 업로드 응답 (ImageKit 호스팅 URL)
            // 성공 시 확보한 URL로 BE 인증 요청(PUT /api/user/owner)을 체이닝한다.
            case instructorVerificationImageUploadResponse(TaskResult<RegisteredImage>)
            // 관장 사범 인증 요청 응답 (PUT /api/user/owner). 성공 시 방금 업로드한 인증 이미지 URL을
            // 함께 실어, 시트 재진입 시 최신 사진이 반영되도록 Optimistic 갱신에 사용한다.
            case instructorVerificationRequestResponse(TaskResult<String>)

            // 닉네임 갱신 응답 (이미지와 동일한 PUT /api/user/profile 사용)

            /// user 프로필이 있어야 여는 화면
            public enum UserProfileEntry: Sendable {
                case profileImageEdit
                case instructorVerification
            }
        }
    }
    
    // MARK: - Dependencies
    @Dependency(\.continuousClock) var clock
    @Dependency(\.communityClient) var communityClient
    @Dependency(\.imageUploadClient) var imageUploadClient
    @Dependency(\.imageClient) var imageClient
    @Dependency(\.cameraAvailabilityClient) var cameraAvailabilityClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.noticeClient) var noticeClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.date) var date
    @Dependency(\.legacyHeaderPatternClient) var legacyHeaderPatternClient


    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.profileImageDisplayed(url)):
                // 업로드 뒤 새 사진이 실제로 보이면 겹쳐 둔 미리보기를 걷는다(#157).
                // 업로드 중에 그려진 건 예전 사진이라 걷지 않는다.
                guard !state.isUploadingProfileImage, url == state.userProfile?.profileImageUrl else { return .none }
                state.pendingProfileImageData = nil
                return .none

            case let .view(.competitionSheetPresentedChanged(isPresented)):
                state.isCompetitionSheetPresented = isPresented
                return .none

            case let .view(.patternSheetPresentedChanged(isPresented)):
                state.isPatternSheetPresented = isPresented
                return .none

            case .view(.onAppear):
                // 게스트 상태에서는 프로필 API를 호출하지 않는다.
                // AppTabView가 모든 탭을 미리 마운트하므로 게스트일 때도 onAppear가 발화한다.
                guard !state.authInfo.isGuest else { return .none }
                guard !state.isLoadingProfile else { return .none }
                // 커뮤니티에 쌓은 MY는 탭의 MY가 불러 둔 값으로 바로 그린 뒤 조용히 다시 불러온다(#197).
                // 뜰 때마다 부른다 — 이 MY 위에 쌓은 다른 MY(글 상세 → 내 댓글)에서 바꾼 값도 뒤로 돌아왔을 때 맞게 보인다.
                // 이미 불러오는 중이면 refreshProfile이 건너뛴다.
                if state.isPushed {
                    Self.requestBeltEntrance(&state)
                }
                if state.isPushed, state.communityProfile != nil {
                    return .send(.internal(.refreshProfile))
                }
                // 이미 프로필 데이터가 있으면 불필요한 재로드 방지
                // (toast dismiss 등 state 변화로 onAppear가 재트리거되는 경우 차단)
                guard state.communityProfile == nil else { return .none }
                return .send(.internal(.loadProfile))

            case .view(.backTapped):
                guard !state.blocksLeaving else { return Self.savingInProgressToast() }
                return .run { _ in await self.dismiss() }

            case .view(.tabEntered), .view(.sceneBecameActive):
                if case .view(.tabEntered) = action {
                    Self.requestBeltEntrance(&state)
                }
                // 웹·다른 기기에서 바꾼 내용, 관장 사범 인증 승인 등을 반영한다(#69).
                // 첫 조회가 아직 없으면(실패 포함) 일반 로딩으로 처리한다.
                guard state.communityProfile != nil else {
                    return .send(.view(.onAppear))
                }
                return .send(.internal(.refreshProfile))

            case .internal(.refreshProfile):
                // 저장·업로드 중이면 그 결과가 화면의 최신값이므로 재조회하지 않는다.
                guard !state.authInfo.isGuest,
                      !state.isLoadingProfile,
                      !state.isUploadingProfileImage,
                      !state.isUploadingInstructorVerification,
                      !state.isRefreshingProfile else { return .none }
                state.isRefreshingProfile = true
                let saveGeneration = state.profileSaveGeneration
                let userGeneration = state.userProfileGeneration
                return .run { send in
                    async let communityResult = TaskResult { try await communityClient.fetchProfile() }
                    async let userResult = TaskResult { try await userClient.fetchUserProfile() }
                    await send(.internal(.refreshProfileResponse(communityResult, saveGeneration: saveGeneration)))
                    await send(.internal(.refreshUserProfileResponse(userResult, generation: userGeneration)))
                }
                .cancellable(id: CancelID.profileRefresh, cancelInFlight: true)

            case let .internal(.refreshProfileResponse(result, saveGeneration)):
                state.isRefreshingProfile = false
                // 응답을 기다리는 사이 저장이 시작됐으면(이미 끝났어도) 저장 전 값이라 덮어쓰지 않는다.
                guard !state.isLoadingProfile, saveGeneration == state.profileSaveGeneration else { return .none }
                switch result {
                case let .success(profile):
                    state.communityProfile = profile
                    return migrateLegacyHeaderPatternIfNeeded(&state)
                case let .failure(error):
                    // 백그라운드 재조회 실패는 기존 화면을 유지하고 조용히 넘긴다.
                    Log.trace("Failed to refresh profile: \(error)", category: .network, level: .error)
                    return .none
                }

            case let .internal(.refreshUserProfileResponse(result, generation)):
                guard !state.isUploadingInstructorVerification, !state.isUploadingProfileImage,
                      generation == state.userProfileGeneration else { return .none }
                switch result {
                case let .success(profile):
                    state.userProfile = profile
                    state.pendingProfileImageData = nil
                case let .failure(error):
                    Log.trace("Failed to refresh user profile: \(error)", category: .network, level: .error)
                }
                return .none

            case .internal(.loadProfile):
                guard !state.authInfo.isGuest else { return .none }
                state.isLoadingProfile = true
                state.profileLoadFailed = false
                let userGeneration = state.userProfileGeneration
                // community 프로필과 user 프로필을 병렬 조회 — 둘은 서로 다른 엔드포인트이고
                // 의존성이 없어 직렬로 기다릴 이유가 없다. 각각 독립 TaskResult로 흘려보내
                // user 조회 실패가 화면(community) 로딩을 막지 않게 한다.
                return .run { send in
                    async let communityResult = TaskResult { try await communityClient.fetchProfile() }
                    async let userResult = TaskResult { try await userClient.fetchUserProfile() }
                    await send(.internal(.profileResponse(communityResult)))
                    await send(.internal(.userProfileResponse(userResult, generation: userGeneration)))
                }

            case let .internal(.profileResponse(.success(profile))):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return migrateLegacyHeaderPatternIfNeeded(&state)

            case let .internal(.userProfileResponse(.success(profile), generation)):
                // 사진을 바꾸는 중이거나 그사이 바꿨으면 바꾸기 전 값이라 덮지 않는다 — 업로드 응답이 최신값을 넣는다.
                guard !state.isUploadingProfileImage, generation == state.userProfileGeneration else { return .none }
                state.userProfile = profile
                // 서버 값이 기준이다. 남은 미리보기가 웹·다른 기기에서 바꾸거나 지운 사진을 가리지 않게 걷는다(#157).
                state.pendingProfileImageData = nil
                return .none

            case let .internal(.userProfileResponse(.failure(error), _)):
                // user 프로필 조회 실패는 화면 표시를 막지 않는다(인증 뱃지 등 부가 정보 한정).
                Log.trace("Failed to load user profile: \(error)", category: .network, level: .error)
                return .none
                
            case let .internal(.profileResponse(.failure(error))):
                state.isLoadingProfile = false
                // 불러오는 사이 로그아웃·탈퇴로 비로그인이 됐으면 늦게 온 실패는 버린다 — 비로그인 카드는 '로그인하기'여야 한다.
                guard !state.authInfo.isGuest else { return .none }
                // 실패는 카드 자리에 안내와 다시 시도로 남긴다 — 같은 말을 토스트로 한 번 더 하지 않는다(#387).
                state.profileLoadFailed = true
                Log.trace("Failed to load profile: \(error)", category: .network, level: .error)
                analyticsClient.logErrorShown(error)
                return .none

            case .view(.profileRetryTapped):
                guard !state.isLoadingProfile else { return .none }
                return .send(.internal(.loadProfile))
                
            case .view(.gymInfoButtonTapped):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                // 프로필을 못 불러왔으면 저장할 기준이 없다 — 화면을 열기 전에 알린다.
                guard state.communityProfile != nil else { return Self.profileUnavailableToast() }
                // 도장 정보 입력 화면으로 네비게이션
                let currentAcademyName = state.communityProfile?.academyName ?? ""
                let mode: MyAcademySettingFeature.Mode = currentAcademyName.isEmpty ? .add : .edit
                state.destination = .academySetting(
                    MyAcademySettingFeature.State(mode: mode, academyName: currentAcademyName)
                )
                return .none
                
            case .view(.nicknameEditButtonTapped):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                // 프로필을 못 불러왔으면 지금 닉네임을 모른다 — 빈 칸으로 열지 않고 알린다(#387).
                guard state.communityProfile != nil else { return Self.profileUnavailableToast() }
                // 닉네임 수정 화면으로 네비게이션
                let currentNickname = state.communityProfile?.nickname ?? ""
                state.destination = .nicknameSetting(
                    NicknameSettingFeature.State(mode: .edit, nickname: currentNickname)
                )
                return .none
                
            case .view(.registerBeltButtonTapped), .view(.beltTapped):
                // 저장 중엔 저장 화면을 열지 않는다 — 열린 화면 위에선 안내가 안 보이고, 고른 값이 거절돼 사라진다(#155).
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                // 프로필을 못 불러왔으면 고른 값을 저장할 기준이 없다 — 시트를 열기 전에 알린다(#387).
                guard state.communityProfile != nil else { return Self.profileUnavailableToast() }
                // 벨트 시트 노출. 등록·수정 모두 벨트만 받고 바로 저장한다(프로필 체급은 받지 않음, #188)
                state.sheet = .beltSetting(
                    BeltSettingFeature.State(
                        selectedRank: state.communityProfile?.beltRank ?? .white,
                        selectedStripe: state.communityProfile?.beltStripe ?? .none
                    )
                )
                return .none
                
            case .view(.registerStyleButtonTapped):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                // 프로필을 못 불러왔으면 저장할 기준이 없다 — 화면을 열기 전에 알린다.
                guard state.communityProfile != nil else { return Self.profileUnavailableToast() }
                // 포지션 설정 화면으로 네비게이션 (스타일 설정의 첫 단계)
                state.destination = .myStyleSetting(
                    MyStyleSettingFeature.State(
                        settingType: .position,
                        mode: .register,
                        beltRank: state.communityProfile?.beltRank,
                        bestPosition: state.communityProfile?.bestPosition,
                        favoritePosition: state.communityProfile?.favoritePosition,
                        bestSubmission: state.communityProfile?.bestSubmission,
                        favoriteSubmission: state.communityProfile?.favoriteSubmission,
                        bestTechnique: state.communityProfile?.bestTechnique,
                        favoriteTechnique: state.communityProfile?.favoriteTechnique
                    )
                )
                return .none
                
            case let .view(.styleCardEditTapped(type)):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                // 프로필을 못 불러왔으면 저장할 기준이 없다 — 화면을 열기 전에 알린다.
                guard state.communityProfile != nil else { return Self.profileUnavailableToast() }
                // 프로필 카드 탭 → 해당 타입만 수정하는 edit 모드로 진입
                state.destination = .myStyleSetting(
                    MyStyleSettingFeature.State(
                        settingType: type,
                        mode: .edit,
                        beltRank: state.communityProfile?.beltRank,
                        bestPosition: state.communityProfile?.bestPosition,
                        favoritePosition: state.communityProfile?.favoritePosition,
                        bestSubmission: state.communityProfile?.bestSubmission,
                        favoriteSubmission: state.communityProfile?.favoriteSubmission,
                        bestTechnique: state.communityProfile?.bestTechnique,
                        favoriteTechnique: state.communityProfile?.favoriteTechnique
                    )
                )
                return .none
                
            // MARK: - Delegate 처리 (자식 Feature로부터)

            case let .destination(.presented(.academySetting(.delegate(.saveAcademyName(academyName))))):
                // 이름을 그대로 두고 '확인'하면 저장 없이 닫는다 — 닉네임 화면과 같이(정책 2.2, QA A2-13).
                if let current = state.communityProfile?.academyName, current == academyName, !state.isLoadingProfile {
                    state.destination = nil
                    return .none
                }
                // 도장 이름 저장 요청 받음 → API 호출
                return .send(.internal(.updateProfileSection(.academy, academyName)))

            case .destination(.presented(.academySetting(.delegate(.deleteAcademy)))):
                // 도장 정보 삭제 요청 받음 → 빈 문자열로 저장하여 도장 정보 제거
                // (nil 이면 요청 JSON 에서 키가 빠져 BE 가 기존 값을 유지하므로 "" 를 보낸다.
                //  응답의 "" 는 DTO.toDomain() 에서 nil 로 정규화됨)
                return .send(.internal(.updateProfileSection(.academy, "")))

            case .destination(.presented(.academySetting(.delegate(.cancel)))):
                // 취소 - 아무것도 하지 않음
                return .none
                
            case let .destination(.presented(.nicknameSetting(.delegate(.didUpdateNickname(nickname))))):
                // 저장은 닉네임 화면이 끝낸 상태. 성공했을 때만 화면을 닫는다(실패는 화면에서 안내, #66).
                state.destination = nil
                state.communityProfile = state.communityProfile?.updatingNickname(nickname)
                // 닉네임 화면이 이미 저장했다. 그 전에 나간 재조회 응답이 옛 닉네임으로 덮지 않게 세대를 올린다.
                state.profileSaveGeneration += 1
                return .send(.internal(.showToast(.init(
                    message: "닉네임 수정을 완료했어요", status: .success
                ))))
                
            case .destination(.presented(.nicknameSetting(.delegate(.cancel)))):
                // 취소 - 아무것도 하지 않음
                return .none

            case .destination(.dismiss):
                // 닉네임 저장 중 뒤로가면 저장이 화면과 함께 취소돼 결과를 못 받는다. 서버엔 반영됐을 수 있어 다시 받는다(QA A2-15).
                guard case .nicknameSetting? = state.destination else { return .none }
                return .send(.internal(.refreshProfile))

            case let .destination(.presented(.myStyleSetting(.delegate(.didConfirmStyle(type, bestKey, favoriteKey))))):
                // 스타일 저장 (최애 + 받아 둔 특기) → register 시 다음 단계, edit 시 화면 닫기
                // 저장 화면은 저장 중엔 열리지 않으므로, 여기 걸리는 건 같은 화면의 '완료' 연타뿐이다(#155).
                guard !state.isLoadingProfile, state.communityProfile != nil,
                      case var .myStyleSetting(styleState)? = state.destination else { return .none }
                let mode = styleState.mode
                // 저장이 끝날 때까지 '완료' · 뒤로가기 버튼을 막는다 — 응답 전에 다른 선택으로 다시 저장하지 않게.
                // 스와이프로 나가는 건 허용한다. 닫힌 뒤 온 응답은 값만 반영하고 다른 화면을 열지 않는다.
                styleState.isSaving = true
                state.destination = .myStyleSetting(styleState)
                switch type {
                case .position:
                    let best = bestKey.flatMap { PositionType(rawValue: $0) }
                    let favorite = favoriteKey.flatMap { PositionType(rawValue: $0) }
                    return .send(.internal(.savePosition(best: best, favorite: favorite, mode: mode)))

                case .submission:
                    let best = bestKey.flatMap { SubmissionType(rawValue: $0) }
                    let favorite = favoriteKey.flatMap { SubmissionType(rawValue: $0) }
                    return .send(.internal(.saveSubmission(best: best, favorite: favorite, mode: mode)))

                case .technique:
                    let best = bestKey.flatMap { TechniqueType(rawValue: $0) }
                    let favorite = favoriteKey.flatMap { TechniqueType(rawValue: $0) }
                    return .send(.internal(.saveTechnique(best: best, favorite: favorite, mode: mode)))
                }
                
            case .destination(.presented(.myStyleSetting(.delegate(.cancel)))):
                // 뒤로가기: 스타일 설정 화면 닫기
                state.destination = nil
                return .none
                
            // MARK: - Sheet Delegate 처리
                
            case let .sheet(.presented(.beltSetting(.delegate(.didConfirmBelt(rank, stripe))))):
                // 벨트 등록·수정: API 호출하고 토스트 표시
                Log.trace("벨트 수정 확인됨 - rank: \(rank.displayName), stripe: \(stripe.displayName)", category: .debug, level: .info)
                state.sheet = nil
                state.isBeltSheetClosing = true
                // 지난 저장에서 시트 닫힘을 기다리던 축하가 남아 있으면 이번 저장 뒤에 엉뚱하게 뜨지 않게 비운다.
                state.pendingPromotion = nil
                state.isBeltEntranceAfterPromotion = false
                // 띠 · 그랄을 그대로 두고 '확인'하면 저장 없이 닫는다(QA A2-13).
                if let profile = state.communityProfile, profile.beltRank == rank, profile.beltStripe == stripe {
                    return .none
                }
                return .send(.internal(.saveBeltInfoOnly(rank: rank, stripe: stripe)))
                
            case let .internal(.saveBeltInfoOnly(rank, stripe)):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }
                
                Log.trace("벨트 수정 - 기존: \(profile.beltRank?.displayName ?? "없음") \(profile.beltStripe?.displayName ?? ""), 새로운: \(rank.displayName) \(stripe.displayName)", category: .debug, level: .info)
                
                // 벨트 정보만 업데이트
                let updatedProfile = profile.updatingBelt(rank: rank, stripe: stripe)
                
                Log.trace("API 요청할 프로필: \(updatedProfile.beltRank?.displayName ?? "없음") \(updatedProfile.beltStripe?.displayName ?? "")", category: .debug, level: .info)
                
                Self.beginProfileSave(&state)
                
                return .run { send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            // 띠·그랄만 바꾸고 성별·체급은 서버 값을 그대로 둔다(#188, jiu-jitsu-backend#172)
                            try await communityClient.updateProfile(updatedProfile, .belt)
                        }
                    )))
                }
                
            // MARK: - API 호출: 프로필 섹션 업데이트

            case let .internal(.updateProfileSection(section, value)):
                // 진입에서 막아 보통은 닿지 않지만, 도장 화면이 결과를 기다리며 잠기지 않게 실패로 돌려준다.
                guard !state.isLoadingProfile, let profile = state.communityProfile else {
                    if case .academySetting? = state.destination {
                        return .send(.destination(.presented(.academySetting(.saveFailed))))
                    }
                    return state.isLoadingProfile ? Self.savingInProgressToast() : Self.profileUnavailableToast()
                }

                // 섹션별로 업데이트할 필드 설정
                let updatedProfile: CommunityProfile
                switch section {
                case .academy:
                    updatedProfile = profile.updatingAcademy(value)

                case .belt, .position, .submission, .technique, .competition, .instructorInfo, .backgroundPattern:
                    // TODO: 다른 섹션 업데이트 구현
                    return .none
                }
                
                Self.beginProfileSave(&state)
                
                return .run { [section] send in
                    await send(.internal(.updateProfileResponse(
                        await TaskResult {
                            // CommunityClient에 섹션 정보도 전달
                            try await communityClient.updateProfile(updatedProfile, section)
                        }
                    )))
                }
                
            // MARK: - API 호출: 스타일 정보 저장 (특기 + 최애 한 번에)

            case let .internal(.savePosition(best, favorite, mode)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }

                let updatedProfile = profile.updatingPosition(best: best, favorite: favorite)
                Self.beginProfileSave(&state)

                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .position)
                    }

                    switch result {
                    case .success(let updatedProfile):
                        await send(.internal(.positionSaved(updatedProfile, mode: mode)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.saveSubmission(best, favorite, mode)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }

                let updatedProfile = profile.updatingSubmission(best: best, favorite: favorite)
                Self.beginProfileSave(&state)

                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .submission)
                    }

                    switch result {
                    case .success(let updatedProfile):
                        await send(.internal(.submissionSaved(updatedProfile, mode: mode)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.saveTechnique(best, favorite, mode)):
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }

                let updatedProfile = profile.updatingTechnique(best: best, favorite: favorite)
                Self.beginProfileSave(&state)

                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .technique)
                    }

                    switch result {
                    case .success(let updatedProfile):
                        await send(.internal(.techniqueSaved(updatedProfile, mode: mode)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            // MARK: - 저장 성공 후 처리

            // 응답이 올 때 화면이 닫혔을 수 있다(저장 중 뒤로가기). 그때는 값만 반영하고 다음 단계를 열지 않는다(#155).
            case let .internal(.positionSaved(profile, mode)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                let isShowing = Self.isShowingStyleSetting(.position, mode: mode, in: state)
                if mode == .edit {
                    if isShowing { state.destination = nil }
                    return .send(.internal(.showToast(.init(message: "포지션을 저장했어요", status: .success))))
                }
                guard isShowing else { return .none }
                // register 플로우: 다음 단계(기술)로 이동
                state.destination = .myStyleSetting(
                    MyStyleSettingFeature.State(
                        settingType: .technique,
                        mode: .register,
                        beltRank: profile.beltRank,
                        bestTechnique: profile.bestTechnique,
                        favoriteTechnique: profile.favoriteTechnique
                    )
                )
                return .none

            case let .internal(.techniqueSaved(profile, mode)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                let isShowing = Self.isShowingStyleSetting(.technique, mode: mode, in: state)
                if mode == .edit {
                    if isShowing { state.destination = nil }
                    return .send(.internal(.showToast(.init(message: "기술을 저장했어요", status: .success))))
                }
                guard isShowing else { return .none }
                // register 플로우: 다음 단계(서브미션)로 이동
                state.destination = .myStyleSetting(
                    MyStyleSettingFeature.State(
                        settingType: .submission,
                        mode: .register,
                        beltRank: profile.beltRank,
                        bestSubmission: profile.bestSubmission,
                        favoriteSubmission: profile.favoriteSubmission
                    )
                )
                return .none

            case let .internal(.submissionSaved(profile, mode)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                let isShowing = Self.isShowingStyleSetting(.submission, mode: mode, in: state)
                if mode == .edit {
                    if isShowing { state.destination = nil }
                    return .send(.internal(.showToast(.init(message: "서브미션을 저장했어요", status: .success))))
                }
                guard isShowing else { return .none }
                // register 플로우 마지막 단계: 프로필 화면으로 복귀
                state.destination = nil
                return .send(.internal(.showToast(.init(message: "모든 스타일 설정을 완료했어요", status: .success))))
                
            // MARK: - API 호출: 프로필 섹션 업데이트
                
            case let .internal(.updateProfileResponse(.success(updatedProfile))):
                state.isLoadingProfile = false
                let previousProfile = state.communityProfile
                state.communityProfile = updatedProfile  // ← 업데이트된 프로필로 교체!
                state.destination = nil  // 화면 닫기

                // 더 높은 띠로 바꿨거나 같은 띠에서 그랄을 올렸으면 토스트 대신 축하 장면을 띄운다(#278, #286).
                // 낮은 띠, 그랄을 내리거나 그대로 둔 경우는 그대로 토스트.
                if let promotion = BeltPromotion(from: previousProfile, to: updatedProfile) {
                    // 띄울 때까지 잡아 둔다 — 같은 패스의 onChange(beltRank)가 이걸 보고 링을 축하 뒤로 미룬다.
                    state.pendingPromotion = promotion
                    // 띠 시트가 아직 내려가는 중이면 새 화면을 띄울 수 없다 → 다 내려간 뒤(beltSheetDidDismiss) 띄운다
                    if state.isBeltSheetClosing {
                        return .send(.delegate(.profileUpdated))
                    }
                    return .merge(.send(.delegate(.profileUpdated)), .run { send in
                        // 아래에서 밀려 올라오지 않고 제자리에서 나타나게 기본 등장 움직임을 끈다
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        await send(.internal(.presentBeltPromotion(promotion)), transaction: transaction)
                    })
                }

                // 어떤 섹션이 업데이트되었는지에 따라 다른 메시지 표시
                let message: String
                if previousProfile?.beltRank == nil && updatedProfile.beltRank != nil {
                    // 최초 벨트 설정
                    message = "벨트 정보 입력을 완료했어요"
                } else if previousProfile?.academyName == nil && updatedProfile.academyName != nil {
                    // 도장 정보 추가
                    message = "도장 정보 입력을 완료했어요"
                } else if previousProfile?.academyName != nil && updatedProfile.academyName == nil {
                    // 도장 정보 삭제
                    message = "도장 정보를 삭제했어요"
                } else if previousProfile?.beltRank != updatedProfile.beltRank ||
                         previousProfile?.beltStripe != updatedProfile.beltStripe {
                    // 벨트 정보 수정
                    message = "벨트 정보 수정을 완료했어요"
                } else {
                    // 기타
                    message = "프로필 수정을 완료했어요"
                }
                
                return .merge(
                    .send(.delegate(.profileUpdated)),
                    .send(.internal(.showToast(.init(message: message, status: .success))))
                )
                
            case let .internal(.updateProfileResponse(.failure(error))):
                state.isLoadingProfile = false
                Log.trace("Failed to update profile: \(error)", category: .network, level: .error)
                // 도장 · 스타일 화면에 뜨든 MY 토스트로 뜨든 실패 안내는 한 번이다.
                analyticsClient.logErrorShown(error)
                // 도장 · 스타일 화면이 떠 있으면 MY 토스트는 가려지므로 그 화면이 직접 알리고 다시 저장하게 한다(#156).
                // 저장 중엔 다른 저장 화면이 열리지 않아(#155) 떠 있는 화면이 곧 실패한 저장의 화면이다.
                switch state.destination {
                case .academySetting?:
                    return .send(.destination(.presented(.academySetting(.saveFailed))))
                case .myStyleSetting?:
                    return .send(.destination(.presented(.myStyleSetting(.saveFailed))))
                default:
                    return .send(.internal(.showToast(.init(message: "저장하지 못했어요. 다시 시도해 주세요", status: .error))))
                }
                
            case let .internal(.showToast(toastState)):
                state.toast = toastState
                return .run { send in
                    try await self.clock.sleep(for: toastState.duration)
                    await send(.internal(.toastDismissed))
                }
                .cancellable(id: CancelID.toast, cancelInFlight: true)
                
            case .internal(.toastDismissed):
                state.toast = nil
                return .cancel(id: CancelID.toast)
                
            case .view(.toastButtonTapped):
                return .send(.internal(.toastDismissed))

            case let .internal(.presentBeltPromotion(promotion)):
                state.pendingPromotion = nil
                state.promotion = promotion
                state.isBeltEntranceAfterPromotion = true
                return .none

            case .view(.beltPromotionDismissed):
                state.promotion = nil
                // 장면에 가려 미뤄 둔 링 움직임을 MY가 다시 보이는 지금 새 띠·그랄로 한 번 한다.
                if state.isBeltEntranceAfterPromotion {
                    state.isBeltEntranceAfterPromotion = false
                    state.beltEntranceTrigger += 1
                    state.hasPlayedBeltEntrance = true
                }
                return .none

            case .view(.beltSheetDidDismiss):
                state.isBeltSheetClosing = false
                if let promotion = state.pendingPromotion {
                    state.pendingPromotion = nil
                    state.promotion = promotion
                    state.isBeltEntranceAfterPromotion = true
                }
                return .none
                
            case .view(.communityActivityTapped):
                return .send(.delegate(.communityActivityRequested))

            case .view(.settingsButtonTapped):
                // 연타로 설정이 두 번 쌓이지 않게 한다.
                if case .settings? = state.path.last { return .none }
                state.path.append(.settings(SettingsFeature.State(authInfo: state.authInfo)))
                return .none

            case .view(.guestLoginTapped):
                return .send(.delegate(.loginRequested))

            // 설정의 알림 화면을 나갈 때 남은 값 저장 — 설정이 바로 닫혀도 끊기지 않게 MY가 맡는다(#241).
            case let .path(.element(id: _, action: .settings(.delegate(.notificationSettingSaveRequested(setting))))):
                return .run { send in
                    do {
                        let saved = try await noticeClient.updateSetting(setting)
                        await send(.internal(.notificationSettingSaved(setting)))
                        // 관심 대회 알림을 켠 채 바로 나갔으면 여기서 저장되므로, 저장 뒤 기기 알림 안내를 부모(AppTab)에 넘긴다(#281).
                        if setting.competitionEnabled == true, saved.competitionEnabled {
                            await send(.delegate(.settings(.competitionAlertTurnedOn)))
                        }
                    } catch {
                        Log.trace("알림 화면 이탈 후 설정 저장 실패: \(error)", category: .network, level: .error)
                        analyticsClient.logErrorShown(error)
                        await send(.internal(.notificationSettingSaveFailed))
                    }
                }

            case .internal(.notificationSettingSaved):
                return .none

            case .internal(.notificationSettingSaveFailed):
                let toast = ToastState(message: "알림 설정을 저장하지 못했어요. 다시 시도해 주세요", status: .error)
                // 알림 화면을 나오면 설정 화면이 MY 위에 남아 MY 토스트가 가려진다 — 설정이 맨 위면 설정 화면에 띄운다(QA A4-2).
                if let id = state.path.ids.last, case .settings? = state.path[id: id] {
                    return .send(.path(.element(id: id, action: .settings(.internal(.showToast(toast))))))
                }
                return .send(.internal(.showToast(toast)))

            case let .path(.element(id: _, action: .settings(.delegate(delegate)))):
                return .send(.delegate(.settings(delegate)))

            // MARK: - 웹 서브뷰 (커뮤니티 활동 등)

            // 서브뷰 안의 중첩 OPEN_SUBVIEW. 커뮤니티 탭과 같이 이미 서브뷰 안이므로 modal 요청도 push로 쌓는다.
            // (동일 origin 검증은 상세가 위임 전에 끝냈다)
            case let .path(.element(id: id, action: .communityDetail(.delegate(.openSubviewRequested(payload))))):
                guard
                    case let .communityDetail(source)? = state.path[id: id],
                    let url = URL(string: payload.url)
                else { return .none }
                // 활동에서 연 글 상세도 카테고리 이름 · 피드로 가기가 홈 탭으로 보낸다(OPEN_HOME_FEED, #480).
                state.path.append(.communityDetail(.init(
                    url: url,
                    title: payload.title,
                    accessToken: source.accessToken,
                    isTabRoot: false,
                    capabilities: [.pickPhotos, .openHomeFeed]
                )))
                return .none

            case let .path(.element(id: _, action: .communityDetail(.delegate(.userProfileRequested(userId))))):
                return .send(.openUserProfile(userId: userId))

            case let .path(.element(id: _, action: .communityDetail(.delegate(delegate)))):
                return .send(.delegate(.webSubview(delegate)))

            case let .path(.element(id: _, action: .userProfile(.delegate(.blockChanged(userId, blocked))))):
                return .send(.delegate(.userBlockChanged(userId: userId, blocked: blocked)))

            case let .openUserProfile(userId):
                // 연타·중복 전달로 같은 프로필이 겹쳐 쌓이지 않게 한다
                if case let .userProfile(current)? = state.path.last, current.userId == userId { return .none }
                state.path.append(.userProfile(.init(userId: userId)))
                return .none

            case let .session(update):
                for id in state.path.ids {
                    if case var .communityDetail(detail)? = state.path[id: id] {
                        CommunityDetailFeature.apply(update, into: &detail)
                        state.path[id: id] = .communityDetail(detail)
                    }
                }
                return .none

            case .view(.addCompetitionButtonTapped):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                // 출전 띠는 지금 띠로(#122), 체급은 지난 기록의 체급으로 미리 골라 둔다(#190).
                state.destination = .competitionInfo(
                    CompetitionInfoFeature.State(
                        mode: .add,
                        currentBelt: state.communityProfile?.beltRank,
                        recentWeightLimit: state.communityProfile?.competitions.recentWeightLimit
                    )
                )
                return .none

            case let .destination(.presented(.competitionInfo(.delegate(.didFinishAdding(competition))))):
                guard state.communityProfile != nil else {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }
                Log.trace(
                    "대회 추가 요청: \(competition.competitionYear) \(competition.competitionName) \(competition.competitionRank.displayName)",
                    category: .debug,
                    level: .info
                )
                // 저장 결과를 보고 완료 화면('부문 추가')으로 넘어가야 하므로 입력 화면은 닫지 않는다(#123).
                Self.beginProfileSave(&state)
                return .run { send in
                    let result = await TaskResult {
                        try await saveCompetitions { $0.addingCompetition(competition) }
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionAdded(saved, competition)))
                    case .failure(let error):
                        Log.trace("Failed to add competition: \(error)", category: .network, level: .error)
                        analyticsClient.logErrorShown(error)
                        await send(.internal(.competitionAddFailed))
                    }
                }

            case let .destination(.presented(.competitionInfo(.delegate(.didFinishEditing(original, updated))))):
                guard state.communityProfile != nil else {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }
                Log.trace(
                    "대회 수정 요청: \(original.competitionName) → \(updated.competitionName)",
                    category: .debug,
                    level: .info
                )
                state.destination = nil
                Self.beginProfileSave(&state)
                return .run { send in
                    let result = await TaskResult {
                        // 고칠 원래 기록을 새 목록에서 못 찾으면 바뀐 것 없이 저장하고 성공이라 하지 않게 멈춘다(QA A3-7).
                        try await saveCompetitions { latest in
                            guard let target = Self.resolve([original], in: latest.competitions)?.first else { return nil }
                            // 고정·자리는 새 목록 값을 따른다 — 수정 화면은 들고 있던 원래 기록의 값을 그대로 실었다.
                            let edited = updated.settingPinned(target.isPinned, displayOrder: target.displayOrder)
                            return latest.updatingCompetition(original: target, with: edited)
                        }
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionUpdated(saved)))
                    case .failure(let missing as CompetitionTargetMissing):
                        await send(.internal(.competitionTargetMissing(latest: missing.latest, isDelete: false)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .destination(.presented(.competitionInfo(.delegate(.didDelete(competition))))):
                guard let profile = state.communityProfile else {
                    state.destination = nil
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }
                state.destination = nil
                return deleteCompetitions([competition], from: profile, state: &state)

            case let .view(.deleteCompetitionConfirmed(entries)):
                // 앞선 저장이 끝나기 전에 목록 전체를 다시 저장하면 그 저장을 덮어쓴다.
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                guard let profile = state.communityProfile else {
                    return .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
                }
                return deleteCompetitions(entries, from: profile, state: &state)

            case let .internal(.competitionAdded(profile, competition)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                // 입력 화면이 완료 화면을 대신 보여 준다. 저장 중 화면이 닫혔으면(예외적) 토스트로 알린다.
                guard case .competitionInfo? = state.destination else {
                    return .send(.internal(.showToast(.init(message: "대회 정보를 추가했어요", status: .success))))
                }
                return .send(.destination(.presented(.competitionInfo(.saveFinished(.succeeded(competition))))))

            case .internal(.competitionAddFailed):
                state.isLoadingProfile = false
                // MY 화면 토스트는 입력 화면에 가려지므로 입력 화면이 실패를 안내하고, 입력값을 지켜 다시 저장하게 한다.
                guard case .competitionInfo? = state.destination else {
                    return .send(.internal(.showToast(.init(message: "저장하지 못했어요. 다시 시도해 주세요", status: .error))))
                }
                return .send(.destination(.presented(.competitionInfo(.saveFinished(.failed)))))

            case let .internal(.competitionUpdated(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .send(.internal(.showToast(.init(message: "대회 정보를 수정했어요", status: .success))))

            case let .internal(.competitionDeleted(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .send(.internal(.showToast(.init(message: "대회 정보를 삭제했어요", status: .success))))

            case .internal(.competitionDeleteFailed):
                state.isLoadingProfile = false
                return .send(.internal(.showToast(.init(message: "삭제하지 못했어요. 다시 시도해 주세요", status: .error))))

            case let .internal(.competitionTargetMissing(latest, isDelete)):
                state.isLoadingProfile = false
                // 다른 곳에서 바뀐 목록을 그대로 보여 줘 회원이 지금 기록을 보고 다시 하게 한다.
                state.communityProfile = latest
                let message = isDelete ? "삭제하지 못했어요. 다시 시도해 주세요" : "저장하지 못했어요. 다시 시도해 주세요"
                return .send(.internal(.showToast(.init(message: message, status: .error))))

            case let .view(.addDivisionTapped(entries)):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                state.destination = .competitionInfo(
                    CompetitionInfoFeature.State(
                        addingDivisionTo: entries,
                        currentBelt: state.communityProfile?.beltRank,
                        recentWeightLimit: entries.recentWeightLimit ?? state.communityProfile?.competitions.recentWeightLimit
                    )
                )
                return .none

            case let .view(.competitionPinToggled(entries)):
                // 저장 중에 또 누르면 저장 전 목록 기준으로 한 번 더 저장해 앞의 변경을 덮으므로 막는다.
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                guard let profile = state.communityProfile, !entries.isEmpty else { return .none }
                // 묶인 줄은 부문 하나라도 고정돼 있으면 고정으로 보이므로(CompetitionGroup.isPinned) 같은 기준으로 푼다.
                let isPinning = !entries.contains(where: \.isPinned)
                if isPinning {
                    let pinnedCount = CompetitionGroup.grouped(profile.competitions).filter(\.isPinned).count
                    guard pinnedCount < CompetitionGroup.maxPinnedCount else {
                        return .send(.internal(.showToast(.init(
                            message: "대표 기록은 \(CompetitionGroup.maxPinnedCount)개까지 고정할 수 있어요",
                            status: .warning
                        ))))
                    }
                }
                Self.beginProfileSave(&state)
                return .run { send in
                    let result = await TaskResult {
                        try await saveCompetitions { latest in
                            guard let targets = Self.resolve(entries, in: latest.competitions) else { return nil }
                            return latest.settingCompetitionsPinned(targets, isPinned: isPinning)
                        }
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionPinUpdated(saved, isPinned: isPinning)))
                    case .failure(let missing as CompetitionTargetMissing):
                        await send(.internal(.competitionTargetMissing(latest: missing.latest, isDelete: false)))
                    case .failure(let error):
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .view(.competitionsReordered(groups)):
                // 끌어 옮긴 뒤 머리줄 '완료'에서 순서가 바뀐 묶음만 한 번에 저장한다. 저장 중에는 '완료'가 막혀 있다.
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                guard let profile = state.communityProfile else { return .none }
                let updatedProfile = profile.reorderingCompetitions(groups)
                guard updatedProfile != profile else { return .none }
                // 끌어 놓은 순서가 저장을 기다리는 동안 원래 자리로 튀었다 돌아오지 않게 먼저 화면에 반영한다.
                state.communityProfile = updatedProfile
                Self.beginProfileSave(&state)
                return .run { send in
                    let result = await TaskResult {
                        try await saveCompetitions { latest in
                            guard let targets = Self.resolve(groups.flatMap { $0 }, in: latest.competitions) else { return nil }
                            // 찾은 새 목록 값을 원래 줄 묶음대로 다시 나눈다.
                            var rest = targets[...]
                            let latestGroups = groups.map { group in
                                defer { rest = rest.dropFirst(group.count) }
                                return Array(rest.prefix(group.count))
                            }
                            return latest.reorderingCompetitions(latestGroups)
                        }
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.competitionOrderSaved(saved)))
                    case .failure(let missing as CompetitionTargetMissing):
                        // 먼저 옮겨 둔 순서 대신 서버 목록으로 맞춘다.
                        await send(.internal(.competitionTargetMissing(latest: missing.latest, isDelete: false)))
                    case .failure(let error):
                        await send(.internal(.competitionOrderReverted(profile)))
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.competitionOrderSaved(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                return .none

            case let .internal(.competitionOrderReverted(profile)):
                state.communityProfile = profile
                return .none

            // MARK: - 상단 바탕 무늬 (#320, #337)

            case let .view(.headerPatternChanged(pattern)):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                guard let profile = state.communityProfile else { return Self.profileUnavailableToast() }
                guard !state.isSavedHeaderPattern(pattern) else { return .none }
                let updatedProfile = profile.updatingBackgroundPattern(pattern.serverValue)
                // 시트를 닫자마자 바탕이 바뀌게 먼저 화면에 반영하고, 저장에 실패하면 되돌린다.
                state.communityProfile = updatedProfile
                Self.beginProfileSave(&state)
                return .run { send in
                    let result = await TaskResult {
                        try await communityClient.updateProfile(updatedProfile, .backgroundPattern)
                    }
                    switch result {
                    case .success(let saved):
                        await send(.internal(.headerPatternSaved(saved)))
                    case .failure(let error):
                        await send(.internal(.headerPatternReverted(profile)))
                        await send(.internal(.updateProfileResponse(.failure(error))))
                    }
                }

            case let .internal(.headerPatternSaved(profile)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                // 서버에 무늬가 생겼으니 기기에 남은 무늬는 더 쓰지 않는다.
                guard profile.backgroundPattern != nil else { return .none }
                return clearLegacyHeaderPattern(&state)

            case let .internal(.headerPatternReverted(profile)):
                state.communityProfile = profile
                return .none

            case let .internal(.legacyHeaderPatternMigrated(.success(profile))):
                state.isLoadingProfile = false
                state.communityProfile = profile
                guard profile.backgroundPattern != nil else { return .none }
                return clearLegacyHeaderPattern(&state)

            case let .internal(.legacyHeaderPatternMigrated(.failure(error))):
                state.isLoadingProfile = false
                // 회원이 한 일이 아니라 알리지 않는다. 기기 무늬는 남겨 두고 다음 조회 때 다시 옮겨 담는다.
                Log.trace("Failed to migrate header pattern: \(error)", category: .network, level: .error)
                return .none

            case let .internal(.competitionPinUpdated(profile, isPinned)):
                state.isLoadingProfile = false
                state.communityProfile = profile
                let message = isPinned ? "맨 위에 고정했어요" : "고정을 해제했어요"
                return .send(.internal(.showToast(.init(message: message, status: .success))))

            case let .view(.competitionDetailTapped(competition)):
                guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
                state.destination = .competitionInfo(
                    CompetitionInfoFeature.State(mode: .edit(original: competition))
                )
                return .none

            case .view(.instructorVerificationMenuTapped):
                guard !state.isUploadingInstructorVerification else { return .none }
                // 신청 상태를 모르면 '미신청'으로 단정해 심사 중인 회원에게도 신청 화면이 뜬다 — 먼저 다시 받는다(QA A3-10).
                guard state.userProfile != nil else { return fetchUserProfile(for: .instructorVerification, state: state) }
                state.sheet = .instructorVerification(Self.instructorVerificationState(from: state))
                return .none

            case let .internal(.presentPickedVerificationImage(data)):
                // 실제로는 걸리지 않는 방어다. 300ms 동안은 픽커 · 고르기 시트가 내려가는 전환 중이라 MY를 눌러
                // 다른 시트를 열 수 없고, 업로드는 이 인증 시트의 [이 사진으로 신청]에서만 시작된다.
                // 그래도 걸리면 시트를 겹쳐 띄우지 않고, 조용히 사라지지 않게 기록을 남긴다.
                guard state.sheet == nil, !state.isUploadingInstructorVerification else {
                    Log.trace("관장 사범 인증 - 고른 사진 확인 시트를 띄우지 못함(다른 시트 또는 업로드 중)", category: .view, level: .error)
                    return .none
                }
                state.sheet = .instructorVerification(
                    Self.instructorVerificationState(from: state, pickedImageData: data)
                )
                return .none

            case let .sheet(.presented(.instructorVerification(.delegate(.didConfirmImage(data))))):
                state.sheet = nil
                // 순차 3-홉(ImageKit 토큰 발급 → ImageKit 업로드 → PUT /api/user/owner)이 2~5초 걸린다.
                // 인증 사진은 노출되지 않는 검수용이라 Optimistic Update 대신 로딩 오버레이로
                // 진행을 표시하고 터치를 막는다. 완료·실패 응답에서 해제 후 결과 토스트(#62).
                state.isUploadingInstructorVerification = true
                state.userProfileGeneration += 1
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

            case let .sheet(.presented(.instructorVerification(.delegate(.mailUnavailable(email))))):
                // 메일 앱이 없으면 주소를 복사해 두고, 시트를 닫아 MY 화면 알림으로 알려 준다.
                state.sheet = nil
                return .run { send in
                    await MainActor.run { UIPasteboard.general.string = email }
                    // 시트가 내려가는 동안 알림이 시트 밑에 가려지지 않게 닫힌 뒤에 띄운다.
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.internal(.showToast(.init(
                        message: "메일 앱을 열 수 없어 문의 주소를 복사했어요", status: .info
                    ))))
                }

            case let .internal(.userProfileFetchedForEntry(result, generation, entry)):
                switch result {
                case let .success(profile):
                    if !state.isUploadingProfileImage, generation == state.userProfileGeneration {
                        state.userProfile = profile
                        state.pendingProfileImageData = nil
                    }
                    // 받는 사이 다른 시트가 열렸으면 겹쳐 띄우지 않는다.
                    guard state.userProfile != nil, state.sheet == nil else { return .none }
                    switch entry {
                    case .profileImageEdit:
                        return .send(.view(.profileImageEditButtonTapped))
                    case .instructorVerification:
                        return .send(.view(.instructorVerificationMenuTapped))
                    }
                case let .failure(error):
                    Log.trace("Failed to load user profile before \(entry): \(error)", category: .network, level: .error)
                    return Self.profileUnavailableToast()
                }

            case let .internal(.presentImageEditSheet(purpose, canDelete)):
                state.sheet = .profileImageEdit(
                    ProfileImageEditFeature.State(purpose: purpose, canDelete: canDelete)
                )
                return .none

            case .view(.profileImageEditButtonTapped):
                // 업로드 중에 또 바꾸면 앞 업로드 응답이 새 사진을 덮을 수 있다(#155).
                guard !state.isUploadingProfileImage else {
                    return .send(.internal(.showToast(.init(message: "사진을 바꾸는 중이에요. 잠시 후 다시 시도해 주세요", status: .info))))
                }
                // user 프로필이 없으면 사진을 다 고르고 자른 뒤에야 실패한다 — 열기 전에 다시 받는다(QA A2-2).
                guard state.userProfile != nil else { return fetchUserProfile(for: .profileImageEdit, state: state) }
                // 프로필 이미지 수정 옵션 바텀시트 노출
                // 실제로 이미지가 렌더링되는 상태일 때만 '삭제' 옵션 노출
                let canDelete = state.userProfile?.hasProfileImage ?? false
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
                // 카메라가 없는 기기에서 `.camera` picker를 띄우면 앱이 죽을 수 있다(#353)
                return .run { send in
                    if await cameraAvailabilityClient.isAvailable() {
                        await send(.internal(.presentImageCaptureSource(.camera)))
                    } else {
                        await send(.internal(.cameraUnavailable))
                    }
                }

            case .sheet(.presented(.profileImageEdit(.delegate(.didSelectAlbum)))):
                state.pendingImagePurpose = state.sheet?.profileImageEdit?.purpose ?? .profileImage
                state.imageCaptureSource = .photoLibrary
                return .none

            case .sheet(.presented(.profileImageEdit(.delegate(.didSelectDelete)))):
                state.sheet = nil
                guard let profile = state.userProfile else {
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", status: .error
                    ))))
                }
                // 삭제는 DELETE /api/image/{id} 사용 — 현재 이미지의 서버 파일 id가 필요하다.
                // id는 프로필 조회 응답(GET /api/user/profile)의 profileImage.id에서 온다.
                guard let imageFileId = profile.profileImageFileId else {
                    Log.trace("프로필 이미지 - 삭제 불가(파일 id 없음)", category: .network, level: .error)
                    return .send(.internal(.showToast(.init(
                        message: "이미지 정보를 불러올 수 없어 삭제하지 못했어요", status: .error
                    ))))
                }
                let updatedProfile = profile.updatingProfileImage(url: nil, fileId: nil)
                state.isUploadingProfileImage = true
                state.userProfileGeneration += 1
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
                // 카메라 확인 사이에 시트를 닫았으면 띄우지 않는다 — 남은 값이 다음 시트에서 picker를 저절로 띄우지 않게
                guard state.sheet != nil else { return .none }
                state.imageCaptureSource = source
                return .none

            case .internal(.cameraUnavailable):
                // 토스트가 시트에 가려지지 않게 시트를 닫고 알린다
                state.sheet = nil
                state.pendingImagePurpose = nil
                return .send(.internal(.showToast(.init(message: "이 기기에서는 카메라를 쓸 수 없어요", status: .info))))

            case let .view(.imagePicked(data)):
                // 사진 선택 완료 — picker dismiss + 액션 시트 정리.
                // purpose에 따라 다음 단계 분기:
                //   - 프로필 이미지: 1:1 크롭 단계로 진행 (헤더 아바타는 정사각형이라 필수)
                //   - 관장 사범 인증: 크롭 생략, 인증 시트로 돌아가 미리보기로 확인받은 뒤 업로드(#388)
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
                    // 고르기 단계가 여기서 끝나므로 purpose 리셋
                    state.pendingImagePurpose = nil
                    // 누르는 순간 바로 제출되지 않게, 픽커 · 고르기 시트가 내려간 뒤 인증 시트에 미리보기로 띄운다.
                    return .run { send in
                        try await clock.sleep(for: .milliseconds(300))
                        await send(.internal(.presentPickedVerificationImage(data)))
                    }
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
                guard state.userProfile != nil else {
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", status: .error
                    ))))
                }
                state.isUploadingProfileImage = true
                state.userProfileGeneration += 1
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
                guard let profile = state.userProfile else {
                    state.isUploadingProfileImage = false
                    state.pendingProfileImageData = nil
                    return .send(.internal(.showToast(.init(
                        message: "프로필 정보를 불러올 수 없어요", status: .error
                    ))))
                }
                // 헤더 표시는 등록된 이미지 URL을, BE 반영·이후 삭제는 발급된 id를 사용한다.
                let imageFileId = registeredImage.id
                let updatedProfile = profile.updatingProfileImage(url: registeredImage.imageUrl, fileId: imageFileId)
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
                state.isUploadingProfileImage = false
                // 업로드 실패 → 미리보기 롤백
                state.pendingProfileImageData = nil
                Log.trace("Failed to upload profile image: \(error)", category: .network, level: .error)
                analyticsClient.logErrorShown(error, as: .upload)
                return .send(.internal(.showToast(.init(
                    message: "사진을 올리지 못했어요. 다시 시도해 주세요", status: .error
                ))))

            case let .internal(.instructorVerificationImageUploadResponse(.success(registeredImage))):
                // CDN 업로드 + 서버 등록 완료 → 발급된 id로 BE 인증 요청(PUT /api/user/owner) 체이닝.
                Log.trace(
                    "관장 사범 인증 - 이미지 등록 완료. imageFileId=\(registeredImage.id), 인증 요청 시작",
                    category: .network,
                    level: .info
                )
                let imageFileId = registeredImage.id
                let imageUrl = registeredImage.imageUrl
                return .run { send in
                    await send(.internal(.instructorVerificationRequestResponse(
                        await TaskResult {
                            try await userClient.requestOwnerVerification(imageFileId)
                            // 인증 요청 성공 시 방금 업로드한 이미지 URL을 그대로 전달 (시트 재진입 반영용)
                            return imageUrl
                        }
                    )))
                }
                .cancellable(id: CancelID.instructorVerificationUpload)

            case let .internal(.instructorVerificationImageUploadResponse(.failure(error))):
                state.isUploadingInstructorVerification = false
                Log.trace("Failed to upload instructor verification image: \(error)", category: .network, level: .error)
                analyticsClient.logErrorShown(error, as: .upload)
                return .send(.internal(.showToast(.init(
                    message: "사진을 올리지 못했어요. 다시 시도해 주세요", status: .error
                ))))

            case let .internal(.instructorVerificationRequestResponse(.success(uploadedImageUrl))):
                state.isUploadingInstructorVerification = false
                // 인증 요청 접수 완료. 검수는 비동기이므로 "업로드했어요" 안내가 정확하다.
                Log.trace("관장 사범 인증 - 인증 요청 완료", category: .network, level: .info)
                // Optimistic — BE 응답을 기다리지 않고 심사 중 + 방금 업로드한 이미지 URL을
                // 즉시 반영해 시트 재진입 시 최신 상태가 보이도록 한다.
                // 다음 MY 진입 시 loadProfile이 실제값으로 덮어쓰므로 드리프트가 남지 않는다.
                state.userProfile = state.userProfile?.updatingOwnerVerification(
                    OwnerVerification(status: .pending, documentImageUrl: uploadedImageUrl, requestedAt: date.now)
                )
                // 승인 · 반려 알림이 없어 결과를 알려 준다고 약속하지 않고, 어디서 보는지 안내한다(#389).
                return .send(.internal(.showToast(.init(
                    message: "신청했어요. 결과는 관장 사범 인증 화면에서 확인할 수 있어요", status: .success
                ))))

            case let .internal(.instructorVerificationRequestResponse(.failure(error))):
                state.isUploadingInstructorVerification = false
                Log.trace("Failed to request owner verification: \(error)", category: .network, level: .error)
                analyticsClient.logErrorShown(error)
                return .send(.internal(.showToast(.init(
                    message: "인증을 요청하지 못했어요. 다시 시도해 주세요", status: .error
                ))))

            case let .internal(.profileImageUpdateResponse(.success(updatedProfile))):
                state.isUploadingProfileImage = false
                state.userProfile = updatedProfile
                state.isProfileImageDeleting = false
                // 업로드 성공 시에는 새 URL 사진이 그려질 때까지(profileImageDisplayed) 미리보기를 겹쳐 둔다.
                // 그 사이 AsyncImage가 `.empty`로 시작하며 기본 아이콘이 깜빡이지 않게 하기 위함.
                // 삭제 케이스에서는 바로 정리한다.
                if updatedProfile.profileImageUrl == nil {
                    state.pendingProfileImageData = nil
                }
                // 업로드/삭제 동일 핸들러로 통합 — profileImageUrl 유무로 토스트 문구 분기
                let message = updatedProfile.profileImageUrl == nil
                    ? "프로필 이미지를 삭제했어요"
                    : "프로필 이미지를 변경했어요"
                return .send(.internal(.showToast(.init(message: message, status: .success))))

            case let .internal(.profileImageUpdateResponse(.failure(error))):
                state.isUploadingProfileImage = false
                // BE 반영 실패 → 미리보기/삭제 표시 롤백
                state.pendingProfileImageData = nil
                state.isProfileImageDeleting = false
                Log.trace("Failed to update profile image url: \(error)", category: .network, level: .error)
                analyticsClient.logErrorShown(error)
                return .send(.internal(.showToast(.init(
                    message: "프로필을 저장하지 못했어요. 다시 시도해 주세요", status: .error
                ))))

            case .destination, .sheet, .imageCropCover, .path, .view, .internal, .delegate:
                return .none

            }
        }
        .onChange(of: { $0.communityProfile?.beltRank }) { oldBelt, newBelt in
            Reduce { state, _ in
                guard newBelt != nil else { return .none }
                if oldBelt != nil {
                    // 띠를 바꾼 직후 — 축하가 곧 뜨거나(pendingPromotion) 떠 있으면 닫힌 뒤(beltPromotionDismissed)로 미룬다
                    if state.pendingPromotion == nil && !state.isBeltEntranceAfterPromotion {
                        state.beltEntranceTrigger += 1
                    }
                    state.hasPlayedBeltEntrance = true
                } else if state.isWaitingBeltEntrance {
                    // 화면에 들어온 뒤 띠가 처음 도착(첫 조회·첫 등록)
                    state.isWaitingBeltEntrance = false
                    state.beltEntranceTrigger += 1
                    state.hasPlayedBeltEntrance = true
                }
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
        .forEach(\.path, action: \.path)
    }

    /// MY가 화면에 들어왔을 때 — 세션에서 아직 안 돌았으면 지금(띠가 있으면) 또는 띠가 올 때 돈다.
    private static func requestBeltEntrance(_ state: inout State) {
        guard !state.hasPlayedBeltEntrance else { return }
        if state.communityProfile?.beltRank != nil {
            state.beltEntranceTrigger += 1
            state.hasPlayedBeltEntrance = true
        } else {
            state.isWaitingBeltEntrance = true
        }
    }

    /// 관장 사범 인증 시트 상태. 사진을 고른 뒤 다시 띄울 때는 고른 사진을 함께 싣는다(#388).
    private static func instructorVerificationState(
        from state: State,
        pickedImageData: Data? = nil
    ) -> InstructorVerificationFeature.State {
        // 역할이 OWNER인데 신청 기록이 없는 회원(승인 API 이전에 권한을 받은 경우)도 완료로 본다.
        // 기록이 있으면 서버 상태를 그대로 따른다.
        let recorded = state.userProfile?.ownerVerification ?? .notRequested
        let verification = state.userProfile?.userRole == .owner && recorded.status == .notRequested
            ? OwnerVerification(status: .approved)
            : recorded
        return InstructorVerificationFeature.State(
            verification: verification,
            nickname: state.communityProfile?.nickname
                ?? state.userProfile?.nickname
                ?? state.authInfo.userInfo?.nickname
                ?? "",
            pickedImageData: pickedImageData
        )
    }

    /// user 프로필을 다시 받아, 받으면 그 화면을 연다(QA A2-2, A3-10). 연타하면 앞 요청은 취소한다.
    private func fetchUserProfile(for entry: Action.InternalAction.UserProfileEntry, state: State) -> Effect<Action> {
        guard !state.authInfo.isGuest else { return .none }
        let generation = state.userProfileGeneration
        return .run { send in
            await send(.internal(.userProfileFetchedForEntry(
                await TaskResult { try await userClient.fetchUserProfile() },
                generation: generation,
                entry: entry
            )))
        }
        .cancellable(id: CancelID.userProfileForEntry, cancelInFlight: true)
    }

    /// 서버에 저장하기 전 이 기기에만 남긴 상단 무늬를 서버로 옮겨 담는다(#337). 프로필을 받을 때마다 부른다.
    /// 서버에 이미 무늬가 있으면(다른 기기에서 골랐거나 이미 옮겨 담음) 서버 값이 기준이라 기기 값만 지운다.
    private func migrateLegacyHeaderPatternIfNeeded(_ state: inout State) -> Effect<Action> {
        if !state.hasLoadedLegacyHeaderPattern {
            state.hasLoadedLegacyHeaderPattern = true
            state.legacyHeaderPattern = legacyHeaderPatternClient.load()
        }
        guard let legacy = state.legacyHeaderPattern, let profile = state.communityProfile else { return .none }
        guard profile.backgroundPattern == nil else { return clearLegacyHeaderPattern(&state) }
        // 다른 저장 중이면 그 응답이 프로필을 바꾸므로 다음 조회 때 옮긴다(#155).
        guard !state.isLoadingProfile else { return .none }
        let updatedProfile = profile.updatingBackgroundPattern(legacy.serverValue)
        Self.beginProfileSave(&state)
        return .run { send in
            await send(.internal(.legacyHeaderPatternMigrated(
                await TaskResult { try await communityClient.updateProfile(updatedProfile, .backgroundPattern) }
            )))
        }
    }

    private func clearLegacyHeaderPattern(_ state: inout State) -> Effect<Action> {
        state.legacyHeaderPattern = nil
        return .run { _ in legacyHeaderPatternClient.clear() }
    }

    /// 프로필 저장을 시작한다. 진행 중이던 재조회 응답은 저장 전 값이라 버려지게 세대를 올린다(#155).
    private static func beginProfileSave(_ state: inout State) {
        state.isLoadingProfile = true
        state.profileSaveGeneration += 1
    }

    /// 앞 저장(또는 처음 불러오기)이 끝나기 전에 새 저장 · 저장 화면 진입을 막을 때의 안내(#155).
    private static func savingInProgressToast() -> Effect<Action> {
        .send(.internal(.showToast(.init(message: "아직 처리 중이에요. 잠시 후 다시 시도해 주세요", status: .info))))
    }

    private static func profileUnavailableToast() -> Effect<Action> {
        .send(.internal(.showToast(.init(message: "프로필 정보를 불러올 수 없어요", status: .error))))
    }

    /// 저장을 시작한 그 스타일 설정 화면이 아직 떠 있는지 — 저장 응답이 올 때 화면을 닫거나 다음 단계로 넘어갈지 정한다.
    private static func isShowingStyleSetting(_ type: MyStyleSettingType, mode: MyStyleSettingFeature.Mode, in state: State) -> Bool {
        guard case let .myStyleSetting(styleState)? = state.destination else { return false }
        return styleState.settingType == type && styleState.mode == mode
    }

    /// 대회 기록을 지우고 프로필을 저장한다 — 수정 화면의 '삭제'(부문 하나)와 대회 시트의 '삭제'(그 대회 부문 전부)가 함께 쓴다.
    private func deleteCompetitions(
        _ entries: [Competition],
        from profile: CommunityProfile,
        state: inout State
    ) -> Effect<Action> {
        guard !state.isLoadingProfile else { return Self.savingInProgressToast() }
        Log.trace("대회 삭제 요청: \(entries.map(\.competitionName))", category: .debug, level: .info)
        let updatedProfile = entries.reduce(profile) { $0.removingCompetition($1) }
        // 지울 기록을 못 찾았으면(그사이 프로필이 바뀜) 저장하지 않는다 — 성공 토스트가 거짓이 된다.
        guard updatedProfile.competitions.count < profile.competitions.count else {
            return .send(.internal(.showToast(.init(message: "삭제하지 못했어요. 다시 시도해 주세요", status: .error))))
        }
        Self.beginProfileSave(&state)
        return .run { send in
            let result = await TaskResult {
                try await saveCompetitions { latest in
                    guard let targets = Self.resolve(entries, in: latest.competitions) else { return nil }
                    return targets.reduce(latest) { $0.removingCompetition($1) }
                }
            }
            switch result {
            case .success(let saved):
                await send(.internal(.competitionDeleted(saved)))
            case .failure(let missing as CompetitionTargetMissing):
                await send(.internal(.competitionTargetMissing(latest: missing.latest, isDelete: true)))
            case .failure(let error):
                Log.trace("Failed to delete competition: \(error)", category: .network, level: .error)
                analyticsClient.logErrorShown(error)
                await send(.internal(.competitionDeleteFailed))
            }
        }
    }

    /// 바꿀 기록을 새로 받은 목록에서 못 찾아 저장하지 않음 — 화면을 맞출 서버 목록을 싣는다(QA A3-1).
    private struct CompetitionTargetMissing: Error {
        let latest: CommunityProfile
    }

    /// 대회 저장은 목록 전체 교체라, 들고 있던 프로필이 낡았으면 그사이 다른 곳(탭 MY · 쌓인 MY · 웹 '내 기록에 남기기')에서
    /// 바꾼 기록을 서버에서 지운다(QA A3-1). 웹 경로처럼 저장 직전에 새로 받아 그 위에 바꾼다.
    /// `change`가 nil이면(바꿀 기록이 새 목록에 없음) 덮어쓰지 않고 `CompetitionTargetMissing`을 던진다.
    private func saveCompetitions(
        _ change: @Sendable (CommunityProfile) -> CommunityProfile?
    ) async throws -> CommunityProfile {
        let latest = try await communityClient.fetchProfile()
        guard let updated = change(latest) else { throw CompetitionTargetMissing(latest: latest) }
        return try await communityClient.updateProfile(updated, .competition)
    }

    /// 대상 기록을 새로 받은 목록에서 찾아 그 목록의 값으로 돌려준다. 하나라도 없으면 nil.
    /// 기록에 식별자가 없어 값으로 찾되, 고정·자리(isPinned · displayOrder)는 다른 곳에서 바뀌었거나 서버가 달리 정리해
    /// 돌려줄 수 있어 견주지 않는다 — 그것만 달라 '못 찾음'으로 저장이 실패하지 않게. 값이 모두 같은 기록을 먼저 고르고,
    /// 같은 기록이 여럿이면 이미 고른 것은 다시 고르지 않아 개수까지 맞춘다.
    private static func resolve(_ targets: [Competition], in competitions: [Competition]) -> [Competition]? {
        var remaining = competitions
        var resolved: [Competition] = []
        for target in targets {
            let unpinned = target.settingPinned(false, displayOrder: nil)
            guard let index = remaining.firstIndex(of: target)
                ?? remaining.firstIndex(where: { $0.settingPinned(false, displayOrder: nil) == unpinned })
            else { return nil }
            resolved.append(remaining.remove(at: index))
        }
        return resolved
    }
}
// MARK: - Sendable Conformances
extension MyProfileFeature.Destination.State: Sendable, Equatable {}
extension MyProfileFeature.Destination.Action: Sendable {}
extension MyProfileFeature.Path.State: Sendable, Equatable {}
extension MyProfileFeature.Path.Action: Sendable {}
extension MyProfileFeature.Sheet.State: Sendable, Equatable {}
extension MyProfileFeature.Sheet.Action: Sendable {}
