//
//  TermsWebViewFeature.swift
//  Presentation
//
//  Created by suni on 5/18/26.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct TermsWebViewFeature: Sendable {
    public init() {}

    @ObservableState
    public struct State: Equatable, Sendable {
        public let url: URL

        public init(url: URL) {
            self.url = url
        }
    }

    public enum Action: Sendable {
        case view(ViewAction)
        case delegate(DelegateAction)

        public enum ViewAction: Sendable {
            case closeButtonTapped
        }

        public enum DelegateAction: Sendable {
            case didClose
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .view(.closeButtonTapped):
                return .send(.delegate(.didClose))

            case .delegate:
                return .none
            }
        }
    }
}
