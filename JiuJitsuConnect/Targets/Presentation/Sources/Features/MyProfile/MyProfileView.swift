//
//  MyProfileView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture
import Domain

// MARK: - Layout Metrics

private enum Metrics {
    // 카드가 헤더와 겹치는 높이 — 도장명 유무에 따라 분기 적용
    enum Card {
        static let overlapWithButton: CGFloat = 46.49
        static let overlapWithAcademyName: CGFloat = 71
    }
    // "..." 메뉴 오른쪽 끝을 "..." 버튼에 맞춘다. 옆에 톱니바퀴(32 + 간격 4)가 있으면 그만큼 안쪽으로(#241).
    enum MoreMenu {
        static let trailing: CGFloat = 16
        static let trailingWithSettings: CGFloat = 16 + 32 + 4
    }
}

// MARK: - MyProfileView

public struct MyProfileView: View {
    @Bindable var store: StoreOf<MyProfileFeature>

    // 대회 줄을 눌렀을 때 띄우는 시트(부문 수정 / 부문 추가 / 삭제). 화면 표시용 일시 상태라 Feature로 올리지 않고,
    // 고른 동작은 시트가 다 닫힌 뒤 한다 — 닫히는 중에 입력 화면을 push하거나 알럿을 띄우면 전환이 겹친다.
    @State private var competitionSheet: CompetitionSheetTarget?
    // 탭의 MY면 스크롤을 알려 탭 바를 숨기고 꺼낸다(#267). 쌓인 MY에는 nil이 온다.
    @Environment(\.tabRootScroll) private var tabRootScroll
    @State private var isUserScrolling = false
    @State private var pendingCompetitionAction: (() -> Void)?
    // 삭제 확인 알럿에 띄울 대회(부문별 기록)
    @State private var competitionPendingDelete: [Competition]?

    public init(store: StoreOf<MyProfileFeature>) {
        self.store = store
    }
    
    // MARK: - Computed Properties
    
    /// 화면에는 최애만 보이므로(#118) 특기만 있는 회원은 스타일이 없는 것으로 본다.
    private var hasStyleInfo: Bool {
        let profile = store.communityProfile
        return profile?.favoritePosition != nil ||
               profile?.favoriteSubmission != nil ||
               profile?.favoriteTechnique != nil
    }

    private var hasCompetitionInfo: Bool {
        !(store.communityProfile?.competitions.isEmpty ?? true)
    }

    /// 스타일·대회 정보가 모두 없을 때만 디폴트(빈) 화면을 노출한다.
    /// 스타일이 비어 있어도 대회 정보가 1개 이상이면 빈 스타일 카드 + 대회 UI를 보여준다.
    private var showsDefaultScreen: Bool {
        !hasStyleInfo && !hasCompetitionInfo
    }
    
    // MARK: - Body

    public var body: some View {
        screen
            // 커뮤니티에서 연 MY(#197)는 남의 프로필처럼 왼쪽 위에 뒤로가기를 둔다.
            // 바깥은 safe area를 지켜 뒤로가기가 상태바 아래에 온다(헤더만 위로 꽉 채움).
            // 세로는 같은 줄 오른쪽 "..." 버튼(safe area + 12, 높이 32)과 가운데를 맞춘다 — 터치 40이라 위 8.
            .overlay(alignment: .topLeading) {
                if store.isPushed {
                    backButton
                        .padding(.leading, 8)
                        .padding(.top, 8)
                }
            }
            .toolbar(store.isPushed ? .hidden : .automatic, for: .navigationBar)
            .navigationBarBackButtonHidden(store.isPushed)
    }

