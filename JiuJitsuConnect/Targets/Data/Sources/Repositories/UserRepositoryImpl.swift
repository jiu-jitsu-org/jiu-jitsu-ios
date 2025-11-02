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
    
    public init(networkService: NetworkService  = DefaultNetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - API
    
    public func signup(info: SignupInfo) async throws -> AuthInfo {
        do {
            // 1. Domain 모델을 Data 모델로 변환
            let requestDTO = info.toRequestDTO()
            
            // 2. 변환된 DTO를 사용하여 API Endpoint 생성 및 요청
            let endpoint = UserEndpoint.signup(requestDTO)
            let responseDTO: SignupResponseDTO = try await networkService.request(endpoint: endpoint)
            
            // 3. 응답받은 Data 모델을 Domain 모델로 변환하여 반환
            return responseDTO.toDomain()
            
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Error Mapping
    
}
