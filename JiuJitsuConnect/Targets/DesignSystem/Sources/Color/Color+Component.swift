// swiftlint:disable all
//
//  Color+Component.swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

public extension Color {
    /// 컴포넌트별로 지정된 색상 네임스페이스
    static let component = ComponentColors()
}

public struct ComponentColors {
    
    // MARK: - Background
    public let background = Background()
    public struct Background {
        public let `default` = Color.semantic.surface.backgroundDefault
    }
    
    // MARK: - Button
    public let button = Button()
    
    public struct Button {
        public let filled = Filled()
        public let tint = Tint()
        public let neutral = Neutral()
        public let text = Text()
        public let inverted = Inverted()
        
        public struct Filled {
            public let defaultBg = Color.semantic.interactive.primary
            public let pressedBg = Color.semantic.primary.pressed
            public let defaultText = Color.semantic.text.onPrimary
            public let pressedText = Color.semantic.text.onPrimary
            public let disabledBg = Color.semantic.interactive.disabled
            public let disabledText = Color.semantic.text.disabled
        }
        
        public struct Tint {
            public let defaultBg = Color.semantic.surface.primarySubtle
            public let pressedBg = Color.semantic.surface.primarySubtlePressed
            public let defaultText = Color.semantic.interactive.primary
            public let pressedText = Color.semantic.interactive.primary
            public let disabledBg = Color.semantic.surface.disabled
            public let disabledText = Color.semantic.text.disabled
        }
        
        public struct Neutral {
            public let defaultBg = Color.semantic.surface.secondary
            public let pressedBg = Color.semantic.surface.secondaryPressed
            public let defaultText = Color.semantic.text.primary
            public let pressedText = Color.semantic.text.primary
            public let disabledBg = Color.semantic.surface.disabled
            public let disabledText = Color.semantic.text.disabled
        }
        
        public struct Text {
            public let defaultBg = Color.semantic.transparent.transparent
            public let pressedBg = Color.semantic.surface.primarySubtle
            public let defaultText = Color.semantic.interactive.primary
            public let pressedText = Color.semantic.interactive.primary
            public let disabledBg = Color.semantic.transparent.transparent
            public let disabledText = Color.semantic.text.disabled
        }
        
        public struct Inverted {
            public let defaultBg = Color.semantic.transparent.transparent
            public let defaultText = Color.semantic.primary.primary
            public let pressedBg = Color.semantic.surface.onDarkPressedBg
            public let pressedText = Color.semantic.primary.onPrimary
            public let disabledBg = Color.semantic.transparent.transparent
            public let disabledText = Color.semantic.icon.disabledOnDark
            
        }
    }
    
    // MARK: - CTA (Call To Action)
    public let cta = CTA()
    
    public struct CTA {
        public let dark = Dark()
        public let primary = Primary()
        public let white = White()
        public let transparentText = TransparentText()

        public struct Dark {
            public let bg = Color.semantic.interactive.strong
            public let text = Color.semantic.text.onDark
            public let pressedBg = Color.semantic.interactive.strongPressed
            public let disabledBg = Color.semantic.interactive.disabled
            public let disabledText = Color.semantic.text.disabled
        }
        
        public struct Primary {
            public let bg = Color.semantic.interactive.primary
            public let text = Color.semantic.primary.onPrimary
            public let pressedBg = Color.semantic.interactive.primaryPressed
            public let disabledBg = Color.semantic.interactive.disabled
            public let disabledText = Color.semantic.text.disabled
        }
        
        public struct White {
            public let bg = Color.semantic.surface.container
            public let text = Color.semantic.text.primary
            public let pressedBg = Color.semantic.surface.containerPressed
            public let disabledBg = Color.semantic.surface.containerDisabled
            public let disabledText = Color.semantic.text.disabled
        }

        public struct TransparentText {
            public let bg = Color.semantic.transparent.transparent
            public let text = Color.semantic.interactive.primary
            public let pressedBg = Color.semantic.surface.primarySubtle
            public let disabledBg = Color.semantic.transparent.transparent
            public let disabledText = Color.semantic.text.disabled
        }
    }
    
    // MARK: - TextField
    public let textfield = TextField()
    
    public struct TextField {
        public let `default` = Default()
        public let disabled = Disabled()
        public let focused = Focused()
        public let filled = Filled()
        public let error = Error()