    // 남의 프로필(UserProfileView)·웹 상세의 뒤로가기와 같은 자리·크기(아이콘 24 / 터치 40). 띠 색 헤더 위라 흰색.
    private var backButton: some View {
        Button {
            store.send(.view(.backTapped))
        } label: {
            Assets.Common.Icon.chevronLeft.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.component.list.setting.background)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var screen: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            // 비로그인 머리(#242)는 도장명이 있을 때와 같은 높이라 같은 만큼 겹친다.
            let cardOverlapHeight = store.authInfo.isGuest || store.communityProfile?.academyName != nil
                ? Metrics.Card.overlapWithAcademyName
                : Metrics.Card.overlapWithButton

            // 메뉴는 헤더 위 overlay로 부착해 스크롤에 따라 함께 이동한다.
            // ("..." 버튼 탭으로만 토글되며 외부 탭 dismiss는 없음)
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .bottom) {
                    // 메인 콘텐츠
                    VStack(spacing: 0) {
                        // 1. 헤더 영역 — "..." 메뉴는 헤더 우상단에 오버레이
                        headerView(safeAreaTop: safeAreaTop)
                            .overlay(alignment: .topTrailing) {
                                if store.isMoreMenuPresented {
                                    MyProfileMoreMenuView(
                                        onInstructorVerificationTapped: {
                                            store.send(.view(.instructorVerificationMenuTapped))
                                        }
                                    )
                                    // "..." 버튼(safeAreaTop + 12 ~ safeAreaTop + 44) 하단에 간격 없이 붙임
                                    // 우측은 버튼 trailing(16)과 동일하게 정렬
                                    .padding(.top, safeAreaTop + 44)
                                    .padding(.trailing, store.isPushed ? Metrics.MoreMenu.trailing : Metrics.MoreMenu.trailingWithSettings)
                                    .transition(.opacity)
                                }
                            }
                            .zIndex(0)

                        // 2. 벨트 카드
                        cardView
                            .offset(y: -cardOverlapHeight)
                            .padding(.bottom, -cardOverlapHeight)
                            .zIndex(1)

                        // 3. 커뮤니티 활동 진입 줄 — 내 글·댓글로 가는 길이라 프로필 내용(대회·기술)과 섞지 않고,
                        //    헤더에 누르는 글자를 늘리지 않으면서 내리지 않아도 보이는 벨트 카드 바로 아래 (#44, #117)
                        //    비로그인은 내 글이 없어 숨긴다(#242).
                        if !store.authInfo.isGuest {
                            MyProfileCommunityActivityRow(
                                onTapped: { store.send(.view(.communityActivityTapped)) }
                            )
                            .padding(.top, 12)
                            .padding(.horizontal, 20)
                        }

                        // 4. 콘텐츠 영역 — 남에게 보여 줄 정보를 위로: 대회 기록 → 최애 기술 (#117)
                        contentView
                            .padding(.top, 36)
                            .padding(.horizontal, 20)
                    }

                    // 배경 그라데이션 (디폴트 화면일 때만)
                    if showsDefaultScreen {
                        // 화면 맨 아래까지 내린다. 탭의 MY는 아래 안전 영역에 떠 있는 탭 바 자리까지 들어 있다(#267).
                        backgroundGradient(bottomOffset: safeAreaBottom)
                    }
                }
            }
            .scrollDisabled(false)
            .onScrollPhaseChange { _, phase in
                isUserScrolling = phase == .interacting || phase == .decelerating
            }
            .onScrollGeometryChange(for: ScrollReport.self) { geometry in
                ScrollReport(
                    offsetY: geometry.contentOffset.y + geometry.contentInsets.top,
                    maxOffsetY: geometry.contentSize.height + geometry.contentInsets.top
                        + geometry.contentInsets.bottom - geometry.containerSize.height
                )
            } action: { _, report in
                tabRootScroll?.report(report.offsetY, report.maxOffsetY, isUserScrolling)
            }
            .onAppear {
                UIScrollView.appearance().bounces = false
                store.send(.view(.onAppear))
            }
            .background(Color.component.background.default)
            .animation(.easeInOut(duration: 0.15), value: store.isMoreMenuPresented)
            .ignoresSafeArea(edges: .top)
            .navigationDestinations(store: $store)
            .uploadingOverlay(isPresented: store.isUploadingInstructorVerification)
            .toastOverlay(store: store)
            .beltPromotionPresentation(store: store)
            // picker 프레젠테이션은 시트 content 안쪽에서 적용된다
            // (iOS는 한 presenter에서 sheet + fullScreenCover 동시 제시를 막으므로
            //  picker가 시트 위에 stacking되려면 시트 자체가 presenter여야 한다)
            .sheetPresentation(store: $store)
            .sheet(item: $competitionSheet, onDismiss: sendPendingCompetitionAction) { target in
                CompetitionActionSheetView(
                    entries: target.entries,
                    onPinToggled: {
                        closeCompetitionSheet { store.send(.view(.competitionPinToggled(target.entries))) }
                    },
                    onDivisionTapped: { entry in
                        closeCompetitionSheet { store.send(.view(.competitionDetailTapped(entry))) }
                    },
                    onAddDivisionTapped: {
                        closeCompetitionSheet { store.send(.view(.addDivisionTapped(target.entries))) }
                    },
                    onDeleteTapped: {
                        closeCompetitionSheet { competitionPendingDelete = target.entries }
                    },
                    onCancelTapped: { competitionSheet = nil }
                )
                .presentationDragIndicator(.hidden)
                .presentationDetents([
                    .height(CompetitionActionSheetView.contentHeight(divisionCount: target.entries.count))
                ])
                .presentationBackground(Color.component.bottomSheet.selected.container.background)
            }
            .appAlert(
                isPresented: Binding(
                    get: { competitionPendingDelete != nil },
                    set: { if !$0 { competitionPendingDelete = nil } }
                ),
                configuration: competitionDeleteAlertConfiguration
            )
            .imageCropPresentation(store: $store)
        }
    }

    // MARK: - View Components

    /// 헤더 영역
    private func headerView(safeAreaTop: CGFloat) -> some View {
        MyProfileHeaderView(
            nickname: store.communityProfile?.nickname ?? store.authInfo.userInfo?.nickname ?? "",
            academyName: store.communityProfile?.academyName,
            // 프로필 이미지는 user-level 데이터(GET /api/user/profile) — 커뮤니티 헤더 버튼과 같은 출처
            profileImageUrl: store.userProfile?.profileImageUrl,
            beltRank: store.communityProfile?.beltRank,
            safeAreaTop: safeAreaTop,
            isOwner: store.userProfile?.userRole == .owner,
            isGuest: store.authInfo.isGuest,
            // 설정은 탭의 MY에서만 연다. 커뮤니티에서 쌓아 연 MY(#197)는 뒤로가기로 돌아가는 화면이다.
            showsSettingsButton: !store.isPushed,
            // Optimistic Update — 업로드/삭제 진행 중 헤더 이미지 미리보기·로딩 표시
            pendingProfileImageData: store.pendingProfileImageData,
            isProfileImageDeleting: store.isProfileImageDeleting,
            isProfileImageBusy: store.isLoadingProfile
                && (store.pendingProfileImageData != nil || store.isProfileImageDeleting),
            onNicknameEditTapped: { store.send(.view(.nicknameEditButtonTapped)) },
            onGymInfoTapped: { store.send(.view(.gymInfoButtonTapped)) },
            onMoreButtonTapped: { store.send(.view(.moreButtonTapped)) },
            onProfileImageEditTapped: { store.send(.view(.profileImageEditButtonTapped)) },
            onSettingsTapped: { store.send(.view(.settingsButtonTapped)) }
        )
    }
    
    /// 벨트 카드
    private var cardView: some View {
        BeltCardView(
            beltRank: store.communityProfile?.beltRank,
            beltStripe: store.communityProfile?.beltStripe,
            registerButtonTitle: store.authInfo.isGuest ? "로그인하기" : "벨트 등록하기",
            onBeltTapped: { store.send(.view(.beltTapped)) },
            onRegisterTapped: {
                store.send(store.authInfo.isGuest ? .view(.guestLoginTapped) : .view(.registerBeltButtonTapped))
            }
        )
    }
    
    /// 콘텐츠 영역 (대회 + 스타일)
    private var contentView: some View {
        VStack(spacing: 0) {
            if showsDefaultScreen {
                EmptyStyleView(
                    showsRegisterButton: !store.authInfo.isGuest,
                    onRegisterStyleTapped: { store.send(.view(.registerStyleButtonTapped)) }
                )
                .padding(.bottom, 18)
            } else {
                VStack(alignment: .leading, spacing: 36) {
                    competitionSection
                    styleSection
                }
                .padding(.bottom, 29)
            }
        }
    }
    
    /// 스타일 섹션
    private var styleSection: some View {
        MyProfileStyleSectionView(
            favoritePosition: store.communityProfile?.favoritePosition,
            favoriteTechnique: store.communityProfile?.favoriteTechnique,
            favoriteSubmission: store.communityProfile?.favoriteSubmission,
            onStyleCardTapped: { store.send(.view(.styleCardEditTapped($0))) }
        )
    }
    
    /// 대회 섹션
    private var competitionSection: some View {
        MyProfileCompetitionSection(
            competitions: store.communityProfile?.competitions,
            medalCount: store.communityProfile?.medalCount ?? .zero,
            onAddCompetitionTapped: { store.send(.view(.addCompetitionButtonTapped)) },
            onCompetitionTapped: { entries in
                // 이전 시트가 닫힘 신호 없이 사라졌을 때 남은 동작이 이번 시트를 닫을 때 실행되지 않게 비운다.
                pendingCompetitionAction = nil
                competitionSheet = CompetitionSheetTarget(entries: entries)
            },
            onCompetitionsReordered: { store.send(.view(.competitionsReordered($0))) },
            isSaving: store.isLoadingProfile
        )
    }

    private func closeCompetitionSheet(then action: @escaping () -> Void) {
        pendingCompetitionAction = action
        competitionSheet = nil
    }

    private func sendPendingCompetitionAction() {
        guard let action = pendingCompetitionAction else { return }
        pendingCompetitionAction = nil
        action()
    }

    /// 대회 삭제 확인 — 여러 부문이면 부문까지 함께 지워진다는 걸 알린다.
    private var competitionDeleteAlertConfiguration: AppAlertConfiguration {
        let entries = competitionPendingDelete ?? []
        let title = CompetitionGroup.grouped(entries).first?.titleWithYear ?? ""
        return AppAlertConfiguration(
            title: "대회 기록을 삭제할까요?",
            message: entries.count > 1 ? "\(title)의 부문 \(entries.count)개가 함께 삭제돼요." : "\(title) 기록이 삭제돼요.",
            primaryButton: .init(
                title: "삭제",
                style: .destructive,
                action: {
                    competitionPendingDelete = nil
                    store.send(.view(.deleteCompetitionConfirmed(entries)))
                }
            ),
            secondaryButton: .init(
                title: "취소",
                style: .neutral,
                action: { competitionPendingDelete = nil }
            )
        )
    }
    
    /// 배경 그라데이션
    private func backgroundGradient(bottomOffset: CGFloat) -> some View {
        VStack {
            Spacer()
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "0090FF").opacity(0), location: 0),
                    .init(color: Color(hex: "0090FF").opacity(0.4), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 433)
        }
        .offset(y: bottomOffset)
        .allowsHitTesting(false)
        .zIndex(-1)
    }
}

