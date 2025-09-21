//
//  Color+Primitive.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//
import SwiftUI

public extension Color {
    /// 가장 기본적인 원시 색상 값 네임스페이스
    static let primitive = PrimitiveColors()
}

public struct PrimitiveColors {
    public let blue = Blue()
    public let coolGray = CoolGray()
    public let red = Red()
    public let bw = BW()
    public let opacity = Opacity()
    
    public struct Blue {
        public let b50 = Color("Color/Blue/Blue-50")
        public let b75 = Color("Color/Blue/Blue-75")
        public let b100 = Color("Color/Blue/Blue-100")
        public let b200 = Color("Color/Blue/Blue-200")
        public let b300 = Color("Color/Blue/Blue-300")
        public let b400 = Color("Color/Blue/Blue-400")
        public let b500p = Color("Color/Blue/Blue-500")
        public let b600 = Color("Color/Blue/Blue-600")
        public let b700 = Color("Color/Blue/Blue-700")
        public let b800 = Color("Color/Blue/Blue-800")
        public let b900 = Color("Color/Blue/Blue-900")
        public let b1000 = Color("Color/Blue/Blue-1000")
    }
    
    public struct CoolGray {
        public let cg25 = Color("Color/Gray/Gray-25")
        public let cg50 = Color("Color/Gray/Gray-50")
        public let cg75 = Color("Color/Gray/Gray-75")
        public let cg100 = Color("Color/Gray/Gray-100")
        public let cg200 = Color("Color/Gray/Gray-200")
        public let cg300 = Color("Color/Gray/Gray-300")
        public let cg400 = Color("Color/Gray/Gray-400")
        public let cg500 = Color("Color/Gray/Gray-500")
        public let cg600 = Color("Color/Gray/Gray-600")
        public let cg700 = Color("Color/Gray/Gray-700")
        public let cg800 = Color("Color/Gray/Gray-800")
        public let cg900 = Color("Color/Gray/Gray-900")
    }

    public struct Red {
        public let r500 = Color("Color/Red/Red-500")
    }

    public struct BW {
        public let black = Color("Color/B&W/Black")
        public let white = Color("Color/B&W/White")
        public let trueBlack = Color("Color/B&W/True-Black")
        public let trueWhite = Color("Color/B&W/True-White")
    }

    public struct Opacity {
        public let black40 = Color("Color/Opacity/Black-40")
        public let white40 = Color("Color/Opacity/White-40")
        public let blue10 = Color("Color/Opacity/Blue-10")
        public let blue40 = Color("Color/Opacity/Blue-40")
        public let red10 = Color("Color/Opacity/Red-10")
    }
}
