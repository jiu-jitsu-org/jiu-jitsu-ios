#if DEBUG || BETA
//
//  TopHeaderDoc.swift
//  DesignSystem
//
//  부품 — 머리줄. 실제 TopHeader 로 그린다.
//

import SwiftUI

struct TopHeaderDoc: View {
    var body: some View {
        CatalogDoc(
            group: .component,
            title: "머리줄",
            summary: "화면 맨 위 — 왼쪽 뒤로가기, 가운데 제목, 오른쪽 글자 버튼(선택). 오른쪽 글자 버튼은 화면이 달라도 같은 회색 글자다.",
            chips: ["쓰는 곳 3(닉네임·도장·대회)", "2026-11-19 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate {
                    TopHeader(title: "대회 정보 수정", onBack: {}, trailing: .init("삭제") {})
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "뒤로가기 — 36 칸, 모서리 10, 옅은 파랑 바탕 + 화살표 24",
                    "제목 — title3, 양옆 버튼 너비와 상관없이 화면 가운데",
                    "오른쪽 글자 버튼(선택) — bodyM 회색, 누르는 자리 36 이상",
                    "높이 60, 좌우 여백 16"
                ])
            }

            CatalogSection(title: "변형") {
                CatalogPlate {
                    VStack(spacing: 12) {
                        CatalogCaptioned(caption: "수정 — 삭제") {
                            TopHeader(title: "도장 정보 수정", onBack: {}, trailing: .init("삭제") {})
                        }
                        CatalogCaptioned(caption: "추가 — 취소") {
                            TopHeader(title: "대회 정보 추가", onBack: {}, trailing: .init("취소") {})
                        }
                        CatalogCaptioned(caption: "저장 중 — 글자 버튼 막힘") {
                            TopHeader(title: "도장 정보 수정", onBack: {}, trailing: .init("삭제", isEnabled: false) {})
                        }
                        CatalogCaptioned(caption: "글자 버튼 없음") {
                            TopHeader(title: "닉네임 설정", onBack: {})
                        }
                        CatalogCaptioned(caption: "완료 화면 — 뒤로가기 없음") {
                            TopHeader(title: "대회 정보 추가", onBack: nil)
                        }
                    }
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.header.text", role: "제목", color: Color.component.header.text),
                        CatalogColorSpec(token: "component.header.actionText", role: "글자 버튼", color: Color.component.header.actionText),
                        CatalogColorSpec(token: "component.header.actionDisabledText", role: "글자 버튼 · 막힘", color: Color.component.header.actionDisabledText),
                        CatalogColorSpec(token: "component.header.backButtonBackground", role: "뒤로가기 바탕", color: Color.component.header.backButtonBackground),
                        CatalogColorSpec(token: "component.header.backButtonIcon", role: "뒤로가기 화살표", color: Color.component.header.backButtonIcon)
                    ],
                    fonts: [
                        (token: "pretendard.title3", role: "제목"),
                        (token: "pretendard.bodyM", role: "글자 버튼")
                    ]
                )
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "삭제처럼 되돌릴 수 없는 동작도 머리줄에서는 회색으로 둔다. 자주 누르지 않아 눈길을 끌 필요가 없고, 빨강은 누른 뒤 뜨는 확인 알림창의 [삭제]에만 쓴다. 설정·알림 화면의 머리줄(꺾쇠 뒤로가기, 높이 44)은 모양이 달라 이 부품을 쓰지 않는다."
            )
        }
    }
}

#Preview("머리줄") {
    NavigationStack { TopHeaderDoc() }
}
#endif
