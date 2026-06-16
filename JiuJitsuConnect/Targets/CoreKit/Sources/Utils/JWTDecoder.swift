//
//  JWTDecoder.swift
//  CoreKit
//
//  서버 access token(JWT)의 만료 시각(exp)을 추출하기 위한 경량 디코더.
//  서명 검증은 하지 않는다(서버가 검증하므로 클라이언트는 만료 시각만 참고).
//  웹뷰에 토큰을 전달할 때 expiresAt을 함께 실어, 웹이 선제 갱신 타이밍을 잡을 수 있게 한다.
//

import Foundation

public enum JWTDecoder {
    /// JWT payload의 `exp`(만료 시각, Unix epoch seconds) 클레임을 추출한다. 파싱 실패 시 nil.
    public static func expiry(of token: String) -> Int? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        guard
            let payloadData = base64URLDecode(String(segments[1])),
            let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        else { return nil }

        // exp는 정수가 일반적이지만 일부 서버는 실수로 내려보내므로 둘 다 허용한다.
        if let exp = json["exp"] as? Int { return exp }
        if let exp = json["exp"] as? Double { return Int(exp) }
        return nil
    }

    /// JWT는 padding 없는 base64url을 쓰므로, 표준 base64로 정규화한 뒤 디코드한다.
    private static func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
