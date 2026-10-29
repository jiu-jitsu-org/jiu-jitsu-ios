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
    // 화면 폭을 다 채우면 막대가 눈을 끌어, 가운데에 짧게 둔다.
    static let progressBarWidth: CGFloat = 160
}

struct CompetitionInfoView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>

    var body: some View {
        VStack(spacing: 0) {
            headerView
            progressBar

            Group {
                switch store.step {
                case .result:
                    CompetitionResultView(store: store)
                case .date:
                    CompetitionDateView(store: store)
                case .name:
                    CompetitionNameView(store: store)
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

            Text(store.mode.headerTitle)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)

            Spacer()

            if store.mode.isEdit {
                Button {
                    store.send(.view(.deleteButtonTapped))
                } label: {
                    Text("삭제")
                        .font(Font.pretendard.buttonS)
                        .foregroundColor(Color.component.header.destructiveText)
                        .frame(width: 48, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    store.send(.view(.cancelButtonTapped))
                } label: {
                    Text("취소")
                        .font(Font.pretendard.bodyM)
                        .foregroundStyle(Color.component.button.text.defaultText)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Style.horizontalPadding)
        .frame(height: Style.headerHeight)
    }

    // 지금 단계까지 칸을 채워, 남은 단계 수를 한눈에 보이게 한다.
    private var progressBar: some View {
        let segmentCount = CompetitionInfoFeature.Step.progressSegmentCount
        return HStack(spacing: 4) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= store.step.rawValue
                            ? Color.primitive.blue.b500p
                            : Color.primitive.coolGray.cg75
                    )
                    .frame(height: 4)
            }
        }
        .frame(width: Style.progressBarWidth)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .animation(.default, value: store.step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(segmentCount)단계 중 \(store.step.rawValue + 1)단계")
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

