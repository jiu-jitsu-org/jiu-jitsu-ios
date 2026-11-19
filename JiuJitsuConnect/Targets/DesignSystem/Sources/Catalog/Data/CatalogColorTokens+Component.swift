// swiftlint:disable all
// 카탈로그 전용 목록 — Color+Component.swift 를 읽어 만든 것. 토큰을 바꾸면 이 목록도 다시 만든다.
#if DEBUG || BETA
import SwiftUI

extension CatalogColorTier {
    static let component = CatalogColorTier(
        name: "Component",
        groups: [
            CatalogColorGroup(name: "component.background", tokens: [
                CatalogColorToken(path: "component.background.default", source: "semantic.surface.backgroundDefault", color: Color.component.background.`default`),
            ]),
            CatalogColorGroup(name: "component.button.filled", tokens: [
                CatalogColorToken(path: "component.button.filled.defaultBg", source: "semantic.interactive.primary", color: Color.component.button.filled.defaultBg),
                CatalogColorToken(path: "component.button.filled.pressedBg", source: "semantic.primary.pressed", color: Color.component.button.filled.pressedBg),
                CatalogColorToken(path: "component.button.filled.defaultText", source: "semantic.text.onPrimary", color: Color.component.button.filled.defaultText),
                CatalogColorToken(path: "component.button.filled.pressedText", source: "semantic.text.onPrimary", color: Color.component.button.filled.pressedText),
                CatalogColorToken(path: "component.button.filled.disabledBg", source: "semantic.interactive.disabled", color: Color.component.button.filled.disabledBg),
                CatalogColorToken(path: "component.button.filled.disabledText", source: "semantic.text.disabled", color: Color.component.button.filled.disabledText),
            ]),
            CatalogColorGroup(name: "component.button.tint", tokens: [
                CatalogColorToken(path: "component.button.tint.defaultBg", source: "semantic.surface.primarySubtle", color: Color.component.button.tint.defaultBg),
                CatalogColorToken(path: "component.button.tint.pressedBg", source: "semantic.surface.primarySubtlePressed", color: Color.component.button.tint.pressedBg),
                CatalogColorToken(path: "component.button.tint.defaultText", source: "semantic.interactive.primary", color: Color.component.button.tint.defaultText),
                CatalogColorToken(path: "component.button.tint.pressedText", source: "semantic.interactive.primary", color: Color.component.button.tint.pressedText),
                CatalogColorToken(path: "component.button.tint.disabledBg", source: "semantic.surface.disabled", color: Color.component.button.tint.disabledBg),
                CatalogColorToken(path: "component.button.tint.disabledText", source: "semantic.text.disabled", color: Color.component.button.tint.disabledText),
            ]),
            CatalogColorGroup(name: "component.button.neutral", tokens: [
                CatalogColorToken(path: "component.button.neutral.defaultBg", source: "semantic.surface.secondary", color: Color.component.button.neutral.defaultBg),
                CatalogColorToken(path: "component.button.neutral.pressedBg", source: "semantic.surface.secondaryPressed", color: Color.component.button.neutral.pressedBg),
                CatalogColorToken(path: "component.button.neutral.defaultText", source: "semantic.text.primary", color: Color.component.button.neutral.defaultText),
                CatalogColorToken(path: "component.button.neutral.pressedText", source: "semantic.text.primary", color: Color.component.button.neutral.pressedText),
                CatalogColorToken(path: "component.button.neutral.disabledBg", source: "semantic.surface.disabled", color: Color.component.button.neutral.disabledBg),
                CatalogColorToken(path: "component.button.neutral.disabledText", source: "semantic.text.disabled", color: Color.component.button.neutral.disabledText),
            ]),
            CatalogColorGroup(name: "component.button.text", tokens: [
                CatalogColorToken(path: "component.button.text.defaultBg", source: "semantic.transparent.transparent", color: Color.component.button.text.defaultBg),
                CatalogColorToken(path: "component.button.text.pressedBg", source: "semantic.surface.primarySubtle", color: Color.component.button.text.pressedBg),
                CatalogColorToken(path: "component.button.text.defaultText", source: "semantic.interactive.primary", color: Color.component.button.text.defaultText),
                CatalogColorToken(path: "component.button.text.pressedText", source: "semantic.interactive.primary", color: Color.component.button.text.pressedText),
                CatalogColorToken(path: "component.button.text.disabledBg", source: "semantic.transparent.transparent", color: Color.component.button.text.disabledBg),
                CatalogColorToken(path: "component.button.text.disabledText", source: "semantic.text.disabled", color: Color.component.button.text.disabledText),
            ]),
            CatalogColorGroup(name: "component.button.inverted", tokens: [
                CatalogColorToken(path: "component.button.inverted.defaultBg", source: "semantic.transparent.transparent", color: Color.component.button.inverted.defaultBg),
                CatalogColorToken(path: "component.button.inverted.defaultText", source: "semantic.primary.primary", color: Color.component.button.inverted.defaultText),
                CatalogColorToken(path: "component.button.inverted.pressedBg", source: "semantic.surface.onDarkPressedBg", color: Color.component.button.inverted.pressedBg),
                CatalogColorToken(path: "component.button.inverted.pressedText", source: "semantic.primary.onPrimary", color: Color.component.button.inverted.pressedText),
                CatalogColorToken(path: "component.button.inverted.disabledBg", source: "semantic.transparent.transparent", color: Color.component.button.inverted.disabledBg),
                CatalogColorToken(path: "component.button.inverted.disabledText", source: "semantic.icon.disabledOnDark", color: Color.component.button.inverted.disabledText),
            ]),
            CatalogColorGroup(name: "component.button.ghost", tokens: [
                CatalogColorToken(path: "component.button.ghost.defaultText", source: "semantic.text.primary", color: Color.component.button.ghost.defaultText),
                CatalogColorToken(path: "component.button.ghost.pressedText", source: "semantic.text.primary", color: Color.component.button.ghost.pressedText),
                CatalogColorToken(path: "component.button.ghost.disabledText", source: "semantic.text.disabled", color: Color.component.button.ghost.disabledText),
            ]),
            CatalogColorGroup(name: "component.cta.dark", tokens: [
                CatalogColorToken(path: "component.cta.dark.bg", source: "semantic.interactive.strong", color: Color.component.cta.dark.bg),
                CatalogColorToken(path: "component.cta.dark.text", source: "semantic.text.onDark", color: Color.component.cta.dark.text),
                CatalogColorToken(path: "component.cta.dark.pressedBg", source: "semantic.interactive.strongPressed", color: Color.component.cta.dark.pressedBg),
                CatalogColorToken(path: "component.cta.dark.disabledBg", source: "semantic.interactive.disabled", color: Color.component.cta.dark.disabledBg),
                CatalogColorToken(path: "component.cta.dark.disabledText", source: "semantic.text.disabled", color: Color.component.cta.dark.disabledText),
            ]),
            CatalogColorGroup(name: "component.cta.primary", tokens: [
                CatalogColorToken(path: "component.cta.primary.bg", source: "semantic.interactive.primary", color: Color.component.cta.primary.bg),
                CatalogColorToken(path: "component.cta.primary.text", source: "semantic.primary.onPrimary", color: Color.component.cta.primary.text),
                CatalogColorToken(path: "component.cta.primary.pressedBg", source: "semantic.interactive.primaryPressed", color: Color.component.cta.primary.pressedBg),
                CatalogColorToken(path: "component.cta.primary.disabledBg", source: "semantic.interactive.disabled", color: Color.component.cta.primary.disabledBg),
                CatalogColorToken(path: "component.cta.primary.disabledText", source: "semantic.text.disabled", color: Color.component.cta.primary.disabledText),
            ]),
            CatalogColorGroup(name: "component.cta.white", tokens: [
                CatalogColorToken(path: "component.cta.white.bg", source: "semantic.surface.container", color: Color.component.cta.white.bg),
                CatalogColorToken(path: "component.cta.white.text", source: "semantic.text.primary", color: Color.component.cta.white.text),
                CatalogColorToken(path: "component.cta.white.pressedBg", source: "semantic.surface.containerPressed", color: Color.component.cta.white.pressedBg),
                CatalogColorToken(path: "component.cta.white.disabledBg", source: "semantic.surface.containerDisabled", color: Color.component.cta.white.disabledBg),
                CatalogColorToken(path: "component.cta.white.disabledText", source: "semantic.text.disabled", color: Color.component.cta.white.disabledText),
            ]),
            CatalogColorGroup(name: "component.cta.transparentText", tokens: [
                CatalogColorToken(path: "component.cta.transparentText.bg", source: "semantic.transparent.transparent", color: Color.component.cta.transparentText.bg),
                CatalogColorToken(path: "component.cta.transparentText.text", source: "semantic.interactive.primary", color: Color.component.cta.transparentText.text),
                CatalogColorToken(path: "component.cta.transparentText.pressedBg", source: "semantic.surface.primarySubtle", color: Color.component.cta.transparentText.pressedBg),
                CatalogColorToken(path: "component.cta.transparentText.disabledBg", source: "semantic.transparent.transparent", color: Color.component.cta.transparentText.disabledBg),
                CatalogColorToken(path: "component.cta.transparentText.disabledText", source: "semantic.text.disabled", color: Color.component.cta.transparentText.disabledText),
            ]),
            CatalogColorGroup(name: "component.cta.tint", tokens: [
                CatalogColorToken(path: "component.cta.tint.bg", source: "semantic.surface.primarySubtle", color: Color.component.cta.tint.bg),
                CatalogColorToken(path: "component.cta.tint.text", source: "semantic.interactive.primary", color: Color.component.cta.tint.text),
                CatalogColorToken(path: "component.cta.tint.pressedBg", source: "semantic.surface.primarySubtlePressed", color: Color.component.cta.tint.pressedBg),
                CatalogColorToken(path: "component.cta.tint.disabledBg", source: "semantic.surface.disabled", color: Color.component.cta.tint.disabledBg),
                CatalogColorToken(path: "component.cta.tint.disabledText", source: "semantic.text.disabled", color: Color.component.cta.tint.disabledText),
            ]),
            CatalogColorGroup(name: "component.textfield.default", tokens: [
                CatalogColorToken(path: "component.textfield.default.bg", source: "semantic.surface.field", color: Color.component.textfield.`default`.bg),
                CatalogColorToken(path: "component.textfield.default.border", source: "semantic.border.default", color: Color.component.textfield.`default`.border),
                CatalogColorToken(path: "component.textfield.default.placeholder", source: "semantic.text.tertiary", color: Color.component.textfield.`default`.placeholder),
                CatalogColorToken(path: "component.textfield.default.icon", source: "semantic.icon.tertiary", color: Color.component.textfield.`default`.icon),
            ]),
            CatalogColorGroup(name: "component.textfield.disabled", tokens: [
                CatalogColorToken(path: "component.textfield.disabled.bg", source: "semantic.surface.field", color: Color.component.textfield.disabled.bg),
                CatalogColorToken(path: "component.textfield.disabled.border", source: "semantic.border.disabled", color: Color.component.textfield.disabled.border),
                CatalogColorToken(path: "component.textfield.disabled.placeholder", source: "semantic.text.disabled", color: Color.component.textfield.disabled.placeholder),
                CatalogColorToken(path: "component.textfield.disabled.icon", source: "semantic.icon.disabled", color: Color.component.textfield.disabled.icon),
            ]),
            CatalogColorGroup(name: "component.textfield.focused", tokens: [
                CatalogColorToken(path: "component.textfield.focused.bg", source: "semantic.surface.field", color: Color.component.textfield.focused.bg),
                CatalogColorToken(path: "component.textfield.focused.border", source: "semantic.border.focus", color: Color.component.textfield.focused.border),
                CatalogColorToken(path: "component.textfield.focused.placeholder", source: "semantic.text.tertiary", color: Color.component.textfield.focused.placeholder),
                CatalogColorToken(path: "component.textfield.focused.icon", source: "semantic.icon.tertiary", color: Color.component.textfield.focused.icon),
            ]),
            CatalogColorGroup(name: "component.textfield.filled", tokens: [
                CatalogColorToken(path: "component.textfield.filled.bg", source: "semantic.surface.field", color: Color.component.textfield.filled.bg),
                CatalogColorToken(path: "component.textfield.filled.border", source: "semantic.border.default", color: Color.component.textfield.filled.border),
                CatalogColorToken(path: "component.textfield.filled.placeholder", source: "semantic.text.primary", color: Color.component.textfield.filled.placeholder),
                CatalogColorToken(path: "component.textfield.filled.icon", source: "semantic.text.tertiary", color: Color.component.textfield.filled.icon),
            ]),
            CatalogColorGroup(name: "component.textfield.error", tokens: [
                CatalogColorToken(path: "component.textfield.error.bg", source: "semantic.surface.field", color: Color.component.textfield.error.bg),
                CatalogColorToken(path: "component.textfield.error.border", source: "semantic.border.error", color: Color.component.textfield.error.border),
                CatalogColorToken(path: "component.textfield.error.placeholder", source: "semantic.text.primary", color: Color.component.textfield.error.placeholder),
                CatalogColorToken(path: "component.textfield.error.icon", source: "semantic.text.tertiary", color: Color.component.textfield.error.icon),
            ]),
            CatalogColorGroup(name: "component.textfieldMultiline.default", tokens: [
                CatalogColorToken(path: "component.textfieldMultiline.default.bg", source: "semantic.surface.field", color: Color.component.textfieldMultiline.`default`.bg),
                CatalogColorToken(path: "component.textfieldMultiline.default.text", source: "semantic.text.tertiary", color: Color.component.textfieldMultiline.`default`.text),
            ]),
            CatalogColorGroup(name: "component.textfieldMultiline.focused", tokens: [
                CatalogColorToken(path: "component.textfieldMultiline.focused.bg", source: "semantic.surface.field", color: Color.component.textfieldMultiline.focused.bg),
                CatalogColorToken(path: "component.textfieldMultiline.focused.border", source: "semantic.border.focus", color: Color.component.textfieldMultiline.focused.border),
                CatalogColorToken(path: "component.textfieldMultiline.focused.text", source: "semantic.text.primary", color: Color.component.textfieldMultiline.focused.text),
            ]),
            CatalogColorGroup(name: "component.textfieldMultiline.filled", tokens: [
                CatalogColorToken(path: "component.textfieldMultiline.filled.bg", source: "semantic.surface.field", color: Color.component.textfieldMultiline.filled.bg),
                CatalogColorToken(path: "component.textfieldMultiline.filled.text", source: "semantic.text.primary", color: Color.component.textfieldMultiline.filled.text),
            ]),
            CatalogColorGroup(name: "component.textfieldMultiline.disabled", tokens: [
                CatalogColorToken(path: "component.textfieldMultiline.disabled.bg", source: "semantic.surface.field", color: Color.component.textfieldMultiline.disabled.bg),
                CatalogColorToken(path: "component.textfieldMultiline.disabled.text", source: "semantic.text.disabled", color: Color.component.textfieldMultiline.disabled.text),
            ]),
            CatalogColorGroup(name: "component.textfieldDisplay.default", tokens: [
                CatalogColorToken(path: "component.textfieldDisplay.default.title", source: "semantic.text.primary", color: Color.component.textfieldDisplay.`default`.title),
                CatalogColorToken(path: "component.textfieldDisplay.default.placeholder", source: "semantic.text.tertiary", color: Color.component.textfieldDisplay.`default`.placeholder),
            ]),
            CatalogColorGroup(name: "component.textfieldDisplay.focus", tokens: [
                CatalogColorToken(path: "component.textfieldDisplay.focus.title", source: "semantic.text.primary", color: Color.component.textfieldDisplay.focus.title),
                CatalogColorToken(path: "component.textfieldDisplay.focus.text", source: "semantic.interactive.primary", color: Color.component.textfieldDisplay.focus.text),
            ]),
            CatalogColorGroup(name: "component.textfieldDisplay.error", tokens: [
                CatalogColorToken(path: "component.textfieldDisplay.error.title", source: "semantic.text.primary", color: Color.component.textfieldDisplay.error.title),
                CatalogColorToken(path: "component.textfieldDisplay.error.text", source: "semantic.text.tertiary", color: Color.component.textfieldDisplay.error.text),
            ]),
            CatalogColorGroup(name: "component.toast.default", tokens: [
                CatalogColorToken(path: "component.toast.default.background", source: "semantic.surface.overlaySurface", color: Color.component.toast.`default`.background),
                CatalogColorToken(path: "component.toast.default.text", source: "semantic.text.onOverlay", color: Color.component.toast.`default`.text),
            ]),
            CatalogColorGroup(name: "component.toast.button", tokens: [
                CatalogColorToken(path: "component.toast.button.bg", source: "semantic.overlay.container", color: Color.component.toast.button.bg),
                CatalogColorToken(path: "component.toast.button.text", source: "semantic.overlay.textPrimary", color: Color.component.toast.button.text),
            ]),
            CatalogColorGroup(name: "component.toast.strong", tokens: [
                CatalogColorToken(path: "component.toast.strong.background", source: "primitive.coolGray.cg900", color: Color.component.toast.strong.background),
                CatalogColorToken(path: "component.toast.strong.shadow", source: "Color(red: 13 / 255, green: 13 / 255, blue: 13 / 255).opacity(0.22)", color: Color.component.toast.strong.shadow),
            ]),
            CatalogColorGroup(name: "component.toast.action", tokens: [
                CatalogColorToken(path: "component.toast.action.text", source: "primitive.blue.b300", color: Color.component.toast.action.text),
                CatalogColorToken(path: "component.toast.action.pressedBg", source: "semantic.surface.onDarkPressedBg", color: Color.component.toast.action.pressedBg),
            ]),
            CatalogColorGroup(name: "component.toast.icon", tokens: [
                CatalogColorToken(path: "component.toast.icon.success", source: "primitive.blue.b300", color: Color.component.toast.icon.success),
                CatalogColorToken(path: "component.toast.icon.info", source: "semantic.icon.subtle", color: Color.component.toast.icon.info),
                CatalogColorToken(path: "component.toast.icon.warning", source: "Color(red: 1, green: 194 / 255, blue: 51 / 255)", color: Color.component.toast.icon.warning),
                CatalogColorToken(path: "component.toast.icon.error", source: "primitive.red.r500", color: Color.component.toast.icon.error),
                CatalogColorToken(path: "component.toast.icon.mark", source: "semantic.icon.primary", color: Color.component.toast.icon.mark),
                CatalogColorToken(path: "component.toast.icon.markOnError", source: "semantic.icon.onDark", color: Color.component.toast.icon.markOnError),
            ]),
            CatalogColorGroup(name: "component.dialog", tokens: [
                CatalogColorToken(path: "component.dialog.dimBg", source: "semantic.overlay.scrim", color: Color.component.dialog.dimBg),
                CatalogColorToken(path: "component.dialog.containerBg", source: "semantic.surface.container", color: Color.component.dialog.containerBg),
                CatalogColorToken(path: "component.dialog.titleText", source: "semantic.text.primary", color: Color.component.dialog.titleText),
                CatalogColorToken(path: "component.dialog.descriptionText", source: "semantic.text.secondary", color: Color.component.dialog.descriptionText),
            ]),
            CatalogColorGroup(name: "component.switch.on", tokens: [
                CatalogColorToken(path: "component.switch.on.bg", source: "semantic.interactive.primary", color: Color.component.`switch`.on.bg),
                CatalogColorToken(path: "component.switch.on.thumb", source: "semantic.icon.onPrimary", color: Color.component.`switch`.on.thumb),
            ]),
            CatalogColorGroup(name: "component.switch.off", tokens: [
                CatalogColorToken(path: "component.switch.off.bg", source: "semantic.surface.inactive", color: Color.component.`switch`.off.bg),
                CatalogColorToken(path: "component.switch.off.thumb", source: "semantic.surface.container", color: Color.component.`switch`.off.thumb),
            ]),
            CatalogColorGroup(name: "component.navibar.container", tokens: [
                CatalogColorToken(path: "component.navibar.container.background", source: "semantic.surface.container", color: Color.component.navibar.container.background),
                CatalogColorToken(path: "component.navibar.container.divider", source: "semantic.border.subtle", color: Color.component.navibar.container.divider),
            ]),
            CatalogColorGroup(name: "component.navibar.selected", tokens: [
                CatalogColorToken(path: "component.navibar.selected.icon", source: "semantic.interactive.primary", color: Color.component.navibar.selected.icon),
                CatalogColorToken(path: "component.navibar.selected.label", source: "semantic.interactive.primary", color: Color.component.navibar.selected.label),
            ]),
            CatalogColorGroup(name: "component.navibar.unselected", tokens: [
                CatalogColorToken(path: "component.navibar.unselected.icon", source: "semantic.icon.secondary", color: Color.component.navibar.unselected.icon),
                CatalogColorToken(path: "component.navibar.unselected.label", source: "semantic.text.secondary", color: Color.component.navibar.unselected.label),
            ]),
            CatalogColorGroup(name: "component.list.setting", tokens: [
                CatalogColorToken(path: "component.list.setting.text", source: "semantic.text.primary", color: Color.component.list.setting.text),
                CatalogColorToken(path: "component.list.setting.background", source: "semantic.surface.container", color: Color.component.list.setting.background),
                CatalogColorToken(path: "component.list.setting.pressedBackground", source: "semantic.surface.containerPressed", color: Color.component.list.setting.pressedBackground),
                CatalogColorToken(path: "component.list.setting.subText", source: "semantic.text.secondary", color: Color.component.list.setting.subText),
                CatalogColorToken(path: "component.list.setting.icon", source: "semantic.icon.secondary", color: Color.component.list.setting.icon),
                CatalogColorToken(path: "component.list.setting.leadingIcon", source: "semantic.icon.primary", color: Color.component.list.setting.leadingIcon),
                CatalogColorToken(path: "component.list.setting.valueText", source: "semantic.text.secondary", color: Color.component.list.setting.valueText),
            ]),
            CatalogColorGroup(name: "component.header", tokens: [
                CatalogColorToken(path: "component.header.text", source: "semantic.text.primary", color: Color.component.header.text),
                CatalogColorToken(path: "component.header.background", source: "semantic.surface.container", color: Color.component.header.background),
                CatalogColorToken(path: "component.header.iconButton", source: "semantic.icon.primary", color: Color.component.header.iconButton),
                CatalogColorToken(path: "component.header.destructiveText", source: "semantic.destructive.destructive", color: Color.component.header.destructiveText),
                CatalogColorToken(path: "component.header.actionText", source: "semantic.text.secondary", color: Color.component.header.actionText),
                CatalogColorToken(path: "component.header.actionDisabledText", source: "semantic.text.disabled", color: Color.component.header.actionDisabledText),
                CatalogColorToken(path: "component.header.backButtonBackground", source: "primitive.blue.b50", color: Color.component.header.backButtonBackground),
                CatalogColorToken(path: "component.header.backButtonIcon", source: "semantic.interactive.primary", color: Color.component.header.backButtonIcon),
                CatalogColorToken(path: "component.header.avatarPlaceholder", source: "Color(hex: \"#E5E7EB\")", color: Color.component.header.avatarPlaceholder),
                CatalogColorToken(path: "component.header.avatarDefaultIcon", source: "semantic.icon.primary", color: Color.component.header.avatarDefaultIcon),
            ]),
            CatalogColorGroup(name: "component.bottomSheet.selected.container", tokens: [
                CatalogColorToken(path: "component.bottomSheet.selected.container.scrim", source: "semantic.overlay.scrim", color: Color.component.bottomSheet.selected.container.scrim),
                CatalogColorToken(path: "component.bottomSheet.selected.container.background", source: "semantic.surface.container", color: Color.component.bottomSheet.selected.container.background),
                CatalogColorToken(path: "component.bottomSheet.selected.container.handle", source: "semantic.border.default", color: Color.component.bottomSheet.selected.container.handle),
                CatalogColorToken(path: "component.bottomSheet.selected.container.title", source: "semantic.text.primary", color: Color.component.bottomSheet.selected.container.title),
                CatalogColorToken(path: "component.bottomSheet.selected.container.closeIcon", source: "semantic.icon.primary", color: Color.component.bottomSheet.selected.container.closeIcon),
            ]),
            CatalogColorGroup(name: "component.bottomSheet.selected.listItem", tokens: [
                CatalogColorToken(path: "component.bottomSheet.selected.listItem.leadingIcon", source: "semantic.interactive.primary", color: Color.component.bottomSheet.selected.listItem.leadingIcon),
                CatalogColorToken(path: "component.bottomSheet.selected.listItem.followingIcon", source: "semantic.text.secondary", color: Color.component.bottomSheet.selected.listItem.followingIcon),
                CatalogColorToken(path: "component.bottomSheet.selected.listItem.label", source: "semantic.text.primary", color: Color.component.bottomSheet.selected.listItem.label),
                CatalogColorToken(path: "component.bottomSheet.selected.listItem.labelRequired", source: "semantic.interactive.primary", color: Color.component.bottomSheet.selected.listItem.labelRequired),
                CatalogColorToken(path: "component.bottomSheet.selected.listItem.labelOptional", source: "semantic.text.tertiary", color: Color.component.bottomSheet.selected.listItem.labelOptional),
            ]),
            CatalogColorGroup(name: "component.bottomSheet.unselected.container", tokens: [
                CatalogColorToken(path: "component.bottomSheet.unselected.container.scrim", source: "semantic.overlay.scrim", color: Color.component.bottomSheet.unselected.container.scrim),
                CatalogColorToken(path: "component.bottomSheet.unselected.container.background", source: "semantic.surface.container", color: Color.component.bottomSheet.unselected.container.background),
                CatalogColorToken(path: "component.bottomSheet.unselected.container.handle", source: "semantic.border.default", color: Color.component.bottomSheet.unselected.container.handle),
                CatalogColorToken(path: "component.bottomSheet.unselected.container.title", source: "semantic.text.primary", color: Color.component.bottomSheet.unselected.container.title),
                CatalogColorToken(path: "component.bottomSheet.unselected.container.closeIcon", source: "semantic.icon.primary", color: Color.component.bottomSheet.unselected.container.closeIcon),
            ]),
            CatalogColorGroup(name: "component.bottomSheet.unselected.listItem", tokens: [
                CatalogColorToken(path: "component.bottomSheet.unselected.listItem.leadingIcon", source: "semantic.icon.secondary", color: Color.component.bottomSheet.unselected.listItem.leadingIcon),
                CatalogColorToken(path: "component.bottomSheet.unselected.listItem.followingIcon", source: "semantic.icon.secondary", color: Color.component.bottomSheet.unselected.listItem.followingIcon),
                CatalogColorToken(path: "component.bottomSheet.unselected.listItem.label", source: "semantic.text.secondary", color: Color.component.bottomSheet.unselected.listItem.label),
                CatalogColorToken(path: "component.bottomSheet.unselected.listItem.labelRequired", source: "semantic.interactive.primary", color: Color.component.bottomSheet.unselected.listItem.labelRequired),
                CatalogColorToken(path: "component.bottomSheet.unselected.listItem.labelOptional", source: "semantic.text.tertiary", color: Color.component.bottomSheet.unselected.listItem.labelOptional),
            ]),
            CatalogColorGroup(name: "component.myProfileHeader.bg", tokens: [
                CatalogColorToken(path: "component.myProfileHeader.bg.default", source: "primitive.blue.b300", color: Color.component.myProfileHeader.bg.`default`),
                CatalogColorToken(path: "component.myProfileHeader.bg.white", source: "primitive.coolGray.cg200", color: Color.component.myProfileHeader.bg.white),
                CatalogColorToken(path: "component.myProfileHeader.bg.blue", source: "primitive.blue.b500p", color: Color.component.myProfileHeader.bg.blue),
                CatalogColorToken(path: "component.myProfileHeader.bg.purple", source: "Color(hex: \"#CD57FF\")", color: Color.component.myProfileHeader.bg.purple),
                CatalogColorToken(path: "component.myProfileHeader.bg.brwon", source: "Color(hex: \"#A66040\")", color: Color.component.myProfileHeader.bg.brwon),
                CatalogColorToken(path: "component.myProfileHeader.bg.black", source: "Color(hex: \"#2D2D2D\")", color: Color.component.myProfileHeader.bg.black),
                CatalogColorToken(path: "component.myProfileHeader.bg.blackBeltBar", source: "Color(hex: \"#AC2828\")", color: Color.component.myProfileHeader.bg.blackBeltBar),
            ]),
            CatalogColorGroup(name: "component.myProfileHeader", tokens: [
                CatalogColorToken(path: "component.myProfileHeader.profileImagePlaceholde", source: "semantic.surface.container", color: Color.component.myProfileHeader.profileImagePlaceholde),
                CatalogColorToken(path: "component.myProfileHeader.nicknameText", source: "semantic.primary.onPrimary", color: Color.component.myProfileHeader.nicknameText),
                CatalogColorToken(path: "component.myProfileHeader.profileImageDefaultIcon", source: "semantic.icon.subtle", color: Color.component.myProfileHeader.profileImageDefaultIcon),
            ]),
            CatalogColorGroup(name: "component.beltCard.default", tokens: [
                CatalogColorToken(path: "component.beltCard.default.bg", source: "semantic.surface.container", color: Color.component.beltCard.`default`.bg),
                CatalogColorToken(path: "component.beltCard.default.text", source: "semantic.text.primary", color: Color.component.beltCard.`default`.text),
            ]),
            CatalogColorGroup(name: "component.beltCard.filled", tokens: [
                CatalogColorToken(path: "component.beltCard.filled.bg", source: "semantic.surface.container", color: Color.component.beltCard.filled.bg),
                CatalogColorToken(path: "component.beltCard.filled.divider", source: "semantic.border.default", color: Color.component.beltCard.filled.divider),
                CatalogColorToken(path: "component.beltCard.filled.labelText", source: "semantic.text.tertiary", color: Color.component.beltCard.filled.labelText),
                CatalogColorToken(path: "component.beltCard.filled.contentText", source: "semantic.text.primary", color: Color.component.beltCard.filled.contentText),
            ]),
            CatalogColorGroup(name: "component.competitionCard", tokens: [
                CatalogColorToken(path: "component.competitionCard.titleText", source: "semantic.text.primary", color: Color.component.competitionCard.titleText),
                CatalogColorToken(path: "component.competitionCard.cardBg", source: "semantic.surface.container", color: Color.component.competitionCard.cardBg),
                CatalogColorToken(path: "component.competitionCard.cardIcon", source: "semantic.icon.secondary", color: Color.component.competitionCard.cardIcon),
                CatalogColorToken(path: "component.competitionCard.cardTextPrimary", source: "semantic.text.primary", color: Color.component.competitionCard.cardTextPrimary),
                CatalogColorToken(path: "component.competitionCard.cardTextSecondary", source: "semantic.text.tertiary", color: Color.component.competitionCard.cardTextSecondary),
            ]),
            CatalogColorGroup(name: "component.skillCard.container", tokens: [
                CatalogColorToken(path: "component.skillCard.container.bg", source: "semantic.surface.tertiary", color: Color.component.skillCard.container.bg),
            ]),
            CatalogColorGroup(name: "component.skillCard.default", tokens: [
                CatalogColorToken(path: "component.skillCard.default.bg", source: "semantic.surface.container", color: Color.component.skillCard.`default`.bg),
                CatalogColorToken(path: "component.skillCard.default.labelText", source: "semantic.text.tertiary", color: Color.component.skillCard.`default`.labelText),
                CatalogColorToken(path: "component.skillCard.default.titleTextFilled", source: "semantic.text.primary", color: Color.component.skillCard.`default`.titleTextFilled),
                CatalogColorToken(path: "component.skillCard.default.titleTextEmpty", source: "semantic.text.primary", color: Color.component.skillCard.`default`.titleTextEmpty),
                CatalogColorToken(path: "component.skillCard.default.titleTextFilled2", source: "semantic.text.primary", color: Color.component.skillCard.`default`.titleTextFilled2),
                CatalogColorToken(path: "component.skillCard.default.iconBgEmpty", source: "semantic.surface.disabled", color: Color.component.skillCard.`default`.iconBgEmpty),
            ]),
            CatalogColorGroup(name: "component.skillCard.editable", tokens: [
                CatalogColorToken(path: "component.skillCard.editable.bg", source: "semantic.surface.container", color: Color.component.skillCard.editable.bg),
                CatalogColorToken(path: "component.skillCard.editable.border", source: "semantic.border.default", color: Color.component.skillCard.editable.border),
                CatalogColorToken(path: "component.skillCard.editable.labelText", source: "semantic.text.tertiary", color: Color.component.skillCard.editable.labelText),
                CatalogColorToken(path: "component.skillCard.editable.labelText2", source: "semantic.text.tertiary", color: Color.component.skillCard.editable.labelText2),
                CatalogColorToken(path: "component.skillCard.editable.titleTextFilled", source: "semantic.text.primary", color: Color.component.skillCard.editable.titleTextFilled),
                CatalogColorToken(path: "component.skillCard.editable.titleTextEmpty", source: "semantic.text.primary", color: Color.component.skillCard.editable.titleTextEmpty),
            ]),
            CatalogColorGroup(name: "component.sectionHeader", tokens: [
                CatalogColorToken(path: "component.sectionHeader.title", source: "semantic.text.primary", color: Color.component.sectionHeader.title),
                CatalogColorToken(path: "component.sectionHeader.subTitle", source: "semantic.text.secondary", color: Color.component.sectionHeader.subTitle),
                CatalogColorToken(path: "component.sectionHeader.label", source: "semantic.text.secondary", color: Color.component.sectionHeader.label),
            ]),
            CatalogColorGroup(name: "component.picker", tokens: [
                CatalogColorToken(path: "component.picker.itemSelectedBg", source: "semantic.surface.secondary", color: Color.component.picker.itemSelectedBg),
                CatalogColorToken(path: "component.picker.itemSelectedText", source: "semantic.text.primary", color: Color.component.picker.itemSelectedText),
                CatalogColorToken(path: "component.picker.itemUnselectedText", source: "semantic.text.tertiary", color: Color.component.picker.itemUnselectedText),
                CatalogColorToken(path: "component.picker.unit", source: "semantic.text.primary", color: Color.component.picker.unit),
            ]),
            CatalogColorGroup(name: "component.errorState.default", tokens: [
                CatalogColorToken(path: "component.errorState.default.titleText", source: "semantic.text.primary", color: Color.component.errorState.`default`.titleText),
                CatalogColorToken(path: "component.errorState.default.descriptionText", source: "semantic.text.secondary", color: Color.component.errorState.`default`.descriptionText),
            ]),
            CatalogColorGroup(name: "component.segment.container", tokens: [
                CatalogColorToken(path: "component.segment.container.bg", source: "semantic.surface.tertiary", color: Color.component.segment.container.bg),
            ]),
            CatalogColorGroup(name: "component.segment.selected", tokens: [
                CatalogColorToken(path: "component.segment.selected.bg", source: "semantic.surface.container", color: Color.component.segment.selected.bg),
                CatalogColorToken(path: "component.segment.selected.titleText", source: "semantic.text.primary", color: Color.component.segment.selected.titleText),
                CatalogColorToken(path: "component.segment.selected.subText", source: "semantic.text.secondary", color: Color.component.segment.selected.subText),
            ]),
            CatalogColorGroup(name: "component.segment.unselected", tokens: [
                CatalogColorToken(path: "component.segment.unselected.bg", source: "semantic.transparent.transparent", color: Color.component.segment.unselected.bg),
                CatalogColorToken(path: "component.segment.unselected.titleText", source: "semantic.text.secondary", color: Color.component.segment.unselected.titleText),
                CatalogColorToken(path: "component.segment.unselected.subText", source: "semantic.text.tertiary", color: Color.component.segment.unselected.subText),
            ]),
            CatalogColorGroup(name: "component.beltSelectButton.selected", tokens: [
                CatalogColorToken(path: "component.beltSelectButton.selected.bg", source: "semantic.surface.primarySubtle", color: Color.component.beltSelectButton.selected.bg),
                CatalogColorToken(path: "component.beltSelectButton.selected.pressedBg", source: "semantic.surface.primarySubtlePressed", color: Color.component.beltSelectButton.selected.pressedBg),
                CatalogColorToken(path: "component.beltSelectButton.selected.labelText", source: "semantic.interactive.primary", color: Color.component.beltSelectButton.selected.labelText),
            ]),
            CatalogColorGroup(name: "component.beltSelectButton.unselected", tokens: [
                CatalogColorToken(path: "component.beltSelectButton.unselected.bg", source: "semantic.surface.secondary", color: Color.component.beltSelectButton.unselected.bg),
                CatalogColorToken(path: "component.beltSelectButton.unselected.pressedBg", source: "semantic.surface.secondaryPressed", color: Color.component.beltSelectButton.unselected.pressedBg),
                CatalogColorToken(path: "component.beltSelectButton.unselected.labelText", source: "semantic.text.primary", color: Color.component.beltSelectButton.unselected.labelText),
            ]),
            CatalogColorGroup(name: "component.beltSelectButton.belt", tokens: [
                CatalogColorToken(path: "component.beltSelectButton.belt.white", source: "primitive.bw.white", color: Color.component.beltSelectButton.belt.white),
                CatalogColorToken(path: "component.beltSelectButton.belt.whiteEdge", source: "primitive.coolGray.cg200", color: Color.component.beltSelectButton.belt.whiteEdge),
                CatalogColorToken(path: "component.beltSelectButton.belt.blue", source: "(계산) header.blue", color: Color.component.beltSelectButton.belt.blue),
                CatalogColorToken(path: "component.beltSelectButton.belt.purple", source: "(계산) header.purple", color: Color.component.beltSelectButton.belt.purple),
                CatalogColorToken(path: "component.beltSelectButton.belt.brown", source: "(계산) header.brwon", color: Color.component.beltSelectButton.belt.brown),
                CatalogColorToken(path: "component.beltSelectButton.belt.black", source: "(계산) header.black", color: Color.component.beltSelectButton.belt.black),
                CatalogColorToken(path: "component.beltSelectButton.belt.rankBar", source: "(계산) header.black", color: Color.component.beltSelectButton.belt.rankBar),
                CatalogColorToken(path: "component.beltSelectButton.belt.blackRankBar", source: "primitive.red.r500", color: Color.component.beltSelectButton.belt.blackRankBar),
                CatalogColorToken(path: "component.beltSelectButton.belt.stripe", source: "primitive.bw.white", color: Color.component.beltSelectButton.belt.stripe),
            ]),
            CatalogColorGroup(name: "component.tabBar.selected", tokens: [
                CatalogColorToken(path: "component.tabBar.selected.text", source: "semantic.interactive.primary", color: Color.component.tabBar.selected.text),
                CatalogColorToken(path: "component.tabBar.selected.underline", source: "semantic.interactive.primary", color: Color.component.tabBar.selected.underline),
            ]),
            CatalogColorGroup(name: "component.tabBar.unselected", tokens: [
                CatalogColorToken(path: "component.tabBar.unselected.text", source: "semantic.text.primary", color: Color.component.tabBar.unselected.text),
            ]),
        ]
    )
}
#endif
