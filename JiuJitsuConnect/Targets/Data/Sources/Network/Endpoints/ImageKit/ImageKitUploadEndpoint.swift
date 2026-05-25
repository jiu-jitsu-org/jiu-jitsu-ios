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
/// 우리 BE의 `Bearer` 토큰이 흘러 들어가서는 안 된다.
/// `NetworkService.requestData`는 `urlRequest.value(forHTTPHeaderField: "Authorization") == nil`
/// 일 때만 Bearer를 주입하므로 (`NetworkService.swift:81`), `Authorization`을 빈 문자열로
/// 미리 세팅해 자동 주입을 차단한다. (`URLRequest.value(_:)`는 빈 문자열을 nil로 normalize하지 않는다.)
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
            return [
                "Content-Type": "multipart/form-data; boundary=\(boundary)",
                // NetworkService의 자동 Bearer 주입 차단 — 트릭이지만 의도된 동작.
                "Authorization": ""
            ]
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
}