/// 스크롤 위치를 탭 바 숨김에 알릴 때 쓰는 값(#267).
private struct ScrollReport: Equatable {
    let offsetY: CGFloat
    let maxOffsetY: CGFloat
}

// MARK: - View Modifiers

private extension View {
    /// 네비게이션 목적지 처리
    @ViewBuilder
    func navigationDestinations(store: Bindable<StoreOf<MyProfileFeature>>) -> some View {
        self
            .navigationDestination(
                item: store.scope(
                    state: \.destination?.academySetting,
                    action: \.destination.academySetting
                )
            ) { academySettingStore in
                MyAcademySettingView(store: academySettingStore)
            }
            .navigationDestination(
                item: store.scope(
                    state: \.destination?.nicknameSetting,
                    action: \.destination.nicknameSetting
                )
            ) { nicknameSettingStore in
                NicknameSettingView(store: nicknameSettingStore)
            }
            .navigationDestination(
                item: store.scope(
                    state: \.destination?.myStyleSetting,
                    action: \.destination.myStyleSetting
                )
            ) { myStyleSettingStore in
                MyStyleSettingView(store: myStyleSettingStore)
            }
            .navigationDestination(
                item: store.scope(
                    state: \.destination?.competitionInfo,
                    action: \.destination.competitionInfo
                )
            ) { competitionInfoStore in
                CompetitionInfoView(store: competitionInfoStore)
            }
    }
    
