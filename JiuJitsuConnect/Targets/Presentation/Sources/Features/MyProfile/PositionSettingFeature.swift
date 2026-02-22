//
//  PositionSettingFeature.swift
//  Presentation
//
//  Created by suni on 2/22/26.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct PositionSettingFeature: Sendable {
    public init() {}
    
    @ObservableState
    public struct State: Equatable, Sendable {
        // 탭 선택 (탑/가드)
        var selectedTab: StyleCategory = .top
        
        // 선택된 포지션 스타일
        var selectedBestPosition: PositionStyle?
        var selectedFavoritePosition: PositionStyle?
        
        public init(
            bestPosition: PositionType? = nil,
            favoritePosition: PositionType? = nil
        ) {
            // 기존 선택된 포지션이 있으면 초기화
            if let best = bestPosition {
                self.selectedBestPosition = PositionStyle.from(positionType: best)
            }
            if let favorite = favoritePosition {
                self.selectedFavoritePosition = PositionStyle.from(positionType: favorite)
            }
        }
        
        // 현재 탭에 따른 포지션 스타일 목록
        var availableStyles: [PositionStyle] {
            PositionStyle.allCases.filter { $0.category == selectedTab }
        }
        
        // 완료 버튼 활성화 조건
        var canComplete: Bool {
            selectedBestPosition != nil
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        
        public enum ViewAction: Sendable {
            case tabSelected(StyleCategory)
            case styleCardTapped(PositionStyle)
            case completeButtonTapped
            case backButtonTapped
            case resetButtonTapped
        }
        
        public enum DelegateAction: Sendable {
            case didConfirmPosition(best: PositionType?, favorite: PositionType?)
            case cancel
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.tabSelected(category)):
                state.selectedTab = category
                return .none
                
            case let .view(.styleCardTapped(style)):
                // 이미 선택된 스타일이면 해제
                if state.selectedBestPosition == style {
                    state.selectedBestPosition = nil
                    state.selectedFavoritePosition = nil
                    return .none
                }
                
                // 새로운 스타일 선택
                if state.selectedBestPosition == nil {
                    // 최고 포지션이 없으면 최고로 설정
                    state.selectedBestPosition = style
                } else {
                    // 최고 포지션이 있으면 선호로 설정
                    state.selectedFavoritePosition = style
                }
                return .none
                
            case .view(.completeButtonTapped):
                guard state.canComplete else { return .none }
                
                let bestType = state.selectedBestPosition?.positionType
                let favoriteType = state.selectedFavoritePosition?.positionType
                
                return .send(.delegate(.didConfirmPosition(best: bestType, favorite: favoriteType)))
                
            case .view(.backButtonTapped):
                return .send(.delegate(.cancel))
                
            case .view(.resetButtonTapped):
                state.selectedBestPosition = nil
                state.selectedFavoritePosition = nil
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Position Style Models

/// 포지션 스타일 (UI용)
public enum PositionStyle: String, CaseIterable, Equatable, Sendable, Identifiable {
    // Top 계열
    case topAttack = "top_attack"
    case topControl = "top_control"
    
    // Guard 계열
    case guardAttack = "guard_attack"
    case guardDefense = "guard_defense"
    
    public var id: String { rawValue }
    
    /// 스타일이 속한 카테고리
    public var category: StyleCategory {
        switch self {
        case .topAttack, .topControl:
            return .top
        case .guardAttack, .guardDefense:
            return .guard
        }
    }
    
    /// 스타일 이름
    public var displayName: String {
        switch self {
        case .topAttack:
            return "탑 포지션"
        case .topControl:
            return "컨트롤 포지션"
        case .guardAttack:
            return "가드 포지션"
        case .guardDefense:
            return "디펜스 포지션"
        }
    }
    
    /// 스타일 설명
    public var description: String {
        switch self {
        case .topAttack:
            return "이 매트 위에서 '선다'는 건 없어.\n'아직 넘어지지 않았다'란 있을 뿐.\n그리고 그 시간은, 이제 끝났어."
        case .topControl:
            return "서두르지 않아. 압박을 주고,\n상대를 무너뜨린 뒤,\n천천히 마무리해."
        case .guardAttack:
            return "누워있다고 당하는 게 아니야.\n오히려 여기가 내 무대.\n올라와봐, 내가 끝내줄게."
        case .guardDefense:
            return "급할 필요 없어. 버티고,\n흐름을 읽고, 기회를 만들어.\n내 템포로 가는 거야."
        }
    }
    
    /// PositionType으로 변환
    public var positionType: PositionType {
        switch self {
        case .topAttack:
            return .top
        case .topControl:
            return .side
        case .guardAttack:
            return .guard
        case .guardDefense:
            return .turtle
        }
    }
    
    /// PositionType에서 PositionStyle로 변환
    public static func from(positionType: PositionType) -> PositionStyle? {
        switch positionType {
        case .top:
            return .topAttack
        case .side:
            return .topControl
        case .guard:
            return .guardAttack
        case .turtle:
            return .guardDefense
        case .mount, .back:
            return nil  // 현재 UI에서 지원하지 않는 타입
        }
    }
    
    /// 배경 색상 (그라데이션 용)
    public var backgroundColors: (top: String, bottom: String) {
        switch self {
        case .topAttack:
            return ("#8B4513", "#5C3317")  // 갈색 계열
        case .topControl:
            return ("#2F4F2F", "#1C3A1C")  // 진한 초록 계열
        case .guardAttack:
            return ("#B8C951", "#7A9F35")  // 연두-초록 그라데이션
        case .guardDefense:
            return ("#6B8E23", "#4A6B1C")  // 올리브 초록 계열
        }
    }
    
    /// 아이콘 이미지 이름
    public var iconName: String {
        switch self {
        case .topAttack:
            return "icon_position_top_attack"
        case .topControl:
            return "icon_position_top_control"
        case .guardAttack:
            return "icon_position_guard_attack"
        case .guardDefense:
            return "icon_position_guard_defense"
        }
    }
}

/// 스타일 카테고리 (탭)
public enum StyleCategory: String, CaseIterable, Equatable, Sendable {
    case top = "TOP"
    case `guard` = "GUARD"
    
    public var displayName: String {
        switch self {
        case .top:
            return "특기"
        case .guard:
            return "최애"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .top:
            return "탑포지션"
        case .guard:
            return "가드포지션"
        }
    }
}