        public struct Default {
            public let bg = Color.semantic.surface.field
            public let border = Color.semantic.border.default
            public let placeholder = Color.semantic.text.tertiary
            public let icon = Color.semantic.icon.tertiary
        }
        
        public struct Disabled {
            public let bg = Color.semantic.surface.field
            public let border = Color.semantic.border.disabled
            public let placeholder = Color.semantic.text.disabled
            public let icon = Color.semantic.icon.disabled
        }
        
        public struct Focused {
            public let bg = Color.semantic.surface.field
            public let border = Color.semantic.border.focus
            public let placeholder = Color.semantic.text.tertiary
            public let icon = Color.semantic.icon.tertiary
        }
        
        public struct Filled {
            public let bg = Color.semantic.surface.field
            public let border = Color.semantic.border.default
            public let placeholder = Color.semantic.text.primary
            public let icon = Color.semantic.text.tertiary
        }
        
        public struct Error {
            public let bg = Color.semantic.surface.field
            public let border = Color.semantic.border.error
            public let placeholder = Color.semantic.text.primary
            public let icon = Color.semantic.text.tertiary
        }
    }

    // MARK: - TextField Display
    public let textfieldDisplay = TextFieldDisplay()
    
    public struct TextFieldDisplay {
        public let `default` = Default()
        public let focus = Focus()
        public let error = Error()

        public struct Default {
            public let title = Color.semantic.text.primary
            public let placeholder = Color.semantic.text.tertiary
        }

        public struct Focus {
            public let title = Color.semantic.text.primary
            public let text = Color.semantic.interactive.primary
        }

        public struct Error {
            public let title = Color.semantic.text.primary
            public let text = Color.semantic.text.tertiary
        }
    }

    // MARK: - Toast
    public let toast = Toast()
    
    public struct Toast {
        public let `default` = Default()
        public let button = Button()

        public struct Default {
            public let background = Color.semantic.surface.overlaySurface
            public let text = Color.semantic.text.onOverlay
        }
        public struct Button {
            public let bg = Color.semantic.overlay.container
            public let text = Color.semantic.overlay.textPrimary
        }
    }

    // MARK: - Dialog
    public let dialog = Dialog()
    
    public struct Dialog {
        public let dimBg = Color.semantic.overlay.scrim
        public let containerBg = Color.semantic.surface.container
        public let titleText = Color.semantic.text.primary
        public let descriptionText = Color.semantic.text.secondary
    }

    // MARK: - Switch
    public let `switch` = Switch()
    
    public struct Switch {
        public let on = On()
        public let off = Off()

        public struct On {
            public let bg = Color.semantic.interactive.primary
            public let thumb = Color.semantic.icon.onPrimary
        }

        public struct Off {
            public let bg = Color.semantic.surface.inactive
            public let thumb = Color.semantic.surface.container
        }
    }

    // MARK: - Navigation Bar
    public let navibar = NaviBar()
    
    public struct NaviBar {
        public let container = Container()
        public let selected = Selected()
        public let unselected = Unselected()

        public struct Container {
            public let background = Color.semantic.surface.container
            public let divider = Color.semantic.border.subtle
        }

        public struct Selected {
            public let icon = Color.semantic.interactive.primary
            public let label = Color.semantic.interactive.primary
        }

        public struct Unselected {
            public let icon = Color.semantic.icon.tertiary
            public let label = Color.semantic.text.tertiary
        }
    }

    // MARK: - List
    public let list = List()
    
    public struct List {
        public let setting = Setting()
        
        public struct Setting {
            public let text = Color.semantic.text.primary
            public let background = Color.semantic.surface.container
            public let subText = Color.semantic.text.secondary
            public let icon = Color.semantic.icon.secondary
            public let leadingIcon = Color.semantic.icon.primary
            public let valueText = Color.semantic.text.secondary
        }
    }
    
    // MARK: - Header
    public let header = Header()
    
    public struct Header {
        public let text = Color.semantic.text.primary
        public let background = Color.semantic.surface.container
        public let iconButton = Color.semantic.icon.primary
    }

    // MARK: - Bottom Sheet
    public let bottomSheet = BottomSheet()
    
