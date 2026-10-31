//
//  UserProfileView.swift
//  Presentation
//

import SwiftUI
import ComposableArchitecture
import DesignSystem
import Domain

private enum Metrics {
    // MY와 같은 헤더 위 여백
    static let headerTopSpacing: CGFloat = 68
    // 도장명(없으면 닉네임)과 벨트 카드 사이 — MY와 같은 13
    static let gapAboveCard: CGFloat = 13
    static let horizontalPadding: CGFloat = 20
}

public struct UserProfileView: View {
    @Bindable var store: StoreOf<UserProfileFeature>
    /// 벨트 카드가 헤더 띠 색과 아래 회색의 경계에 정확히 반씩 걸치도록 실제 높이를 잰다
    @State private var beltCardHeight: CGFloat = 88

    public init(store: StoreOf<UserProfileFeature>) {
        self.store = store
    }

    public var body: some View {
        // 바깥 ZStack은 safe area를 지켜 뒤로가기를 상태바 아래에 둔다(헤더만 위로 꽉 채움).
        ZStack(alignment: .topLeading) {
            if let profile = store.profile {
                content(profile)
            } else if store.hasError {
                errorView
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            backButton(onHeader: store.profile != nil)
                .padding(.leading, 8)
                .padding(.top, 2)
        }
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                ToastView(
                    state: toast,
                    onSwipe: { store.send(.view(.toastDismissed), animation: .default) },
                    onButtonTapped: { _ in store.send(.view(.toastDismissed), animation: .default) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, toast.bottomPadding)
            }
        }
        .animation(.default, value: store.toast)
        .sheet(item: $store.scope(state: \.beltPrompt, action: \.beltPrompt)) { promptStore in
            BeltPromptView(store: promptStore)
                // 저장 중에 내려 닫으면 저장이 끊기고 '나중에'로 7일 미뤄진다 — 저장이 끝날 때까지 막는다
                .interactiveDismissDisabled(promptStore.isSaving)
                .presentationDragIndicator(.hidden)
                .presentationDetents([.height(BeltPromptView.contentHeight)])
                .presentationBackground(Color.component.bottomSheet.selected.container.background)
        }
        .background(Color.component.background.default)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear { store.send(.view(.onAppear)) }
        .appAlert(
            isPresented: Binding(
                get: { store.isNotFoundAlertPresented },
                set: { if !$0 { store.send(.view(.notFoundAlertConfirmed)) } }
            ),
            configuration: AppAlertConfiguration(
                title: "존재하지 않는 회원입니다",
                message: "탈퇴했거나 찾을 수 없는 회원이에요.",
                primaryButton: .init(title: "확인") { store.send(.view(.notFoundAlertConfirmed)) },
                secondaryButton: nil
            )
        )
    }

    // MARK: - Content

    private func content(_ profile: CommunityPublicProfile) -> some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    UserProfileHeaderView(
                        nickname: profile.nickname,
                        academyName: profile.academyName,
                        profileImageUrl: profile.profileImageUrl,
                        beltRank: profile.beltRank,
                        safeAreaTop: safeAreaTop,
                        bottomSpacing: Metrics.gapAboveCard + beltCardHeight / 2
                    )

                    UserProfileBeltCardView(
                        beltRank: profile.beltRank,
                        beltStripe: profile.beltStripe,
                        isOwner: profile.isOwner
                    )
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { beltCardHeight = $0 }
                    .padding(.horizontal, Metrics.horizontalPadding)
                    .offset(y: -beltCardHeight / 2)
                    .padding(.bottom, -beltCardHeight / 2)

