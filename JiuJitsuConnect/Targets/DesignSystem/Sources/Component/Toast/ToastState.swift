//
//  ToastState.swift
//  CoreKit
//
//  Created by suni on 9/22/25.
//

import Foundation

/// 화면 아래에 잠깐 떴다 사라지는 토스트.
///
/// 상태(`Status`)마다 왼쪽 아이콘만 바뀐다 — 모양·움직임은 같다. 웹 토스트(`shared/ui/toast.tsx`)와 맞춘다.
/// 되돌리거나 다시 할 수 있는 동작은 `button`을 넘겨 오른쪽 글자 버튼을 함께 띄운다.
public struct ToastState: Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var message: String
    public var status: Status
    public var button: ButtonItem?
    public var bottomPadding: CGFloat

    public init(message: String,
                status: Status = .info,
                button: ButtonItem? = nil,
                bottomPadding: CGFloat = 24) {
        self.message = message
        self.status = status
        self.button = button
        self.bottomPadding = bottomPadding
    }

    /// 왼쪽 아이콘.
    public enum Status: Equatable, Sendable, CaseIterable {
        /// 완료 — 요청이 끝났을 때("포지션을 저장했어요")
        case success
        /// 안내 — 상태가 바뀌었거나 알려줄 것이 있을 때("시간이 지나 가입이 중단됐어요")
        case info
        /// 주의 — 한도에 닿았거나 지금은 할 수 없을 때
        case warning
        /// 실패 — 요청이 실패했을 때("저장에 실패했어요")
        case error
    }

    /// 오른쪽 글자 버튼.
    public struct ButtonItem: Equatable, Sendable {
        public var title: String
        public var action: Action

        public init(title: String, action: Action) {
            self.title = title
            self.action = action
        }
    }

    // 버튼이 눌렸을 때 Reducer가 어떤 동작을 할지 정의
    public enum Action: Equatable, Sendable {
        case done

        public var description: String {
            switch self {
            case .done:
                return "done"
            }
        }
    }

    /// 떠 있는 시간 — 웹과 같다. 버튼이 있으면 문구를 읽고 누를 시간이 필요해 더 오래 둔다.
    public var duration: Duration {
        button == nil ? .seconds(2) : .seconds(5)
    }
}
