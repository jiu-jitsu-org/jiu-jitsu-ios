//
//  CheckNicknameInfo.swift
//  Domain
//
//  Created by suni on 11/21/25.
//

import Foundation

public struct CheckNicknameInfo: Equatable {
    public let nickname: String
    
    public init(nickname: String) {
        self.nickname = nickname
    }
}
