//
//  InstructorVerificationView.swift
//  Presentation
//
//  Created by suni on 5/25/26.
//

import SwiftUI
import UIKit
import ComposableArchitecture
import DesignSystem
import Domain

/// 관장 사범 인증 안내 + 사진 업로드 진입을 제공하는 바텀 시트.
/// 레이아웃은 `ProfileImageEditView` (handle / title / CTA)를 따른다.
public struct InstructorVerificationView: View {

    @Bindable var store: StoreOf<InstructorVerificationFeature>

    /// 시트 본문 자연 높이 — 호출부에서 `presentationDetents`에 사용.
    /// 다른 시트(`BeltSettingView` 등)와 동일한 정적 상수 패턴.
    /// 업로드 계열 단계는 시뮬레이터에서 잰 본문 내재 높이에 iOS 26 Liquid Glass partial sheet 보정(~27)을 더한다.
    /// 보정값은 #388 이전 처음 시트(Figma 409, 본문 내재 382)에서 가져와, 단계마다 안내박스~CTA 간격이 같게 한다.
    /// - 처음: 본문 457 — 빨간 경고 줄 대신 서류 예시(제목 + 세 줄)가 들어간다.
    /// - 사진 고른 뒤: 본문 567 — 경고 줄 없이 미리보기(4 + 200 + 12)가 들어간다.
    /// - 심사 중: 본문 457 — 경고 줄 없이 썸네일(4 + 90 + 12)이 들어간다. 사진 URL이 없으면 썸네일만큼(106) 낮다.
    /// - 반려: #388 이전과 같다. 사유가 두 줄까지 늘 수 있어 처음 시트보다 한 줄(21) 더 잡는다.
    /// - 승인: 안내박스 없이 닉네임 미리보기와 확인 버튼만 있다 — 본문 내재 248(24 + 69 + 16 + 64 + 75) + 여백 56.
    ///   업로드 시트의 안내박스~CTA 간격(~60)과 맞춘 값이다. 문의처가 있으면 문의 버튼(4 + 51)이 붙는다.
    public static func contentHeight(for state: InstructorVerificationFeature.State) -> CGFloat {
        switch state.phase {
        case .approved:
            return 304 + (state.contactEmail != nil ? 55 : 0)
        case .notRequested:
            return 484
        case .picked:
            return 594
        case .pending:
            return state.existingImageUrl != nil ? 484 : 378
        case .rejected:
            return 430
        }
    }

    public init(store: StoreOf<InstructorVerificationFeature>) {
        self.store = store
    }

    // MARK: - Metrics

    private enum Metrics {
        // titleSection / noticeBox / ctaSection 3곳에서 공유되는 좌우 여백
        static let horizontalPadding: CGFloat = 20
        static let noticeCornerRadius: CGFloat = 15
        // 심사 중 썸네일(정사각) · 고른 사진 미리보기 공통 모서리
        static let imageSize: CGFloat = 90
        static let imageCornerRadius: CGFloat = 15
        // 타이틀과 사진 · 사진과 안내박스 사이 — 썸네일 · 미리보기 공통
        static let imageTopPadding: CGFloat = 4
        static let imageBottomPadding: CGFloat = 12
    }

    /// 운영에서 받는 서류 예시(#388). 처음 화면의 경고 줄 자리에 보여 준다.
    private static let documentExamples = [
        "사범 자격증",
        "도장 사업자 등록증",
        "이름과 도장명이 함께 보이는 사진"
    ]

    // MARK: - Body

    @ViewBuilder
    public var body: some View {
        switch store.phase {
        case .approved:
            approvedBody
        case .notRequested, .rejected:
            uploadBody(title: "관장 사범 인증하기", subtitle: "인증 가능한 사진을 업로드해 주세요.")
        case .picked:
            uploadBody(title: "관장 사범 인증하기", subtitle: "이름과 도장명이 잘 보이는지 확인해 주세요.")
        case .pending:
            uploadBody(title: "심사 중이에요", subtitle: pendingSubtitle)
        }
    }

