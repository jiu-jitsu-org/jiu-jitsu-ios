//
//  RegisterImageResponseDTO.swift
//  Data
//
//  Created by suni on 6/4/26.
//

import Foundation
import Domain

/// `POST /api/image` 응답의 `data` 영역.
///
/// `NetworkService.request<T>`가 `BaseResponseDTO<T>`로 감싸 디코드한 뒤 `.data`만
/// 반환하므로 inner 필드만 표현한다.
struct RegisterImageResponseDTO: Decodable {
    let id: Int64
    let cdnId: String
    let imageUrl: String
    let status: String

    func toDomain() -> RegisteredImage {
        RegisteredImage(
            id: id,
            cdnId: cdnId,
            imageUrl: imageUrl,
            // 알 수 없는 status는 등록 직후 기본값(TEMP)으로 안전 매핑.
            status: RegisteredImage.Status(rawValue: status) ?? .temp
        )
    }
}