    /// 관장 사범 인증 업로드 중 화면 딤 + 인디케이터. 터치를 받아 하위 조작(메뉴 재진입 등)을 막는다.
    func uploadingOverlay(isPresented: Bool) -> some View {
        self.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.4)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .tint(.white)
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isPresented)
    }

    /// 띠나 그랄을 올려 저장했을 때 탭 바까지 덮는 축하 장면(#278, #286). 나타나고 사라지는 움직임은 장면 안에서 직접 한다.
    func beltPromotionPresentation(store: StoreOf<MyProfileFeature>) -> some View {
        self.fullScreenCover(
            item: Binding(
                get: { store.promotion },
                set: { if $0 == nil { store.send(.view(.beltPromotionDismissed)) } }
            )
        ) { promotion in
            BeltPromotionView(promotion: promotion) {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                store.send(.view(.beltPromotionDismissed), transaction: transaction)
            }
        }
    }

    /// 토스트 오버레이
    func toastOverlay(store: StoreOf<MyProfileFeature>) -> some View {
        self.toast(
            store.toast,
            onSwipe: { store.send(.internal(.toastDismissed)) },
            onButtonTapped: { store.send(.view(.toastButtonTapped($0))) }
        )
    }
    
    /// 시트 프레젠테이션
    ///
    /// 모든 시트는 본문에 `.ignoresSafeArea(.container, edges: .bottom)`를 적용해
    /// home indicator safe area를 시트 자기 영역으로 흡수한다. 따라서 detent는
    /// 본문 자연 높이(`contentHeight`)와 정확히 동일하게 잡고, 별도 safe area
    /// buffer를 더하지 않는다.
    @ViewBuilder
    func sheetPresentation(store: Bindable<StoreOf<MyProfileFeature>>) -> some View {
        self
            .sheet(
                item: store.scope(
                    state: \.sheet?.beltSetting,
                    action: \.sheet.beltSetting
                ),
                onDismiss: {
                    // 다 내려간 뒤에야 승급 축하 덮개를 띄울 수 있다(#278). 제자리에서 나타나게 등장 움직임은 끈다.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    store.wrappedValue.send(.view(.beltSheetDidDismiss), transaction: transaction)
                }
            ) { beltSettingStore in
                BeltSettingView(store: beltSettingStore)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(BeltSettingView.contentHeight)])
                    .presentationBackground(
                        Color.component.bottomSheet.selected.container.background
                    )
            }
            .sheet(
                item: store.scope(
                    state: \.sheet?.profileImageEdit,
                    action: \.sheet.profileImageEdit
                )
            ) { profileImageEditStore in
                ProfileImageEditView(store: profileImageEditStore)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([
                        .height(
                            ProfileImageEditView.contentHeight(
                                canDelete: profileImageEditStore.canDelete
                            )
                        )
                    ])
                    .presentationBackground(
                        Color.component.bottomSheet.selected.container.background
                    )
                    // 시트 위에 카메라/앨범 picker stacking — 시트가 자체 presenter가
                    // 되어야 iOS의 sheet + fullScreenCover 동시 제시 제약을 우회할 수 있다
                    .imageCapturePresentation(store: store)
            }
            .sheet(
                item: store.scope(
                    state: \.sheet?.instructorVerification,
                    action: \.sheet.instructorVerification
                )
            ) { instructorVerificationStore in
                InstructorVerificationView(store: instructorVerificationStore)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([
                        .height(InstructorVerificationView.contentHeight(
                            hasImage: instructorVerificationStore.existingImageUrl != nil,
                            isRejected: instructorVerificationStore.isRejected,
                            isApproved: instructorVerificationStore.isApproved,
                            hasContact: instructorVerificationStore.contactEmail != nil
                        ))
                    ])
                    .presentationBackground(
                        Color.component.bottomSheet.selected.container.background
                    )
            }
    }

    /// 카메라/앨범 풀스크린 픽커 프레젠테이션
    @ViewBuilder
    func imageCapturePresentation(store: Bindable<StoreOf<MyProfileFeature>>) -> some View {
        let isCameraPresented = Binding<Bool>(
            get: { store.wrappedValue.imageCaptureSource == .camera },
            set: { newValue in
                if !newValue {
                    store.wrappedValue.send(.view(.imagePickerCancelled))
                }
            }
        )
        let isLibraryPresented = Binding<Bool>(
            get: { store.wrappedValue.imageCaptureSource == .photoLibrary },
            set: { newValue in
                if !newValue {
                    store.wrappedValue.send(.view(.imagePickerCancelled))
                }
            }
        )

        self
            .fullScreenCover(isPresented: isCameraPresented) {
                CameraPickerView(
                    onPicked: { image in
                        if let data = image.jpegData(compressionQuality: 0.95) {
                            store.wrappedValue.send(.view(.imagePicked(data)))
                        } else {
                            store.wrappedValue.send(.view(.imagePickerCancelled))
                        }
                    },
                    onCancel: {
                        store.wrappedValue.send(.view(.imagePickerCancelled))
                    }
                )
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: isLibraryPresented) {
                PhotoLibraryPickerView(
                    onPicked: { image in
                        if let data = image.jpegData(compressionQuality: 0.95) {
                            store.wrappedValue.send(.view(.imagePicked(data)))
                        } else {
                            store.wrappedValue.send(.view(.imagePickerCancelled))
                        }
                    },
                    onCancel: {
                        store.wrappedValue.send(.view(.imagePickerCancelled))
                    }
                )
                .ignoresSafeArea()
            }
    }

    /// 1:1 크롭 풀스크린 프레젠테이션
    @ViewBuilder
    func imageCropPresentation(store: Bindable<StoreOf<MyProfileFeature>>) -> some View {
        self.fullScreenCover(
            item: store.scope(state: \.imageCropCover, action: \.imageCropCover)
        ) { cropStore in
            ProfileImageCropView(store: cropStore)
        }
    }
}

