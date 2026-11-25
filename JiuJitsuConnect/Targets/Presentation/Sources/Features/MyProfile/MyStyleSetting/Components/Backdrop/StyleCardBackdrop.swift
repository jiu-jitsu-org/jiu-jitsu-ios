//
//  StyleCardBackdrop.swift
//  Presentation
//
//  최애 기술 카드 앞면 바탕 그래픽(#495).
//  시안: https://claude.ai/artifact/6RZj9W2WfmtF5PfRNibvXk (2차)
//

import SwiftUI
import DesignSystem
import Domain

/// 최애 기술 카드 앞면 바탕 시안
///
/// 모든 시안은 기술마다 그림이 다르다. 기술의 힘(누르기 · 메치기 · 조이기 · 돌리기 · 뚫기 · 깨고 나오기…)을
/// `StyleImpact`로 옮겨 충격 지점 · 방향 · 파편 모양을 정한다. 그림 파일 없이 `Canvas`로만 그린다.
enum StyleCardBackdrop: String, CaseIterable, Identifiable, Sendable {
    /// 1 충격 — 충격 지점에서 뾰족한 폭발, 파편이 기술의 방향으로 튄다
    case impact
    /// 2 맞부딪힘 — 내 쪽(띠 색)과 상대 쪽(회색)이 톱니처럼 맞물려 부딪힌다
    case clash
    /// 3 파편 — 밝은 바탕이 유리처럼 깨진다
    case shatter
    /// 4 의성어 — 기술의 소리(꾸욱 · 쿠웅 …)와 폭발
    case soundEffect
    /// 5 잔상 충격 — 잔상 + 앞쪽 폭발
    case echoImpact
    /// 6 점수 충격 — 점수가 폭발 한가운데서 터져 나온다
    case scoreImpact
    /// E 점수판 — 1차에서 남긴 안
    case scoreboard
    /// M 잔상 — 1차에서 남긴 안
    case echo

    /// 앱에 쓰는 시안. 다른 시안을 쓰려면 여기만 바꾼다.
    static let current: StyleCardBackdrop = .impact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .impact: return "충격"
        case .clash: return "맞부딪힘"
        case .shatter: return "파편"
        case .soundEffect: return "의성어"
        case .echoImpact: return "잔상 충격"
        case .scoreImpact: return "점수 충격"
        case .scoreboard: return "점수판"
        case .echo: return "잔상"
        }
    }

    /// 어두운 바탕 — 위 글자를 흰색으로 쓴다
    var isDark: Bool { self != .shatter }

    /// 캐릭터 그림을 바탕에 다시 쓰는 시안(잔상)
    var usesPoseImage: Bool { self == .echo || self == .echoImpact }
}

// MARK: - 띠별 색

/// 바탕 그래픽에 쓰는 띠별 색 한 벌. DesignSystem 토큰을 띠에 맞게 모은다.
struct StyleCardBackdropColors {
    let deep: Color
    let base: Color
    let mid: Color
    let light: Color
    let tint: Color
    let soft: Color
    let strap: Color
    let glow: Color
    let glowOpacity: Double
    /// 띠 끝 칸 — 검정띠만 빨강
    let rank: Color
    /// 띠 색 그대로(흰띠는 순백)
    let beltLine: Color
    /// 파편에 섞는 포인트 — 검정띠는 띠 끝 빨강, 나머지는 밝은 띠 색
    let accent: Color
    /// 밝은 바탕 위 글자
    let ink: Color
    let inkText: Color
    let opponent: Color
    let opponentDeep: Color
    let opponentSpark: Color

    init(belt: BeltRank) {
        let tokens = Color.component.myBelt
        let set = tokens.styleCardBackdrop
        let palette: ComponentColors.MyBelt.StyleCardBackdrop.Palette
        switch belt {
        case .white: palette = set.white
        case .blue: palette = set.blue
        case .purple: palette = set.purple
        case .brown: palette = set.brown
        case .black: palette = set.black
        }
        let tone = belt.styleCardTone
        deep = palette.deep
        base = palette.base
        mid = palette.mid
        light = palette.light
        tint = tone.background
        soft = palette.soft
        strap = palette.strap
        glow = palette.glow
        glowOpacity = palette.glowOpacity
        rank = belt == .black ? tokens.blackRankBar : tokens.ringRankBar
        beltLine = belt.beltSurfaceColor
        accent = belt == .black ? tokens.blackRankBar : palette.light
        ink = tone.title
        inkText = tone.text
        opponent = set.opponent
        opponentDeep = set.opponentDeep
        opponentSpark = set.opponentSpark
    }
}

// MARK: - 기술마다 다른 힘

