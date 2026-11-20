//
//  AppFeature+ProfileAnalytics.swift
//  Presentation
//
//  프로필 · MY 기록(#429). MY 항목 저장 성공(profile_edit), 띠 저장(belt_update), 띠 묻기 시트(belt_prompt),
//  다른 회원 프로필 열기(profile_view, 화면 기록이 남길 때 같이). 대회 추가는 대회 기록 저장과 같은 자리에서 남긴다.
//  웹의 띠 묻기 · 띠 저장은 웹이 남긴다(FE #582).
//

import ComposableArchitecture
import Domain

extension AppFeature {
    /// 응답을 기다리는 MY 저장. 띠는 저장 전 값으로 변화(change)를, 도장은 추가 · 수정 · 삭제를 정해 둔다.
    enum PendingProfileSave: Equatable, Sendable {
        case belt(previousRank: BeltRank?, previousStripe: BeltStripe?)
        case academy(AnalyticsEvent.ProfileEditAction)
    }

    /// 사진을 고른 방법과, 고를 때 프로필 사진이 있었는지(있었으면 edit, 없었으면 add).
    struct PendingPhoto: Equatable, Sendable {
        let method: AnalyticsEvent.PhotoMethod
        let hadImage: Bool
    }
}

extension AppFeature.Analytics {
    func reduceProfileEvent(into state: inout State, action: Action) {
        if let profileAction = Self.userProfileAction(of: action) {
            reduceBeltPromptEvent(profileAction)
        }
        if let (myAction, myPage) = Self.myProfileAction(of: action, in: state) {
            reduceMyProfileEvent(myAction, myPage: myPage, state: &state)
        }
    }

    // MARK: - 띠 묻기

    private func reduceBeltPromptEvent(_ action: UserProfileFeature.Action) {
        switch action {
        // 띠가 없다는 확인 응답이 곧 시트가 뜬 순간이다.
        case let .internal(.myProfileResponse(.success(profile))) where profile.beltRank == nil:
            log(.beltPrompt(.view))

        case let .beltPrompt(.presented(.internal(.saveResponse(.success(profile))))):
            log(.beltPrompt(.save))
            // 띠가 없는 회원에게만 뜨므로 저장 전 띠는 없다.
            logBeltUpdate(previousRank: nil, previousStripe: nil, saved: profile, from: .beltPrompt)

        case .beltPrompt(.presented(.delegate(.later))), .beltPrompt(.dismiss):
            log(.beltPrompt(.later))

        default:
            break
        }
    }

    // MARK: - MY 저장

    private func reduceMyProfileEvent(_ action: MyProfileFeature.Action, myPage: MyProfileFeature.State, state: inout State) {
        switch action {
        // 띠 · 도장 저장은 시작 액션이 바꾸지 않은 프로필(저장 전 값)을 보고 잡아 둔다.
        case .internal(.saveBeltInfoOnly):
            guard let profile = myPage.communityProfile else { return }
            state.analytics.pendingProfileSave = .belt(previousRank: profile.beltRank, previousStripe: profile.beltStripe)

        case let .internal(.updateProfileSection(.academy, name)):
            guard let profile = myPage.communityProfile else { return }
            let editAction: AnalyticsEvent.ProfileEditAction = if (name ?? "").isEmpty {
                .delete
            } else {
                (profile.academyName ?? "").isEmpty ? .add : .edit
            }
            state.analytics.pendingProfileSave = .academy(editAction)

        case let .internal(.updateProfileResponse(.success(profile))):
            let pending = state.analytics.pendingProfileSave
            state.analytics.pendingProfileSave = nil
            switch pending {
            case let .belt(previousRank, previousStripe):
                log(.profileEdit(.belt, action: previousRank == nil ? .add : .edit))
                logBeltUpdate(previousRank: previousRank, previousStripe: previousStripe, saved: profile, from: .myProfile)
            case let .academy(editAction):
                log(.profileEdit(.academy, action: editAction))
            case nil:
                break
            }

        case .internal(.updateProfileResponse(.failure)):
            state.analytics.pendingProfileSave = nil

        case .destination(.presented(.nicknameSetting(.delegate(.didUpdateNickname)))):
            log(.profileEdit(.nickname, action: .edit))

        // 스타일 첫 설정은 포지션 → 기술 → 서브미션 단계마다 하나씩 남는다.
        case let .internal(.positionSaved(_, mode)):
            log(.profileEdit(.position, action: Self.styleAction(mode)))
        case let .internal(.techniqueSaved(_, mode)):
            log(.profileEdit(.technique, action: Self.styleAction(mode)))
        case let .internal(.submissionSaved(_, mode)):
            log(.profileEdit(.submission, action: Self.styleAction(mode)))

        case .internal(.competitionUpdated):
            log(.profileEdit(.competition, action: .edit))
        case .internal(.competitionDeleted):
            log(.profileEdit(.competition, action: .delete))
        case .internal(.competitionPinUpdated(_, isPinned: true)):
            log(.profileEdit(.competition, action: .pin))
        case .internal(.competitionOrderSaved):
            log(.profileEdit(.competition, action: .reorder))

        // 사진 · 인증 사진을 고른 방법. 카메라는 쓸 수 있는지 확인한 뒤 실제로 띄웠을 때만.
        case .sheet(.presented(.profileImageEdit(.delegate(.didSelectAlbum)))):
            state.analytics.pendingPhoto = .init(method: .album, hadImage: myPage.userProfile?.hasProfileImage ?? false)
        case .internal(.presentImageCaptureSource(.camera)):
            guard myPage.imageCaptureSource == .camera else { return }
            state.analytics.pendingPhoto = .init(method: .camera, hadImage: myPage.userProfile?.hasProfileImage ?? false)

        case let .internal(.profileImageUpdateResponse(.success(profile))):
            guard profile.profileImageUrl != nil else {
                log(.profileEdit(.photo, action: .delete))
                return
            }
            let photo = state.analytics.pendingPhoto
            state.analytics.pendingPhoto = nil
            log(.profileEdit(.photo, action: photo?.hadImage == true ? .edit : .add, method: photo?.method))

        case .internal(.instructorVerificationRequestResponse(.success)):
            log(.profileEdit(.ownerCert, action: .add, method: state.analytics.pendingPhoto?.method))
            state.analytics.pendingPhoto = nil

        case .view(.headerPatternChanged):
            log(.profileEdit(.headerPattern, action: .edit))

        default:
            break
        }
    }

