//
//  ImageEndpoint.swift
//  Data
//
//  Created by suni on 6/4/26.
//

import Foundation
import Domain

enum ImageEndpoint {
    /// CDN 업로드 후 이미지 등록 (POST `/api/image`).
    case register(request: RegisterImageRequestDTO)
    /// 이미지 삭제 (DELETE `/api/image/{id}`).
    case delete(id: Int64)
}

extension ImageEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }

    var path: String {
        switch self {
        case .register:
            return "/api/image"
        case .delete(let id):
            return "/api/image/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register:
            return .post
        case .delete:
            return .delete
        }
    }

    var body: Data? {
        switch self {
        case .register(let request):
            return try? JSONEncoder().encode(request)
        case .delete:
            return nil
        }
    }
}
