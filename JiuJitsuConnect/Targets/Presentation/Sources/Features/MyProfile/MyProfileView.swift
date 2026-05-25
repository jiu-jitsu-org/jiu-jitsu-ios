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
}

// MARK: - MyProfileView

public struct MyProfileView: View {
    @Bindable var store: StoreOf<MyProfileFeature>
    
    public init(store: StoreOf<MyProfileFeature>) {
        self.store = store
    }
    
    // MARK: - Computed Properties
    
    private var hasStyleInfo: Bool {
        let profile = store.communityProfile
        return profile?.bestPosition != nil ||
               profile?.favoritePosition != nil ||
               profile?.bestSubmission != nil ||
               profile?.favoriteSubmission != nil ||
               profile?.bestTechnique != nil ||
               profile?.favoriteTechnique != nil
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let cardOverlapHeight = store.communityProfile?.academyName != nil
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
                                    .padding(.trailing, 16)
                                    .transition(.opacity)
                                }
                            }
                            .zIndex(0)

                        // 2. 벨트/체급 카드
                        cardView
                            .offset(y: -cardOverlapHeight)
                            .padding(.bottom, -cardOverlapHeight)
                            .zIndex(1)

                        // 3. 콘텐츠 영역
                        contentView
                            .padding(.top, 36)
                            .padding(.horizontal, 20)
                    }

                    // 배경 그라데이션 (스타일 정보 없을 때만)
                    if !hasStyleInfo {
                        backgroundGradient(safeAreaBottom: safeAreaBottom)
                    }
                }
            }
            .scrollDisabled(false)
            .onAppear {
                UIScrollView.appearance().bounces = false
                store.send(.view(.onAppear))
            }
            .background(Color.component.background.default)
            .animation(.easeInOut(duration: 0.15), value: store.isMoreMenuPresented)
            .ignoresSafeArea(edges: .top)
            .navigationDestinations(store: $store)
            .toastOverlay(store: store)
            .sheetPresentation(store: $store)
            .imageCapturePresentation(store: $store)
            .imageCropPresentation(store: $store)
        }
    }

    // MARK: - View Components

    /// 헤더 영역
    private func headerView(safeAreaTop: CGFloat) -> some View {
        MyProfileHeaderView(
            nickname: store.communityProfile?.nickname ?? store.authInfo.userInfo?.nickname ?? "",
            academyName: store.communityProfile?.academyName,
            profileImageUrl: store.communityProfile?.profileImageUrl,
            beltRank: store.communityProfile?.beltRank,
            safeAreaTop: safeAreaTop,
            onNicknameEditTapped: { store.send(.view(.nicknameEditButtonTapped)) },
            onGymInfoTapped: { store.send(.view(.gymInfoButtonTapped)) },
            onMoreButtonTapped: { store.send(.view(.moreButtonTapped)) },
            onProfileImageEditTapped: { store.send(.view(.profileImageEditButtonTapped)) }
        )
    }
    
    /// 벨트/체급 카드
    private var cardView: some View {
        BeltWeightCardView(
            beltRank: store.communityProfile?.beltRank,
            beltStripe: store.communityProfile?.beltStripe,
            weightKg: store.communityProfile?.weightKg,
            isWeightHidden: store.communityProfile?.isWeightHidden ?? false,
            onBeltTapped: { store.send(.view(.beltTapped)) },
            onWeightClassTapped: { store.send(.view(.weightClassTapped)) },
            onWeightVisibilityToggleTapped: { store.send(.view(.weightVisibilityToggleButtonTapped)) },
            onRegisterTapped: { store.send(.view(.registerBeltButtonTapped)) }
        )
    }
    
    /// 콘텐츠 영역 (스타일 + 대회)
    private var contentView: some View {
        VStack(spacing: 0) {
            if hasStyleInfo {
                VStack(alignment: .leading, spacing: 36) {
                    styleSection
                    competitionSection
                }
                .padding(.bottom, 29)
            } else {
                EmptyStyleView(
                    onRegisterStyleTapped: { store.send(.view(.registerStyleButtonTapped)) }
                )
                .padding(.bottom, 18)
            }
        }
    }
    
    /// 스타일 섹션
    private var styleSection: some View {
        MyProfileStyleSectionView(
            bestPosition: store.communityProfile?.bestPosition,
            favoritePosition: store.communityProfile?.favoritePosition,
            bestTechnique: store.communityProfile?.bestTechnique,
            favoriteTechnique: store.communityProfile?.favoriteTechnique,
            bestSubmission: store.communityProfile?.bestSubmission,
            favoriteSubmission: store.communityProfile?.favoriteSubmission,
            onStyleCardTapped: { type, tab in store.send(.view(.styleCardEditTapped(type, tab))) }
        )
    }
    
    /// 대회 섹션
    private var competitionSection: some View {
        MyProfileCompetitionSection(
            competitions: store.communityProfile?.competitions,
            onAddCompetitionTapped: { store.send(.view(.addCompetitionButtonTapped)) },
            onCompetitionDetailTapped: { competition in
                store.send(.view(.competitionDetailTapped(competition)))
            }
        )
    }
    
    /// 배경 그라데이션
    private func backgroundGradient(safeAreaBottom: CGFloat) -> some View {
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
        .offset(y: 58 + safeAreaBottom)
        .allowsHitTesting(false)
        .zIndex(-1)
    }
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
    
    /// 토스트 오버레이
    func toastOverlay(store: StoreOf<MyProfileFeature>) -> some View {
        self.overlay(alignment: .bottom) {
            if let toastState = store.toast {
                ToastView(
                    state: toastState,
                    onSwipe: { store.send(.internal(.toastDismissed), animation: .default) },
                    onButtonTapped: { store.send(.view(.toastButtonTapped($0)), animation: .default) }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, toastState.bottomPadding)
                .animation(.default, value: toastState)
            }
        }
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
                )
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
                    state: \.sheet?.weightClassSetting,
                    action: \.sheet.weightClassSetting
                )
            ) { weightClassSettingStore in
                WeightClassSettingView(store: weightClassSettingStore)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(WeightClassSettingView.contentHeight)])
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
                        .height(InstructorVerificationView.contentHeight)
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