                    // 비어 있는 칸도 자리는 둔다 — 칸째 숨기면 화면이 텅 비어 보인다.
                    // 비었다는 말은 '안 했다'가 아니라 '아직 안 남겼다'로 적는다(대회는 나갔어도 기록을 안 했을 수 있다).
                    VStack(alignment: .leading, spacing: 36) {
                        UserProfileCompetitionSection(competitions: profile.competitions)

                        MyProfileStyleSectionView(
                            favoritePosition: profile.favoritePosition,
                            favoriteTechnique: profile.favoriteTechnique,
                            favoriteSubmission: profile.favoriteSubmission,
                            onStyleCardTapped: nil
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 36)
                    .padding(.horizontal, Metrics.horizontalPadding)
                    .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var errorView: some View {
        VStack(spacing: 13) {
            Text("잠시 문제가 생겼어요")
                .font(.pretendard.bodyM)
                .foregroundStyle(Color.component.errorState.default.titleText)
            Button {
                store.send(.view(.retryTapped))
            } label: {
                AppButtonConfiguration(title: "재시도", size: .medium)
            }
            .appButtonStyle(.neutral, size: .medium)
            .frame(height: 38)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 웹 상세의 뒤로가기와 같은 자리·크기(아이콘 24 / 터치 40). 띠 색 헤더 위에서는 흰색.
    private func backButton(onHeader: Bool) -> some View {
        Button {
            store.send(.view(.backTapped))
        } label: {
            Assets.Common.Icon.chevronLeft.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(
                    onHeader
                        ? Color.component.list.setting.background
                        : Color.component.header.iconButton
                )
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UserProfileHeaderView

/// 사진 · 닉네임 · 도장 — MY 헤더에서 고치기 버튼을 뺀 모양
private struct UserProfileHeaderView: View {
    let nickname: String
    let academyName: String?
    let profileImageUrl: String?
    let beltRank: BeltRank?
    let safeAreaTop: CGFloat
    let bottomSpacing: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: safeAreaTop + Metrics.headerTopSpacing)

            profileImage
                .frame(width: 90, height: 90)
                .background(Color.component.list.setting.background)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            Text(nickname)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.list.setting.background)
                .frame(height: 29)
                .padding(.top, 12)

            if let academyName {
                Text(academyName)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.list.setting.background.opacity(0.7))
                    .frame(height: 32)
            }

            Spacer().frame(height: bottomSpacing)
        }
        .frame(maxWidth: .infinity)
        .background(beltRank.headerBackgroundColor)
    }

    @ViewBuilder
    private var profileImage: some View {
        if let profileImageUrl, let url = URL(string: profileImageUrl),
           url.scheme == "https" || url.scheme == "http" {
            AsyncImage(url: url) { phase in
                if case let .success(image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    defaultIcon
                }
            }
        } else {
            defaultIcon
        }
    }

    private var defaultIcon: some View {
        Assets.Common.Icon.profile.swiftUIImage
            .resizable()
            .foregroundStyle(Color.component.myProfileHeader.profileImageDefaultIcon)
            .frame(width: 64, height: 64)
    }
}

// MARK: - UserProfileBeltCardView

/// 벨트 + 관장·사범 인증 — MY 벨트 카드와 같은 모양(누를 수 없음). 벨트가 없어도 자리는 둔다.
private struct UserProfileBeltCardView: View {
    let beltRank: BeltRank?
    let beltStripe: BeltStripe?
    let isOwner: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let beltRank {
                beltRank.beltIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primitive.coolGray.cg50)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("벨트")
                    .font(Font.pretendard.labelM)
                    .foregroundStyle(Color.component.beltCard.filled.labelText)

                if let beltRank {
                    Text([beltRank.displayName, beltStripe?.displayName].compactMap { $0 }.joined(separator: " "))
                        .font(Font.pretendard.title3)
                        .foregroundStyle(Color.component.beltCard.filled.contentText)
                } else {
                    Text("아직 등록하지 않았어요")
                        .font(Font.pretendard.title3)
                        .foregroundStyle(Color.component.skillCard.default.titleTextEmpty)
                }
            }

            Spacer(minLength: 8)

            // 역할 값(`OWNER`)이 관장과 사범을 구분하지 않아 MY와 같은 문구를 쓴다
            if isOwner {
                HStack(spacing: 4) {
                    Assets.MyProfile.Icon.badgeCheckLight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text("관장·사범")
                        .font(Font.pretendard.buttonS)
                        .foregroundStyle(Color.semantic.primary.primary)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.component.beltCard.default.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 4)
    }
}

// MARK: - UserProfileCompetitionSection

/// 대회 기록 — MY와 같은 묶음·정렬이지만 고치기(⋯·추가) 없이 읽기만 한다. 기록이 없어도 자리는 둔다.
private struct UserProfileCompetitionSection: View {
    let competitions: [Competition]

    private enum RowMetrics {
        static let medalSize: CGFloat = 18
        static let titleLineHeight: CGFloat = 20
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("대회 기록")
                    .font(.pretendard.title3)
                    .foregroundStyle(Color.component.sectionHeader.title)

                ForEach(CompetitionGroup.medalCounts(of: competitions), id: \.rank) { item in
                    HStack(spacing: 2) {
                        item.rank.medalImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("\(item.count)")
                            .font(.pretendard.bodyS)
                            .foregroundStyle(Color.component.sectionHeader.subTitle)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.rank.displayName) \(item.count)개")
                }
            }
            .frame(height: 32)

            Group {
                if competitions.isEmpty {
                    Text("아직 남긴 대회 기록이 없어요")
                        .font(.pretendard.bodyS)
                        .foregroundStyle(Color.component.sectionHeader.subTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 4) {
                        ForEach(Array(CompetitionGroup.grouped(competitions).enumerated()), id: \.offset) { _, group in
                            row(group)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.component.skillCard.default.bg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private func row(_ group: CompetitionGroup) -> some View {
        let hasDivisions = group.entries.count > 1
        return HStack(alignment: hasDivisions ? .top : .center, spacing: 8) {
            group.representativeRank.medalImage
                .resizable()
                .scaledToFit()
                .frame(width: RowMetrics.medalSize, height: RowMetrics.medalSize)
                .frame(height: hasDivisions ? RowMetrics.titleLineHeight : nil)
                .accessibilityLabel(group.representativeRank.displayName)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.pretendard.custom(weight: .semiBold, size: 14))
                    .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                    .lineLimit(1)
                    .frame(minHeight: RowMetrics.titleLineHeight)

                Text(group.detailText)
                    .font(.pretendard.labelM)
                    .foregroundStyle(Color.component.competitionCard.cardTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if hasDivisions {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(group.entries.enumerated()), id: \.offset) { _, entry in
                            Text(group.divisionMedalText(of: entry))
                                .font(.pretendard.labelM)
                                .foregroundStyle(Color.component.competitionCard.cardTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 40)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("남이 보는 프로필") {
    NavigationStack {
        UserProfileView(
            store: Store(initialState: UserProfileFeature.State(userId: 101)) {
                UserProfileFeature()
            } withDependencies: {
                $0.communityClient = .previewValue
            }
        )
    }
}
