//
//  RegisteredCompetition.swift
//  Domain
//

import Foundation

/// 서버에 등록된 대회 — 대회명 자동완성(#121) 후보.
///
/// 같은 대회를 사람마다 다르게 적지 않도록 등록된 이름을 골라 쓰게 하는 용도다.
/// 등록 대회는 회차(이름 + 연도) 단위라 같은 이름이 연도별로 여러 개 올 수 있다.
public struct RegisteredCompetition: Equatable, Sendable {
    /// 등록된 대회 식별자. 고른 기록을 저장할 때 `Competition.competitionId`로 함께 보낸다.
    public let id: Int?

    /// 대회명
    public let name: String

    /// 대회가 열린 연도 — 날짜를 모르는 대회는 nil.
    /// 고르면 기록의 연도를 이 값으로 맞춘다.
    public let year: Int?

    public init(id: Int? = nil, name: String, year: Int? = nil) {
        self.id = id
        self.name = name
        self.year = year
    }
}
