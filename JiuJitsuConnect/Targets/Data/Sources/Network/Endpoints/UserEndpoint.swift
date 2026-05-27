//
//  UserEndpoint.swift
//  Data
//
//  Created by suni on 11/2/25.
//

import Foundation
import Domain

enum UserEndpoint {
    case signup(request: SignupRequestDTO, tempToken: String)
    case checkNickname(request: CheckNicknameRequestDTO)
    case withdrawal
    /// 회원 앱 정보 등록 (Swagger: POST `/user/appInfo` — 서버 라우팅에 맞춰 `/api/user/appInfo`)
    case registerAppInfo(request: AppInfoRequestDTO)
    /// 사용자 프로필 갱신 (PUT `/api/user/profile`) — 프로필 이미지 URL 등 user-level 필드.
    /// 커뮤니티 프로필(`/api/community/profile`)과는 데이터 도메인이 다르다.
    case updateProfile(request: UpdateUserProfileRequestDTO)
    /// 닉네임 단독 수정 (PUT `/api/user/profile/nickname`) — nickname 쿼리 파라미터 전달.
    case updateNickname(nickname: String)
    /// 프로필 이미지 URL 갱신 (PUT `/api/user/profile/image`) — profileImageUrl 쿼리 파라미터 전달.
    /// 이미지 삭제(nil)는 이 엔드포인트로 처리하지 않는다.
    case updateProfileImage(profileImageUrl: String)
}

extension UserEndpoint: Endpoint {
    var baseURL: String {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
//        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "TEST_BASE_URL") as? String else {
            fatalError("BASE_URL is not set in Info.plist")
        }
        return baseURL
    }

    var path: String {
        switch self {
        case .signup, .withdrawal:
            return "/api/user"
        case .checkNickname:
            return "/api/user/check/nickname"
        case .registerAppInfo:
            return "/api/user/appInfo"
        case .updateProfile:
            return "/api/user/profile"
        case .updateNickname:
            return "/api/user/profile/nickname"
        case .updateProfileImage:
            return "/api/user/profile/image"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .checkNickname:
            return .get
        case .signup, .registerAppInfo:
            return .post
        case .withdrawal:
            return .delete
        case .updateProfile, .updateNickname, .updateProfileImage:
            return .put
        }
    }

    var headers: [String: String]? {
        switch self {
        case .signup(_, let tempToken):
            return ["Content-Type": "application/json", "Authorization": "Bearer \(tempToken)"]
        default:
            return ["Content-Type": "application/json"]
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .checkNickname(let request):
            return ["nickname": request.nickname]
        case .updateNickname(let nickname):
            return ["nickname": nickname]
        case .updateProfileImage(let profileImageUrl):
            return ["profileImageUrl": profileImageUrl]
        default: return nil
        }
    }

    var body: Data? {
        switch self {
        case .signup(let request, _):
            return try? JSONEncoder().encode(request)
        case .registerAppInfo(let request):
            return try? JSONEncoder().encode(request)
        case .updateProfile(let request):
            return try? JSONEncoder().encode(request)
        default: return nil
        }
    }

}

private extension Encodable {
    // Encodable을 [String: Any]?로 변환하는 헬퍼
    var toDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    }
}
