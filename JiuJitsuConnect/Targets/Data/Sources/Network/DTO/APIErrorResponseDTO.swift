//
//  APIErrorResponseDTO.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation

// 서버가 내려주는 표준 에러 응답 DTO
public struct APIErrorResponseDTO: Decodable, Equatable, Sendable {
    public let success: Bool
    public let code: String
    public let message: String
}
