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
                VStack(spacing: 0) {
                    resultSection
                    // 이름 없는 기록은 같은 대회끼리 묶을 수 없어 '부문 추가' 대신 나만 보기 안내를 둔다(#125).
                    if store.savedRecords.last?.isNameless == true {
                        namelessNoticeSection
                    } else {
                        addDivisionSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            confirmButton
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

    private var addDivisionSection: some View {
        VStack(spacing: 12) {
            // 바로 위에 방금 기록한 대회가 보이므로 '같은 대회에서'는 빼도 뜻이 남는다.
            Text("다른 부문도 나갔나요?")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.list.setting.subText)

            Button {
                store.send(.view(.addDivisionButtonTapped))
            } label: {
                AppButtonConfiguration(
                    title: "부문 추가",
                    leftIcon: Assets.Common.Icon.plus.swiftUIImage,
                    size: .medium
                )
            }
            .appButtonStyle(.tint, size: .medium, height: 44)
        }
        // 회색 면으로 감싸면 면 전체가 버튼처럼 보여, 문구와 버튼만 둔다.
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private var namelessNoticeSection: some View {
        VStack(spacing: 6) {
            Text("대회명 없이 저장한 기록은 나만 볼 수 있어요")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.sectionHeader.subTitle)
            Text("프로필에서 대회명을 채우면 공개돼요")
                .font(Font.pretendard.labelM)
                .foregroundStyle(Color.component.list.setting.subText)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.component.skillCard.container.bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.top, 40)
    }

    private var confirmButton: some View {
        CTAButton(
            title: "완료",
            action: {
                store.send(.view(.doneButtonTapped))
            }
        )
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
            competitionWeightClass: .under76,
            competitionBelt: .brown
        )
    ]
    return CompetitionDoneView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}

#Preview("대회명 없이 저장") {
    var state = CompetitionInfoFeature.State(mode: .add, currentBelt: .brown)
    state.step = .done
    state.savedRecords = [
        Competition(competitionYear: 2025, competitionName: "", competitionRank: .bronze)
    ]
    return CompetitionDoneView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
