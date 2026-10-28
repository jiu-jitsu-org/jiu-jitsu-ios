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
    // 뒤로가기 버튼과, 완료 화면에서 그 자리를 비워 제목을 가운데에 두는 빈 칸이 같은 크기를 쓴다.
    static let backButtonSize: CGFloat = 36
}

struct CompetitionInfoView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>

    var body: some View {
        VStack(spacing: 0) {
            headerView
            // 완료 화면은 입력이 끝난 상태라 진행 막대를 숨긴다.
            if store.step != .done {
                progressBar
            }

            Group {
                switch store.step {
                case .result:
                    CompetitionResultView(store: store)
                case .year:
                    CompetitionYearView(store: store)
                case .name:
                    CompetitionNameView(store: store)
                case .division:
                    CompetitionDivisionView(store: store)
                case .done:
                    CompetitionDoneView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: store.step)
        }
        .background(Color.primitive.bw.white)
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                ToastView(
                    state: toast,
                    onSwipe: { store.send(.view(.toastSwiped), animation: .default) },
                    onButtonTapped: { _ in store.send(.view(.toastSwiped), animation: .default) }
                )
                .padding(.horizontal, 24)
                // 아래 버튼(부문 단계는 완료 + 건너뛰기)을 가리지 않도록 버튼 위에 띄운다.
                .padding(.bottom, 120)
                .animation(.default, value: toast)
            }
        }
        // 저장 중에는 다시 누르거나 화면을 떠나지 못하게 막는다(중복 저장 방지).
        .disabled(store.isSaving)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            // 완료 화면은 이미 저장된 뒤라 되돌아갈 곳이 없고, 아래 '완료' 버튼으로만 닫는다.
            if store.step == .done {
                Color.clear.frame(width: Style.backButtonSize, height: Style.backButtonSize)
            } else {
                backButton
            }

            Spacer()

            Text(store.headerTitle)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.header.text)

            Spacer()

            if store.step == .done {
                Color.clear.frame(width: Style.backButtonSize, height: Style.backButtonSize)
            } else if store.mode.isEdit {
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

    private var backButton: some View {
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
            .frame(width: Style.backButtonSize, height: Style.backButtonSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // 지금 단계까지 칸을 채워, 남은 단계 수를 한눈에 보이게 한다.
    private var progressBar: some View {
        let segmentCount = store.inputSteps.count
        let currentIndex = store.inputSteps.firstIndex(of: store.step) ?? 0
        return HStack(spacing: 4) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= currentIndex
                            ? Color.primitive.blue.b500p
                            : Color.primitive.coolGray.cg75
                    )
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .animation(.default, value: store.step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(segmentCount)단계 중 \(currentIndex + 1)단계")
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

