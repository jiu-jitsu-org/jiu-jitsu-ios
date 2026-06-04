//
//  RegisterImageRequestDTO.swift
//  Data
//
//  API 전송 전용 모델 (Swagger: cdnId, imageUrl).
//

import Foundation

struct RegisterImageRequestDTO: Encodable, Sendable {
    let cdnId: String
    let imageUrl: String
}
