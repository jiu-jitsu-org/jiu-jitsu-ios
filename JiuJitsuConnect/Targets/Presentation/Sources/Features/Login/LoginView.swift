import SwiftUI
import ComposableArchitecture

public struct LoginView: View {
    let store: StoreOf<LoginFeature>
    
    public init(store: StoreOf<LoginFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 상단 여백 및 타이틀
            Spacer()
            
            Text("JiuJitsuConnect")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("로그인하고 모든 기능을 이용해보세요")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top, 8)
            
            Spacer()
            
            // MARK: - 소셜 로그인 버튼
            VStack(spacing: 12) {
                // 카카오 로그인 버튼
                Button(action: { store.send(.kakaoButtonTapped) }) {
                    SocialLoginButton(
                        imageName: "kakao.logo", // 카카오 로고 이미지 이름
                        text: "카카오로 시작하기",
                        backgroundColor: Color(red: 254/255, green: 229/255, blue: 0/255),
                        foregroundColor: .black
                    )
                }
                
                // 구글 로그인 버튼
                Button(action: { store.send(.googleButtonTapped) }) {
                    SocialLoginButton(
                        imageName: "google.logo", // 구글 로고 이미지 이름
                        text: "Google로 시작하기",
                        backgroundColor: .white,
                        foregroundColor: .black,
                        borderColor: .gray.opacity(0.5)
                    )
                }
                
                // 애플 로그인 버튼
                Button(action: { store.send(.appleButtonTapped) }) {
                    SocialLoginButton(
                        imageName: "apple.logo", // 애플 로고 이미지 이름
                        text: "Apple로 계속하기",
                        backgroundColor: .black,
                        foregroundColor: .white
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // MARK: - 둘러보기 버튼
            Button(action: { store.send(.aroundButtonTapped) }) {
                Text("둘러보기")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .padding()
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - 재사용 가능한 소셜 로그인 버튼 View
struct SocialLoginButton: View {
    let imageName: String
    let text: String
    let backgroundColor: Color
    let foregroundColor: Color
    var borderColor: Color = .clear // 테두리 색상 (선택 사항)

    var body: some View {
        HStack {
            Image(imageName) // 로고 이미지
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            Spacer()
            
            Text(text)
                .fontWeight(.semibold)
            
            Spacer()
            
            // 너비 맞추기 위한 빈 공간
            Color.clear.frame(width: 20, height: 20)
        }
        .padding()
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}
