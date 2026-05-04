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
    enum Card {
        static let overlapWithButton: CGFloat = 46.49
        static let overlapWithAcademyName: CGFloat = 71
    }
    
    enum Content {
        static let topPadding: CGFloat = 36
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 36
        static let bottomPadding: CGFloat = 29
        static let emptyStyleBottomPadding: CGFloat = 18
    }
    
    enum Gradient {
        static let height: CGFloat = 433
        static let bottomOffset: CGFloat = 58
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
            
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .bottom) {
                    // 메인 콘텐츠
                    VStack(spacing: 0) {
                        // 1. 헤더 영역
                        headerView(safeAreaTop: safeAreaTop)
                            .zIndex(0)
                        
                        // 2. 벨트/체급 카드
                        cardView
                            .offset(y: -cardOverlapHeight)
                            .padding(.bottom, -cardOverlapHeight)
                            .zIndex(1)
                        
                        // 3. 콘텐츠 영역
                        contentView
                            .padding(.top, Metrics.Content.topPadding)
                            .padding(.horizontal, Metrics.Content.horizontalPadding)
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
            .ignoresSafeArea(edges: .top)
            .navigationDestinations(store: $store)
            .toastOverlay(store: store)
            .sheetPresentation(store: $store)
            .overlay(alignment: .bottomTrailing) {
                // TODO: 테스트 기간 동안만 사용 - 운영 배포 전 제거 필요
                debugDataResetButton
            }
        }
    }
    
    // MARK: - Debug Components
    
    /// 디버그용 데이터 리셋 버튼 (테스트 전용)
    private var debugDataResetButton: some View {
        Button {
            store.send(.view(.debugResetDataButtonTapped))
        } label: {
            Text(store.isDataReset ? "📥 내 데이터 불러오기" : "🔄 데이터 리셋 (UI 확인용)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(store.isDataReset ? Color.blue.opacity(0.8) : Color.red.opacity(0.8))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - View Components
    
    /// 헤더 영역
    private func headerView(safeAreaTop: CGFloat) -> some View {
        MyProfileHeaderView(
            nickname: store.isDataReset ? "" : (store.communityProfile?.nickname ?? store.authInfo.userInfo?.nickname ?? ""),
            academyName: store.isDataReset ? nil : store.communityProfile?.academyName,
            profileImageUrl: store.isDataReset ? nil : store.communityProfile?.profileImageUrl,
            beltRank: store.communityProfile?.beltRank,
            safeAreaTop: safeAreaTop,
            onNicknameEditTapped: { store.send(.view(.nicknameEditButtonTapped)) },
            onGymInfoTapped: { store.send(.view(.gymInfoButtonTapped)) }
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
                VStack(alignment: .leading, spacing: Metrics.Content.sectionSpacing) {
                    styleSection
                    competitionSection
                }
                .padding(.bottom, Metrics.Content.bottomPadding)
            } else {
                EmptyStyleView(
                    onRegisterStyleTapped: { store.send(.view(.registerStyleButtonTapped)) }
                )
                .padding(.bottom, Metrics.Content.emptyStyleBottomPadding)
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
            .frame(height: Metrics.Gradient.height)
        }
        .offset(y: Metrics.Gradient.bottomOffset + safeAreaBottom)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(336)])
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.height(340)])
                    .presentationBackground(
                        Color.component.bottomSheet.selected.container.background
                    )
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
