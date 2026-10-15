//
//  NoticeEndpoint.swift
//  Data
//

import Foundation

enum NoticeEndpoint {
    /// 알림 목록 조회 (GET `/api/notice`)
    case getList
    /// 알림 수신 설정 조회 (GET `/api/notice/setting`)
    case getSetting
    /// 알림 수신 설정 변경 (POST `/api/notice/setting`)
    case updateSetting(request: NoticeSettingRequestDTO)
}

extension NoticeEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }

    var path: String {
        switch self {
        case .getList: return "/api/notice"
        case .getSetting, .updateSetting: return "/api/notice/setting"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getList, .getSetting: return .get
        case .updateSetting: return .post
        }
    }

    var body: Data? {
        switch self {
        case .getList, .getSetting: return nil
        case .updateSetting(let request): return try? JSONEncoder().encode(request)
        }
    }
}
