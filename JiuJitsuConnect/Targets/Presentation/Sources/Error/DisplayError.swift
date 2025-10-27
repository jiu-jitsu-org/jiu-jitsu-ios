//
//  DisplayError.swift
//  Presentation
//
//  Created by suni on 10/2/25.
//

import Foundation

public enum DisplayError: Error, Equatable {
    case none
    case toast(String)
    case alert(String)
    case info(String)
}
