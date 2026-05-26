//
//  ImageKitAuthEndpoint.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation

/// 우리 백엔드에서 ImageKit 업로드용 서명(`token`/`expire`/`signature`)을 발급받는 엔드포인트.
///
/// 표준 NetworkService 경로를 그대로 사용하므로 `Bearer` 토큰이 자동 주입된다 (의도).
enum ImageKitAuthEndpoint {
    case fetchAuthParams
}

extension ImageKitAuthEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }

    var path: String {
        switch self {
        case .fetchAuthParams:
            return "/api/image/auth"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchAuthParams:
            return .get
        }
    }
}
