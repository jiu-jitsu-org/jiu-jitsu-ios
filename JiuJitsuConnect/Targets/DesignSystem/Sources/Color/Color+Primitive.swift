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
    public let kakao = Kakao()
    public let apple = Apple()
    public let google = Google()
    
    public struct Blue {
        public let b50 = Color("Blue/Blue-50", bundle: .module)
        public let b75 = Color("Blue/Blue-75", bundle: .module)
        public let b100 = Color("Blue/Blue-100", bundle: .module)
        public let b200 = Color("Blue/Blue-200", bundle: .module)
        public let b300 = Color("Blue/Blue-300", bundle: .module)
        public let b400 = Color("Blue/Blue-400", bundle: .module)
        public let b500p = Color("Blue/Blue-500-Primary", bundle: .module)
        public let b600 = Color("Blue/Blue-600", bundle: .module)
        public let b700 = Color("Blue/Blue-700", bundle: .module)
        public let b800 = Color("Blue/Blue-800", bundle: .module)
        public let b900 = Color("Blue/Blue-900", bundle: .module)
        public let b1000 = Color("Blue/Blue-1000", bundle: .module)
    }
    
    public struct CoolGray {
        public let cg25 = Color("CoolGray/Gray-25", bundle: .module)
        public let cg50 = Color("CoolGray/Gray-50", bundle: .module)
        public let cg75 = Color("CoolGray/Gray-75", bundle: .module)
        public let cg100 = Color("CoolGray/Gray-100", bundle: .module)
        public let cg200 = Color("CoolGray/Gray-200", bundle: .module)
        public let cg300 = Color("CoolGray/Gray-300", bundle: .module)
        public let cg400 = Color("CoolGray/Gray-400", bundle: .module)
        public let cg500 = Color("CoolGray/Gray-500", bundle: .module)
        public let cg600 = Color("CoolGray/Gray-600", bundle: .module)
        public let cg700 = Color("CoolGray/Gray-700", bundle: .module)
        public let cg800 = Color("CoolGray/Gray-800", bundle: .module)
        public let cg900 = Color("CoolGray/Gray-900", bundle: .module)
    }

    public struct Red {
        public let r500 = Color("Red/Red-500", bundle: .module)
    }

    public struct BW {
        public let black = Color("B&W/Black", bundle: .module)
        public let white = Color("B&W/White", bundle: .module)
        public let trueBlack = Color("B&W/True-Black", bundle: .module)
        public let trueWhite = Color("B&W/True-White", bundle: .module)
    }

    public struct Opacity {
        public let black40 = Color("Opacity/Black-40", bundle: .module)
        public let white40 = Color("Opacity/White-40", bundle: .module)
        public let blue10 = Color("Opacity/Blue-10", bundle: .module)
        public let blue40 = Color("Opacity/Blue-40", bundle: .module)
        public let red10 = Color("Opacity/Red-10", bundle: .module)
    }
    
    public struct Kakao {
        public let bg = Color("Kakao/Bg", bundle: .module)
        public let text = Color("Kakao/Text", bundle: .module)
    }
    
    public struct Apple {
        public let bg = Color("Apple/Bg", bundle: .module)
        public let text = Color("Apple/Text", bundle: .module)
    }
    
    public struct Google {
        public let bg = Color("Google/Bg", bundle: .module)
        public let text = Color("Google/Text", bundle: .module)
    }
}
