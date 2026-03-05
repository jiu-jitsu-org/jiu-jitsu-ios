//
//  MyStyleSettingFeature.swift
//  Presentation
//
//  Created by suni on 2/22/26.
//

import Foundation
import ComposableArchitecture
import Domain

// MARK: - Setting Type

public enum MyStyleSettingType: Sendable, Equatable {
    case position
    case submission
    case technique
    
    public var navigationTitle: String {
        switch self {
        case .position: return "포지션 설정"
        case .submission: return "서브미션 설정"
        case .technique: return "기술 설정"
        }
    }
}

// MARK: - Style Protocol

public protocol StyleSelectable: Identifiable, Equatable, Sendable {
    var id: String { get }
    var rawValue: String { get }
    var displayName: String { get }
    
    // UI 전용 속성
    var description: String { get }
    var backgroundColors: (top: String, bottom: String) { get }
    var iconName: String { get }
}

// MARK: - Domain Extension: PositionType + UI

extension PositionType: StyleSelectable {
    /// UI용 상세 설명
    public var description: String {
        switch self {
        case .top:
            return "이 매트 위에서 '선다'는 건 없어.\n'아직 넘어지지 않았다'란 있을 뿐.\n그리고 그 시간은, 이제 끝났어."
        case .side:
            return "서두르지 않아. 압박을 주고,\n상대를 무너뜨린 뒤,\n천천히 마무리해."
        case .guard:
            return "누워있다고 당하는 게 아니야.\n오히려 여기가 내 무대.\n올라와봐, 내가 끝내줄게."
        case .turtle:
            return "급할 필요 없어. 버티고,\n흐름을 읽고, 기회를 만들어.\n내 템포로 가는 거야."
        case .mount:
            return "가장 지배적인 위치.\n여기서는 내가 왕이야."
        case .back:
            return "등을 보인 순간,\n게임은 끝났어."
        }
    }
    
    /// UI용 배경 색상 (그라데이션)
    public var backgroundColors: (top: String, bottom: String) {
        switch self {
        case .top:
            return ("#8B4513", "#5C3317")  // 갈색 계열
        case .side:
            return ("#2F4F2F", "#1C3A1C")  // 진한 초록 계열
        case .guard:
            return ("#B8C951", "#7A9F35")  // 연두-초록 그라데이션
        case .turtle:
            return ("#6B8E23", "#4A6B1C")  // 올리브 초록 계열
        case .mount:
            return ("#8B0000", "#4A0000")  // 진한 빨강 계열
        case .back:
            return ("#1C1C1C", "#000000")  // 검정 계열
        }
    }
    
    /// UI용 아이콘 이미지 이름
    public var iconName: String {
        switch self {
        case .top:
            return "icon_position_top"
        case .side:
            return "icon_position_side"
        case .guard:
            return "icon_position_guard"
        case .turtle:
            return "icon_position_turtle"
        case .mount:
            return "icon_position_mount"
        case .back:
            return "icon_position_back"
        }
    }
}

// MARK: - Domain Extension: SubmissionType + UI

extension SubmissionType: StyleSelectable {
    /// UI용 상세 설명
    public var description: String {
        switch self {
        case .armLocks:
            return "팔을 잡았다면,\n그건 이미 끝난 거야.\n저항? 그건 네 선택이지만."
        case .chokes:
            return "숨을 끊는 순간,\n모든 게 조용해져.\n잘 자, 편히."
        case .legLocks:
            return "다리를 잡았어?\n이제 걷기 힘들 거야.\n아플 테니 조심해."
        case .shoulderLocks:
            return "어깨가 빠지기 전에\n탭하는 게 좋을 거야.\n안 그러면 후회해."
        case .spineLocks:
            return "척추는 소중하니까,\n빨리 탭하는 게 현명해."
        }
    }
    
    /// UI용 배경 색상 (그라데이션)
    public var backgroundColors: (top: String, bottom: String) {
        switch self {
        case .armLocks:
            return ("#DC143C", "#8B0000")  // 빨강 계열
        case .chokes:
            return ("#FF8C00", "#FF4500")  // 주황 계열
        case .legLocks:
            return ("#9370DB", "#6A5ACD")  // 보라 계열
        case .shoulderLocks:
            return ("#4169E1", "#191970")  // 파랑 계열
        case .spineLocks:
            return ("#2E8B57", "#006400")  // 녹색 계열
        }
    }
    
