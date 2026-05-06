//
//  CompetitionInfoView.swift
//  Presentation
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

private enum Style {
    static let headerHeight: CGFloat = 60
    static let horizontalPadding: CGFloat = 16
}

struct CompetitionInfoView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Group {
                switch store.step {
                case .date:
                    CompetitionDateView(store: store)
                case .name:
                    CompetitionNameView(store: store)
                case .result:
                    // Step 3에서 CompetitionResultView로 교체 예정
                    stepPlaceholder("결과 선택 (Step 3 예정)")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: store.step)
        }
        .background(Color.primitive.bw.white)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            Button {
                store.send(.view(.backButtonTapped))
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primitive.blue.b50)

                    Assets.Common.Icon.arrowLeft.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.primitive.blue.b500p)
                }
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("대회 정보 추가")
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)

            Spacer()

            Rectangle()
                .fill(.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
    }

    @ViewBuilder
    private func stepPlaceholder(_ text: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Text(text)
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
            Spacer()
            CTAButton(title: "다음") {
                store.send(.view(.nextButtonTapped))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CompetitionInfoView(
            store: Store(initialState: CompetitionInfoFeature.State()) {
                CompetitionInfoFeature()
            }
        )
    }
}
