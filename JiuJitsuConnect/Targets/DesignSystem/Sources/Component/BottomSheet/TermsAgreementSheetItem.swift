//
//  TermsAgreementSheetItem.swift
//  DesignSystem
//
//  Created by suni on 9/30/25.
//

import SwiftUI

// MARK: - 데이터 모델
public struct TermsAgreementSheetItem: Identifiable, Equatable {
    public let id: UUID // 각 항목을 고유하게 식별
    public var title: String
    public var isChecked: Bool
    public var type: ItemType

    public enum ItemType {
        case required
        case optional

        var text: String {
            switch self {
            case .required: "필수"
            case .optional: "선택"
            }
        }
        var selectedColor: Color {
            switch self {
            case .required: Color.component.bottomSheet.selected.listItem.labelRequired
            case .optional: Color.component.bottomSheet.selected.listItem.labelOptional
            }
        }
        
        var unselectedColor: Color {
            switch self {
            case .required: Color.component.bottomSheet.unselected.listItem.labelRequired
            case .optional: Color.component.bottomSheet.unselected.listItem.labelOptional
            }
        }
    }
    
    public init(id: UUID = UUID(), title: String, isChecked: Bool, type: ItemType) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
        self.type = type
    }
}
