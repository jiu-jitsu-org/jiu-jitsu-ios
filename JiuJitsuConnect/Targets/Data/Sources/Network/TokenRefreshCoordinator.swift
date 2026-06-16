//
//  TokenRefreshCoordinator.swift
//  Data
//
//  access token 만료(401) 시의 토큰 갱신을 single-flight로 직렬화하는 actor.
//
//  refresh 토큰은 서버에서 1회용으로 회전(rotation)되므로, 동시에 여러 요청이 만료를 감지해
//  각자 refresh를 호출하면 두 번째 호출은 이미 무효화된 refresh 토큰을 보내 강제 로그아웃된다.
//  이를 막기 위해 진행 중인 갱신이 있으면 그 결과를 공유하고, 갱신은 한 번만 수행한다.
//
//  401 인터셉터(`validAccessToken`)와 명시적 갱신(`refresh`, 웹뷰 위임 등)이 같은 코디네이터를
//  공유해야 경쟁이 사라지므로, 네트워크 레이어에서 단일 인스턴스로 보유한다.
//

import Foundation

actor TokenRefreshCoordinator {
    private let tokenStorage: TokenStorage
    /// refreshToken을 받아 서버 갱신을 수행하고, 새 accessToken을 반환하며 Keychain에 토큰을 저장한다.
    private let performRefresh: @Sendable (_ refreshToken: String) async throws -> String
    /// 진행 중인 갱신 Task. nil이면 갱신 중이 아니다.
    private var inFlight: Task<String, Error>?

    init(
        tokenStorage: TokenStorage,
        performRefresh: @escaping @Sendable (_ refreshToken: String) async throws -> String
    ) {
        self.tokenStorage = tokenStorage
        self.performRefresh = performRefresh
    }

    /// 명시적 토큰 갱신(웹뷰 위임 등). 진행 중인 갱신이 있으면 그 결과를 공유한다.
    @discardableResult
    func refresh() async throws -> String {
        if let inFlight {
            return try await inFlight.value
        }
        return try await startRefresh()
    }

    /// 401 인터셉터용 갱신. 401을 받은 요청이 들고 있던 accessToken을 넘기면 갱신된 토큰을 돌려준다.
    /// 다른 요청이 막 갱신을 끝냈다면(저장된 토큰이 만료 토큰과 다르면) 재갱신 없이 그 토큰을 재사용한다.
    func validAccessToken(replacing expiredToken: String?) async throws -> String {
        if let inFlight {
            return try await inFlight.value
        }
        if let current = tokenStorage.getAccessToken(), current != expiredToken {
            return current
        }
        return try await startRefresh()
    }

    /// 새 갱신 Task를 띄운다. 이 메서드 진입~`inFlight` 설정 사이에는 await가 없어
    /// 동시 호출이 끼어들 수 없으므로 single-flight가 보장된다.
    private func startRefresh() async throws -> String {
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            throw NetworkError.sessionExpired
        }
        let task = Task<String, Error> { [performRefresh] in
            try await performRefresh(refreshToken)
        }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}
