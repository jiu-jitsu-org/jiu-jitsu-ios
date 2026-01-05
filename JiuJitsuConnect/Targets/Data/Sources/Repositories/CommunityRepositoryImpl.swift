//
//  CommunityRepositoryImpl.swift
//  Data
//
//  Created by suni on 1/5/26.
//

import Foundation
import Domain
import OSLog
import CoreKit

public final class CommunityRepositoryImpl: CommunityRepository {
    private let networkService: NetworkService
    
    public init(networkService: NetworkService = DefaultNetworkService()) {
        self.networkService = networkService
    }
    
    public func fetchProfile() async throws -> CommunityProfile {
        do {
            let endpoint = CommunityEndpoint.getProfile
            let responseDTO: CommunityProfileResponseDTO = try await networkService.request(endpoint: endpoint)
            return responseDTO.toDomain()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
    
    public func updateProfile(_ profile: CommunityProfile) async throws -> CommunityProfile {
        do {
            let requestDTO = PostCommunityProfileRequestDTO(from: profile)
            let endpoint = CommunityEndpoint.postProfile(requestDTO)
            let responseDTO: CommunityProfileResponseDTO = try await networkService.request(endpoint: endpoint)
            return responseDTO.toDomain()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
}
