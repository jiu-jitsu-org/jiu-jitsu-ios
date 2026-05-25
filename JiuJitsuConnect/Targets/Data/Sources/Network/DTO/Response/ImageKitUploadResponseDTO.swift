//
//  ImageKitUploadResponseDTO.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation

/// ImageKit Upload API 응답.
///
/// ImageKit 응답은 우리 앱의 `BaseResponseDTO` 형식을 사용하지 않으므로
/// `NetworkService.requestData`로 raw Data를 받아 직접 디코드한다.
/// 참고: https://imagekit.io/docs/api-reference/upload-file/upload-file
struct ImageKitUploadResponseDTO: Decodable {
    let fileId: String
    let url: String
    let name: String?
}
