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
    
    /// 타입 명 (설정 제외)
    public var title: String {
        switch self {
        case .position: return "포지션"
        case .submission: return "서브미션"
        case .technique: return "기술"
        }
    }
    
    /// 네비게이션 타이틀 (설정 포함)
    public var navigationTitle: String {
        return "\(title) 설정"
    }
}

// MARK: - Style Protocol

public protocol StyleSelectable: Identifiable, Equatable, Sendable {
    var id: String { get }
    var rawValue: String { get }
    
    // UI 전용 속성
    var fullTitle: String { get }              // 타이틀 (풀 네임): "탑 포지션", "가드 포지션"
    var shortTitle: String { get }             // 요약된 타이틀: "탑", "가드"
    var tabTitle: String { get }               // 탭에 표시될 타이틀: "탑포지션", "가드포지션"
    var cardDescription: String { get }        // 카드에 들어갈 약 3줄의 설명
    var backgroundImageName: String { get }    // 카드 백그라운드 이미지
    var iconImageName: String { get }          // 카드에 들어갈 아이콘
    var smallCardColorHex: String { get }      // 작은 카드 배경색 (16진수)
}

// MARK: - Domain Extension: PositionType + UI

extension PositionType: StyleSelectable {
    /// 타이틀 (풀 네임)
    public var fullTitle: String {
        switch self {
        case .top:
            return "탑 포지션"
        case .guard:
            return "가드 포지션"
        }
    }
    
    /// 요약된 타이틀
    public var shortTitle: String {
        switch self {
        case .top:
            return "탑"
        case .guard:
            return "가드"
        }
    }
    
    /// 탭에 표시될 타이틀
    public var tabTitle: String {
        switch self {
        case .top:
            return "탑 포지션"
        case .guard:
            return "가드 포지션"
        }
    }
    
    /// 카드에 들어갈 설명 (약 3줄)
    public var cardDescription: String {
        switch self {
        case .top:
            return "이 매트 위에서 '선다'는 건 없어.\n'아직 넘어지지 않았다'만 있을 뿐.\n그리고 그 시간은, 이제 끝났어."
        case .guard:
            return "이 매트 위에서 '선다'는 건 없어.\n'아직 넘어지지 않았다'만 있을 뿐.\n그리고 그 시간은, 이제 끝났어."
        }
    }
    
    /// 카드 백그라운드 이미지
    public var backgroundImageName: String {
        switch self {
        case .top:
            return "bg_position_top"
        case .guard:
            return "bg_position_guard"
        }
    }
    
    /// 카드 아이콘 이미지
    public var iconImageName: String {
        switch self {
        case .top:
            return "icon_position_top"
        case .guard:
            return "icon_position_guard"
        }
    }
    
    /// 작은 카드 배경색
    public var smallCardColorHex: String {
        switch self {
        case .top:
            return "#341F1A"
        case .guard:
            return "#355530"
        }
    }
}

// MARK: - Domain Extension: SubmissionType + UI

extension SubmissionType: StyleSelectable {
    /// 타이틀 (풀 네임)
    public var fullTitle: String {
        switch self {
        case .armLocks:
            return "팔 관절기"
        case .chokes:
            return "조르기"
        case .legLocks:
            return "하체 관절기"
        }
    }
    
    /// 요약된 타이틀
    public var shortTitle: String {
        switch self {
        case .armLocks:
            return "팔"
        case .chokes:
            return "조르"
        case .legLocks:
            return "하체"
        }
    }
    
    /// 탭에 표시될 타이틀
    public var tabTitle: String {
        switch self {
        case .armLocks:
            return "팔 관절기"
        case .chokes:
            return "조르기"
        case .legLocks:
            return "하체 관절기"
        }
    }
    
