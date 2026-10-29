//
//  RepositoryFactory.swift
//  App
//
//  Domain 프로토콜을 따르는 Repository 구현체의 인스턴스화를 한 곳에 모아
//  `DependencyContainer`가 Data 레이어 구현 타입(`*Impl`)에 직접 결합되지 않도록 분리한다.
//
//  Repository 생성에 외부 의존성(NetworkService·TokenStorage 등)이 추가될 경우
//  본 파일의 팩토리 메서드가 단일 진입점이 된다.
//
//  401 토큰 갱신을 single-flight로 직렬화하려면 모든 Repository가 동일한 NetworkService
//  인스턴스(=동일 코디네이터)를 공유해야 한다. 따라서 NetworkService·TokenStorage는
//  DependencyContainer가 단일 인스턴스로 만들어 주입한다.
//

import Foundation
import Domain
import Data

enum RepositoryFactory {
    static func makeAuthRepository(
        networkService: NetworkService,
        tokenStorage: TokenStorage
    ) -> AuthRepository {
        AuthRepositoryImpl(networkService: networkService, tokenStorage: tokenStorage)
    }

    static func makeUserRepository(
        networkService: NetworkService,
        tokenStorage: TokenStorage
    ) -> UserRepository {
        UserRepositoryImpl(networkService: networkService, tokenStorage: tokenStorage)
    }

    static func makeCommunityRepository(networkService: NetworkService) -> CommunityRepository {
        CommunityRepositoryImpl(networkService: networkService)
    }

    static func makeImageUploadRepository(networkService: NetworkService) -> ImageUploadRepository {
        ImageUploadRepositoryImpl(networkService: networkService)
    }

    static func makeImageRepository(networkService: NetworkService) -> ImageRepository {
        ImageRepositoryImpl(networkService: networkService)
    }
}
