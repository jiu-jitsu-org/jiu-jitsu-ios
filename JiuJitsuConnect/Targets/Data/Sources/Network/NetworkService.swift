//
//  NetworkService.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation
import Domain
import CoreKit

public protocol NetworkService: Sendable {
    func request<T: Decodable>(endpoint: Endpoint) async throws -> T

    // 빈 응답을 처리하는 경우 (DELETE, PUT 등)
    func requestVoid(endpoint: Endpoint) async throws

    // Raw Data가 필요한 경우 (파일 다운로드 등)
    func requestData(endpoint: Endpoint) async throws -> Data

    /// 401 인터셉터·웹뷰 위임이 공유하는 single-flight 토큰 갱신. 갱신된 accessToken을 반환한다.
    /// (Keychain 토큰 저장까지 끝난 상태로 반환된다.)
    @discardableResult
    func refreshSession() async throws -> String
}

public final class DefaultNetworkService: NetworkService {

    private let session: URLSession
    private let tokenStorage: TokenStorage
    private let decoder: JSONDecoder
    /// 토큰 갱신을 single-flight로 직렬화하는 코디네이터. 인터셉터·웹 위임이 공유한다.
    private let refreshCoordinator: TokenRefreshCoordinator
    /// 인터셉터가 토큰을 자동 갱신/세션 만료했을 때 Presentation(웹뷰 동기화·로그아웃)에 알리는 채널.
    private let sessionEventBroadcaster: AuthSessionEventBroadcaster?

    public init(
        session: URLSession = .shared,
        tokenStorage: TokenStorage = DefaultTokenStorage(),
        sessionEventBroadcaster: AuthSessionEventBroadcaster? = nil,
        decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
    ) {
        self.session = session
        self.tokenStorage = tokenStorage
        self.sessionEventBroadcaster = sessionEventBroadcaster
        self.decoder = decoder
        // 코디네이터의 실제 갱신 동작은 self를 참조하지 않는 static 실행기로 주입해
        // 초기화 순환/리테인 사이클을 피한다. (캡처값 session·tokenStorage는 Sendable)
        self.refreshCoordinator = TokenRefreshCoordinator(tokenStorage: tokenStorage) { refreshToken in
            try await DefaultNetworkService.executeRefresh(
                session: session,
                tokenStorage: tokenStorage,
                refreshToken: refreshToken
            )
        }
    }

