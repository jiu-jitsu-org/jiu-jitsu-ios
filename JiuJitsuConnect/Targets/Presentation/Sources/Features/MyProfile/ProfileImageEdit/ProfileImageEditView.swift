//
//  ProfileImageEditView.swift
//  Presentation
//
//  Created by suni on 5/19/26.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct ProfileImageEditView: View {

    @Bindable var store: StoreOf<ProfileImageEditFeature>

    public init(store: StoreOf<ProfileImageEditFeature>) {
        self.store = store
    }

    // MARK: - Metrics

    private enum Metrics {
        // titleSection/optionsSection/cancelButton 3곳에서 공유
        static let horizontalPadding: CGFloat = 20
        // optionRow 배경과 contentShape 2곳에서 공유
        static let rowCornerRadius: CGFloat = 10
    }

    // MARK: - Sheet Content Height (safe area 미포함)

    /// 바텀 시트 detent용 본문 고정 높이.
    /// 공통: 24(handle) + 48(title) + 16+20(optionsTop) + (rows) + 20(optionsBottom) + 8+51+24(CTA)
    /// - 삭제 가능(rows = 3): rows = 51*3 + 8*2 = 169 → 총 380
    /// - 삭제 불가(rows = 2): rows = 51*2 + 8     = 110 → 총 321
    public static func contentHeight(canDelete: Bool) -> CGFloat {
        canDelete ? 380 : 321
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            optionsSection
                .padding(.top, 16)
            cancelButton
        }
        // detent > 본문 시 남는 공간이 위로 떨어져 핸들이 내려오는 현상 방지.
        // 시트 가용 영역 전체를 채우면서 본문을 상단에 못박는다.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.component.bottomSheet.selected.container.background)
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
        VStack {
            Spacer()
            Text("프로필 이미지 수정")
                .font(Font.pretendard.title2)
                .foregroundStyle(Color.component.sectionHeader.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private var optionsSection: some View {
        VStack(spacing: 8) {
            optionRow(
                title: "사진 촬영",
                showsChevron: true,
                action: { store.send(.view(.cameraTapped)) }
            )

            optionRow(
                title: "앨범에서 찾기",
                showsChevron: true,
                action: { store.send(.view(.albumTapped)) }
            )

            if store.canDelete {
                optionRow(
                    title: "삭제",
                    showsChevron: false,
                    action: { store.send(.view(.deleteTapped)) }
                )
            }
        }
        .padding(.vertical, 20)
    }

    private func optionRow(
        title: String,
        showsChevron: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .font(Font.pretendard.bodyS)
                    .foregroundStyle(Color.component.bottomSheet.unselected.listItem.label)

                Spacer()

                if showsChevron {
                    Assets.Common.Icon.chevronRight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(
                            Color.component.bottomSheet.selected.listItem.followingIcon
                        )
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 51)
            .contentShape(RoundedRectangle(cornerRadius: Metrics.rowCornerRadius))
        }
        // 기본 상태는 모두 비선택 — 탭(터치 다운) 동안에만 배경 하이라이트 노출
        .buttonStyle(PressableRowButtonStyle(cornerRadius: Metrics.rowCornerRadius))
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private var cancelButton: some View {
        CTAButton(
            title: "취소",
            action: {
                store.send(.view(.cancelTapped))
            }
        )
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

// MARK: - PressableRowButtonStyle

/// 터치 다운 동안에만 배경을 노출하는 옵션 행 버튼 스타일
private struct PressableRowButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        configuration.isPressed
                            ? Color.component.picker.itemSelectedBg
                            : Color.clear
                    )
            )
    }
}

// MARK: - Previews

#Preview("프로필 이미지 수정 - 삭제 가능") {
    ProfileImageEditView(
        store: Store(
            initialState: ProfileImageEditFeature.State(canDelete: true)
        ) {
            ProfileImageEditFeature()
        }
    )
}

#Preview("프로필 이미지 수정 - 삭제 불가") {
    ProfileImageEditView(
        store: Store(
            initialState: ProfileImageEditFeature.State(canDelete: false)
        ) {
            ProfileImageEditFeature()
        }
    )
}
