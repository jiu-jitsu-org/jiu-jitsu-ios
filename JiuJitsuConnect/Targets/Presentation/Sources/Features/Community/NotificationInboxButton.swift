//
//  NotificationInboxButton.swift
//  Presentation
//
//  머리줄 오른쪽의 알림함 종 + 새 알림 점. 홈과 대회 탭(#258)이 함께 써서 크기·점 위치가 어긋나지 않게 한다.
//

import SwiftUI
import DesignSystem

struct NotificationInboxButton: View {
    let hasUnread: Bool
    let action: () -> Void

    private enum Metrics {
        // 홈 머리줄의 다른 아이콘 버튼(검색·내 사진)과 같은 크기
        static let iconSize: CGFloat = 24
        static let buttonSize: CGFloat = 40
        // 새 알림 점: 6pt 원 + 바깥 1pt 테두리. 빨간 원이 종 아이콘(24pt) 상단에 딱 붙고 오른쪽에서 1pt 안쪽에 겹친다.
        static let dotSize: CGFloat = 6
        static let dotStrokeWidth: CGFloat = 1
        static let dotTrailingInset: CGFloat = 1
    }

    var body: some View {
        Button(action: action) {
            Assets.Common.Icon.inbox.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                .foregroundStyle(Color.component.header.iconButton)
                .overlay(alignment: .topTrailing) {
                    if hasUnread {
                        dot
                    }
                }
                .frame(width: Metrics.buttonSize, height: Metrics.buttonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("알림함")
        .accessibilityValue(hasUnread ? "새 알림 있음" : "")
    }

    // 테두리는 바깥(outside) 정렬이라 6pt 원 뒤에 테두리 두께만큼 큰 원을 깔아 표현한다.
    // 위치는 빨간 원 기준이라 테두리는 아이콘 위·오른쪽 바깥으로 1pt씩 걸칠 수 있다.
    private var dot: some View {
        Circle()
            .fill(Color.primitive.red.notification)
            .frame(width: Metrics.dotSize, height: Metrics.dotSize)
            .background {
                Circle()
                    .fill(Color.primitive.bw.white)
                    .padding(-Metrics.dotStrokeWidth)
            }
            .padding(.trailing, Metrics.dotTrailingInset)
    }
}

#Preview {
    HStack {
        NotificationInboxButton(hasUnread: false) {}
        NotificationInboxButton(hasUnread: true) {}
    }
}
