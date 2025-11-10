//
//  ToastState.swift
//  CoreKit
//
//  Created by suni on 9/22/25.
//

import Foundation

public struct ToastState: Equatable, Identifiable {
    public var id = UUID()
    public var message: String
    public var style: Style
    public var bottomPadding: CGFloat
    
    public init(message: String,
                style: Style,
                bottomPadding: CGFloat = 24) {
        self.message = message
        self.style = style
        self.bottomPadding = bottomPadding
    }
    
    public enum Style: Equatable {
        case info
        case action(title: String, action: Action)
    }

    // 버튼이 눌렸을 때 Reducer가 어떤 동작을 할지 정의
    public enum Action: Equatable {
        case done
        
        public var description: String {
            switch self {
            case .done:
                return "done"
            }
        }
    }
    
    // 노출 시간을 스타일별로 반환
    public var duration: Duration {
        switch self.style {
        case .info: return .seconds(3)
        case .action: return .seconds(5)
        }
    }
}
