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
    /// event가 nil이면 웹이 아직 화면을 알리지 않은 웹뷰 — 알리는 순간(맨 위에 있으면) 기록한다.
    struct VisibleScreen: Equatable, Sendable {
        let id: String
        let event: AnalyticsEvent?
    }

    enum ScreenView {
        typealias NativeScreen = AnalyticsEvent.NativeScreen

        static let loginCoverID = "loginCover"
        static let tabIDs: Set<String> = ["home", "competition", "my"]

        /// 화면 위치가 속한 탭(id의 첫 마디). 로그인 화면 · 모달은 nil.
        static func tab(of id: String) -> String? {
            let first = String(id.prefix { $0 != "/" })
            return tabIDs.contains(first) ? first : nil
        }

        static func visibleScreen(in state: State) -> VisibleScreen? {
            switch state.destination {
            case let .login(login)?:
                return loginScreen(login, from: AnalyticsEvent.LoginEntry.launch.rawValue, id: "login")
            case let .appTab(appTab)?:
                if let login = appTab.loginCover {
                    // '내 기록에 남기기'(#250)로 연 모달은 그 기록을 기다리는 동안 record.
                    let entry: AnalyticsEvent.LoginEntry? = state.analytics.loginCoverFrom ?? (appTab.pendingCompetitionRecord != nil ? .record : nil)
                    return loginScreen(login, from: entry?.rawValue, id: loginCoverID)
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

        /// from: 로그인 첫 화면은 launch, 로그인 모달은 띄운 곳(안내 창 · 만료 안내 · 웹이 바로 연 모달 · 내 기록에 남기기 · MY · 설정, #426).
        private static func loginScreen(_ login: LoginFeature.State, from: String?, id: String) -> VisibleScreen {
            if case let .termsAgreement(terms)? = login.sheet {
                if let policy = terms.termsWebCover {
                    return policyScreen(policy.url, id: "\(id)/terms/policy")
                }
                return native(.signupTerms, id: "\(id)/terms")
            }
            if let elementID = login.path.ids.last, let element = login.path[id: elementID] {
                switch element {
                case .nicknameSetting: return native(.signupNickname, id: "\(id)/\(elementID)")
                case .signupComplete: return native(.signupComplete, id: "\(id)/\(elementID)")
                }
            }
            return native(.login, from: from, id: id)
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
            // 편집 화면은 항목(section)마다 하나로 센다 — 사진 시트 → 자르기, 인증 시트 → 인증 사진 고르기처럼
            // 한 항목 안에서 시트가 바뀌어도 한 번만 남긴다.
            if myPage.isCompetitionSheetPresented {
                return edit(.competition, id: id)
            }
            if myPage.isPatternSheetPresented {
                return edit(.headerPattern, id: id)
            }
            if myPage.imageCropCover != nil {
                return edit(.photo, id: id)
            }
            if let sheet = myPage.sheet {
                switch sheet {
                case .beltSetting: return edit(.belt, id: id)
                case let .profileImageEdit(imageEdit):
                    return edit(imageEdit.purpose == .instructorVerification ? .ownerCert : .photo, id: id)
                case .instructorVerification: return edit(.ownerCert, id: id)
                }
            }
            if let destination = myPage.destination {
                switch destination {
                case .academySetting: return edit(.academy, id: id)
                case .nicknameSetting: return edit(.nickname, id: id)
                case let .myStyleSetting(style): return edit(styleSection(style.settingType), id: id)
                case .competitionInfo: return native(.competitionRecordAdd, id: "\(id)/destination")
                }
            }
            if let elementID = myPage.path.ids.last, let element = myPage.path[id: elementID] {
                let elementPath = "\(id)/\(elementID)"
                switch element {
                case let .communityDetail(detail): return web(detail.analyticsScreen, id: elementPath)
                case .userProfile: return native(.userProfile, id: elementPath)
                case let .settings(settings): return settingsScreen(settings, id: elementPath)
                case .competitionInfo: return native(.competitionRecordAdd, id: elementPath)
                }
            }
            return native(.myProfile, id: id)
        }

        private static func settingsScreen(_ settings: SettingsFeature.State, id: String) -> VisibleScreen {
            if let policy = settings.termsWebCover {
                return policyScreen(policy.url, id: "\(id)/policy")
            }
            if case .notificationSetting? = settings.destination {
                return native(.notificationSettings, id: "\(id)/notification")
            }
            // 이용 통계 화면(#476)은 사전에 따로 이름이 없다 — 설정과 같은 id로 두어 들어갈 때 settings가 한 번 더 남지 않게 하고,
            // 거기서 연 처리방침만 policy로 남긴다.
            if case let .analyticsSetting(analytics)? = settings.destination, let policy = analytics.termsWebCover {
                return policyScreen(policy.url, id: "\(id)/analytics/policy")
            }
            return native(.settings, id: id)
        }

        private static func edit(_ section: AnalyticsEvent.ProfileSection, id: String) -> VisibleScreen {
            native(.myProfileEdit, section: section.rawValue, id: "\(id)/edit/\(section.rawValue)")
        }

        private static func styleSection(_ type: MyStyleSettingType) -> AnalyticsEvent.ProfileSection {
            switch type {
            case .position: .position
            case .submission: .submission
            case .technique: .technique
            }
        }

        /// 약관 웹뷰는 브리지가 없어 웹이 화면을 알리지 않는다 — 앱이 연 주소로 policy · section을 남긴다.
        private static func policyScreen(_ url: URL, id: String) -> VisibleScreen {
            let section: String? = switch url.lastPathComponent {
            case "terms-of-service": "terms"
            case "privacy-policy": "privacy"
            case "marketing-consent": "marketing"
            // 공지사항(#369)도 같은 약관 웹뷰로 연다. 웹 안에서 상세로 넘어가도 앱은 처음 주소로 남긴다.
            case "notices": "notices"
            default: nil
            }
            return VisibleScreen(id: id, event: .screenView(.policy, section: section, screenClass: "webview"))
        }

        // MARK: - 만들기

        private static func native(
            _ screen: NativeScreen,
            section: String? = nil,
            from: String? = nil,
            id: String
        ) -> VisibleScreen {
            VisibleScreen(id: id, event: .screenView(screen, section: section, from: from))
        }

        /// 웹뷰는 웹이 알린 마지막 화면을 그대로 남긴다.
        private static func web(_ lastScreen: AnalyticsEvent?, id: String) -> VisibleScreen {
            VisibleScreen(id: id, event: lastScreen)
        }
    }
}