    private func logBeltUpdate(
        previousRank: BeltRank?,
        previousStripe: BeltStripe?,
        saved profile: CommunityProfile,
        from entry: AnalyticsEvent.BeltUpdateEntry
    ) {
        guard let rank = profile.beltRank else { return }
        let stripe = profile.beltStripe ?? BeltStripe.none
        log(.beltUpdate(
            change: Self.beltChange(from: previousRank, previousStripe, to: rank, stripe),
            belt: rank.rawValue.lowercased(),
            stripes: stripe.count,
            from: entry
        ))
    }

    // MARK: - 값

    /// 승급 · 그랄 올림은 MY 축하 장면(`BeltPromotion`)과 같은 기준이다.
    static func beltChange(
        from previousRank: BeltRank?,
        _ previousStripe: BeltStripe?,
        to rank: BeltRank,
        _ stripe: BeltStripe
    ) -> AnalyticsEvent.BeltChange {
        guard
            let previousRank,
            let previousIndex = BeltRank.allCases.firstIndex(of: previousRank),
            let index = BeltRank.allCases.firstIndex(of: rank)
        else { return .firstSet }
        if index > previousIndex { return .promotion }
        if index == previousIndex, stripe.count > (previousStripe ?? BeltStripe.none).count { return .stripeUp }
        return .correction
    }

    private static func styleAction(_ mode: MyStyleSettingFeature.Mode) -> AnalyticsEvent.ProfileEditAction {
        switch mode {
        case .register: .add
        case .edit: .edit
        }
    }

    /// 프로필 바로 전에 남긴 화면 → 사전 "from 값". 웹은 작성자를 누른 곳을 알리지 않아(`OPEN_USER_PROFILE`) 아래 화면으로 정한다.
    /// 화면 이름과 from 값이 다른 것만 바꾸고, 모르는 화면은 싣지 않는다.
    static func profileViewEntry(after previous: AppFeature.VisibleScreen?) -> String? {
        guard case let .string(name)? = previous?.event?.parameters["screen_name"] else { return nil }
        switch name {
        case "home_feed", "post_detail", "balance_detail", "competition_list", "competition_calendar",
             "competition_detail", "my_activity":
            return name
        case "community_search": return "search"
        case "notification_inbox": return "notification"
        case "blocked_users": return "blocked_list"
        default: return nil
        }
    }

    // MARK: - 화면 찾기

    /// MY가 받은 액션과 그 상태(액션을 처리한 뒤). MY 탭과, 홈 path · coverPath에 쌓인 MY.
    private static func myProfileAction(
        of action: Action,
        in state: State
    ) -> (MyProfileFeature.Action, MyProfileFeature.State)? {
        guard
            case let .destination(.presented(.appTab(tabAction))) = action,
            case let .appTab(appTab)? = state.destination
        else { return nil }
        switch tabAction {
        case let .myPage(myAction):
            return (myAction, appTab.myPage)
        case let .home(.path(.element(id: id, action: .myProfile(myAction)))):
            guard case let .myProfile(myPage)? = appTab.home.path[id: id] else { return nil }
            return (myAction, myPage)
        case let .home(.coverPath(.element(id: id, action: .myProfile(myAction)))):
            guard case let .myProfile(myPage)? = appTab.home.coverPath[id: id] else { return nil }
            return (myAction, myPage)
        default:
            return nil
        }
    }
}
