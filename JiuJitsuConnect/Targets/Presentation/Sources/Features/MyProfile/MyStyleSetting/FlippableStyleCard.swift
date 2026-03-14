//
//  FlippableStyleCard.swift
//  Presentation
//
//  Created by suni on 3/14/26.
//

import SwiftUI
import DesignSystem
import Domain

/// 플립 가능한 3D 스타일 카드 컴포넌트
///
/// 좌우 드래그로 앞면/뒷면을 전환할 수 있는 인터랙티브 카드입니다.
/// - 앞면: `StyleCard` (배경 이미지, 아이콘, 설명)
/// - 뒷면: `StyleCardBack` (간단한 텍스트)
/// - 제스처: 좌우 드래그로 180도 회전
/// - 애니메이션: 3D 회전, 동적 섀도우
struct FlippableStyleCard: View {
    let style: any StyleSelectable
    let settingType: MyStyleSettingType
    
    @State private var dragAngle: Double = 0
    @State private var cumulativeRotation: Double = 0  // 누적 회전각
    
    // MARK: - Metrics
    
    private enum Metrics {
        // 제스처 임계값
        static let dragThreshold: CGFloat = 60
        static let velocityThreshold: CGFloat = 30
        
        // 드래그 감도
        static let dragSensitivity: CGFloat = 0.5
        
        // 회전 각도
        static let flipAngle: Double = 180
        
        // 애니메이션
        static let springResponse: Double = 0.45
        static let springDamping: Double = 0.72
        
        // 3D 효과
        static let perspective: Double = 0.4
        
        // 섀도우
        static let shadowRadius1: CGFloat = 6    // Blur 12 → radius 6
        static let shadowRadius2: CGFloat = 14   // Blur 24 → radius 12, spread 4 보정 +2
        static let shadowOpacity1: Double = 0.20
        static let shadowOpacity2: Double = 0.25
        static let shadowOffsetY: CGFloat = 2
        static let shadowOffsetMultiplier: Double = 6
    }
    
    // MARK: - Computed Properties
    
    /// 현재 총 회전각 기준으로 앞/뒷면 판단
    private var showBack: Bool {
        let normalized = dragAngle.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        return (positive > 90 && positive < 270)
    }
    
    /// 회전 각도 기반으로 섀도우 강도 계산 (0.0 ~ 1.0)
    /// - 정면/뒷면: 1.0 (최대 강도)
    /// - 옆면(90도): 0.0 (최소 강도)
    private var shadowIntensity: Double {
        let normalized = abs(dragAngle).truncatingRemainder(dividingBy: 180)
        let progress = normalized / 180  // 0 = 정면, 0.5 = 옆면, 1.0 = 뒷면
        return abs(cos(progress * .pi))
    }
    
