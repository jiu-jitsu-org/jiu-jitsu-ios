//
//  RegisteredCompetition.swift
//  Domain
//

import Foundation

/// 서버에 등록된 대회 — 대회명 자동완성(#121) 후보.
///
/// 같은 대회를 사람마다 다르게 적지 않도록 등록된 이름을 골라 쓰게 하는 용도다.
/// 서버 검색 API(backend #165)가 아직 없어 필드는 가정이다.
public struct RegisteredCompetition: Equatable, Sendable {
    /// 등록된 대회 식별자. 기록과 연결해 저장하는 계약이 정해지면 쓴다.
    public let id: Int?

    /// 대회명
    public let name: String

    /// 대회가 열린 연도 — 공개 일정에서 온 대회만 있다(#126). 회원이 등록한 대회 등 날짜를 모르면 nil.
    /// 고르면 기록의 연도를 이 값으로 맞춘다.
    public let year: Int?

    public init(id: Int? = nil, name: String, year: Int? = nil) {
        self.id = id
        self.name = name
        self.year = year
    }
}