    /// UI용 아이콘 이미지 이름
    public var iconName: String {
        switch self {
        case .armLocks:
            return "icon_submission_armlock"
        case .chokes:
            return "icon_submission_choke"
        case .legLocks:
            return "icon_submission_leglock"
        case .shoulderLocks:
            return "icon_submission_shoulderlock"
        case .spineLocks:
            return "icon_submission_spinelock"
        }
    }
}

// MARK: - Domain Extension: TechniqueType + UI

extension TechniqueType: StyleSelectable {
    /// UI용 상세 설명
    public var description: String {
        switch self {
        case .takedowns:
            return "서있는 상태에서 시작해서\n매트에 눕히는 건,\n내가 제일 잘하는 거야."
        case .sweeps:
            return "아래에서 위로,\n한 번의 움직임으로 역전.\n이게 바로 스윕이지."
        case .escapes:
            return "갇혔다고? 천만에.\n언제든 빠져나갈 수 있어,\n내가 원할 때 말이야."
        case .transitions:
            return "포지션에서 포지션으로,\n끊임없이 움직이며\n상대를 혼란에 빠뜨려."
        case .guardPasses:
            return "가드를 뚫는 건\n예술이야. 인내심과\n기술의 조화지."
        }
    }
    
    /// UI용 배경 색상 (그라데이션)
    public var backgroundColors: (top: String, bottom: String) {
        switch self {
        case .takedowns:
            return ("#FFD700", "#FFA500")  // 금색 계열
        case .sweeps:
            return ("#00CED1", "#4682B4")  // 청록 계열
        case .escapes:
            return ("#32CD32", "#228B22")  // 연두 계열
        case .transitions:
            return ("#FF69B4", "#C71585")  // 핑크 계열
        case .guardPasses:
            return ("#8A2BE2", "#4B0082")  // 보라 계열
        }
    }
    
    /// UI용 아이콘 이미지 이름
    public var iconName: String {
        switch self {
        case .takedowns:
            return "icon_technique_takedown"
        case .sweeps:
            return "icon_technique_sweep"
        case .escapes:
            return "icon_technique_escape"
        case .transitions:
            return "icon_technique_transition"
        case .guardPasses:
            return "icon_technique_guardpass"
        }
    }
}

// MARK: - Feature

@Reducer
public struct MyStyleSettingFeature: Sendable {
    public init() {}
    
    public enum SelectionTab: String, CaseIterable, Equatable, Sendable {
        case best
        case favorite
        
        public var displayName: String {
            switch self {
            case .best: return "특기"
            case .favorite: return "최애"
            }
        }
    }
    
    @ObservableState
    public struct State: Equatable, Sendable {
        // 설정 타입 (포지션/서브미션/기술)
        var settingType: MyStyleSettingType
        
        // 탭 선택 (특기/최애)
        var selectedTab: SelectionTab = .best
        
        // 포지션 선택
        var selectedBestPosition: PositionType?
        var selectedFavoritePosition: PositionType?
        
        // 서브미션 선택
        var selectedBestSubmission: SubmissionType?
        var selectedFavoriteSubmission: SubmissionType?
        
        // 기술 선택
        var selectedBestTechnique: TechniqueType?
        var selectedFavoriteTechnique: TechniqueType?
        
        public init(
            settingType: MyStyleSettingType,
            bestPosition: PositionType? = nil,
            favoritePosition: PositionType? = nil
        ) {
            self.settingType = settingType
            self.selectedBestPosition = bestPosition
            self.selectedFavoritePosition = favoritePosition
        }
        
        // 현재 타입의 모든 스타일 목록 (특기/최애 탭 모두 동일)
        var availableStyles: [any StyleSelectable] {
            switch settingType {
            case .position:
                return PositionType.allCases
            case .submission:
                return SubmissionType.allCases
            case .technique:
                return TechniqueType.allCases
            }
        }
        
