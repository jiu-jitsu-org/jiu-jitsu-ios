//
//  UserRepository.swift
//  Domain
//
//  Created by suni on 11/2/25.
//

import Foundation

public protocol UserRepository {
    func signup(info: SignupInfo) async throws -> AuthInfo
}
