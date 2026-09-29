//
//  ImageKitUploadEndpoint.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation

/// ImageKit 업로드 엔드포인트 — `upload.imagekit.io/api/v1/files/upload`.
///
/// **인증**: ImageKit는 multipart 폼의 `publicKey/signature/token/expire`로 인증한다.
/// 우리 BE의 `Bearer` 토큰이 흘러 들어가서는 안 되므로 `requiresAuth = false`로 자동 주입을 끈다.
enum ImageKitUploadEndpoint {
    case upload(body: Data, boundary: String)
}

extension ImageKitUploadEndpoint: Endpoint {
    var baseURL: String { ImageKitConfig.uploadBaseURL }

    var path: String { ImageKitConfig.uploadPath }

    var method: HTTPMethod { .post }

    var headers: [String: String]? {
        switch self {
        case .upload(_, let boundary):
            return ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        }
    }

    var body: Data? {
        switch self {
        case .upload(let data, _):
            return data
        }
    }

    var timeout: TimeInterval {
        // 업로드는 기본 30s로 부족할 수 있어 60s로 늘림
        60.0
    }

    // 외부 CDN(ImageKit)이라 우리 BE 토큰과 무관하다. 401이 와도 우리 토큰을 갱신/회전하지 않는다.
    var allowsAuthRetry: Bool { false }

    var requiresAuth: Bool { false }
}
