//
//  LogoutRequestDTO.swift
//  Data
//
//  Created by suni on 12/1/25.
//

import Foundation

struct LogoutRequestDTO: Encodable, Sendable {
    let accessToken: String
    let refreshToken: String
}
