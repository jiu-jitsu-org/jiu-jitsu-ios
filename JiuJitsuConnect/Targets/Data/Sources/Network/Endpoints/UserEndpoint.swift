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
    /// 사용자 프로필 조회 (GET `/api/user/profile`) — 계정/권한/관장사범 인증 상태 포함.
    case getProfile
    /// 회원 앱 정보 등록 (Swagger: POST `/user/appInfo` — 서버 라우팅에 맞춰 `/api/user/appInfo`)
    case registerAppInfo(request: AppInfoRequestDTO)
    /// 닉네임 단독 수정 (PUT `/api/user/profile/nickname`) — nickname 쿼리 파라미터 전달.
    case updateNickname(nickname: String)
    /// 프로필 이미지 설정 (PUT `/api/user/profile/image`) — 서버 등록 이미지 파일 id를 imageFileId 쿼리 파라미터로 전달.
    case setProfileImage(imageFileId: Int64)
    /// 관장/사범 인증 요청 (PUT `/api/user/owner`) — 서버 등록 인증 이미지 파일 id를 imageFileId 쿼리 파라미터로 전달하고 권한을 요청한다.
    case requestOwnerVerification(imageFileId: Int64)
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
        case .getProfile:
            return "/api/user/profile"
        case .checkNickname:
            return "/api/user/check/nickname"
        case .registerAppInfo:
            return "/api/user/appInfo"
        case .updateNickname:
            return "/api/user/profile/nickname"
        case .setProfileImage:
            return "/api/user/profile/image"
        case .requestOwnerVerification:
            return "/api/user/owner"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .checkNickname, .getProfile:
            return .get
        case .signup, .registerAppInfo:
            return .post
        case .withdrawal:
            return .delete
        case .updateNickname, .setProfileImage, .requestOwnerVerification:
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
        case .setProfileImage(let imageFileId):
            return ["imageFileId": String(imageFileId)]
        case .requestOwnerVerification(let imageFileId):
            return ["imageFileId": String(imageFileId)]
        default: return nil
        }
    }

    var body: Data? {
        switch self {
        case .signup(let request, _):
            return try? JSONEncoder().encode(request)
        case .registerAppInfo(let request):
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
