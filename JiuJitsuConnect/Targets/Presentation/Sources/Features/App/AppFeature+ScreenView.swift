//
//  AppFeature+ScreenView.swift
//  Presentation
//
//  화면 기록(screen_view, #425): 지금 맨 위에 실제로 보이는 화면을 상태에서 계산한다.
//  뷰의 onAppear를 쓰지 않는 이유 — 탭은 투명도로 숨겨 탭을 바꿔도 onAppear가 오지 않고, 스와이프 백을 하다 취소하면
//  아래 화면이 잠깐 보였다 숨는다. 상태는 스와이프가 끝나야 바뀌므로 취소된 노출은 세지 않는다.
//

import ComposableArchitecture
import Foundation

extension AppFeature {
    /// 맨 위 화면. id는 쌓인 위치(같은 이름의 다른 글로 넘어가도 새 화면으로), event는 남길 기록.
    /// event가 nil이면 이름이 없는 화면(약관 등)이거나 웹이 아직 화면을 알리지 않은 웹뷰 — 기록하지 않지만, 거기서 돌아오면
    /// 아래 화면을 다시 기록한다.
    struct VisibleScreen: Equatable, Sendable {
        let id: String
        let event: AnalyticsEvent?
    }

    enum ScreenView {
        typealias NativeScreen = AnalyticsEvent.NativeScreen

        static func visibleScreen(in state: State) -> VisibleScreen? {
            switch state.destination {
            case let .login(login)?:
                return loginScreen(login, id: "login")
            case let .appTab(appTab)?:
                if let login = appTab.loginCover {
                    return loginScreen(login, id: "loginCover")
                }
                // 첫 홈은 인사 장면이 끝난 뒤에 센다.
                guard !appTab.isGreetingShowing else { return nil }
                switch appTab.selectedTab {
                case .home: return homeScreen(appTab.home)
                case .competition: return competitionScreen(appTab.competition)
                case .myPage: return myScreen(appTab.myPage, id: "my")
                }
            case .splash?, nil:
                return nil
            }
        }

        // MARK: - 로그인 · 가입

        private static func loginScreen(_ login: LoginFeature.State, id: String) -> VisibleScreen {
            if case .termsAgreement? = login.sheet {
                return native(.signupTerms, id: "\(id)/terms")
            }
            if let elementID = login.path.ids.last, let element = login.path[id: elementID] {
                switch element {
                case .nicknameSetting: return native(.signupNickname, id: "\(id)/\(elementID)")
                case .signupComplete: return native(.signupComplete, id: "\(id)/\(elementID)")
                }
            }
            return native(.login, id: id)
        }

        // MARK: - 탭

        private static func homeScreen(_ home: CommunityFeature.State) -> VisibleScreen {
            if let cover = home.detailCover {
                if let elementID = home.coverPath.ids.last, let element = home.coverPath[id: elementID] {
                    return communityPathScreen(element, id: "home/cover/\(elementID)")
                }
                return web(cover.analyticsScreen, id: "home/cover")
            }
            if let elementID = home.path.ids.last, let element = home.path[id: elementID] {
                return communityPathScreen(element, id: "home/\(elementID)")
            }
            return web(home.analyticsScreen, id: "home")
        }

        private static func communityPathScreen(_ element: CommunityFeature.Path.State, id: String) -> VisibleScreen {
            switch element {
            case let .detail(detail): web(detail.analyticsScreen, id: id)
            case .userProfile: native(.userProfile, id: id)
            case let .myProfile(myPage): myScreen(myPage, id: id)
            case .competitionInfo: native(.competitionRecordAdd, id: id)
            }
        }

        private static func competitionScreen(_ competition: CompetitionTabFeature.State) -> VisibleScreen {
            if let elementID = competition.path.ids.last, let element = competition.path[id: elementID] {
                let id = "competition/\(elementID)"
                switch element {
                case let .communityDetail(detail): return web(detail.analyticsScreen, id: id)
                case .userProfile: return native(.userProfile, id: id)
                case .competitionInfo: return native(.competitionRecordAdd, id: id)
                }
            }
            return web(competition.web?.analyticsScreen, id: "competition")
        }

        /// MY는 탭에 들어올 때(또는 홈에 쌓일 때) 센다 — 숨은 채 만들어진 MY는 맨 위가 아니라 세지 않는다.
        /// 축하 · 시트 · 편집 화면이 MY 위를 덮으므로 위에 있는 것부터 본다.
        private static func myScreen(_ myPage: MyProfileFeature.State, id: String) -> VisibleScreen {
            if myPage.promotion != nil {
                return native(.beltPromotion, id: "\(id)/promotion")
            }
            if myPage.imageCropCover != nil {
                return native(.myProfileEdit, section: "photo", id: "\(id)/crop")
            }
            if let sheet = myPage.sheet {
                switch sheet {
                case .beltSetting: return native(.myProfileEdit, section: "belt", id: "\(id)/sheet")
                case .profileImageEdit: return native(.myProfileEdit, section: "photo", id: "\(id)/sheet")
                case .instructorVerification: return native(.myProfileEdit, section: "owner_cert", id: "\(id)/sheet")
                }
            }
            if let destination = myPage.destination {
                let destinationID = "\(id)/destination"
                switch destination {
                case .academySetting: return native(.myProfileEdit, section: "academy", id: destinationID)
                case .nicknameSetting: return native(.myProfileEdit, section: "nickname", id: destinationID)
                case let .myStyleSetting(style):
                    return native(.myProfileEdit, section: styleSection(style.settingType), id: destinationID)
                case .competitionInfo: return native(.competitionRecordAdd, id: destinationID)
                }
            }
            if let elementID = myPage.path.ids.last, let element = myPage.path[id: elementID] {
                let elementPath = "\(id)/\(elementID)"
                switch element {
                case let .communityDetail(detail): return web(detail.analyticsScreen, id: elementPath)
                case .userProfile: return native(.userProfile, id: elementPath)
                case let .settings(settings): return settingsScreen(settings, id: elementPath)
                }
            }
            return native(.myProfile, id: id)
        }

        private static func settingsScreen(_ settings: SettingsFeature.State, id: String) -> VisibleScreen {
            if settings.termsWebCover != nil {
                // 약관 화면은 브리지가 없는 웹이라 웹이 화면을 알리지 않는다 — 이름 없는 화면으로 둔다.
                return VisibleScreen(id: "\(id)/terms", event: nil)
            }
            if case .notificationSetting? = settings.destination {
                return native(.notificationSettings, id: "\(id)/notification")
            }
            return native(.settings, id: id)
        }

        private static func styleSection(_ type: MyStyleSettingType) -> String {
            switch type {
            case .position: "position"
            case .submission: "submission"
            case .technique: "technique"
            }
        }

        // MARK: - 만들기

        private static func native(_ screen: NativeScreen, section: String? = nil, id: String) -> VisibleScreen {
            VisibleScreen(id: id, event: .screenView(screen, section: section))
        }

        /// 웹뷰는 웹이 알린 마지막 화면을 그대로 남긴다.
        private static func web(_ lastScreen: AnalyticsEvent?, id: String) -> VisibleScreen {
            VisibleScreen(id: id, event: lastScreen)
        }
    }
}
