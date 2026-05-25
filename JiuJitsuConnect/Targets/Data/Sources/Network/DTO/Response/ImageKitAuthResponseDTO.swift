//
//  ImageKitAuthResponseDTO.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation

/// 우리 BE가 ImageKit 업로드용 서명을 발급해주는 응답.
///
/// `NetworkService.request<T>`가 `BaseResponseDTO<T>`로 감싸 디코드한 뒤
/// `.data`만 돌려주므로 여기서는 inner T만 표현한다.
/// 키 이름은 BE 합의 후 확정 — 다르면 CodingKeys 추가.
struct ImageKitAuthResponseDTO: Decodable {
    let token: String
    let expire: Int        // epoch seconds
    let signature: String
}
