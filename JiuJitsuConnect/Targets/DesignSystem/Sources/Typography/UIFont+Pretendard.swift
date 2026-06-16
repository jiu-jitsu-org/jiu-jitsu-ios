//
//  UIFont+Pretendard.swift
//  DesignSystem
//
//  SwiftUI `Font.pretendard` 토큰의 UIKit(UIFont) 버전.
//  WKWebView 위 네이티브 오버레이 등 UIKit 인터롭에서 동일한 타이포 토큰을 쓰기 위함이며,
//  폰트 이름 문자열은 여기(DesignSystem)에만 두고 feature 코드에는 토큰만 노출한다.
//  실제 폰트 등록은 Info.plist `UIAppFonts`로 앱 시작 시 이뤄지므로 UIFont(name:)으로 조회된다.
//

import UIKit

public extension UIFont {
    static let pretendard = PretendardUIFont()
}

public struct PretendardUIFont {
    // MARK: - Display
    public let display1 = PretendardUIFont.make(.semiBold, 30)

    // MARK: - Title
    public let title1 = PretendardUIFont.make(.semiBold, 22)
    public let title2 = PretendardUIFont.make(.semiBold, 20)
    public let title3 = PretendardUIFont.make(.semiBold, 18)

    // MARK: - Body
    public let bodyM = PretendardUIFont.make(.medium, 16)
    public let bodyS = PretendardUIFont.make(.medium, 14)

    // MARK: - Label
    public let labelM = PretendardUIFont.make(.medium, 12)
    public let labelS = PretendardUIFont.make(.medium, 10)

    // MARK: - Button
    public let buttonL = PretendardUIFont.make(.semiBold, 18)
    public let buttonM = PretendardUIFont.make(.semiBold, 16)
    public let buttonS = PretendardUIFont.make(.semiBold, 12)

    // MARK: - Caption
    public let captionM = PretendardUIFont.make(.medium, 12)

    /// 사이즈와 웨이트를 직접 지정해야 할 경우 사용
    public func custom(weight: Pretendard.Weight, size: CGFloat) -> UIFont {
        PretendardUIFont.make(weight, size)
    }

    // 등록 실패 시에도 크래시 없이 시스템 폰트로 폴백한다.
    private static func make(_ weight: Pretendard.Weight, _ size: CGFloat) -> UIFont {
        UIFont(name: "Pretendard-\(weight.rawValue)", size: size)
            ?? .systemFont(ofSize: size, weight: weight.uiFontWeight)
    }
}

private extension Pretendard.Weight {
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .black: return .black
        case .bold: return .bold
        case .extraBold: return .heavy
        case .semiBold: return .semibold
        case .medium: return .medium
        case .regular: return .regular
        case .light: return .light
        case .extraLight: return .ultraLight
        case .thin: return .thin
        }
    }
}
