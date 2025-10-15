//
//  BaseResponseDTO.swift
//  Data
//
//  Created by suni on 10/16/25.
//

import Foundation

// in Data Layer
struct BaseResponseDTO<T: Decodable>: Decodable {
    let success: Bool
    let code: String
    let message: String
    let data: T? // 실제 원하는 데이터 모델
}
