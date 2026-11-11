//
//  TabRootScroll.swift
//  Presentation
//

import SwiftUI

/// 탭 첫 화면(홈 피드·대회 목록·MY)이 스크롤할 때 AppTabView에 알리는 길(#267).
/// 아래로 내리면 탭 바를 숨기고 맨 위로 버튼을 띄우며, 위로 올리면 탭 바를 다시 꺼낸다.
/// AppTabView가 탭 첫 화면에만 넣고, 쌓인 화면(상세 등)에는 넣지 않는다.
struct TabRootScrollAction: Equatable {
    /// 같은 탭이면 같은 값으로 본다. AppTabView가 그릴 때마다 새로 만들어도 탭 첫 화면을 다시 그리지 않게 한다.
    /// (닫힌 함수는 AppTabView의 상태 저장소·store를 읽으므로 처음 만든 것을 그대로 써도 늘 지금 값을 본다.)
    let key: AnyHashable
    /// - offsetY: 맨 위에서 내려온 거리(0 이상)
    /// - maxOffsetY: 끝까지 내렸을 때의 거리
    /// - isUserScrolling: 손으로 끌거나 끌고 난 뒤 미끄러지는 중인지(코드가 옮긴 스크롤·레이아웃 변화는 false)
    let report: @MainActor (
        _ offsetY: CGFloat,
        _ maxOffsetY: CGFloat,
        _ isUserScrolling: Bool
    ) -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key
    }
}

extension EnvironmentValues {
    @Entry var tabRootScroll: TabRootScrollAction?
}
