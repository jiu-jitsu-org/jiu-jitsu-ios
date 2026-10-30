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
    // 화면 폭을 다 채우면 막대가 눈을 끌어, 가운데에 짧게 둔다.
    static let progressBarWidth: CGFloat = 160
    // 단계 사이 전환 — 한 동작(옆으로 밀기)으로, 기본 500ms.
    static let stepAnimation: Animation = .easeInOut(duration: 0.5)
}

struct CompetitionInfoView: View {
    @Bindable var store: StoreOf<CompetitionInfoFeature>
    // 지금 그리고 있는 단계와 그 단계로 온 방향. store.step보다 한 박자 늦게 따라간다(아래 onChange 참고).
    @State private var shownStep: CompetitionInfoFeature.Step
    @State private var isMovingBack = false

    init(store: StoreOf<CompetitionInfoFeature>) {
        self.store = store
        _shownStep = State(initialValue: store.step)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            // 완료 화면은 입력이 끝난 상태라 진행 막대를 숨긴다.
            if store.step != .done {
                progressBar
            }

            // 전환 중에는 나가는 단계와 들어오는 단계가 함께 있어, 위아래로 나뉘지 않게 겹쳐 둔다.
            ZStack {
                Group {
                    switch shownStep {
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
                // 나가는 단계는 0.5초 동안 남아 있다. 그 사이 '다음'을 또 눌러 다음 단계 동작이 실행되지 않게 막는다.
                .allowsHitTesting(shownStep == store.step)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 앞으로 가면 다음 단계가 오른쪽에서, 뒤로 가면 이전 단계가 왼쪽에서 들어온다.
                .transition(
                    isMovingBack
                        ? .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
                        : .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: store.step) { _, newStep in
            // 나가는 화면은 마지막으로 그려질 때 붙어 있던 전환으로 사라진다. 방향을 먼저 바꿔 한 번 그린 뒤
            // 다음 차례에 단계를 바꿔야, 앞으로 가다 뒤로 갈 때도 나가는 화면이 맞는 쪽으로 빠진다.
            isMovingBack = store.isMovingBack
            Task { @MainActor in
                withAnimation(Style.stepAnimation) { shownStep = newStep }
            }
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
        .frame(width: Style.progressBarWidth)
        .frame(maxWidth: .infinity)
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

