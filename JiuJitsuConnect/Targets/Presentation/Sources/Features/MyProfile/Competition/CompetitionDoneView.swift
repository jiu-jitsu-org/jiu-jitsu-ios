import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

/// 저장 후 완료 화면 — 방금 남긴 기록을 보여 주고, 같은 대회의 다른 부문을 이어서 기록할 수 있게 한다(#123).
///
/// 한 부문만 나간 대부분은 '완료'로 바로 닫고, 더 딴 사람만 '부문 추가'를 누른다.
struct CompetitionDoneView: View {
    let store: StoreOf<CompetitionInfoFeature>

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                resultSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            buttonSection
        }
    }

    // MARK: - View Components

    private var resultSection: some View {
        VStack(spacing: 16) {
            if let latest = store.savedRecords.last {
                latest.competitionRank.medalImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    // 회원가입 완료와 같은 꽃가루를 메달 뒤에서 한 번 터뜨린다. 부문을 더해 저장할 때마다 다시 터진다.
                    .background {
                        if store.celebratesOnDone {
                            JJSLottieView("Confetti", loopMode: .playOnce)
                                .frame(width: 280, height: 280)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Text("기록했어요")
                .font(Font.pretendard.display1)
                .foregroundStyle(Color.component.textfieldDisplay.focus.title)
                .frame(height: 36)

            // 부문을 추가할 때마다 한 줄씩 늘어, 이 대회에서 무엇을 남겼는지 한눈에 보인다.
            VStack(spacing: 6) {
                ForEach(Array(store.savedRecords.enumerated()), id: \.offset) { _, record in
                    Text(record.completionSummary)
                        .font(Font.pretendard.bodyM)
                        .foregroundStyle(Color.component.sectionHeader.subTitle)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }

    // 부문 추가와 완료를 한 묶음으로 둔다(#146). 질문 바로 아래에 답인 '부문 추가'를 두고, '완료'는 다른 화면과 같은 맨 아래 자리에 둔다. 둘 다 색 면이라 붙어 보이지 않게 8pt를 둔다.
    private var buttonSection: some View {
        VStack(spacing: 12) {
            // 바로 위에 방금 기록한 대회가 보이므로 '같은 대회에서'는 빼도 뜻이 남는다.
            Text("다른 부문도 나갔나요?")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.subText)

            VStack(spacing: 8) {
                CTAButton(
                    title: "부문 추가",
                    type: .tint,
                    leftIcon: Assets.Common.Icon.plus.swiftUIImage,
                    action: {
                        store.send(.view(.addDivisionButtonTapped))
                    }
                )

                CTAButton(
                    title: "완료",
                    action: {
                        store.send(.view(.doneButtonTapped))
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    var state = CompetitionInfoFeature.State(mode: .add, currentBelt: .brown)
    state.step = .done
    state.celebratesOnDone = true
    state.savedRecords = [
        Competition(
            competitionYear: 2026,
            competitionName: "2026 서울 오픈",
            competitionRank: .silver,
            competitionUniform: .gi,
            competitionWeightLimit: CompetitionWeightLimit(kg: 76, bound: .under),
            competitionBelt: .brown
        )
    ]
    return CompetitionDoneView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
