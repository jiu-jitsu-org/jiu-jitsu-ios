// swiftlint:disable all
// 카탈로그 전용 목록 — Color+Primitive.swift 를 읽어 만든 것. 토큰을 바꾸면 이 목록도 다시 만든다.
#if DEBUG || BETA
import SwiftUI

extension CatalogColorTier {
    static let primitive = CatalogColorTier(
        name: "Primitive",
        groups: [
            CatalogColorGroup(name: "primitive.blue", tokens: [
                CatalogColorToken(path: "primitive.blue.b50", source: "#E6F5FF", color: Color.primitive.blue.b50),
                CatalogColorToken(path: "primitive.blue.b75", source: "#C2E6FF", color: Color.primitive.blue.b75),
                CatalogColorToken(path: "primitive.blue.b100", source: "#B0DDFF", color: Color.primitive.blue.b100),
                CatalogColorToken(path: "primitive.blue.b200", source: "#8ACCFF", color: Color.primitive.blue.b200),
                CatalogColorToken(path: "primitive.blue.b300", source: "#5CB8FF", color: Color.primitive.blue.b300),
                CatalogColorToken(path: "primitive.blue.b400", source: "#2DA3FC", color: Color.primitive.blue.b400),
                CatalogColorToken(path: "primitive.blue.b500p", source: "#0091FF", color: Color.primitive.blue.b500p),
                CatalogColorToken(path: "primitive.blue.b600", source: "#007BE0", color: Color.primitive.blue.b600),
                CatalogColorToken(path: "primitive.blue.b700", source: "#0065B8", color: Color.primitive.blue.b700),
                CatalogColorToken(path: "primitive.blue.b800", source: "#004F8F", color: Color.primitive.blue.b800),
                CatalogColorToken(path: "primitive.blue.b900", source: "#033969", color: Color.primitive.blue.b900),
                CatalogColorToken(path: "primitive.blue.b1000", source: "#032645", color: Color.primitive.blue.b1000),
            ]),
            CatalogColorGroup(name: "primitive.coolGray", tokens: [
                CatalogColorToken(path: "primitive.coolGray.cg25", source: "#EDEFEF", color: Color.primitive.coolGray.cg25),
                CatalogColorToken(path: "primitive.coolGray.cg50", source: "#E6E7E8", color: Color.primitive.coolGray.cg50),
                CatalogColorToken(path: "primitive.coolGray.cg75", source: "#D7D8D9", color: Color.primitive.coolGray.cg75),
                CatalogColorToken(path: "primitive.coolGray.cg100", source: "#CECFD1", color: Color.primitive.coolGray.cg100),
                CatalogColorToken(path: "primitive.coolGray.cg200", source: "#B7B9BD", color: Color.primitive.coolGray.cg200),
                CatalogColorToken(path: "primitive.coolGray.cg300", source: "#9C9EA6", color: Color.primitive.coolGray.cg300),
                CatalogColorToken(path: "primitive.coolGray.cg400", source: "#83868F", color: Color.primitive.coolGray.cg400),
                CatalogColorToken(path: "primitive.coolGray.cg500", source: "#70737C", color: Color.primitive.coolGray.cg500),
                CatalogColorToken(path: "primitive.coolGray.cg600", source: "#63666E", color: Color.primitive.coolGray.cg600),
                CatalogColorToken(path: "primitive.coolGray.cg700", source: "#4D4E54", color: Color.primitive.coolGray.cg700),
                CatalogColorToken(path: "primitive.coolGray.cg800", source: "#37383D", color: Color.primitive.coolGray.cg800),
                CatalogColorToken(path: "primitive.coolGray.cg900", source: "#292A2E", color: Color.primitive.coolGray.cg900),
            ]),
            CatalogColorGroup(name: "primitive.red", tokens: [
                CatalogColorToken(path: "primitive.red.r500", source: "#FF1D0D", color: Color.primitive.red.r500),
                CatalogColorToken(path: "primitive.red.notification", source: "#FF3B40", color: Color.primitive.red.notification),
            ]),
            CatalogColorGroup(name: "primitive.bw", tokens: [
                CatalogColorToken(path: "primitive.bw.black", source: "#0D0D0D", color: Color.primitive.bw.black),
                CatalogColorToken(path: "primitive.bw.white", source: "#FAFAFA", color: Color.primitive.bw.white),
                CatalogColorToken(path: "primitive.bw.trueBlack", source: "#000000", color: Color.primitive.bw.trueBlack),
                CatalogColorToken(path: "primitive.bw.trueWhite", source: "#FFFFFF", color: Color.primitive.bw.trueWhite),
            ]),
            CatalogColorGroup(name: "primitive.opacity", tokens: [
                CatalogColorToken(path: "primitive.opacity.black40", source: "#000000 40%", color: Color.primitive.opacity.black40),
                CatalogColorToken(path: "primitive.opacity.white20", source: "#FFFFFF 20%", color: Color.primitive.opacity.white20),
                CatalogColorToken(path: "primitive.opacity.white40", source: "#FFFFFF 40%", color: Color.primitive.opacity.white40),
                CatalogColorToken(path: "primitive.opacity.blue10", source: "#009DFF 10%", color: Color.primitive.opacity.blue10),
                CatalogColorToken(path: "primitive.opacity.blue40", source: "#009DFF 40%", color: Color.primitive.opacity.blue40),
                CatalogColorToken(path: "primitive.opacity.red10", source: "#FF1D0D 10%", color: Color.primitive.opacity.red10),
            ]),
            CatalogColorGroup(name: "primitive.kakao", tokens: [
                CatalogColorToken(path: "primitive.kakao.bg", source: "#FEE500", color: Color.primitive.kakao.bg),
                CatalogColorToken(path: "primitive.kakao.text", source: "#1F1F1F", color: Color.primitive.kakao.text),
            ]),
            CatalogColorGroup(name: "primitive.apple", tokens: [
                CatalogColorToken(path: "primitive.apple.bg", source: "#050708", color: Color.primitive.apple.bg),
                CatalogColorToken(path: "primitive.apple.text", source: "#FFFFFF", color: Color.primitive.apple.text),
            ]),
            CatalogColorGroup(name: "primitive.google", tokens: [
                CatalogColorToken(path: "primitive.google.bg", source: "#FFFFFF", color: Color.primitive.google.bg),
                CatalogColorToken(path: "primitive.google.text", source: "#292A2E", color: Color.primitive.google.text),
            ]),
        ]
    )
}
#endif