        // 현재 선택된 특기 스타일
        var selectedBestStyle: (any StyleSelectable)? {
            switch settingType {
            case .position: return selectedBestPosition
            case .submission: return selectedBestSubmission
            case .technique: return selectedBestTechnique
            }
        }
        
        // 현재 선택된 최애 스타일
        var selectedFavoriteStyle: (any StyleSelectable)? {
            switch settingType {
            case .position: return selectedFavoritePosition
            case .submission: return selectedFavoriteSubmission
            case .technique: return selectedFavoriteTechnique
            }
        }
        
        // 현재 탭에서 선택된 스타일
        var currentSelectedStyle: (any StyleSelectable)? {
            switch selectedTab {
            case .best: return selectedBestStyle
            case .favorite: return selectedFavoriteStyle
            }
        }
        
        // 완료 버튼 활성화 조건
        var canComplete: Bool {
            selectedBestStyle != nil
        }
    }
    
    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)
        
        public enum ViewAction: Sendable {
            case tabSelected(SelectionTab)
            case styleCardTapped(any StyleSelectable)
            case completeButtonTapped
            case backButtonTapped
            case resetButtonTapped
        }
        
        public enum DelegateAction: Sendable {
            case didConfirmStyles(best: String?, favorite: String?)
            case cancel
        }
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(.tabSelected(tab)):
                state.selectedTab = tab
                return .none
                
            case let .view(.styleCardTapped(style)):
                // 현재 탭에 따라 적절한 저장소에 저장
                switch state.settingType {
                case .position:
                    if let positionStyle = style as? PositionType {
                        switch state.selectedTab {
                        case .best:
                            // 특기 선택/해제
                            if state.selectedBestPosition == positionStyle {
                                state.selectedBestPosition = nil
                            } else {
                                state.selectedBestPosition = positionStyle
                            }
                        case .favorite:
                            // 최애 선택/해제
                            if state.selectedFavoritePosition == positionStyle {
                                state.selectedFavoritePosition = nil
                            } else {
                                state.selectedFavoritePosition = positionStyle
                            }
                        }
                    }
                    
                case .submission:
                    if let submissionStyle = style as? SubmissionType {
                        switch state.selectedTab {
                        case .best:
                            if state.selectedBestSubmission == submissionStyle {
                                state.selectedBestSubmission = nil
                            } else {
                                state.selectedBestSubmission = submissionStyle
                            }
                        case .favorite:
                            if state.selectedFavoriteSubmission == submissionStyle {
                                state.selectedFavoriteSubmission = nil
                            } else {
                                state.selectedFavoriteSubmission = submissionStyle
                            }
                        }
                    }
                    
                case .technique:
                    if let techniqueStyle = style as? TechniqueType {
                        switch state.selectedTab {
                        case .best:
                            if state.selectedBestTechnique == techniqueStyle {
                                state.selectedBestTechnique = nil
                            } else {
                                state.selectedBestTechnique = techniqueStyle
                            }
                        case .favorite:
                            if state.selectedFavoriteTechnique == techniqueStyle {
                                state.selectedFavoriteTechnique = nil
                            } else {
                                state.selectedFavoriteTechnique = techniqueStyle
                            }
                        }
                    }
                }
                return .none
                
            case .view(.completeButtonTapped):
                guard state.canComplete else { return .none }
                
                // API 키만 추출해서 전달 (rawValue 사용)
                let bestKey = state.selectedBestStyle?.rawValue
                let favoriteKey = state.selectedFavoriteStyle?.rawValue
                
                return .send(.delegate(.didConfirmStyles(best: bestKey, favorite: favoriteKey)))
                
            case .view(.backButtonTapped):
                return .send(.delegate(.cancel))
                
            case .view(.resetButtonTapped):
                // 타입별로 리셋
                switch state.settingType {
                case .position:
                    state.selectedBestPosition = nil
                    state.selectedFavoritePosition = nil
                case .submission:
                    state.selectedBestSubmission = nil
                    state.selectedFavoriteSubmission = nil
                case .technique:
                    state.selectedBestTechnique = nil
                    state.selectedFavoriteTechnique = nil
                }
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
