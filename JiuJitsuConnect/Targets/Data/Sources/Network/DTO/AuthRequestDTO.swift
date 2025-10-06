//
//  AuthRequestDTO.swift
//  Data
//
//  Created by suni on 10/6/25.
//

import Foundation

struct AuthRequestDTO: Encodable, Sendable {
    let accessToken: String
    let provider: String
}