    /// 회전 시 카드가 옆으로 기울어지면 X 오프셋도 살짝 변화
    private var shadowOffsetX: Double {
        sin(dragAngle * .pi / 180) * Metrics.shadowOffsetMultiplier
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 뒷면 (처음부터 180도 뒤집어 대기)
            StyleCardBack(style: style, settingType: settingType)
                .rotation3DEffect(
                    .degrees(Metrics.flipAngle),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(showBack ? 1 : 0)
            
            // 앞면
            StyleCard(style: style, isSelected: true)
                .opacity(showBack ? 0 : 1)
        }
        .rotation3DEffect(
            .degrees(dragAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: Metrics.perspective
        )
        // Shadow 1 - 기본 섀도우 (Blur: 12, Color: #000000 20%)
        .shadow(
            color: Color.black.opacity(Metrics.shadowOpacity1 * shadowIntensity),
            radius: Metrics.shadowRadius1,
            x: shadowOffsetX,
            y: Metrics.shadowOffsetY
        )
        // Shadow 2 - 깊이감 섀도우 (Blur: 24, Spread: 4, Color: #000000 25%)
        .shadow(
            color: Color.black.opacity(Metrics.shadowOpacity2 * shadowIntensity),
            radius: Metrics.shadowRadius2,
            x: shadowOffsetX,
            y: Metrics.shadowOffsetY
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
    }
    
    // MARK: - Gesture Handlers
    
    /// 드래그 진행 중 처리
    private func handleDragChanged(_ value: DragGesture.Value) {
        // 누적 회전각에 드래그 이동량을 더함 (양방향 지원)
        dragAngle = cumulativeRotation + value.translation.width * Metrics.dragSensitivity
    }
    
    /// 드래그 종료 시 처리
    private func handleDragEnded(_ value: DragGesture.Value) {
        let dragDistance = value.translation.width
        // 속도 기반으로 넘길지 복귀할지 판단
        let velocity = value.predictedEndTranslation.width - value.translation.width
        let shouldFlip = abs(dragDistance) > Metrics.dragThreshold || abs(velocity) > Metrics.velocityThreshold
        
        withAnimation(.spring(response: Metrics.springResponse, dampingFraction: Metrics.springDamping)) {
            if shouldFlip {
                // 드래그 방향에 따라 ±180도 회전
                if dragDistance < 0 {
                    cumulativeRotation -= Metrics.flipAngle  // 왼쪽으로 드래그 → 왼쪽 회전
                } else {
                    cumulativeRotation += Metrics.flipAngle  // 오른쪽으로 드래그 → 오른쪽 회전
                }
                dragAngle = cumulativeRotation
            } else {
                // 복귀
                dragAngle = cumulativeRotation
            }
        }
    }
}

// MARK: - Preview

#Preview("FlippableStyleCard - Position Top") {
    FlippableStyleCard(
        style: PositionType.top,
        settingType: .position
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("FlippableStyleCard - Position Guard") {
    FlippableStyleCard(
        style: PositionType.guard,
        settingType: .position
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("FlippableStyleCard - Submission ArmLocks") {
    FlippableStyleCard(
        style: SubmissionType.armLocks,
        settingType: .submission
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("FlippableStyleCard - Submission Chokes") {
    FlippableStyleCard(
        style: SubmissionType.chokes,
        settingType: .submission
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("FlippableStyleCard - Technique Takedowns") {
    FlippableStyleCard(
        style: TechniqueType.takedowns,
        settingType: .technique
    )
    .padding()
    .background(Color.component.background.default)
}

#Preview("FlippableStyleCard - Interactive Comparison") {
    struct InteractivePreview: View {
        @State private var selectedType: MyStyleSettingType = .position
        
        var currentStyle: any StyleSelectable {
            switch selectedType {
            case .position: return PositionType.top
            case .submission: return SubmissionType.armLocks
            case .technique: return TechniqueType.takedowns
            }
        }
        
        var body: some View {
            VStack(spacing: 30) {
                // 타입 선택
                Picker("설정 타입", selection: $selectedType) {
                    Text("포지션").tag(MyStyleSettingType.position)
                    Text("서브미션").tag(MyStyleSettingType.submission)
                    Text("기술").tag(MyStyleSettingType.technique)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Text("좌우로 드래그하여 카드를 뒤집어보세요")
                    .font(.pretendard.bodyS)
                    .foregroundColor(.primitive.coolGray.cg500)
                
                // 플립 가능한 카드
                FlippableStyleCard(
                    style: currentStyle,
                    settingType: selectedType
                )
            }
            .padding()
            .background(Color.component.background.default)
        }
    }
    
    return InteractivePreview()
}

#Preview("FlippableStyleCard - All Styles") {
    ScrollView {
        VStack(spacing: 40) {
            Text("포지션 스타일")
                .font(.pretendard.display1)
            
            VStack(spacing: 20) {
                FlippableStyleCard(style: PositionType.top, settingType: .position)
                FlippableStyleCard(style: PositionType.guard, settingType: .position)
            }
            
            Text("서브미션 스타일")
                .font(.pretendard.display1)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                FlippableStyleCard(style: SubmissionType.armLocks, settingType: .submission)
                FlippableStyleCard(style: SubmissionType.chokes, settingType: .submission)
                FlippableStyleCard(style: SubmissionType.legLocks, settingType: .submission)
            }
            
            Text("기술 스타일")
                .font(.pretendard.display1)
                .padding(.top, 20)
            
            VStack(spacing: 20) {
                FlippableStyleCard(style: TechniqueType.takedowns, settingType: .technique)
                FlippableStyleCard(style: TechniqueType.sweeps, settingType: .technique)
            }
        }
        .padding()
    }
    .background(Color.component.background.default)
}
