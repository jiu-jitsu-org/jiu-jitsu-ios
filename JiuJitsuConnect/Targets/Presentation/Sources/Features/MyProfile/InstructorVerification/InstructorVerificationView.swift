//
//  InstructorVerificationView.swift
//  Presentation
//
//  Created by suni on 5/25/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

/// 관장 사범 인증 안내 + 사진 업로드 진입을 제공하는 바텀 시트.
/// 레이아웃은 `ProfileImageEditView` (handle / title / CTA)를 따른다.
public struct InstructorVerificationView: View {

    @Bindable var store: StoreOf<InstructorVerificationFeature>

    /// 본문 자연 높이.
    /// noticeBox 안 다국행 텍스트의 줄바꿈이 디바이스 폭에 따라 달라져
    /// 정적 contentHeight 상수로는 detent와 본문 실측 높이 사이에 빈 공간이 생긴다
    /// (= noticeBox-CTA 간격이 디자인 의도 28pt보다 커 보이는 원인).
    /// GeometryReader로 측정해 detent에 흘려보내면 자연 padding(20+8)만으로
    /// 의도된 간격이 정확히 유지되고, CTA는 디바이스 바닥에서 항상 16pt 위에 고정.
    /// 첫 프레임만 추정치(409)로 시작했다가 측정 직후 정확한 값으로 수렴한다.
    @State private var measuredHeight: CGFloat = 409

    public init(store: StoreOf<InstructorVerificationFeature>) {
        self.store = store
    }

    // MARK: - Metrics

    private enum Metrics {
        // titleSection / noticeBox / ctaSection 3곳에서 공유되는 좌우 여백
        static let horizontalPadding: CGFloat = 20
        static let noticeCornerRadius: CGFloat = 15
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            noticeBox
                .padding(.top, 16)
            ctaSection
        }
        // 본문 자연 높이 측정 — `.ignoresSafeArea`보다 먼저 적용해야 safe area를
        // 무시하기 전(= 순수 레이아웃) 높이를 잡을 수 있다.
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ContentHeightKey.self,
                    value: geo.size.height
                )
            }
        )
        .background(Color.component.bottomSheet.selected.container.background)
        // 디자이너 의도: CTA가 home indicator safe area 위가 아닌 디바이스 바닥에서
        // 16pt 위에 붙어야 하므로 하단 safe area를 무시한다.
        .ignoresSafeArea(.container, edges: .bottom)
        .onPreferenceChange(ContentHeightKey.self) { newValue in
            // 0pt 일시적 보고/identity 값 거름. 측정값이 들어오면 detent에 반영.
            if newValue > 0 {
                measuredHeight = newValue
            }
        }
        // 시트 자체가 본문 자연 높이에 맞춰 detent를 잡는다 (호출부 MyProfileView는
        // 이 시트의 detent/배경을 따로 설정하지 않는다 — 다른 정적 시트들과 다른 패턴).
        .presentationDetents([.height(measuredHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(
            Color.component.bottomSheet.selected.container.background
        )
    }

    // MARK: - View Components

    private var handleBar: some View {
        ZStack {
            Capsule()
                .fill(Color.component.bottomSheet.selected.container.handle)
                .frame(width: 48, height: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 24)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Text("관장 사범 인증하기")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(minHeight: 24)

            Text("인증 가능한 사진을 업로드해주세요.")
                .font(Font.pretendard.labelM)
                .foregroundStyle(Color.component.sectionHeader.subTitle)
                .frame(minHeight: 17)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 69)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                // SF Symbol — 디자인 시스템에 경고 아이콘 에셋이 없어 시스템 심볼로 대체
                Assets.MyProfile.Icon.triangleAlert.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color.semantic.error.error)

                Text("인증 가능한 사진을 업로드해주세요.")
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.semantic.error.error)
            }
            .frame(height: 21)

            Text(
                """
                사진을 업로드하면 2-3일 내 관리자가 확인 후 인증 여부를 알려드립니다.
                해당 사진은 인증용으로, 외부에 노출되지 않습니다.
                """
            )
            .font(Font.pretendard.bodyS)
            .lineSpacing(3)
            .foregroundStyle(Color.primitive.coolGray.cg500)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: Metrics.noticeCornerRadius)
                .fill(Color.primitive.coolGray.cg25)
        )
        .padding(Metrics.horizontalPadding)
    }

    private var ctaSection: some View {
        VStack(spacing: 0) {
            CTAButton(
                title: "사진 업로드",
                action: { store.send(.view(.uploadTapped)) }
            )

            cancelButton
        }
        .padding(.top, 8)
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.bottom, 16)
    }

    /// 취소 버튼.
    /// 디자이너 의도: 시각적으로는 `CTAButton(.text)`의 disabled 상태와 동일한
    /// 텍스트 컬러(`Color.component.cta.transparentText.disabledText`)를 쓰지만,
    /// 실제 탭은 항상 동작해야 한다.
    /// `CTAButton(.text)` + `.disabled(true)`는 탭이 막혀 사용 불가이고,
    /// `CTAButton` 내부 ButtonStyle에서 `.foregroundStyle`을 강제 적용하기 때문에
    /// 외부에서 컬러만 override할 수도 없어, 동일한 사양(buttonM / height 51 /
    /// 투명 배경)으로 inline Button을 둔다.
    private var cancelButton: some View {
        Button {
            store.send(.view(.cancelTapped))
        } label: {
            Text("취소")
                .font(Font.pretendard.buttonM)
                .foregroundStyle(Color.component.cta.transparentText.disabledText)
                .frame(maxWidth: .infinity)
                .frame(height: 51)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PreferenceKey

/// 본문 자연 높이를 detent로 전파하기 위한 PreferenceKey.
private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Previews

#Preview("관장 사범 인증") {
    InstructorVerificationView(
        store: Store(initialState: InstructorVerificationFeature.State()) {
            InstructorVerificationFeature()
        }
    )
}
