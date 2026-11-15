#if DEBUG || BETA
//
//  TextFieldDoc.swift
//  DesignSystem
//
//  부품 — 입력칸(MultilineTextField). 실제 부품을 그대로 넣어 그린다.
//

import SwiftUI

struct TextFieldDoc: View {
    @State private var liveText = ""
    @State private var isLiveFocused = false
    @State private var filledText = "오스 주짓수 아카데미 강남점"
    @State private var errorText = "닉네임!!"
    @State private var unfocused = false

    var body: some View {
        CatalogDoc(
            group: .component,
            title: "입력칸",
            summary: "닉네임·도장명·대회명처럼 값 하나를 크게 받는 가운데 정렬 입력칸. 길면 줄바꿈되고, Return 은 줄을 넣지 않고 다음 단계로 보낸다.",
            chips: ["쓰는 곳 3(3화면)", "글자 display1", "상태 4", "2026-11-16 기준"]
        ) {
            CatalogSection(title: "개요") {
                CatalogPlate {
                    field($filledText, color: Color.component.textfieldDisplay.focus.text)
                }
            }

            CatalogSection(title: "해부도") {
                CatalogAnatomyList(items: [
                    "제목(화면이 그림) — textfieldDisplay.<상태>.title",
                    "입력 글자 — UIFont.pretendard.display1, 가운데 정렬, 폭을 넘으면 줄바꿈",
                    "커서 — 비어 있을 때는 숨기고 화면이 그린 커서를 쓴다(tintColor .clear)"
                ])
            }

            CatalogSection(title: "상태", note: "글자 색만 바뀐다. 테두리·바탕은 없다. 닉네임·도장명 화면은 오류 때 default.placeholder 를 쓴다(error.text 와 같은 text.tertiary).") {
                CatalogPlate {
                    VStack(spacing: 20) {
                        CatalogCaptioned(caption: "비어 있음 — 자리 글자는 화면이 따로 그린다") {
                            Text("닉네임을 입력해 주세요")
                                .font(.pretendard.display1)
                                .foregroundStyle(Color.component.textfieldDisplay.default.placeholder)
                        }
                        CatalogCaptioned(caption: "입력 중 · 채움") {
                            field($filledText, color: Color.component.textfieldDisplay.focus.text)
                        }
                        CatalogCaptioned(caption: "오류 — 글자가 회색으로 흐려진다. 이유는 아래 안내 줄이 말한다") {
                            field($errorText, color: Color.component.textfieldDisplay.error.text)
                        }
                    }
                }
            }

            CatalogSection(title: "직접 입력", note: "Return 을 눌러도 줄이 들어가지 않는다.") {
                CatalogPlate {
                    VStack(spacing: 12) {
                        ZStack {
                            if liveText.isEmpty {
                                Text("도장 이름")
                                    .font(.pretendard.display1)
                                    .foregroundStyle(Color.component.textfieldDisplay.default.placeholder)
                            }
                            MultilineTextField(
                                text: $liveText,
                                isFocused: $isLiveFocused,
                                font: UIFont.pretendard.display1,
                                textColor: Color.component.textfieldDisplay.focus.text,
                                tintColor: Color.component.textfieldDisplay.focus.text,
                                onSubmit: { isLiveFocused = false }
                            )
                        }
                        Text("글자 \(liveText.count)")
                            .font(.pretendard.labelM)
                            .foregroundStyle(Color.semantic.text.secondary)
                    }
                }
            }

            CatalogSection(title: "가이드라인") {
                CatalogGuideline(
                    goodText: "값 하나를 받는 단계 화면에서 화면 가운데 크게 쓴다. 위 제목이 무엇을 쓰는지 알려 준다.",
                    badText: "여러 칸을 받는 폼이나 긴 글(게시글·댓글)에는 쓰지 않는다. Return 으로 줄을 넣을 수 없다."
                ) {
                    field(.constant("블루벨트"), color: Color.component.textfieldDisplay.focus.text)
                } bad: {
                    field(.constant("오늘 오픈매트 다녀왔어요 다들 수고하셨습니다"), color: Color.component.textfieldDisplay.focus.text)
                }
            }

            CatalogSection(title: "스펙") {
                CatalogSpecTable(
                    colors: [
                        CatalogColorSpec(token: "component.textfieldDisplay.default.title", role: "제목 · 기본", color: Color.component.textfieldDisplay.default.title),
                        CatalogColorSpec(token: "component.textfieldDisplay.default.placeholder", role: "자리 글자", color: Color.component.textfieldDisplay.default.placeholder),
                        CatalogColorSpec(token: "component.textfieldDisplay.focus.title", role: "제목 · 입력 중", color: Color.component.textfieldDisplay.focus.title),
                        CatalogColorSpec(token: "component.textfieldDisplay.focus.text", role: "글자 · 커서", color: Color.component.textfieldDisplay.focus.text),
                        CatalogColorSpec(token: "component.textfieldDisplay.error.title", role: "제목 · 오류", color: Color.component.textfieldDisplay.error.title),
                        CatalogColorSpec(token: "component.textfieldDisplay.error.text", role: "글자 · 오류", color: Color.component.textfieldDisplay.error.text)
                    ],
                    fonts: [(token: "UIFont.pretendard.display1", role: "입력 글자(앱 3곳 모두)")]
                )
            }

            CatalogNote(
                title: "이 서비스만의 사정",
                text: "SwiftUI TextField(axis: .vertical) 는 Return 이 줄바꿈으로 들어온 뒤에야 지울 수 있어 한 프레임 깜빡인다. 그래서 UITextView 로 감싸 Return 자체를 막았다. 한글 조합 중 같은 값을 되쓰면 조합이 끊겨 값이 다를 때만 바꾼다. 색 토큰에는 상자형 입력칸(component.textfield·textfieldMultiline)도 있지만 이를 쓰는 공용 부품은 아직 없다."
            )
        }
    }

    private func field(_ text: Binding<String>, color: Color) -> some View {
        MultilineTextField(
            text: text,
            isFocused: $unfocused,
            font: UIFont.pretendard.display1,
            textColor: color,
            tintColor: .clear,
            onSubmit: {}
        )
    }
}

#Preview("입력칸") {
    NavigationStack { TextFieldDoc() }
}

#endif
