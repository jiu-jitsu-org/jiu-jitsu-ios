//
//  SettingView.swift
//  Presentation
//
//  Created by suni on 11/6/25.
//

import SwiftUI
import ComposableArchitecture

struct SettingView: View {
    @Bindable var store: StoreOf<SettingFeature>
    
    init(store: StoreOf<SettingFeature>) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            Text("설정 화면")
            Text("로그인/회원가입 성공!")
            if let nickname = store.authInfo.userInfo?.nickname {
                Text("환영합니다, \(nickname)님")
            }
        }
    }
}
