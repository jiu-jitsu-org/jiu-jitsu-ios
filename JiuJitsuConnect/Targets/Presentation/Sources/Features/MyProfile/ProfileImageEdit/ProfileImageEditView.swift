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
        static let rowCornerRadius: CGFloat = 12
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            handleBar
            titleSection
            optionsSection
                .padding(.top, 8)
            cancelButton
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
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
                .foregroundStyle(Color.component.bottomSheet.selected.container.title)
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
                hasBackground: true,
                action: { store.send(.view(.cameraTapped)) }
            )

            optionRow(
                title: "앨범에서 찾기",
                showsChevron: true,
                hasBackground: false,
                action: { store.send(.view(.albumTapped)) }
            )

            if store.canDelete {
                optionRow(
                    title: "삭제",
                    showsChevron: false,
                    hasBackground: false,
                    action: { store.send(.view(.deleteTapped)) }
                )
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private func optionRow(
        title: String,
        showsChevron: Bool,
        hasBackground: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .font(Font.pretendard.bodyM)
                    .foregroundStyle(Color.component.bottomSheet.selected.listItem.label)

                Spacer()

                if showsChevron {
                    Assets.Common.Icon.chevronRight.swiftUIImage
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(
                            Color.component.bottomSheet.selected.listItem.followingIcon
                        )
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Metrics.rowCornerRadius)
                    .fill(
                        hasBackground
                            ? Color.component.list.setting.background
                            : Color.clear
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: Metrics.rowCornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button {
            store.send(.view(.cancelTapped))
        } label: {
            AppButtonConfiguration(title: "취소", size: .large)
        }
        .appButtonStyle(.primary, size: .large, height: 52)
        .padding(.horizontal, Metrics.horizontalPadding)
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
