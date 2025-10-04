//
//  TermItem.swift
//  Domain
//
//  Created by suni on 10/4/25.
//

import Foundation

public struct TermItem: Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let type: TermType
    public let contentURL: URL? // 상세보기 웹뷰를 위한 URL
    
    public enum TermType: Equatable {
        case required
        case optional
    }
    
    public init(id: UUID = UUID(), title: String, type: TermType, contentURL: URL? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.contentURL = contentURL
    }
}
