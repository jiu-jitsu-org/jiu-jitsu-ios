//
//  NetworkLogger.swift
//  Data
//
//  Created by suni on 9/29/25.
//

import Foundation
import CoreKit
import OSLog

final class NetworkLogger {
    static func log(request: URLRequest) {
        // 로그의 각 부분을 배열에 담아 마지막에 합칩니다.
        var components: [String] = ["-----------🚀 Request-----------"]
        
        if let url = request.url {
            components.append("URL: \(url.absoluteString)")
        }
        
        if let method = request.httpMethod {
            components.append("Method: \(method)")
        }
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            // 헤더를 보기 좋게 정렬하여 출력합니다.
            let formattedHeaders = headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n  ")
            components.append("Headers: {\n  \(formattedHeaders)\n}")
        }
        
        if let body = request.httpBody, let bodyString = prettyPrintedJSON(from: body) {
            components.append("Body: \n\(bodyString)")
        }
        
        components.append("---------------------------------")
        
        // 모든 컴포넌트를 줄바꿈 문자로 합쳐 하나의 메시지로 만듭니다.
        let message = components.joined(separator: "\n")
        
        // 마지막에 한 번만 로그를 기록합니다.
        Log.trace(message, category: .network)
    }
    
    static func log(response: HTTPURLResponse, data: Data?) {
        var components: [String] = ["-----------✨ Response-----------"]
        
        if let url = response.url {
            components.append("URL: \(url.absoluteString)")
        }
        
        // 상태 코드에 따라 이모지를 추가하여 가독성을 높입니다.
        let statusCodeEmoji = (200..<300).contains(response.statusCode) ? "✅" : "❌"
        components.append("StatusCode: \(response.statusCode) \(statusCodeEmoji)")
        
        if let headers = response.allHeaderFields as? [String: Any], !headers.isEmpty {
            let formattedHeaders = headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n  ")
            components.append("Headers: {\n  \(formattedHeaders)\n}")
        }
        
        if let data = data, let bodyString = prettyPrintedJSON(from: data) {
            components.append("Body: \n\(bodyString)")
        }
        
        components.append("----------------------------------")
        
        let message = components.joined(separator: "\n")
        
        // 성공/실패 여부에 따라 로그 레벨을 동적으로 결정합니다.
        let level: OSLogType = (200..<300).contains(response.statusCode) ? .default : .error
        
        Log.trace(message, category: .network, level: level)
    }
    
    /// 요청 결과를 Pulse 콘솔 Network 탭용으로 기록합니다. 전송 실패(URLError 등)도 error로 남깁니다.
    static func record(request: URLRequest, response: URLResponse? = nil, data: Data? = nil, error: Error? = nil) {
        Log.networkTask(request: request, response: response, data: data, error: error)
    }

    /// Data를 예쁘게 포맷팅된 JSON 문자열로 변환합니다.
    private static func prettyPrintedJSON(from data: Data) -> String? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8)
        } catch {
            // JSON이 아닌 일반 데이터(e.g., 이미지)일 경우 그대로 변환
            return String(data: data, encoding: .utf8)
        }
    }
}
