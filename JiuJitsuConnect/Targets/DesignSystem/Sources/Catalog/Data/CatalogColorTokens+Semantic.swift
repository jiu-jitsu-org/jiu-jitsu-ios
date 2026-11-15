// swiftlint:disable all
// 카탈로그 전용 목록 — Color+Semantic.swift 를 읽어 만든 것. 토큰을 바꾸면 이 목록도 다시 만든다.
#if DEBUG || BETA
import SwiftUI

extension CatalogColorTier {
    static let semantic = CatalogColorTier(
        name: "Semantic",
        groups: [
            CatalogColorGroup(name: "semantic.surface", tokens: [
                CatalogColorToken(path: "semantic.surface.container", source: "primitive.bw.white", color: Color.semantic.surface.container),
                CatalogColorToken(path: "semantic.surface.containerPressed", source: "primitive.coolGray.cg75", color: Color.semantic.surface.containerPressed),
                CatalogColorToken(path: "semantic.surface.containerDisabled", source: "primitive.coolGray.cg100", color: Color.semantic.surface.containerDisabled),
                CatalogColorToken(path: "semantic.surface.secondary", source: "primitive.coolGray.cg50", color: Color.semantic.surface.secondary),
                CatalogColorToken(path: "semantic.surface.secondaryPressed", source: "primitive.coolGray.cg75", color: Color.semantic.surface.secondaryPressed),
                CatalogColorToken(path: "semantic.surface.tertiary", source: "primitive.coolGray.cg75", color: Color.semantic.surface.tertiary),
                CatalogColorToken(path: "semantic.surface.disabled", source: "primitive.coolGray.cg50", color: Color.semantic.surface.disabled),
                CatalogColorToken(path: "semantic.surface.background", source: "primitive.coolGray.cg25", color: Color.semantic.surface.background),
                CatalogColorToken(path: "semantic.surface.backgroundDefault", source: "primitive.coolGray.cg25", color: Color.semantic.surface.backgroundDefault),
                CatalogColorToken(path: "semantic.surface.inactive", source: "primitive.coolGray.cg75", color: Color.semantic.surface.inactive),
                CatalogColorToken(path: "semantic.surface.field", source: "primitive.coolGray.cg25", color: Color.semantic.surface.field),
                CatalogColorToken(path: "semantic.surface.primary", source: "primitive.blue.b100", color: Color.semantic.surface.primary),
                CatalogColorToken(path: "semantic.surface.primarySubtle", source: "primitive.blue.b50", color: Color.semantic.surface.primarySubtle),
                CatalogColorToken(path: "semantic.surface.primarySubtlePressed", source: "primitive.blue.b75", color: Color.semantic.surface.primarySubtlePressed),
                CatalogColorToken(path: "semantic.surface.primaryPressed", source: "primitive.blue.b200", color: Color.semantic.surface.primaryPressed),
                CatalogColorToken(path: "semantic.surface.overlaySurface", source: "primitive.coolGray.cg700", color: Color.semantic.surface.overlaySurface),
                CatalogColorToken(path: "semantic.surface.overlaySurfacePressed", source: "primitive.coolGray.cg800", color: Color.semantic.surface.overlaySurfacePressed),
                CatalogColorToken(path: "semantic.surface.onDarkPressedBg", source: "primitive.opacity.white20", color: Color.semantic.surface.onDarkPressedBg),
            ]),
            CatalogColorGroup(name: "semantic.text", tokens: [
                CatalogColorToken(path: "semantic.text.primary", source: "primitive.coolGray.cg900", color: Color.semantic.text.primary),
                CatalogColorToken(path: "semantic.text.secondary", source: "primitive.coolGray.cg500", color: Color.semantic.text.secondary),
                CatalogColorToken(path: "semantic.text.tertiary", source: "primitive.coolGray.cg300", color: Color.semantic.text.tertiary),
                CatalogColorToken(path: "semantic.text.disabled", source: "primitive.coolGray.cg400", color: Color.semantic.text.disabled),
                CatalogColorToken(path: "semantic.text.onPrimary", source: "primitive.bw.white", color: Color.semantic.text.onPrimary),
                CatalogColorToken(path: "semantic.text.onDark", source: "primitive.bw.white", color: Color.semantic.text.onDark),
                CatalogColorToken(path: "semantic.text.onInactive", source: "primitive.bw.white", color: Color.semantic.text.onInactive),
                CatalogColorToken(path: "semantic.text.onOverlay", source: "primitive.bw.white", color: Color.semantic.text.onOverlay),
            ]),
            CatalogColorGroup(name: "semantic.border", tokens: [
                CatalogColorToken(path: "semantic.border.default", source: "primitive.coolGray.cg200", color: Color.semantic.border.`default`),
                CatalogColorToken(path: "semantic.border.pressed", source: "primitive.coolGray.cg300", color: Color.semantic.border.pressed),
                CatalogColorToken(path: "semantic.border.disabled", source: "primitive.coolGray.cg100", color: Color.semantic.border.disabled),
                CatalogColorToken(path: "semantic.border.subtle", source: "primitive.coolGray.cg25", color: Color.semantic.border.subtle),
                CatalogColorToken(path: "semantic.border.focus", source: "primitive.blue.b500p", color: Color.semantic.border.focus),
                CatalogColorToken(path: "semantic.border.error", source: "primitive.red.r500", color: Color.semantic.border.error),
            ]),
            CatalogColorGroup(name: "semantic.icon", tokens: [
                CatalogColorToken(path: "semantic.icon.primary", source: "primitive.coolGray.cg900", color: Color.semantic.icon.primary),
                CatalogColorToken(path: "semantic.icon.secondary", source: "primitive.coolGray.cg500", color: Color.semantic.icon.secondary),
                CatalogColorToken(path: "semantic.icon.tertiary", source: "primitive.coolGray.cg300", color: Color.semantic.icon.tertiary),
                CatalogColorToken(path: "semantic.icon.subtle", source: "primitive.coolGray.cg100", color: Color.semantic.icon.subtle),
                CatalogColorToken(path: "semantic.icon.disabled", source: "primitive.coolGray.cg400", color: Color.semantic.icon.disabled),
                CatalogColorToken(path: "semantic.icon.onPrimary", source: "primitive.bw.white", color: Color.semantic.icon.onPrimary),
                CatalogColorToken(path: "semantic.icon.onDark", source: "primitive.bw.white", color: Color.semantic.icon.onDark),
                CatalogColorToken(path: "semantic.icon.onInactive", source: "primitive.bw.white", color: Color.semantic.icon.onInactive),
                CatalogColorToken(path: "semantic.icon.onInactive2", source: "primitive.bw.white", color: Color.semantic.icon.onInactive2),
                CatalogColorToken(path: "semantic.icon.onOverlay", source: "primitive.bw.white", color: Color.semantic.icon.onOverlay),
                CatalogColorToken(path: "semantic.icon.disabledOnDark", source: "primitive.opacity.white40", color: Color.semantic.icon.disabledOnDark),
            ]),
            CatalogColorGroup(name: "semantic.interactive", tokens: [
                CatalogColorToken(path: "semantic.interactive.primary", source: "primitive.blue.b500p", color: Color.semantic.interactive.primary),
                CatalogColorToken(path: "semantic.interactive.primaryPressed", source: "primitive.blue.b600", color: Color.semantic.interactive.primaryPressed),
                CatalogColorToken(path: "semantic.interactive.strong", source: "primitive.coolGray.cg700", color: Color.semantic.interactive.strong),
                CatalogColorToken(path: "semantic.interactive.strongPressed", source: "primitive.coolGray.cg800", color: Color.semantic.interactive.strongPressed),
                CatalogColorToken(path: "semantic.interactive.disabled", source: "primitive.coolGray.cg100", color: Color.semantic.interactive.disabled),
            ]),
            CatalogColorGroup(name: "semantic.overlay", tokens: [
                CatalogColorToken(path: "semantic.overlay.container", source: "primitive.coolGray.cg50", color: Color.semantic.overlay.container),
                CatalogColorToken(path: "semantic.overlay.containerPressed", source: "primitive.coolGray.cg200", color: Color.semantic.overlay.containerPressed),
                CatalogColorToken(path: "semantic.overlay.containerDisabled", source: "primitive.coolGray.cg100", color: Color.semantic.overlay.containerDisabled),
                CatalogColorToken(path: "semantic.overlay.textPrimary", source: "primitive.coolGray.cg900", color: Color.semantic.overlay.textPrimary),
                CatalogColorToken(path: "semantic.overlay.textDisabled", source: "primitive.coolGray.cg400", color: Color.semantic.overlay.textDisabled),
                CatalogColorToken(path: "semantic.overlay.border", source: "primitive.coolGray.cg200", color: Color.semantic.overlay.border),
                CatalogColorToken(path: "semantic.overlay.scrim", source: "primitive.opacity.black40", color: Color.semantic.overlay.scrim),
            ]),
            CatalogColorGroup(name: "semantic.primary", tokens: [
                CatalogColorToken(path: "semantic.primary.primary", source: "primitive.blue.b500p", color: Color.semantic.primary.primary),
                CatalogColorToken(path: "semantic.primary.pressed", source: "primitive.blue.b600", color: Color.semantic.primary.pressed),
                CatalogColorToken(path: "semantic.primary.onPrimary", source: "primitive.bw.white", color: Color.semantic.primary.onPrimary),
                CatalogColorToken(path: "semantic.primary.faint", source: "primitive.blue.b50", color: Color.semantic.primary.faint),
                CatalogColorToken(path: "semantic.primary.subtle", source: "primitive.blue.b100", color: Color.semantic.primary.subtle),
            ]),
            CatalogColorGroup(name: "semantic.error", tokens: [
                CatalogColorToken(path: "semantic.error.error", source: "primitive.red.r500", color: Color.semantic.error.error),
                CatalogColorToken(path: "semantic.error.onError", source: "primitive.bw.white", color: Color.semantic.error.onError),
            ]),
            CatalogColorGroup(name: "semantic.transparent", tokens: [
                CatalogColorToken(path: "semantic.transparent.transparent", source: "clear", color: Color.semantic.transparent.transparent),
            ]),
            CatalogColorGroup(name: "semantic.destructive", tokens: [
                CatalogColorToken(path: "semantic.destructive.destructive", source: "primitive.red.r500", color: Color.semantic.destructive.destructive),
            ]),
        ]
    )
}
#endif
