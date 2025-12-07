//
//  SuccessResponseDTO.swift
//  Data
//
//  Created by suni on 12/7/25.
//

import Foundation

// in Data Layer
struct SuccessResponseDTO: Decodable {
    let success: Bool
    let message: String
}