// MARK: - Previews

#Preview("기본 - 대회 정보 없음") {
    MyProfileView(
        store: Store(
            initialState: MyProfileFeature.State(
                authInfo: AuthInfo(
                    accessToken: "sample_token",
                    refreshToken: "sample_refresh",
                    tempToken: nil,
                    isNewUser: false,
                    userInfo: AuthInfo.UserInfo(
                        userId: 1,
                        email: "user@example.com",
                        nickname: "주짓수 러버",
                        profileImageUrl: nil,
                        snsProvider: "apple",
                        deactivatedWithinGrace: false
                    )
                )
            )
        ) {
            MyProfileFeature()
        }
    )
}
#Preview("대회 정보 있음 - 다양한 메달") {
    MyProfileView(
        store: Store(
            initialState: MyProfileFeature.State(
                authInfo: AuthInfo(
                    accessToken: "sample_token",
                    refreshToken: "sample_refresh",
                    tempToken: nil,
                    isNewUser: false,
                    userInfo: AuthInfo.UserInfo(
                        userId: 1,
                        email: "user@example.com",
                        nickname: "주짓수 러버",
                        profileImageUrl: nil,
                        snsProvider: "apple",
                        deactivatedWithinGrace: false
                    )
                ),
                communityProfile: CommunityProfile(
                    nickname: "주짓수 러버",
                    profileImageUrl: nil,
                    beltRank: .blue,
                    beltStripe: .two,
                    gender: .male,
                    weightKg: 75.0,
                    academyName: "그라시에 바하 주짓수",
                    competitions: [
                        Competition(
                            competitionYear: 2025,
                            competitionMonth: 11,
                            competitionName: "2025 서울 오픈 챔피언십",
                            competitionRank: .gold
                        ),
                        Competition(
                            competitionYear: 2025,
                            competitionMonth: 8,
                            competitionName: "전국 주짓수 선수권 대회",
                            competitionRank: .silver
                        ),
                        Competition(
                            competitionYear: 2025,
                            competitionMonth: 5,
                            competitionName: "부산 국제 주짓수 대회",
                            competitionRank: .bronze
                        ),
                        Competition(
                            competitionYear: 2025,
                            competitionMonth: 3,
                            competitionName: "강남 주짓수 토너먼트",
                            competitionRank: .participation
                        )
                    ],
                    bestSubmission: .chokes,
                    favoriteSubmission: .armLocks,
                    bestTechnique: .guardPasses,
                    favoriteTechnique: .sweeps,
                    bestPosition: .top,
                    favoritePosition: .guard,
                    isWeightHidden: false,
                    isOwner: true
                )
            )
        ) {
            MyProfileFeature()
        }
    )
}

