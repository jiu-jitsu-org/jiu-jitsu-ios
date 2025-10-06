//
//  NicknameSettingView.swift
//  Presentation
//
//  Created by suni on 10/6/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

struct NicknameSettingView: View {
    
    @Bindable var store: StoreOf<NicknameSettingFeature>
    
    init(store: StoreOf<NicknameSettingFeature>) {
        self.store = store
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
