import SwiftUI
import ComposableArchitecture
import Domain
import DesignSystem

/// 저장 후 완료 화면 — 방금 남긴 기록을 메달 캐릭터로 축하하고, 같은 대회의 다른 부문을 이어서 기록할 수 있게 한다(#123, #220).
///
/// 한 부문만 나간 대부분은 '완료'로 바로 닫고, 더 딴 사람만 '부문 추가'를 누른다.
struct CompetitionDoneView: View {
    let store: StoreOf<CompetitionInfoFeature>

    private enum Metrics {
        // 기록 줄이 많아 글자 영역이 길어져도 캐릭터가 이만큼은 보이고, 넘치는 기록 줄은 스크롤한다.
        static let minStageHeight: CGFloat = 280
        // 몸통 밑단은 잘린 단면이라 시트 뒤로 숨긴다(로그인 화면과 같은 방식).
        static let sheetOverlap: CGFloat = 20
        static let characterTopGap: CGFloat = 30
        // 무대가 아무리 커져도 캐릭터는 이 높이까지만 커지고, 남는 자리는 꽃가루가 쓴다.
        static let maxCharacterHeight: CGFloat = 400
        static let characterBottomInset: CGFloat = 14
    }

    var body: some View {
        // 글자 영역이 내용만큼 먼저 자리를 잡고, 남는 높이는 모두 캐릭터·꽃가루 자리가 된다(#235).
        VStack(spacing: 0) {
            GeometryReader { proxy in
                stage(height: proxy.size.height)
            }
            .frame(minHeight: Metrics.minStageHeight)

            sheet
                .padding(.top, -Metrics.sheetOverlap)
                .layoutPriority(1)
        }
    }

    // MARK: - View Components

    private func stage(height: CGFloat) -> some View {
        let latest = store.savedRecords.last
        let characterHeight = min(height - Metrics.characterTopGap, Metrics.maxCharacterHeight)
        let character = latest.flatMap { record in
            store.doneCharacterBelt.map { MedalCharacter(belt: $0, rank: record.competitionRank) }
        }

        return ZStack(alignment: .bottom) {
            Color.primitive.coolGray.cg25

            if store.celebratesOnDone {
                // 캐릭터 뒤에서 퍼진다. 그림이 있는 쪽은 올라오는 움직임이 끝날 즈음, 아이콘은 조금 일찍 시작한다.
                PaperConfettiView(startDelay: character == nil ? 0.22 : 0.44)
            }

            if let character {
                MedalCharacterView(character: character, height: characterHeight, celebrates: store.celebratesOnDone)
                    .padding(.bottom, Metrics.characterBottomInset)
            } else if let latest {
                MedalIconRiseView(image: latest.competitionRank.medalImage, celebrates: store.celebratesOnDone)
                    .padding(.bottom, height * 0.3)
            }
        }
        .frame(height: height)
        .clipped()
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            Text("기록했어요")
                .font(Font.pretendard.display1)
                .foregroundStyle(Color.component.textfieldDisplay.focus.title)
                .frame(height: 36)
                .padding(.bottom, 8)

            // 다 들어가면 줄 수만큼만 차지하고, 캐릭터 최소 자리에 닿으면 그때부터 스크롤한다.
            ViewThatFits(in: .vertical) {
                recordList

                ScrollView {
                    recordList
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            buttonSection
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
        .background(
            Color.primitive.bw.white,
            in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
        )
    }

    // 부문을 추가할 때마다 한 줄씩 늘어, 이 대회에서 무엇을 남겼는지 한눈에 보인다.
    private var recordList: some View {
        VStack(spacing: 6) {
            ForEach(Array(store.savedRecords.enumerated()), id: \.offset) { _, record in
                Text(record.completionSummary)
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.component.sectionHeader.subTitle)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
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
        .padding(.top, 12)
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
            competitionWeightLimit: .under(kg: 76),
            competitionBelt: .brown
        )
    ]
    return CompetitionDoneView(
        store: Store(initialState: state) {
            CompetitionInfoFeature()
        }
    )
}