    public func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint: endpoint)

        do {
            let baseResponse = try self.decoder.decode(BaseResponseDTO<T>.self, from: data)

            if baseResponse.success, let responseData = baseResponse.data {
                return responseData
            } else {
                let apiError = APIErrorResponseDTO(
                    success: baseResponse.success,
                    code: baseResponse.code,
                    message: baseResponse.message
                )
                throw NetworkError.statusCodeError(statusCode: 200, response: apiError)
            }
        } catch let error as NetworkError {
            throw error // 위에서 던진 statusCodeError를 다시 던집니다.
        } catch {
            throw NetworkError.decodingError(error) // BaseResponseDTO 디코딩 자체에 실패한 경우
        }
    }

    public func requestVoid(endpoint: Endpoint) async throws {
        // requestData를 호출하여 응답을 확인하지만, 반환값은 사용하지 않습니다.
        // 에러가 발생하면 requestData 내부에서 throw 할 것입니다.
        _ = try await requestData(endpoint: endpoint)
    }

    public func requestData(endpoint: Endpoint) async throws -> Data {
        try await requestData(endpoint: endpoint, allowAuthRetry: true)
    }

    @discardableResult
    public func refreshSession() async throws -> String {
        // 웹뷰 위임 등 명시적 갱신. 인터셉터와 같은 코디네이터를 타 single-flight를 공유한다.
        // (UI 통지는 호출부에서 처리하므로 여기서는 이벤트를 방송하지 않는다.)
        try await refreshCoordinator.refresh()
    }

    /// - Parameter allowAuthRetry: 401 후 토큰 갱신·재시도를 허용할지. 재시도 호출은 false로 내려와
    ///   무한 재귀를 막는다.
    private func requestData(endpoint: Endpoint, allowAuthRetry: Bool) async throws -> Data {
        guard var urlRequest = endpoint.asURLRequest() else {
            throw NetworkError.invalidURL
        }

        // 이 요청에 실제로 실린 accessToken. 401 후 갱신 시 "이미 다른 요청이 갱신했는지" 판별에 쓴다.
        var sentAccessToken: String?
        if urlRequest.value(forHTTPHeaderField: "Authorization") == nil,
           let accessToken = tokenStorage.getAccessToken() {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            sentAccessToken = accessToken
        }

        #if DEBUG || BETA
        NetworkLogger.log(request: urlRequest)
        #endif

        let data: Data
        let response: URLResponse

        // --- 1. API 요청 및 데이터 수신 (URLError 처리 포함) ---
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw NetworkError.noConnection
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.unknown(error)
            }
        } catch {
            throw NetworkError.unknown(error)
        }

        // --- 2. HTTP 응답 및 상태 코드 확인 ---
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG || BETA
        NetworkLogger.log(response: httpResponse, data: data)
        #endif

        // --- 3. 401 → 토큰 갱신 후 1회 재시도 (인터셉터) ---
        if httpResponse.statusCode == 401, allowAuthRetry, endpoint.allowsAuthRetry {
            return try await retryAfterTokenRefresh(endpoint: endpoint, sentAccessToken: sentAccessToken)
        }

        // --- 4. 그 외 상태 코드로 성공/실패 분기 ---
        guard (200...299).contains(httpResponse.statusCode) else {
            // 실패 시, 응답 데이터를 APIErrorResponseDTO로 디코딩 시도
            let apiError = try? self.decoder.decode(APIErrorResponseDTO.self, from: data)
            throw NetworkError.statusCodeError(statusCode: httpResponse.statusCode, response: apiError)
        }

        return data
    }

    /// 401을 받은 요청을 토큰 갱신 후 1회만 재시도한다. 갱신 성공 시 웹뷰 동기화 이벤트를,
    /// 갱신 실패(세션 만료) 시 세션 만료 이벤트를 방송한다.
    private func retryAfterTokenRefresh(endpoint: Endpoint, sentAccessToken: String?) async throws -> Data {
        let newAccessToken: String
        do {
            newAccessToken = try await refreshCoordinator.validAccessToken(replacing: sentAccessToken)
        } catch {
            sessionEventBroadcaster?.send(.sessionExpired)
            throw NetworkError.sessionExpired
        }
        // 네이티브가 갱신한 토큰을 웹뷰에도 동기화한다(하이브리드 토큰 소유권은 네이티브).
        sessionEventBroadcaster?.send(
            .tokenRefreshed(accessToken: newAccessToken, expiresAt: JWTDecoder.expiry(of: newAccessToken))
        )
        return try await requestData(endpoint: endpoint, allowAuthRetry: false)
    }

    /// 인터셉터 재귀 없이 refresh 엔드포인트를 직접 호출해 토큰을 갱신·저장하고 새 accessToken을 반환한다.
    /// self를 참조하지 않도록 static으로 두어 코디네이터 주입 시 순환을 피한다.
    private static func executeRefresh(
        session: URLSession,
        tokenStorage: TokenStorage,
        refreshToken: String
    ) async throws -> String {
        let endpoint = AuthEndpoint.refresh(RefreshRequestDTO(refreshToken: refreshToken))
        guard let urlRequest = endpoint.asURLRequest() else {
            throw NetworkError.invalidURL
        }

        #if DEBUG || BETA
        NetworkLogger.log(request: urlRequest)
        #endif

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG || BETA
        NetworkLogger.log(response: httpResponse, data: data)
        #endif

        guard (200...299).contains(httpResponse.statusCode) else {
            // refresh 자체가 4xx/5xx → refresh 토큰 만료 등으로 세션 만료.
            throw NetworkError.sessionExpired
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        guard
            let decoded = try? decoder.decode(BaseResponseDTO<RefreshResponseDTO>.self, from: data),
            decoded.success,
            let payload = decoded.data,
            let newAccessToken = payload.accessToken,
            let newRefreshToken = payload.refreshToken
        else {
            throw NetworkError.sessionExpired
        }

        // provider는 refresh로 바뀌지 않으므로 기존 값을 유지한다.
        let provider = tokenStorage.getProvider() ?? ""
        tokenStorage.save(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            provider: provider
        )
        return newAccessToken
    }
}
