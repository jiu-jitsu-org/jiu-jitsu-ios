//
//  MultipartFormDataBuilder.swift
//  Data
//
//  Created by suni on 5/25/26.
//

import Foundation

/// `multipart/form-data` 본문을 만드는 미니 빌더.
///
/// 현재 사용처는 ImageKit 업로드 한 군데이므로 `Network/ImageKit/` 하위에 둔다.
/// 다른 사용처가 생기면 `Network/Multipart/`로 승격한다.
struct MultipartFormDataBuilder {
    let boundary: String
    private var body = Data()

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    mutating func appendField(name: String, value: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    mutating func appendFile(name: String, filename: String, mimeType: String, data: Data) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    func finalize() -> Data {
        var finalBody = body
        finalBody.appendString("--\(boundary)--\r\n")
        return finalBody
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
