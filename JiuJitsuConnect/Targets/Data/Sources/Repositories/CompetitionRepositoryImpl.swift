//
//  CompetitionRepositoryImpl.swift
//  Data
//

import Foundation
import Domain

public final class CompetitionRepositoryImpl: CompetitionRepository {
    private let networkService: NetworkService

    public init(networkService: NetworkService = DefaultNetworkService()) {
        self.networkService = networkService
    }

    public func searchCompetitions(keyword: String) async throws -> [RegisteredCompetition] {
        do {
            let endpoint = CompetitionEndpoint.search(keyword: keyword)
            let responseDTO: [RegisteredCompetitionResponseDTO] = try await networkService.request(endpoint: endpoint)
            return responseDTO.map { $0.toDomain() }
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw DomainError.unknown(error.localizedDescription)
        }
    }
}
