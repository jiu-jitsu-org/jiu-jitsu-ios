//
//  AppFeature+CompetitionRecordAnalytics.swift
//  Presentation
//
//  대회 기록 추가 기록(#454). 수정 화면은 세지 않는다(screen_view로 충분).
//  기록 추가 화면은 MY(탭 · 홈에 쌓인 MY)와 대회 상세 위(대회 탭 · 홈 · 홈 모달)에 뜨므로 그 자리들을 같은 규칙으로 읽는다.
//

import ComposableArchitecture
import Domain
import Foundation

extension AppFeature.Analytics {
    /// 저장 성공만 센다 — 실패(`.failed`)나 그냥 닫으면 이 액션이 오지 않는다.
    func reduceCompetitionRecordEvent(into state: inout State, action: Action) {
        guard
            let (recordAction, record) = Self.competitionRecordAction(of: action, in: state),
            case let .saveFinished(.succeeded(competition)) = recordAction,
            let entry = record.entry.map(Self.recordEntry)
        else { return }
        log(.competitionRecordSave(
            from: entry,
            medal: Self.medal(competition.competitionRank),
            competitionId: competition.competitionId
        ))
    }

    /// 기록 추가 화면이 처음 보였다(그 화면의 첫 screen_view를 남긴 순간). 탭 전환 · 복귀 · 위 화면 닫힘으로 다시 보인 건 세지 않는다.
    func logCompetitionRecordStart(_ state: State) {
        guard let record = Self.topCompetitionRecord(in: state), let entry = record.entry.map(Self.recordEntry) else { return }
        log(.competitionRecordStart(from: entry, competitionId: record.linkedCompetition?.id))
    }

    // MARK: - 화면 찾기

    /// 기록 추가 화면이 받은 액션과 그 화면 상태(액션을 처리한 뒤). 저장 중 탭을 바꿔도 저장한 그 화면을 읽는다.
    private static func competitionRecordAction(
        of action: Action,
        in state: State
    ) -> (CompetitionInfoFeature.Action, CompetitionInfoFeature.State)? {
        guard
            case let .destination(.presented(.appTab(tabAction))) = action,
            case let .appTab(appTab)? = state.destination
        else { return nil }
        switch tabAction {
        case let .myPage(.destination(.presented(.competitionInfo(recordAction)))):
            return myRecord(appTab.myPage).map { (recordAction, $0) }

        case let .competition(.path(.element(id: id, action: .competitionInfo(recordAction)))):
            guard case let .competitionInfo(record)? = appTab.competition.path[id: id] else { return nil }
            return (recordAction, record)

        case let .home(.path(.element(id: id, action: elementAction))):
            return homeRecordAction(elementAction, element: appTab.home.path[id: id])

        case let .home(.coverPath(.element(id: id, action: elementAction))):
            return homeRecordAction(elementAction, element: appTab.home.coverPath[id: id])

        default:
            return nil
        }
    }

    /// 홈 스택은 대회 상세 위의 기록 추가와, 쌓인 MY 위의 기록 추가 둘 다 담는다.
    private static func homeRecordAction(
        _ action: CommunityFeature.Path.Action,
        element: CommunityFeature.Path.State?
    ) -> (CompetitionInfoFeature.Action, CompetitionInfoFeature.State)? {
        switch (action, element) {
        case let (.competitionInfo(recordAction), .competitionInfo(record)?):
            return (recordAction, record)
        case let (.myProfile(.destination(.presented(.competitionInfo(recordAction)))), .myProfile(myPage)?):
            return myRecord(myPage).map { (recordAction, $0) }
        default:
            return nil
        }
    }

    /// 맨 위에 보이는 기록 추가 화면. `ScreenView`가 `competition_record_add`를 내는 자리와 같다.
    private static func topCompetitionRecord(in state: State) -> CompetitionInfoFeature.State? {
        guard case let .appTab(appTab)? = state.destination, appTab.loginCover == nil else { return nil }
        switch appTab.selectedTab {
        case .home:
            let home = appTab.home
            let top = home.detailCover != nil ? home.coverPath.last : home.path.last
            switch top {
            case let .competitionInfo(record)?: return record
            case let .myProfile(myPage)?: return myRecord(myPage)
            default: return nil
            }
        case .competition:
            guard case let .competitionInfo(record)? = appTab.competition.path.last else { return nil }
            return record
        case .myPage:
            return myRecord(appTab.myPage)
        }
    }

    private static func myRecord(_ myPage: MyProfileFeature.State) -> CompetitionInfoFeature.State? {
        guard case let .competitionInfo(record)? = myPage.destination else { return nil }
        return record
    }

    // MARK: - 값

    private static func recordEntry(_ entry: CompetitionInfoFeature.Entry) -> AnalyticsEvent.CompetitionRecordEntry {
        switch entry {
        case .myProfile: .myProfile
        case .divisionAdd: .divisionAdd
        case .competitionDetail: .record
        }
    }

    private static func medal(_ rank: CompetitionRank) -> AnalyticsEvent.Medal {
        switch rank {
        case .gold: .gold
        case .silver: .silver
        case .bronze: .bronze
        case .participation: .participation
        }
    }
}
