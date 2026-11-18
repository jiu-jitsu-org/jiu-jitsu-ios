//
//  PostReportRequestDTO.swift
//  Data
//
//  신고 생성 요청 (`POST /api/reports`). 회원 신고는 reportType `USER`, targetId는 회원 id(#328).
//

import Foundation

struct PostReportRequestDTO: Encodable, Sendable {
    let reportType: String
    let targetId: Int
    let reason: String
    /// '기타'로 입력한 내용. nil이면 키째 보내지 않는다.
    let detail: String?
}