#Preview("대회 정보 1개") {
    MyProfileView(
        store: Store(
            initialState: MyProfileFeature.State(
                authInfo: AuthInfo(
                    accessToken: "sample_token",
                    refreshToken: "sample_refresh",
                    tempToken: nil,
                    isNewUser: false,
                    userInfo: AuthInfo.UserInfo(
                        userId: 1,
                        email: "user@example.com",
                        nickname: "주짓수 초보",
                        profileImageUrl: nil,
                        snsProvider: "apple",
                        deactivatedWithinGrace: false
                    )
                ),
                communityProfile: CommunityProfile(
                    nickname: "주짓수 초보",
                    profileImageUrl: nil,
                    beltRank: .white,
                    beltStripe: BeltStripe.none,
                    gender: .female,
                    weightKg: 58.0,
                    academyName: "주짓수 도장",
                    competitions: [
                        Competition(
                            competitionYear: 2026,
                            competitionMonth: 1,
                            competitionName: "신년 주짓수 페스티벌",
                            competitionRank: .gold
                        )
                    ],
                    bestSubmission: .legLocks,
                    favoriteSubmission: .chokes,
                    bestTechnique: .escapes,
                    favoriteTechnique: .takedowns,
                    bestPosition: .guard,
                    favoritePosition: .top,
                    isWeightHidden: false,
                    isOwner: true
                )
            )
        ) {
            MyProfileFeature()
        }
    )
}

// MARK: - CompetitionSheetTarget

/// 대회 시트에 띄울 대회(부문별 기록) — sheet(item:)용 식별자를 붙인다.
private struct CompetitionSheetTarget: Identifiable {
    let id = UUID()
    let entries: [Competition]
}
