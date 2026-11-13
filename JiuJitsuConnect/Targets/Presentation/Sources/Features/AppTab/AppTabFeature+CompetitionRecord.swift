//
//  AppTabFeature+CompetitionRecord.swift
//  Presentation
//
//  대회 상세의 '내 기록에 남기기'(#250)를 대회 탭·홈(#304) 어디서 열었든 같은 흐름으로 처리한다.
//  기록 추가는 상세를 연 그 탭 스택에 쌓고, 저장 결과는 그 입력 화면에 돌려준다.
//

import ComposableArchitecture
import CoreKit
import Domain
import Foundation

extension AppTabFeature {
    /// 비로그인으로 누른 '내 기록에 남기기' — 어느 대회를 어느 탭(대회·홈)에 쌓인 상세에서 눌렀는지.
    struct PendingCompetitionRecord: Equatable {
        let payload: OpenCompetitionRecordPayload
        let tab: Tab
    }

    /// 대회 기록 추가가 쌓인 스택(#250, #304). 저장 결과를 그 입력 화면에 돌려줄 때 쓴다.
    public enum CompetitionRecordStack: Sendable, Equatable {
        case competition
        case home
        case homeCover
    }

    /// 대회 상세의 '내 기록에 남기기'(#250, #304). 웹은 비로그인이면 로그인 안내를 대신 보내지만, 웹과 앱의 로그인 상태가
    /// 어긋났을 때를 대비해 앱도 막는다 — 로그인 모달을 띄우고, 로그인하면 이 대회로 상세를 연 그 탭에 이어서 연다.
    static func requestCompetitionRecord(
        _ payload: OpenCompetitionRecordPayload,
        from tab: Tab,
        into state: inout State
    ) -> Effect<Action> {
        guard !state.authInfo.isGuest else {
            state.pendingCompetitionRecord = PendingCompetitionRecord(payload: payload, tab: tab)
            state.pendingWebLoginTab = tab
            // 연타로 로그인 창이 이미 떠 있으면 새로 만들지 않는다(입력 중인 로그인이 초기화되지 않게).
            guard state.loginCover == nil else { return .none }
            return .send(.internal(.showLoginModal))
        }
        pushCompetitionRecord(payload, from: tab, into: &state)
        return .none
    }

    /// 대회 상세 위에 대회명·연도를 채운 기록 추가를 쌓는다(#250). 띠·체급 기본값은 MY와 같이 프로필에서 가져온다.
    /// 상세를 연 탭의 스택에 쌓아 저장·뒤로가기 뒤 그 상세로 돌아오게 한다(#304). 연타·중복 전달로 겹쳐 쌓이지 않게 한다.
    static func pushCompetitionRecord(_ payload: OpenCompetitionRecordPayload, from tab: Tab, into state: inout State) {
        let profile = state.myPage.communityProfile
        let record = CompetitionInfoFeature.State(
            prefilledName: payload.name,
            year: payload.year,
            competitionId: payload.competitionId,
            currentBelt: profile?.beltRank,
            recentWeightLimit: profile?.competitions.recentWeightLimit
        )
        switch tab {
        case .home:
            CommunityFeature.pushCompetitionRecord(record, into: &state.home)
        case .competition, .myPage:
            if case .competitionInfo? = state.competition.path.last { return }
            state.competition.path.append(.competitionInfo(record))
        }
    }

    /// 기록 추가 저장(#250). MY와 같이 프로필의 대회 목록을 통째로 다시 저장한다.
    /// MY가 들고 있는 프로필은 앱을 켤 때 받은 값일 수 있어(로그인 직후엔 아직 받는 중), 저장 직전에 늘 새로 받아
    /// 그 위에 더한다 — 그 사이 다른 곳에서 남긴 기록이 지워지지 않게.
    /// 저장 결과를 보고 완료 화면('부문 추가')으로 넘어가야 하므로 입력 화면은 닫지 않는다.
    func saveCompetitionRecord(_ competition: Competition, id: StackElementID, stack: CompetitionRecordStack) -> Effect<Action> {
        .run { [communityClient] send in
            let result = await TaskResult {
                let profile = try await communityClient.fetchProfile()
                return try await communityClient.updateProfile(profile.addingCompetition(competition), .competition)
            }
            await send(.internal(.competitionRecordSaved(id: id, stack: stack, competition: competition, result)))
        }
    }

    /// 저장 결과를 기록 추가 입력 화면에 돌려준다. 저장 중 입력 화면이 닫혔으면(예외적) 돌려줄 곳이 없다.
    static func finishCompetitionRecordSave(
        _ result: CompetitionInfoFeature.SaveResult,
        id: StackElementID,
        stack: CompetitionRecordStack,
        state: State
    ) -> Effect<Action> {
        let action = CompetitionInfoFeature.Action.saveFinished(result)
        switch stack {
        case .competition:
            guard case .competitionInfo? = state.competition.path[id: id] else { return .none }
            return .send(.competition(.path(.element(id: id, action: .competitionInfo(action)))))
        case .home:
            guard case .competitionInfo? = state.home.path[id: id] else { return .none }
            return .send(.home(.path(.element(id: id, action: .competitionInfo(action)))))
        case .homeCover:
            guard case .competitionInfo? = state.home.coverPath[id: id] else { return .none }
            return .send(.home(.coverPath(.element(id: id, action: .competitionInfo(action)))))
        }
    }
}
