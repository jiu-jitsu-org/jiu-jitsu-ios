//
//  CompetitionAlertSettingClient.swift
//  Presentation
//

import Foundation
import ComposableArchitecture

/// 설정 › 알림의 '관심 대회 알림' 켬/끔(#255, 기기 저장). 회원 id별 값이다.
/// userId가 nil(비로그인)이면 늘 꺼짐으로 읽고 쓰기는 무시한다.
/// 알림 설정 API에 이 항목이 생기면 NoticeClient로 옮긴다.
public struct CompetitionAlertSettingClient: Sendable {
    public var isEnabled: @Sendable (_ userId: Int?) -> Bool
    public var setEnabled: @Sendable (_ isEnabled: Bool, _ userId: Int?) -> Void
    /// 이 회원의 값이 바뀔 때마다 새 값을 흘려보낸다. 다른 탭(웹의 '알림 받기')에서 켠 값을 열려 있는 설정 화면에 반영하는 데 쓴다.
    public var changes: @Sendable (_ userId: Int?) -> AsyncStream<Bool>

    public init(
        isEnabled: @Sendable @escaping (_ userId: Int?) -> Bool,
        setEnabled: @Sendable @escaping (_ isEnabled: Bool, _ userId: Int?) -> Void,
        changes: @Sendable @escaping (_ userId: Int?) -> AsyncStream<Bool>
    ) {
        self.isEnabled = isEnabled
        self.setEnabled = setEnabled
        self.changes = changes
    }
}

extension CompetitionAlertSettingClient: DependencyKey {
    public static let liveValue: Self = .unimplemented

    public static let testValue: Self = .unimplemented

    /// 프리뷰에서는 켜진 모습을 보인다
    public static let previewValue = CompetitionAlertSettingClient(
        isEnabled: { _ in true },
        setEnabled: { _, _ in },
        changes: { _ in AsyncStream { $0.finish() } }
    )
}

extension DependencyValues {
    public var competitionAlertSettingClient: CompetitionAlertSettingClient {
        get { self[CompetitionAlertSettingClient.self] }
        set { self[CompetitionAlertSettingClient.self] = newValue }
    }
}

extension CompetitionAlertSettingClient {
    static let unimplemented: Self = Self(
        isEnabled: { _ in fatalError("competitionAlertSettingClient.isEnabled is not implemented") },
        setEnabled: { _, _ in fatalError("competitionAlertSettingClient.setEnabled is not implemented") },
        changes: { _ in fatalError("competitionAlertSettingClient.changes is not implemented") }
    )
}
