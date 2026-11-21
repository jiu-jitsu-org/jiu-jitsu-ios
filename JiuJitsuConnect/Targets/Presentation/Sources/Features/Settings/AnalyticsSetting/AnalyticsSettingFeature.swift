//
//  AnalyticsSettingFeature.swift
//  Presentation
//
//  설정 → 이용 통계 화면(#476). 수집 끄기 스위치를 설정 목록에서 한 단계 아래로 옮겨,
//  목록에서 한 번 눌러 꺼지지 않게 하고 설명 · 처리방침을 같이 보여 준다.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct AnalyticsSettingFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        var isEnabled: Bool
        // 설정의 '개인정보 처리 방침'과 같은 주소. WEB_URL이 없으면 nil — 링크를 눌러도 아무 일 없다.
        let privacyPolicyURL: URL?

        // 이 화면 위에서 띄운다. 스택 아래에 있는 설정 화면이 띄우면 보이지 않는 화면이 표시를 맡게 된다.
        @Presents var termsWebCover: TermsWebViewFeature.State?

        public init(isEnabled: Bool, privacyPolicyURL: URL?) {
            self.isEnabled = isEnabled
            self.privacyPolicyURL = privacyPolicyURL
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case termsWebCover(PresentationAction<TermsWebViewFeature.Action>)

        public enum ViewAction: Sendable {
            case backTapped
            case toggled(Bool)
            case privacyPolicyTapped
        }
    }

    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.backTapped):
                return .run { _ in await self.dismiss() }

            case let .view(.toggled(isEnabled)):
                // 끄면 바로 수집을 멈추고, 다시 켤 때까지 다음 실행에도 꺼 둔다(#423).
                state.isEnabled = isEnabled
                analyticsClient.setCollectionEnabled(isEnabled)
                return .none

            case .view(.privacyPolicyTapped):
                guard let url = state.privacyPolicyURL else { return .none }
                state.termsWebCover = TermsWebViewFeature.State(url: url)
                return .none

            case .termsWebCover(.presented(.delegate(.didClose))):
                state.termsWebCover = nil
                return .none

            case .termsWebCover:
                return .none
            }
        }
        .ifLet(\.$termsWebCover, action: \.termsWebCover) {
            TermsWebViewFeature()
        }
    }
}
