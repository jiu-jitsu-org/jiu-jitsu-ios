//
//  View+AppAlertStyle.swift
//  DesignSystem
//
//  Created by suni on 11/23/25.
//

import SwiftUI

// MARK: - Host item
/// 화면 어디서 .appAlert를 호출해도 같은 host(보통 AppTabView)의 overlay에 단일 알럿이 표시되도록
/// 전달되는 단위. id로 식별해 자기가 띄운 알럿만 안전하게 정리할 수 있게 한다.
struct AppAlertItem: Identifiable {
    let id: UUID
    let configuration: AppAlertConfiguration
    let dismiss: () -> Void
}

// MARK: - Environment
// EnvironmentValues에 Binding을 노출해 child의 .appAlert가 host의 @State에 직접 read/write 한다.
// PreferenceKey는 iOS 17+에서 onPreferenceChange가 Sendable을 요구해 closure를 포함한 item을 담을 수 없으므로
// Environment binding 패턴을 사용한다.
private struct AppAlertHostKey: EnvironmentKey {
    static let defaultValue: Binding<AppAlertItem?> = .constant(nil)
}

extension EnvironmentValues {
    var appAlertHost: Binding<AppAlertItem?> {
        get { self[AppAlertHostKey.self] }
        set { self[AppAlertHostKey.self] = newValue }
    }
}

// MARK: - Host modifier (root에 한 번 적용)
private struct AppAlertHostModifier: ViewModifier {
    @State private var item: AppAlertItem?

    func body(content: Content) -> some View {
        content
            .environment(\.appAlertHost, $item)
            .overlay {
                if let item {
                    AppAlertView(configuration: item.configuration, dismiss: item.dismiss)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: item?.id)
    }
}

public extension View {
    /// child 화면의 `.appAlert(isPresented:configuration:)`가 띄우는 알럿을 이 view 위에 호스팅한다.
    /// 보통 AppTabView body의 가장 바깥 modifier로 한 번만 적용한다.
    /// 적용된 view 위에 overlay가 그려지므로 탭바를 포함한 화면 전체를 dim이 덮는다.
    func appAlertHost() -> some View {
        self.modifier(AppAlertHostModifier())
    }
}

// MARK: - Trigger modifier (각 화면에 적용)
private struct AppAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: AppAlertConfiguration

    @Environment(\.appAlertHost) private var host
    // 자기가 띄운 알럿의 id를 기억해, 다른 화면이 host를 차지한 동안 잘못 정리하지 않게 한다.
    @State private var presentedID: UUID?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                syncHost(isPresented: newValue)
            }
            .onDisappear {
                clearIfMine()
            }
    }

    private func syncHost(isPresented presented: Bool) {
        if presented {
            let id = UUID()
            presentedID = id
            // dismiss closure에서 binding을 통해 isPresented를 false로 되돌리면
            // 위 onChange가 다시 호출되어 host item을 정리한다.
            let isPresentedBinding = $isPresented
            host.wrappedValue = AppAlertItem(
                id: id,
                configuration: configuration,
                dismiss: {
                    isPresentedBinding.wrappedValue = false
                }
            )
        } else {
            clearIfMine()
        }
    }

    private func clearIfMine() {
        guard let id = presentedID, host.wrappedValue?.id == id else { return }
        host.wrappedValue = nil
        presentedID = nil
    }
}

public extension View {
    func appAlert(isPresented: Binding<Bool>, configuration: AppAlertConfiguration) -> some View {
        self.modifier(AppAlertModifier(isPresented: isPresented, configuration: configuration))
    }
}
