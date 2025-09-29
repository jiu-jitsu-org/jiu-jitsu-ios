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
        let logger = Logger.network
        logger.debug("-----------🚀 Request-----------")
        
        if let url = request.url {
            logger.debug("URL: \(url.absoluteString)")
        }
        
        if let method = request.httpMethod {
            logger.debug("Method: \(method)")
        }
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("Headers: \(headers)")
        }
        
        if let body = request.httpBody, let bodyString = prettyPrintedJSON(from: body) {
            logger.debug("Body: \n\(bodyString)")
        }
        
        logger.debug("---------------------------------")
    }
    
    static func log(response: HTTPURLResponse, data: Data?) {
        let logger = Logger.network
        logger.debug("-----------✨ Response-----------")
        
        if let url = response.url {
            logger.debug("URL: \(url.absoluteString)")
        }
        
        logger.debug("StatusCode: \(response.statusCode)")
        
        if let headers = response.allHeaderFields as? [String: Any], !headers.isEmpty {
            logger.debug("Headers: \(headers)")
        }
        
        if let data = data, let bodyString = prettyPrintedJSON(from: data) {
            logger.debug("Body: \n\(bodyString)")
        }
        
        logger.debug("----------------------------------")
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
