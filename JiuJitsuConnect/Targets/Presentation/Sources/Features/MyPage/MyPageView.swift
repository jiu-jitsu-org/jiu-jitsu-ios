//
//  MyPageView.swift
//  Presentation
//
//  Created by suni on 12/7/25.
//

import SwiftUI
import DesignSystem
import ComposableArchitecture

public struct MyPageView: View {
    let store: StoreOf<MyPageFeature>
    
    public init(store: StoreOf<MyPageFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. 상단 프로필 헤더
                profileHeaderView
                
                VStack(spacing: 40) {
                    // 2. 벨트/체급 카드
                    beltWeightCardView
                    
                    // 3. 스타일 등록 영역
                    styleSectionView
                }
                .padding(.top, 30)
                .padding(.bottom, 50)
            }
        }
        .background(Color(uiColor: .systemGray6)) // 전체 배경색
        .ignoresSafeArea(edges: .top) // 헤더가 상단 Safe Area를 덮도록 설정
    }
    
    // MARK: - Subviews
    
    private var profileHeaderView: some View {
        ZStack {
            Color.blue // DesignSystem의 브랜드 컬러 사용 권장
            
            VStack(spacing: 16) {
                Spacer().frame(height: 60) // Safe Area 대응 여백
                
                // 프로필 이미지
                Image(systemName: "person.circle.fill") // Placeholder
                    .resizable()
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 80, height: 80)
                    .background(.white)
                    .clipShape(Circle())
                
                // 닉네임
                Text(store.authInfo.userInfo?.nickname ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                // 도장 정보 입력 버튼
                Button {
                    store.send(.gymInfoButtonTapped)
                } label: {
                    Text("도장 정보 입력하기")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white))
                }
                
                Spacer().frame(height: 30)
            }
        }
    }
    
    private var beltWeightCardView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "circle.inset.filled")
                    .foregroundStyle(Color.blue)
                Text("?? kg")
                    .foregroundStyle(.gray)
            }
            .font(.title3)
            
            Text("벨트와 체급이 어떻게 되세요?")
                .font(.headline)
                .foregroundStyle(.black)
            
            Button {
                store.send(.registerBeltButtonTapped)
            } label: {
                Text("벨트/체급 등록하기")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    private var styleSectionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("나의 주짓수를 보여주세요")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Text("특기와 최애 포지션, 기술 등을 등록해보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Button {
                store.send(.registerStyleButtonTapped)
            } label: {
                Text("내 스타일 등록하기")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
            }
            
            // 하단 장식용 카드들
            decorativeCardsView
                .padding(.top, 20)
        }
    }
    
    private var decorativeCardsView: some View {
        ZStack {
            // 카드들을 겹쳐서 배치하고 회전 효과 적용
            HStack(spacing: -15) {
                decorativeCard(icon: "figure.wrestling", title: "특기", subtitle: "탑 포지션", color: .red)
                    .rotationEffect(.degrees(-12))
                    .offset(y: 20)
                
                VStack(spacing: -10) {
                    decorativeCard(icon: "figure.strengthtraining.traditional", title: "최애", subtitle: "가드 포지션", color: .gray)
                        .rotationEffect(.degrees(5))
                        .zIndex(1)
                    
                    decorativeCard(icon: "figure.rolling", title: "특기", subtitle: "팔 관절기", color: .cyan)
                        .rotationEffect(.degrees(-5))
                }
                
                decorativeCard(icon: "figure.run", title: "특기", subtitle: "이스케이프", color: .green)
                    .rotationEffect(.degrees(10))
                    .offset(y: 30)
            }
        }
    }
    
    private func decorativeCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(8)
                .background(color.opacity(0.15))
                .clipShape(Circle())
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
            }
        }
        .padding(12)
        .frame(width: 90, height: 110)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}
