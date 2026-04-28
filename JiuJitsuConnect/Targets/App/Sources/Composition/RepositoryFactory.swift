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

import Foundation
import Domain
import Data

enum RepositoryFactory {
    static func makeAuthRepository() -> AuthRepository {
        AuthRepositoryImpl()
    }

    static func makeUserRepository() -> UserRepository {
        UserRepositoryImpl()
    }

    static func makeCommunityRepository() -> CommunityRepository {
        CommunityRepositoryImpl()
    }
}