/// 기술의 힘을 바탕 그림으로 옮기는 값. 좌표는 카드(262×394) 기준.
struct StyleImpact: Sendable {
    enum Kind: Sendable {
        /// 위에서 내리누름(탑)
        case press
        /// 밀고 오는 힘을 막아 튕겨 냄(가드)
        case block
        /// 한 점이 꺾이며 금이 감(팔 관절기)
        case snap
        /// 사방에서 안으로 조여듦(조르기)
        case squeeze
        /// 비틀며 감겨 들어감(하체 관절기)
        case twist
        /// 바닥에 꽂히는 충격(테이크다운)
        case slam
        /// 돌며 뒤집힘(스윕)
        case spin
        /// 갇힌 껍질을 깨고 빠져나옴(이스케이프)
        case breakOut
        /// 벽을 뚫고 지나감(가드패스)
        case through
    }

    let kind: Kind
    /// 충격 지점
    let point: CGPoint
    /// 캐릭터가 움직이는 방향(잔상 · 파편이 나가는 쪽)
    let move: CGVector
    /// 나 → 상대 방향(도) — 맞부딪힘 경계선 기울기
    let clashDegrees: CGFloat
    /// IBJJF 점수(서브미션은 TAP)
    let score: String
    /// 기술의 소리
    let soundEffect: String
    let soundEffectPoint: CGPoint
    let soundEffectDegrees: CGFloat
    /// 파편 배치를 기술마다 고정하는 씨앗
    let seed: Int
}

extension StyleSelectable {
    /// 이 기술의 힘. 모르는 스타일이면 팔 관절기 모양을 쓴다.
    var impact: StyleImpact {
        switch self {
        case let position as PositionType:
            switch position {
            case .top:
                return StyleImpact(
                    kind: .press, point: CGPoint(x: 131, y: 112), move: CGVector(dx: 0, dy: 1), clashDegrees: 0,
                    score: "+4", soundEffect: "꾸욱!", soundEffectPoint: CGPoint(x: 94, y: 56), soundEffectDegrees: -7, seed: 3
                )
            case .guard:
                return StyleImpact(
                    kind: .block, point: CGPoint(x: 104, y: 112), move: CGVector(dx: -1, dy: 0), clashDegrees: 180,
                    score: "PULL", soundEffect: "턱!", soundEffectPoint: CGPoint(x: 168, y: 56), soundEffectDegrees: 8, seed: 5
                )
            }
        case let submission as SubmissionType:
            switch submission {
            case .armLocks:
                return .armLock
            case .chokes:
                return StyleImpact(
                    kind: .squeeze, point: CGPoint(x: 131, y: 116), move: CGVector(dx: 1, dy: 0), clashDegrees: 0,
                    score: "TAP", soundEffect: "꽈악!", soundEffectPoint: CGPoint(x: 168, y: 56), soundEffectDegrees: 8, seed: 5
                )
            case .legLocks:
                return StyleImpact(
                    kind: .twist, point: CGPoint(x: 140, y: 132), move: CGVector(dx: 1, dy: 0), clashDegrees: 0,
                    score: "TAP", soundEffect: "우드득!", soundEffectPoint: CGPoint(x: 168, y: 56), soundEffectDegrees: 6, seed: 8
                )
            }
        case let technique as TechniqueType:
            switch technique {
            case .takedowns:
                return StyleImpact(
                    kind: .slam, point: CGPoint(x: 170, y: 204), move: CGVector(dx: 1, dy: 0.45), clashDegrees: 12,
                    score: "+2", soundEffect: "쿠웅!", soundEffectPoint: CGPoint(x: 94, y: 56), soundEffectDegrees: -8, seed: 8
                )
            case .sweeps:
                return StyleImpact(
                    kind: .spin, point: CGPoint(x: 131, y: 112), move: CGVector(dx: 0.7, dy: -0.7), clashDegrees: -45,
                    score: "+2", soundEffect: "휘릭!", soundEffectPoint: CGPoint(x: 94, y: 56), soundEffectDegrees: -10, seed: 5
                )
            case .escapes:
                return StyleImpact(
                    kind: .breakOut, point: CGPoint(x: 128, y: 112), move: CGVector(dx: 1, dy: 0), clashDegrees: 180,
                    score: "ESC", soundEffect: "쏘옥!", soundEffectPoint: CGPoint(x: 94, y: 56), soundEffectDegrees: -6, seed: 6
                )
            case .guardPasses:
                return StyleImpact(
                    kind: .through, point: CGPoint(x: 76, y: 112), move: CGVector(dx: 1, dy: 0), clashDegrees: 180,
                    score: "+3", soundEffect: "슈욱!", soundEffectPoint: CGPoint(x: 168, y: 56), soundEffectDegrees: 7, seed: 10
                )
            }
        default:
            return .armLock
        }
    }
}

private extension StyleImpact {
    static let armLock = StyleImpact(
        kind: .snap, point: CGPoint(x: 156, y: 96), move: CGVector(dx: 0, dy: -1), clashDegrees: 90,
        score: "TAP", soundEffect: "뚜둑!", soundEffectPoint: CGPoint(x: 94, y: 56), soundEffectDegrees: -8, seed: 8
    )
}