    /// 카드에 들어갈 설명 (약 3줄)
    public var cardDescription: String {
        switch self {
        case .armLocks:
            return "도망갈 곳은 없어. 네 팔은 내 손아귀에 완벽히 잡혔으니까.\n남은 건 네 결정뿐."
        case .chokes:
            return "내 몸은 아나콘다, 넌 그냥 먹잇감.\n탭이 늦으면, 네 뼈가 먼저 비명을 지를 거다."
        case .legLocks:
            return "네가 아무리 발버둥 쳐도 소용없어. 네 하체는 이제 완벽하게\n내 통제하에 들어왔으니까."
        }
    }
    
    /// 카드 백그라운드 이미지
    public var backgroundImageName: String {
        switch self {
        case .armLocks:
            return "bg_submission_armlock"
        case .chokes:
            return "bg_submission_choke"
        case .legLocks:
            return "bg_submission_leglock"
        }
    }
    
    /// 카드 아이콘 이미지
    public var iconImageName: String {
        switch self {
        case .armLocks:
            return "icon_submission_armlock"
        case .chokes:
            return "icon_submission_choke"
        case .legLocks:
            return "icon_submission_leglock"
        }
    }
    
    /// 작은 카드 배경색
    public var smallCardColorHex: String {
        switch self {
        case .armLocks:
            return "#0A6B59"
        case .chokes:
            return "#8A64F9"
        case .legLocks:
            return "#156A7E"
        }
    }
}

// MARK: - Domain Extension: TechniqueType + UI

extension TechniqueType: StyleSelectable {
    /// 타이틀 (풀 네임)
    public var fullTitle: String {
        switch self {
        case .takedowns:
            return "테이크다운"
        case .sweeps:
            return "스윕 · 뒤집기"
        case .escapes:
            return "이스케이프\n디펜스"
        case .guardPasses:
            return "가드패스"
        }
    }
    
    /// 요약된 타이틀
    public var shortTitle: String {
        switch self {
        case .takedowns:
            return "테이"
        case .sweeps:
            return "스윕"
        case .escapes:
            return "이스"
        case .guardPasses:
            return "패스"
        }
    }
    
    /// 탭에 표시될 타이틀
    public var tabTitle: String {
        switch self {
        case .takedowns:
            return "테이크다운"
        case .sweeps:
            return "스윕 · 뒤집기"
        case .escapes:
            return "이스케이프 디펜스"
        case .guardPasses:
            return "가드패스"
        }
    }
    
    /// 카드에 들어갈 설명 (약 3줄)
    public var cardDescription: String {
        switch self {
        case .takedowns:
            return "이 매트 위에서 '선다'는 건 없어.\n'아직 넘어지지 않았다'만 있을 뿐.\n그리고 그 시간은, 이제 끝났어."
        case .sweeps:
            return "지금 네가 보는 천장, 곧 네 등이 마주할 매트가 될 거다. 세상이 뒤집히는 기분을 즐겨보라고."
        case .escapes:
            return "계속 그렇게 힘을 낭비해. 네가 헛된 그림자에 매달려 있을 때,\n난 이미 사라지고 없을 걸?"
        case .guardPasses:
            return "계속 막아봐.\n네 다리는 고작 두 개뿐이지만,\n내가 뚫을 패스는 무한하거든."
        }
    }
    
    /// 카드 백그라운드 이미지
    public var backgroundImageName: String {
        switch self {
        case .takedowns:
            return "bg_technique_takedown"
        case .sweeps:
            return "bg_technique_sweep"
        case .escapes:
            return "bg_technique_escape"
        case .guardPasses:
            return "bg_technique_guardpass"
        }
    }
    
    /// 카드 아이콘 이미지
    public var iconImageName: String {
        switch self {
        case .takedowns:
            return "icon_technique_takedown"
        case .sweeps:
            return "icon_technique_sweep"
        case .escapes:
            return "icon_technique_escape"
        case .guardPasses:
            return "icon_technique_guardpass"
        }
    }
    
    /// 작은 카드 배경색
    public var smallCardColorHex: String {
        switch self {
        case .takedowns:
            return "#009DAE"
        case .sweeps:
            return "#F769C4"
        case .escapes:
            return "#F07613"
        case .guardPasses:
            return "#4F535B"
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
