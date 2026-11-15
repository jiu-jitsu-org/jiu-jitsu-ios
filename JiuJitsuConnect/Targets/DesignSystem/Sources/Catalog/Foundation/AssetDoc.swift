#if DEBUG || BETA
//
//  AssetDoc.swift
//  DesignSystem
//
//  기초 — 에셋. SwiftGen 으로 만든 이미지를 묶음별로 실물 그대로 보여 준다.
//  띠 캐릭터(Character.Belt)는 자세·표정을 조합하는 부품이라 '띠 캐릭터' 문서에 둔다.
//

import SwiftUI

struct CatalogAssetItem: Identifiable {
    let name: String
    let asset: ImageAsset
    var id: String { asset.name }
}

struct CatalogAssetGroup: Identifiable {
    let name: String
    let items: [CatalogAssetItem]
    var id: String { name }
}

struct AssetDoc: View {
    private let groups = CatalogAssetGroup.all
    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 8)]

    var body: some View {
        CatalogDoc(
            group: .foundation,
            title: "에셋",
            summary: "Assets.xcassets 이미지를 SwiftGen 이 Assets.<묶음>.<이름> 으로 만든다. 이름 문자열로 부르지 않는다.",
            chips: [
                "묶음 \(groups.count)",
                "이미지 \(groups.reduce(0) { $0 + $1.items.count })",
                "띠 캐릭터 \(BeltPose.allCases.count + BeltFace.allCases.count) 별도",
                "2026-11-16 기준"
            ]
        ) {
            CatalogSection(title: "개요", note: "앱 화면은 Assets.<묶음>.<이름>.swiftUIImage 로 그린다.") {
                CatalogPlate {
                    HStack(spacing: 20) {
                        Assets.Common.Shaka.icon.swiftUIImage
                            .resizable().scaledToFit().frame(width: 48, height: 48)
                        Assets.MyProfile.Medal.blackGold.swiftUIImage
                            .resizable().scaledToFit().frame(width: 48, height: 48)
                        Assets.MyProfile.Icon.beltBlue.swiftUIImage
                            .resizable().scaledToFit().frame(width: 48, height: 48)
                    }
                }
            }

            ForEach(groups) { group in
                CatalogSection(title: group.name, note: "\(group.items.count)개") {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(group.items) { item in
                            VStack(spacing: 6) {
                                item.asset.swiftUIImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                Text(item.name)
                                    .font(.pretendard.labelS)
                                    .foregroundStyle(Color.semantic.text.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 92)
                            .padding(.horizontal, 4)
                            .background(Color.component.background.default, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "SwiftGen 이 만든 이름으로 부른다. 이미지가 지워지면 빌드에서 바로 걸린다.",
                    badText: "Image(\"Common/Icon/check\") 처럼 문자열로 부르지 않는다. 오타가 나도 빈칸으로만 보인다."
                ) {
                    Text("Assets.Common.Icon.check.swiftUIImage")
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.primary)
                } bad: {
                    Text("Image(\"Common/Icon/check\")")
                        .font(.pretendard.labelM)
                        .foregroundStyle(Color.semantic.text.primary)
                }
            }
        }
    }
}

#Preview("에셋") {
    NavigationStack { AssetDoc() }
}

#endif