    public struct BottomSheet {
        public let selected = Selected()
        public let unselected = Unselected()

        public struct Selected {
            public let container = Container()
            
            public struct Container {
                public let scrim = Color.semantic.overlay.scrim
                public let background = Color.semantic.surface.container
                public let handle = Color.semantic.border.default
                public let title = Color.semantic.text.primary
                public let closeIcon = Color.semantic.icon.primary
            }
            
            public let listItem = ListItem()
            
            public struct ListItem {
                public let leadingIcon = Color.semantic.interactive.primary
                public let followingIcon = Color.semantic.text.secondary
                public let label = Color.semantic.text.primary
                public let labelRequired = Color.semantic.interactive.primary
                public let labelOptional = Color.semantic.text.tertiary
            }
        }

        public struct Unselected {
            public let container = Container()
            
            public struct Container {
                public let scrim = Color.semantic.overlay.scrim
                public let background = Color.semantic.surface.container
                public let handle = Color.semantic.border.default
                public let title = Color.semantic.text.primary
                public let closeIcon = Color.semantic.icon.primary
            }
            
            public let listItem = ListItem()
            
            public struct ListItem {
                public let leadingIcon = Color.semantic.icon.secondary
                public let followingIcon = Color.semantic.icon.secondary
                public let label = Color.semantic.text.secondary
                public let labelRequired = Color.semantic.interactive.primary
                public let labelOptional = Color.semantic.text.tertiary
            }
        }
    }
    
    // MARK: - My Profile Header
    public let myProfileHeader = MyProfileHeader()
    
    public struct MyProfileHeader {
        public let bg = Bg()
        
        public let profileImagePlaceholde = Color.semantic.surface.container
        public let nicknameText = Color.semantic.primary.onPrimary
        public let profileImageDefaultIcon = Color.semantic.icon.subtle
        
        public struct Bg {
            public let `default` = Color.primitive.blue.b300
            public let white = Color.primitive.coolGray.cg200
            public let blue = Color.primitive.blue.b500p
            public let purple = Color(hex: "#CD57FF")
            public let brwon = Color(hex: "#A66040")
            public let black = Color(hex: "#2D2D2D")
        }
    }
    
    // MARK: - Belt Card
    public let beltCard = BeltCard()
    
    public struct BeltCard {
        public let `default` = Default()
        public let filled = Filled()
        
        public struct Default {
            public let bg = Color.semantic.surface.container
            public let text = Color.semantic.text.primary
        }
        
        public struct Filled {
            public let bg = Color.semantic.surface.container
            public let divider = Color.semantic.border.default
            public let labelText = Color.semantic.text.tertiary
            public let contentText = Color.semantic.text.primary
        }
    }
    
    // MARK: - Skill Card
    public let skillCard = SkillCard()
    
    public struct SkillCard {
        public let container = Container()
        public let `default` = Default()
        public let editable = Editable()
        
        public struct Container {
            public let bg = Color.semantic.surface.tertiary
        }
        
        public struct Default {
            public let bg = Color.semantic.surface.container
            public let labelText = Color.semantic.text.tertiary
            public let titleTextFilled = Color.semantic.text.primary
            public let titleTextEmpty = Color.semantic.text.primary
            public let titleTextFilled2 = Color.semantic.text.primary
            public let iconBgEmpty = Color.semantic.surface.disabled
        }
        
        public struct Editable {
            public let bg = Color.semantic.surface.container
            public let border = Color.semantic.border.default
            public let labelText = Color.semantic.text.tertiary
            public let labelText2 = Color.semantic.text.tertiary
            public let titleTextFilled = Color.semantic.text.primary
            public let titleTextEmpty = Color.semantic.text.primary
        }
    }
    
    // MARK: - Section Header
    public let sectionHeader = SectionHeader()
    
    public struct SectionHeader {
        public let title = Color.semantic.text.primary
        public let subTitle = Color.semantic.text.secondary
        public let label = Color.semantic.text.secondary
    }
    
    // MARK: - Section Header
    public let picker = Picker()
    
    public struct Picker {
        public let itemSelectedBg = Color.semantic.surface.secondary
        public let itemSelectedText = Color.semantic.text.primary
        public let itemUnselectedText = Color.semantic.text.tertiary
        public let unit = Color.semantic.text.primary
    }
    
}
