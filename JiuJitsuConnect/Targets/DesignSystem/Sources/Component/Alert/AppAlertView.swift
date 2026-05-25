//
//  AppAlertView.swift
//  JiuJitsuConnect
//
//  Created by suni on 11/23/25.
//

import SwiftUI

// MARK: - AppAlertView
public struct AppAlertView: View {
    
    let configuration: AppAlertConfiguration
    @Binding var isPresented: Bool
    
    public var body: some View {
        ZStack {
            Color.component.dialog.dimBg
                .ignoresSafeArea()
                .onTapGesture {
                    // Dimmed 영역을 탭하면 닫히도록 할 수 있습니다 (선택 사항).
                    // isPresented = false
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(configuration.title)
                    .font(.pretendard.title2)
                    .foregroundColor(Color.component.dialog.titleText)
                    .lineLimit(2)
                
                Text(configuration.message)
                    .font(.pretendard.bodyM)
                    .foregroundColor(Color.component.dialog.descriptionText)
                    .lineLimit(3)
                    .lineSpacing(4) // .lineHeight(8) 대신 사용
                
                HStack(spacing: 8) {
                    if let secondaryButton = configuration.secondaryButton {
                        Button(action: {
                            secondaryButton.action()
                            isPresented = false
                        }) {
                            AppButtonConfiguration(title: secondaryButton.title, size: .large)
                                .frame(maxWidth: .infinity)
                        }
                        .appButtonStyle(secondaryButton.style, size: .large, height: 51)
                    }
                    
                    Button(action: {
                        configuration.primaryButton.action()
                        isPresented = false
                    }) {
                        AppButtonConfiguration(title: configuration.primaryButton.title, size: .large)
                            .frame(maxWidth: .infinity)
                    }
                    .appButtonStyle(configuration.primaryButton.style, size: .large, height: 51)
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(Color.component.dialog.containerBg)
            .cornerRadius(20)
            .padding(.horizontal, 27.5)
            // 외부 .animation이 마운트 transaction을 통해 자식까지 전파되면
            // Button(maxWidth: .infinity)이 처음 측정될 때의 layout 변화까지
            // implicit animation으로 잡혀 "버튼이 길었다 줄어드는" 잔상이 발생한다.
            // 박스 subtree로 흐르는 transaction의 animation을 끊어, 등장은 외부 transition만
            // animate되게 하고 내부 layout은 즉시 결정되도록 한다.
            // (ButtonStyle의 isPressed animation은 자기 transaction을 따로 만들기 때문에 영향 없음.)
            .transaction { transaction in
                transaction.animation = nil
            }
        }
    }
}

// MARK: - Preview
struct AppAlertPreview: View {
    @State private var showAlertWithOneButton = false
    @State private var showAlertWithTwoButtons = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Show Alert (1 Button)") {
                showAlertWithOneButton = true
            }
            
            Button("Show Alert (2 Buttons)") {
                showAlertWithTwoButtons = true
            }
        }
        .appAlert(
            isPresented: $showAlertWithOneButton,
            configuration: .init(
                title: "로그아웃",
                message: "정말 로그아웃 하시겠어요?",
                primaryButton: .init(title: "확인", action: { }), secondaryButton: nil)
        )
        .appAlert(
            isPresented: $showAlertWithTwoButtons,
            configuration: .init(
                title: "회원 탈퇴",
                message: "정말 탈퇴 하시겠어요?\n모든 정보가 삭제되며 복구할 수 없습니다.",
                primaryButton: .init(title: "탈퇴", action: { }),
                secondaryButton: .init(title: "취소", action: { })
            )
        )
    }
}

#Preview {
    AppAlertPreview()
}
