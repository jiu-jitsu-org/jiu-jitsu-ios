//
//  SignupRequestDTO.swift
//  Data
//
//  Created by suni on 11/2/25.
//

import Foundation

struct SignupRequestDTO: Encodable, Sendable {
    let nickname: String
    let isMarketingAgreed: Bool
}
