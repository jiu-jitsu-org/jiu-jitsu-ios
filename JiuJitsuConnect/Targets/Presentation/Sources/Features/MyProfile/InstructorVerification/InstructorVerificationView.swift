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

    /// 시트 본문 자연 높이 — 호출부에서 `presentationDetents`에 사용.
    /// 다른 시트(`BeltSettingView` 등)와 동일한 정적 상수 패턴.
    /// Figma 디자인 가이드 기준 전체 바텀 시트 높이 = 409
    /// (본문 내재 369 + iOS 26 Liquid Glass partial sheet 내부 inset 보정 ~40)
    public static let contentHeight: CGFloat = 409

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
            // contentHeight(409) - body 자식 합(369) = 40pt의 빈 공간이 어딘가에 들어가야 한다.
            // 이 Spacer 없으면 40pt가 CTA 아래에 쌓여 CTA가 디바이스 바닥에서 멀어진다.
            // Spacer로 noticeBox와 CTA 사이가 흡수하면 CTA가 시트 바닥에 못박힌다.
            Spacer(minLength: 0)
            ctaSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        // iOS 26 Liquid Glass partial 시트 외곽에 시스템이 ~10pt floating gap을 두므로
        // 시각적 거리는 padding + 10pt가 되지만, iOS 기본 패턴을 거스르지 않기 위해
        // 디자인 토큰 그대로 16pt를 둔다.
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

// MARK: - Previews

#Preview("관장 사범 인증") {
    InstructorVerificationView(
        store: Store(initialState: InstructorVerificationFeature.State()) {
            InstructorVerificationFeature()
        }
    )
}
