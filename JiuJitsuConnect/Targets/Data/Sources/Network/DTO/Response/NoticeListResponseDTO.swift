//
//  NoticeListResponseDTO.swift
//  Data
//

import Foundation

/// 알림 목록 항목(`GET /api/notice`). 알림함 화면은 웹이 그리므로, 앱은 GNB 새 알림 점을
/// 판단하는 데 필요한 필드만 디코딩한다. 나머지 필드(날짜 형식 등)가 바뀌어도 점 표시가 깨지지 않게 하기 위함이다.
struct NoticeListResponseDTO: Decodable, Sendable {
    let id: Int64
    let isRead: Bool
}
