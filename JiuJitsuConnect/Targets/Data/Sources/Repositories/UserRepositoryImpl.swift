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

public final class UserRepositoryImpl: NSObject, UserRepository {
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
    
    // MARK: - Error Mapping
    
}
