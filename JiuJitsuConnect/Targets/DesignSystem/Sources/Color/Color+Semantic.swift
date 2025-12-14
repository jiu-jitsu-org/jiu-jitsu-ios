//
//  Color+Semantic..swift
//  DesignSystem
//
//  Created by suni on 9/21/25.
//

import SwiftUI

public extension Color {
    /// 역할과 의미가 부여된 색상 네임스페이스
    static let semantic = SemanticColors()
}

public struct SemanticColors {
    
    // MARK: - Surface (표면)
    public let surface = Surface()
    
    public struct Surface {
        public let container = Color.primitive.bw.white
        public let containerPressed = Color.primitive.coolGray.cg75
        public let containerDisabled = Color.primitive.coolGray.cg100
        public let secondary = Color.primitive.coolGray.cg50
        public let secondaryPressed = Color.primitive.coolGray.cg75
        public let tertiary = Color.primitive.coolGray.cg75
        public let disabled = Color.primitive.coolGray.cg50
        public let background = Color.primitive.coolGray.cg25
        public let backgroundDefault = Color.primitive.coolGray.cg25
        public let inactive = Color.primitive.coolGray.cg75
        public let field = Color.primitive.coolGray.cg25
        public let primary = Color.primitive.blue.b100
        public let primarySubtle = Color.primitive.blue.b50
        public let primarySubtlePressed = Color.primitive.blue.b75
        public let primaryPressed = Color.primitive.blue.b200
        public let overlaySurface = Color.primitive.coolGray.cg700
        public let overlaySurfacePressed = Color.primitive.coolGray.cg800
    }
    
    // MARK: - Text (텍스트)
    public let text = Text()
    
    public struct Text {
        public let primary = Color.primitive.coolGray.cg900
        public let secondary = Color.primitive.coolGray.cg500
        public let tertiary = Color.primitive.coolGray.cg300
        public let disabled = Color.primitive.coolGray.cg400
        public let onPrimary = Color.primitive.bw.white
        public let onDark = Color.primitive.bw.white
        public let onInactive = Color.primitive.bw.white
        public let onOverlay = Color.primitive.bw.white
    }
    
    // MARK: - Border (테두리)
    public let border = Border()
    
    public struct Border {
        public let `default` = Color.primitive.coolGray.cg200
        public let pressed = Color.primitive.coolGray.cg300
        public let disabled = Color.primitive.coolGray.cg100
        public let subtle = Color.primitive.coolGray.cg25
        public let focus = Color.primitive.blue.b500p
        public let error = Color.primitive.red.r500
    }
    
    // MARK: - Icon (아이콘)
    public let icon = Icon()
    
    public struct Icon {
        public let primary = Color.primitive.coolGray.cg900
        public let secondary = Color.primitive.coolGray.cg500
        public let tertiary = Color.primitive.coolGray.cg300
        public let subtle = Color.primitive.coolGray.cg100
        public let disabled = Color.primitive.coolGray.cg400
        public let onPrimary = Color.primitive.bw.white
        public let onDark = Color.primitive.bw.white
        public let onInactive = Color.primitive.bw.white
        public let onInactive2 = Color.primitive.bw.white
        public let onOverlay = Color.primitive.bw.white
    }

    // MARK: - Interactive (상호작용)
    public let interactive = Interactive()
    
    public struct Interactive {
        public let primary = Color.primitive.blue.b500p
        public let primaryPressed = Color.primitive.blue.b600
        public let strong = Color.primitive.coolGray.cg700
        public let strongPressed = Color.primitive.coolGray.cg800
        public let disabled = Color.primitive.coolGray.cg100
    }

    // MARK: - Overlay (오버레이)
    public let overlay = Overlay()
    
    public struct Overlay {
        public let container = Color.primitive.coolGray.cg50
        public let containerPressed = Color.primitive.coolGray.cg200
        public let containerDisabled = Color.primitive.coolGray.cg100
        public let textPrimary = Color.primitive.coolGray.cg900
        public let textDisabled = Color.primitive.coolGray.cg400
        public let border = Color.primitive.coolGray.cg200
        public let scrim = Color.primitive.opacity.black40
    }

    // MARK: - Primary (주요 색상)
    public let primary = Primary()
    
    public struct Primary {
        public let primary = Color.primitive.blue.b500p
        public let pressed = Color.primitive.blue.b600
        public let onPrimary = Color.primitive.bw.white
        public let faint = Color.primitive.blue.b50
        public let subtle = Color.primitive.blue.b100
    }
    
    // MARK: - Error (오류)
    public let error = ErrorColor()
    
    public struct ErrorColor {
        public let error = Color.primitive.red.r500
        public let onError = Color.primitive.bw.white
    }

    // MARK: - Transparent (투명)
    public let transparent = Transparent()
    
    public struct Transparent {
        public let transparent = Color.clear
    }
}
