//
//  AppFeature+SafetyAnalytics.swift
//  Presentation
//
//  신고 · 차단 기록(#428). 앱이 신고 · 차단하는 곳은 다른 회원 프로필의 ⋯ 메뉴뿐이라(#328) 그 화면의 서버 응답만 본다.
//  글 · 댓글 신고(웹이 넘긴 사유 시트), 댓글 ⋮ 차단, 차단한 회원 목록의 해제는 웹이 남긴다(FE #580).
//

import ComposableArchitecture
import Domain

extension AppFeature.Analytics {
    /// 성공 응답 한 곳에서만 센다. 그 뒤 부모로 퍼지는 `blockChanged` · `userBlockChanged`와
    /// 웹뷰로 보내는 `USER_BLOCK_CHANGED`는 같은 차단을 알리는 것이라 보지 않는다.
    func reduceSafetyEvent(action: Action) {
        guard let profileAction = Self.userProfileAction(of: action) else { return }
        // 화면 이름과 입구 값이 같다(사전 "from 값" user_profile).
        let from = AnalyticsEvent.NativeScreen.userProfile.rawValue
        switch profileAction {
        case let .internal(.reportResponse(reason, .success)):
            log(.reportSubmit(reason: .init(serverValue: reason), from: from))

        // 이미 신고한 회원도 신고를 낸 것으로 센다(사전 "이미 신고한 것 포함").
        case let .internal(.reportResponse(reason, .failure(error))):
            guard case .apiError(code: .alreadyReported, _)? = error as? DomainError else { return }
            log(.reportSubmit(reason: .init(serverValue: reason), from: from))

        // 서버 차단은 토글이라 결과가 해제(false)일 수 있다 — 화면이 실패로 안내하므로 세지 않는다.
        case .internal(.blockResponse(_, .success(true))):
            log(.userBlock(blocked: true, from: from))

        case .internal(.unblockResponse(.success)):
            log(.userBlock(blocked: false, from: from))

        default:
            break
        }
    }

    /// 다른 회원 프로필이 쌓이는 곳: 홈 path · coverPath(그 안에 쌓인 MY의 path 포함), 대회 탭 path, MY 탭 path.
    private static func userProfileAction(of action: Action) -> UserProfileFeature.Action? {
        guard case let .destination(.presented(.appTab(appTab))) = action else { return nil }
        switch appTab {
        case let .home(.path(.element(id: _, action: element))),
             let .home(.coverPath(.element(id: _, action: element))):
            switch element {
            case let .userProfile(profile): return profile
            case let .myProfile(myPage): return userProfileAction(inMy: myPage)
            default: return nil
            }
        case let .competition(.path(.element(id: _, action: .userProfile(profile)))):
            return profile
        case let .myPage(myPage):
            return userProfileAction(inMy: myPage)
        default:
            return nil
        }
    }

    private static func userProfileAction(inMy action: MyProfileFeature.Action) -> UserProfileFeature.Action? {
        guard case let .path(.element(id: _, action: .userProfile(profile))) = action else { return nil }
        return profile
    }
}