    private func uploadBody(title: String, subtitle: String) -> some View {
        VStack(spacing: 0) {
            handleBar
            titleSection(title: title, subtitle: subtitle)
            VStack(spacing: 0) {
                // 고른 사진(신청 전)이나 심사 중인 사진을 타이틀과 안내박스 사이에 보여 준다
                imageSection
                noticeBox
                    .padding(.bottom, 20)
            }
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

    /// 승인된 회원 — 다시 올릴 서류가 없으니 인증이 어떻게 보이는지만 보여 주고 닫는다.
    private var approvedBody: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection(title: "관장 사범 인증 완료", subtitle: "닉네임 옆에 인증 표시가 보여요.")
            nicknamePreview
                .padding(.top, 16)
            Spacer(minLength: 0)
            VStack(spacing: 4) {
                CTAButton(title: "확인", action: { store.send(.view(.cancelTapped)) })

                if store.contactEmail != nil {
                    CTAButton(title: "인증 정보 변경 문의하기", type: .text) {
                        store.send(.view(.contactTapped))
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// MY 헤더·커뮤니티 글과 같은 뱃지 + 닉네임 — 인증이 실제로 어떻게 붙는지 그대로 보여 준다.
    private var nicknamePreview: some View {
        HStack(spacing: 5) {
            Assets.MyProfile.Icon.badgeCheckLight.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(store.nickname)
                .font(Font.pretendard.title3)
                .foregroundStyle(Color.component.sectionHeader.title)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metrics.horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: Metrics.noticeCornerRadius)
                .fill(Color.primitive.coolGray.cg25)
        )
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private func titleSection(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Text(title)
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(minHeight: 24)

            Text(subtitle)
                .font(Font.pretendard.labelM)
                .foregroundStyle(Color.component.sectionHeader.subTitle)
                .frame(minHeight: 17)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 69)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    /// 심사 중이면 낸 날짜와 기다릴 기간을 알린다. 날짜를 모르면 날짜 없이 안내한다.
    private var pendingSubtitle: String {
        guard let requestedAt = store.verification.requestedAt else {
            return "사진을 확인하고 있어요 (2~3일)"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        // 서버가 서울 시각으로 기록하므로 날짜도 서울 기준으로 보여 준다 — 해외 기기에서 하루 어긋나지 않게
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일"
        return "\(formatter.string(from: requestedAt))에 낸 사진을 확인하고 있어요 (2~3일)"
    }

    @ViewBuilder
    private var imageSection: some View {
        switch store.phase {
        case let .picked(data):
            pickedImagePreview(data)
                .padding(.top, Metrics.imageTopPadding)
                .padding(.bottom, Metrics.imageBottomPadding)
        case .pending:
            existingImageSection
        case .notRequested, .rejected, .approved:
            EmptyView()
        }
    }

    /// 고른 사진 미리보기 — 서류 글자가 보이도록 자르지 않고 비율 그대로 크게 보여 준다.
    private func pickedImagePreview(_ data: Data) -> some View {
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.imageCornerRadius))
            } else {
                RoundedRectangle(cornerRadius: Metrics.imageCornerRadius)
                    .fill(Color.primitive.coolGray.cg100)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding(.horizontal, Metrics.horizontalPadding)
        .accessibilityLabel("고른 사진")
    }

    /// 심사 중인 인증 사진 썸네일. 사진 URL이 없으면 렌더링하지 않는다.
    @ViewBuilder
    private var existingImageSection: some View {
        if let urlString = store.existingImageUrl,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    RoundedRectangle(cornerRadius: Metrics.imageCornerRadius)
                        .fill(Color.primitive.coolGray.cg100)
                }
            }
            .frame(width: Metrics.imageSize, height: Metrics.imageSize)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.imageCornerRadius))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.imageTopPadding)
            .padding(.bottom, Metrics.imageBottomPadding)
        }
    }

    private var noticeBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch store.phase {
            case .notRequested:
                documentExamplesSection
            case .rejected:
                rejectedWarning
            case .picked, .pending, .approved:
                // 사진을 이미 골랐거나 낸 뒤라 무엇을 올릴지 다시 말하지 않는다. 상태는 제목 · 부제가 알린다.
                EmptyView()
            }

            // 승인 · 반려 알림은 보내지 않아 '알려드립니다'라고 약속하지 않는다(#389). 결과는 이 시트에서 본다.
            // 입구 위치(MY ⋯)는 바뀔 수 있어 경로 대신 '이 화면'이라고 쓴다.
            Text(
                """
                사진을 올리면 2~3일 안에 관리자가 확인합니다. 결과는 이 화면에서 확인할 수 있습니다.
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
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    /// 처음 화면 — 부제와 같은 말을 한 번 더 하는 대신, 어떤 사진이면 되는지 보여 준다(#388).
    private var documentExamplesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("이런 사진이면 돼요")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(minHeight: 21)

            ForEach(Self.documentExamples, id: \.self) { example in
                HStack(alignment: .top, spacing: 6) {
                    Text("·")
                        .accessibilityHidden(true)
                    Text(example)
                }
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.primitive.coolGray.cg700)
                .frame(minHeight: 21)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// 반려 사유 경고 줄. 사유가 없으면 반려됐다는 것만 알린다.
    private var rejectedWarning: some View {
        HStack(alignment: .top, spacing: 4) {
            // SF Symbol — 디자인 시스템에 경고 아이콘 에셋이 없어 시스템 심볼로 대체
            Assets.MyProfile.Icon.triangleAlert.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .frame(height: 21)
                .foregroundStyle(Color.semantic.error.error)

            Text(store.verification.rejectReason.map { "반려 사유: \($0)" } ?? "인증이 반려됐어요. 사진을 다시 올려 주세요.")
                .font(Font.pretendard.bodyS)
                .foregroundStyle(Color.semantic.error.error)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 21)
    }

    private var ctaSection: some View {
        VStack(spacing: 0) {
            switch store.phase {
            case .picked:
                CTAButton(title: "이 사진으로 신청", action: { store.send(.view(.submitTapped)) })
                CTAButton(title: "다시 고르기", type: .text) {
                    store.send(.view(.repickTapped))
                }
            case .pending:
                CTAButton(title: "사진 바꾸기", action: { store.send(.view(.uploadTapped)) })
                cancelButton
            case .notRequested, .rejected, .approved:
                CTAButton(title: "사진 업로드", action: { store.send(.view(.uploadTapped)) })
                cancelButton
            }
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

#Preview("관장 사범 인증 - 최초") {
    InstructorVerificationView(
        store: Store(initialState: InstructorVerificationFeature.State()) {
            InstructorVerificationFeature()
        }
    )
}

#Preview("관장 사범 인증 - 사진 고른 뒤") {
    let sample = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400)).image { context in
        UIColor.systemGray4.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
    }
    InstructorVerificationView(
        store: Store(
            initialState: InstructorVerificationFeature.State(pickedImageData: sample.jpegData(compressionQuality: 0.8))
        ) {
            InstructorVerificationFeature()
        }
    )
}

#Preview("관장 사범 인증 - 심사 중") {
    InstructorVerificationView(
        store: Store(
            initialState: InstructorVerificationFeature.State(
                verification: OwnerVerification(
                    status: .pending,
                    documentImageUrl: "https://ik.imagekit.io/preview/verification_preview.jpg",
                    requestedAt: Date()
                )
            )
        ) {
            InstructorVerificationFeature()
        }
    )
}

#Preview("관장 사범 인증 - 승인됨") {
    InstructorVerificationView(
        store: Store(
            initialState: InstructorVerificationFeature.State(
                verification: OwnerVerification(status: .approved),
                nickname: "암바장인곰",
                contactEmail: "support@example.com"
            )
        ) {
            InstructorVerificationFeature()
        }
    )
}

#Preview("관장 사범 인증 - 거절됨") {
    InstructorVerificationView(
        store: Store(
            initialState: InstructorVerificationFeature.State(
                verification: OwnerVerification(status: .rejected, rejectReason: "도장명과 이름이 함께 보이는 사진이 필요해요.")
            )
        ) {
            InstructorVerificationFeature()
        }
    )
}
