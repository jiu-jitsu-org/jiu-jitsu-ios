import SwiftUI
import ComposableArchitecture

// MARK: - Main View
public struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>
    
    public init(store: StoreOf<MainFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // 배경색 (임시)
                Color.blue.opacity(0.8).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Oss")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Spacer().frame(height: 50)
                    
                    // 임시 버튼 목록
                    VStack(spacing: 20) {
                        Button {
                            store.send(.profileButtonTapped)
                        } label: {
                            Text("프로필 이동")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            store.send(.settingsButtonTapped)
                        } label: {
                            Text("설정 화면 이동")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            // 네비게이션 목적지 처리
            .navigationDestination(
                item: $store.scope(state: \.destination?.settings, action: \.destination.settings)
            ) { store in
                // 실제 SettingsView가 있다면 교체하세요
                SettingsView(store: store)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.loginModal, action: \.loginModal)
        ) { loginStore in
            LoginView(store: loginStore)
        }
    }
}
