//
//  SNSProvider.swift
//  Domain
//
//  Created by suni on 9/29/25.
//

import Foundation

public enum SNSProvider: String, Codable, CaseIterable {
    case google = "GOOGLE"
    case apple = "APPLE"
    case kakao = "KAKAO"
    
    public var displayName: String {
        switch self {
        case .google: "구글"
        case .apple: "에플"
        case .kakao: "카카오"
        }
    }
}
