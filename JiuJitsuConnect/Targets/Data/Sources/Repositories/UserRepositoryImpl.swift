//
//  UserRepositoryImpl.swift
//  Data
//
//  Created by suni on 11/2/25.
//

import Foundation
import Domain
import OSLog
import CoreKit

public final class UserRepositoryImpl: UserRepository {
    private let networkService: NetworkService
    private let tokenStorage: TokenStorage
    
    public init(
        networkService: NetworkService = DefaultNetworkService(),
        tokenStorage: TokenStorage = DefaultTokenStorage()
    ) {
        self.networkService = networkService
        self.tokenStorage = tokenStorage
    }
    
    // MARK: - API
    
    public func signup(info: SignupInfo) async throws -> AuthInfo {
        do {
            // 1. Domain 모델을 Data 모델로 변환
            let requestDTO = SignupRequestDTO(info: info)
            
            // 2. 변환된 DTO를 사용하여 API Endpoint 생성 및 요청
            let endpoint = UserEndpoint.signup(request: requestDTO, tempToken: info.tempToken)
            let responseDTO: SignupResponseDTO = try await networkService.request(endpoint: endpoint)
            
            // 로그인 성공 시 토큰 저장
            if let accessToken = responseDTO.accessToken,
               let refreshToken = responseDTO.refreshToken,
               let provider = responseDTO.userInfo?.snsProvider {
                tokenStorage.save(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    provider: provider
                )
            }
            
            // 3. 응답받은 Data 모델을 Domain 모델로 변환하여 반환
            return responseDTO.toDomain()
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    public func checkNickname(info: CheckNicknameInfo) async throws -> Bool {
        do {
            // 1. Domain 모델을 Data 모델로 변환
            let requestDTO = CheckNicknameRequestDTO(info: info)
            
            // 2. 변환된 DTO를 사용하여 API Endpoint 생성 및 요청
            let endpoint = UserEndpoint.checkNickname(request: requestDTO)
            let responseDTO: Bool = try await networkService.request(endpoint: endpoint)
            
            return responseDTO
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    public func withdrawal() async throws -> Bool {
        do {
            let endpoint = UserEndpoint.withdrawal
            let responseDTO: Bool = try await networkService.request(endpoint: endpoint)
            
            return responseDTO
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    public func fetchUserProfile() async throws -> UserProfile {
        do {
            let endpoint = UserEndpoint.getProfile
            let responseDTO: GetUserProfileResponseDTO = try await networkService.request(endpoint: endpoint)
            return responseDTO.toDomain()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func registerAppInfo(info: AppInfo) async throws -> Bool {
        do {
            let requestDTO = AppInfoRequestDTO(info: info)
            let endpoint = UserEndpoint.registerAppInfo(request: requestDTO)
            let responseDTO: Bool = try await networkService.request(endpoint: endpoint)
            
            return responseDTO
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func updateProfileImage(_ profileImageUrl: String?) async throws -> Bool {
        do {
            // nil(삭제 의도) → BE sentinel "default"로 매핑. 실제 URL은 그대로 전달.
            let urlForWire = profileImageUrl ?? ProfileImageSentinel.empty
            let endpoint = UserEndpoint.updateProfileImage(profileImageUrl: urlForWire)
            let _: UpdateUserProfileResponseDTO = try await networkService.request(endpoint: endpoint)
            return true
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func updateNickname(_ nickname: String) async throws -> Bool {
        do {
            let endpoint = UserEndpoint.updateNickname(nickname: nickname)
            let _: UpdateUserProfileResponseDTO = try await networkService.request(endpoint: endpoint)
            return true
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    public func requestOwnerVerification(imageUrl: String) async throws -> Bool {
        do {
            // 응답은 갱신된 user 객체(ownerRequested 등). 호출부는 성공 여부만 사용하므로
            // 닉네임/이미지 갱신과 동일하게 디코딩만 검증하고 결과 본문은 사용하지 않는다.
            let endpoint = UserEndpoint.requestOwnerVerification(imageUrl: imageUrl)
            let _: UpdateUserProfileResponseDTO = try await networkService.request(endpoint: endpoint)
            return true
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Error Mapping

}
