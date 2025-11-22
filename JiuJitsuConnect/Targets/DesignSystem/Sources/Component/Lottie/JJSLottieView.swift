//
//  JJSLottieView.swift
//  DesignSystem
//
//  Created by suni on 11/21/25.
//

import SwiftUI
import Lottie

public struct JJSLottieView: UIViewRepresentable {
    private let filename: String
    private let loopMode: LottieLoopMode
    
    public init(_ filename: String, loopMode: LottieLoopMode = .loop) {
        self.filename = filename
        self.loopMode = loopMode
    }
    
    public func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        
        let configuration = LottieConfiguration(renderingEngine: .mainThread)
        view.configuration = configuration
        
        view.contentMode = .scaleAspectFit
        
        Task {
            // 1. .lottie (DotLottie) 로드 시도
            // await 키워드를 사용해 비동기적으로 파일을 불러옵니다.
            if let dotLottie = try? await DotLottieFile.named(filename, bundle: Bundle.module) {
                
                // UI 업데이트는 반드시 메인 스레드에서 해야 합니다.
                await MainActor.run {
                    view.loadAnimation(from: dotLottie)
                    view.loopMode = loopMode
                    view.play()
                }
                
            }
            // 2. 실패 시 JSON 로드 시도 (기존 방식)
            else if let animation = LottieAnimation.named(filename, bundle: Bundle.module) {
                
                await MainActor.run {
                    view.animation = animation
                    view.loopMode = loopMode
                    view.play()
                }
                
            } else {
                print("❌ Lottie 로드 실패: \(filename)")
            }
        }
        
        return view
    }
    
    public func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        // 필요 시 업데이트 로직
    }
}
